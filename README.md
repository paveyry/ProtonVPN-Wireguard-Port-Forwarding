ProtonVPN Wireguard Port-Forwarding
===================================

Overview
--------

This simple script (`connect.sh`) allows the user to connect to a specific wireguard
config for ProtonVPN among a pool of different config files, while always having the VPN network
interface named the same (so that it does not have to be changed in other apps if they select a
specific interface to avoid ever connecting when VPN is down for example).

### Port Forwarding

> [!WARNING]
> Just setting `NAT-PMP (Port Fowarding) = on` in the wireguard files is not enough for Port-Forwarding
to work. Port-Forwarding needs to be toggled on when generating the config file on
`https://account.protonvpn.com -> Downloads -> Wireguard configuration`

This script handles Port-Forwarding. Once the Port forwarding has started, this script can copy the port
to clipboard (set the appropriate command in the `CLIPBOARD_CMD` var to enable it, like `wl-copy`
for Wayland or `xclip` for X11). The port is also stored in a file so that other apps or scripts
can be configured to read it at startup instead of having to manually set it.

### Firewall

The script also opens the forwarded port on the Firewall. This assumes the machine uses Firewalld,
amend or remove the firewall-related commands if you use a different or no firewall.

Usage
-----

Just pass the selected wireguard config file as the unique argument to the script.

Example:

        ./connect.sh wg-UK-1.conf

Launchers
---------

It is possible to create `.desktop` launchers with flag icons by producing `.desktop` files similar
to the one in the `example-launcher-desktop` directory. The icon field links to the appropriate country
in a local clone of <https://github.com/lipis/flag-icons>.
