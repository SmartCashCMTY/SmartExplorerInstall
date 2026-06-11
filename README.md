# SmartExplorerInstall 3.0.0

Installer for the SmartCash 3.0.0 Block Explorer (Iquidus).

## Quick Start

```bash
wget https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/main/SmartInstallExplorer.sh
sudo bash ./SmartInstallExplorer.sh
```

## What It Does

- Downloads and verifies the SmartCash 3.0.0 binaries from [Node-Client-Wallet releases](https://github.com/SmartCashCMTY/Node-Client-Wallet/releases/tag/v3.0.0)
- Installs MongoDB, Node.js 18, Nginx, and the Iquidus Explorer
- Creates systemd services: `smartcash3.service`, `iquidus-explorer.service`
- Configures UFW firewall (IPv6 disabled), fail2ban, chrony, swap
- Connects to seed nodes `151.252.59.32:29678` and `151.252.59.33:29678`

## Useful Commands

```bash
systemctl status smartcash3 --no-pager
systemctl status mongod --no-pager
systemctl status iquidus-explorer --no-pager
journalctl -u iquidus-explorer -f
```

## Initial Database Sync

```bash
cd /opt/smartcash3/explorer
sudo -u iquidus node scripts/sync.js index update
sudo -u iquidus node scripts/peers.js
```

## Open the Explorer

`http://YOUR_SERVER_IP/explorer/`

## License

SmartCash Core and related projects are released under the terms of the MIT license.