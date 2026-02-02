#!/bin/bash

set -e

[[ -z "$1" ]] && echo "Usage: ./connect.sh wireguard_config_file_name" && exit 1

### CONFIG VARS ###

#- Name of the wireguard connection produced (and name of the wireguard config symlink created)
INTERFACE_NAME="PROTONVPN"

#- Directory containing the various wireguard config files
VPN_CONFIG_DIR="$HOME/VPNConfig"

#- File where the forwarded port is written
PORT_FILE="$VPN_CONFIG_DIR/.port.txt"

#- Command which copies its stdin (the forwarded port) to clipboard once port forwarding is started
#- Can be `wl-copy` on Wayland or `xclip` on X11 for example
#- Default of `cat > /dev/null` means the port does not get copied to clipboard
CLIPBOARD_CMD="cat > /dev/null"


### SCRIPT ###

# Display selected config as terminal window name
printf "\33]2;$1\007"

# Kill existing wireguard connection if present
sudo wg-quick down $INTERFACE_NAME || echo "no existing connection found"

# Close last forwarded port on Firealld if it hadn't been until now
sudo firewall-cmd --zone=public --remove-port="$(cat $PORT_FILE)/tcp"
sudo firewall-cmd --zone=public --remove-port="$(cat $PORT_FILE)/udp"

# Create the symlink to the selected wireguard config file
rm -f "$VPN_CONFIG_DIR/$INTERFACE_NAME.conf"
ln -s "$VPN_CONFIG_DIR/$1" "$VPN_CONFIG_DIR/$INTERFACE_NAME.conf"

# If it does not exist, create a symlink in /etc/wireguard to the local config symlink
# This part of the script can be commented out once it has run once and the symlink is present
if ! sudo test -L "/etc/wireguard/$INTERFACE_NAME.conf"; then
    echo "CREATED /etc/wireguard symlink"
    sudo ln -s "$VPN_CONFIG_DIR/$INTERFACE_NAME.conf" "/etc/wireguard/$INTERFACE_NAME.conf"
fi

# Start wireguard connection
wg-quick up $INTERFACE_NAME

hasPort=false
# Port forwarding loop
while true 
do
    # Display time
    date

    # Execute natpmpc command to start or probe the port forwarding and capture stdout
    out="$(natpmpc -a 1 0 udp 60 -g 10.2.0.1 && natpmpc -a 1 0 tcp 60 -g 10.2.0.1 || { echo -e "ERROR with natpmpc command \a" ; break ; })"
    # Capture the port only in the first iteration
    if [ "$hasPort" = false ] ; then
        # Extract forwarded port from natpmpc stdout
        export PORT="$(echo "$out" | sed -Enz "s!.*Mapped public port ([0-9]+).*!\1!p")"
        # Write forwarded port to file
        echo "$PORT" > "$PORT_FILE"
        # Open forwarded port on Firewalld
        sudo firewall-cmd --zone=public --add-port="$PORT/tcp"
        sudo firewall-cmd --zone=public --add-port="$PORT/udp"
        # Copy forwarded port to clipboard
        echo "$PORT" | eval "$CLIPBOARD_CMD" || echo "Clipboard copy command failed"
        hasPort=true
    fi
    # Display natpmpc stdout
    echo "$out"
    # Display forwarded port and disclaimer to not close the terminal
    echo "PORT FORWARDING ENABLED ON PORT $PORT -- KEEP TERMINAL OPEN TO KEEP PORT FORWARDING ACTIVE"
    # Sleep 45 seconds to make sure to probe natpmpc before the 60s expiry of the previous iteration
    sleep 45
done
