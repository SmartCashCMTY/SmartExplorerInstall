# SmartExplorerInstall 3.0.0

SmartCash 3.0.0 Explorer Update 3.0.0 installer for Ubuntu Server 24.04 LTS.

## What It Does
- Downloads and verifies the SmartCash 3.0.0 binaries
- Installs MongoDB, Node.js, Nginx, and Iquidus Explorer
- Creates the explorer and daemon systemd services
- Configures firewall, fail2ban, chrony, and swap

## Quick Start
```bash
wget https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/main/SmartInstallExplorer.sh
sudo bash ./SmartInstallExplorer.sh
```

## System Requirements
- Ubuntu Server 24.04 LTS
- Public IPv4 address
- 2 vCPU
- 4 GB RAM or better
- 30 GB SSD or more

## Hardware Requirements
- VPS or dedicated server with static public IPv4
- Open inbound ports as required by the installer
- Stable internet connection
## Installation
```bash
wget https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/main/SmartInstallExplorer.sh
sudo bash ./SmartInstallExplorer.sh
```

## Configuration
- Explorer config: `/opt/smartcash3/explorer/settings.json`
- SmartCash config: `/etc/smartcash3/smartcash.conf`
- Web access: `http://YOUR_SERVER_IP/` or `http://YOUR_SERVER_IP/explorer/`

## Update
- Re-run the installer after backing up config and database files

## Backup
- `/opt/smartcash3/explorer/settings.json`
- `/etc/smartcash3/smartcash.conf`
- MongoDB database dump

## Security
- Keep RPC credentials private
- Never commit secrets, seed phrases, or API keys

## Credits
Original SmartCash Project: https://github.com/smartcash
This repository is an Update 3.0.0 based on the open-source work of the SmartCash project.
All rights to original components, trademarks, logos, source code, and documentation remain with their respective owners.
The original creator and relevant open-source contributors should be acknowledged appropriately.

## License
SmartCash Core components are generally released under MIT. Iquidus Explorer and third-party components keep their own licenses.
Please check the original project license.

## Disclaimer
Use at your own risk. No warranty is provided for functionality, availability, or security. No liability is accepted for direct or indirect damages, data loss, wallet loss, lost private keys, misconfiguration, network issues, blockchain issues, software bugs, or security vulnerabilities.

## Cryptocurrency Risks
Cryptocurrencies are high-risk digital assets. Losses, including total loss, are possible. Node operation and staking-related workflows may fail or behave unexpectedly. You are responsible for wallet backups, local law compliance, and tax obligations.

## Legal Notice
Use this software in accordance with the laws and regulations that apply in your jurisdiction. You are responsible for regulatory, tax, and legal compliance in your country. No legal, tax, or financial advice is provided.
