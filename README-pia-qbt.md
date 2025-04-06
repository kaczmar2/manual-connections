# VPN and qBittorrent Port Forwarding Integration

This system automates the setup of a Private Internet Access (PIA) VPN connection using WireGuard and dynamically updates the qBittorrent listening port and interface with the forwarded port assigned by PIA.

## 1. Modifications to `port_forwarding.sh`

The original `port_forwarding.sh` script (used by PIA's manual setup) was modified to:
- **Directly invoke** the `update-qbt-port.sh` script, passing the forwarded port as an argument:

```bash
echo -e "${green}Calling update-qbt-port.sh with port ${port}${nc}"
/opt/pia/update-qbt-port.sh "$port"
```

This ensures qBittorrent is updated immediately after PIA assigns the port, avoiding race conditions or stale data.

## 2. `update-qbt-port.sh`

This script accepts the forwarded port as a command-line argument and updates the qBittorrent listening port using its Web API.

Key features:
- Validates the provided port argument.
- Authenticates with the qBittorrent Web UI using configured credentials.
- Sends a JSON request to update the `listen_port` and `current_network_interface` settings.
- Waits for qBittorrent to become available before attempting to update.
- Outputs either `success` or an `error` message for systemd logging.

> Path: `/opt/pia/update-qbt-port.sh`

## 3. Systemd Service: `pia-vpn.service`

The `pia-vpn.service` systemd unit handles VPN startup and split tunneling.

### Key behavior:
- Adds the LAN route before VPN connection to preserve internal network access.
- Starts the VPN using `run_setup.sh`, which includes `port_forwarding.sh` and triggers the qBittorrent port update.
- Uses `Type=idle` to allow the system to complete other boot tasks before starting the VPN service, reducing boot time impact and avoiding network-related race conditions.

### Sample `pia-vpn.service`:
```ini
[Unit]
Description=Private Internet Access VPN (WireGuard with Split Tunnel)
After=network.target

[Service]
Type=idle
WorkingDirectory=/opt/pia
Environment="VPN_PROTOCOL=wireguard"
Environment="DISABLE_IPV6=yes"
Environment="AUTOCONNECT=true"
Environment="PIA_PF=true"
Environment="PIA_DNS=true"
Environment="PIA_USER=p0123456"
Environment="PIA_PASS=xxxxxxxxx"
ExecStart=/bin/bash -c './add-lan-route.sh && ./run_setup.sh'
ExecStopPost=/bin/bash -c '/opt/pia/remove-lan-route.sh; wg-quick down pia'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

This service ensures full automation of the VPN tunnel, local network access, and qBittorrent port forwarding at boot, without delaying system startup.
