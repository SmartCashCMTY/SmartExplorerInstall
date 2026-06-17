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
SmartCash Core is released under the MIT License. See COPYING for details.
Third-party components and libraries retain their respective licenses.
If the license of any component cannot be clearly determined, please check the original project.

## Disclaimer
This software is provided "as is", without warranty of any kind, express or implied. Use at your own risk.
The authors and contributors assume no liability for:
- Direct or indirect damages
- Data loss or corruption
- Financial losses
- Loss of access to wallets or private keys
- Misconfiguration or operator error
- Network or blockchain issues
- Software bugs or security vulnerabilities

## Cryptocurrency Risks
Cryptocurrencies involve substantial risk of loss and are not suitable for all investors.
- The value of digital assets can be highly volatile and may result in total loss
- Node operation, staking, and mining carry technical and financial risks
- You are solely responsible for securing your wallets and private keys
- You are responsible for compliance with local laws and tax obligations
- Past performance does not guarantee future results

## Legal Notice
Use of this software must comply with all applicable local, national, and international laws and regulations.
- You are responsible for regulatory, tax, and legal compliance in your jurisdiction
- No legal, tax, or financial advice is provided
- This software does not constitute an offer or solicitation of any kind
- All trademarks and logos remain the property of their respective owners