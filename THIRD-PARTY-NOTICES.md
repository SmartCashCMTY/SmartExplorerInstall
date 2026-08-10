# Third-Party Notices

This repository provides an automated installer that downloads, installs, and
configures multiple third-party software components. The installer scripts
themselves are MIT-licensed by SmartCashCMTY.

## Software Installed by This Installer

### SmartCash Core 3.0.0

- **Project:** SmartCash Core (based on Bitcoin Core)
- **Upstream:** https://github.com/SmartCashCMTY/Core-Source-Repo
- **Download source:** https://github.com/SmartCashCMTY/Node-Client-Wallet/releases/tag/v3.0.0
- **Binary:** smartcash3-3.0.0-x86_64-linux-gnu.tar.gz
- **License:** MIT
- **Copyright:** Copyright (c) 2009-2017 The Bitcoin Core developers; Copyright (c) 2017-2020 The SmartCash developers
- **Integrity:** SHA256 checksum verified at install time

### Iquidus Explorer

- **Project:** Iquidus Explorer
- **Upstream:** https://github.com/iquidus/explorer
- **License:** MIT
- **Copyright:** Copyright (c) 2015 Iquidus Technology / Luke Williams
- **Installation:** Cloned via git from upstream at install time
- **Dependencies:** npm packages installed via `npm install --production`

### MongoDB 8.0

- **Project:** MongoDB Community Server
- **Upstream:** https://www.mongodb.com/
- **License:** Server Side Public License (SSPL) v1
- **Installation source:** MongoDB APT repository (repo.mongodb.org)
- **GPG key:** https://pgp.mongodb.com/server-8.0.asc

### Node.js 20.x LTS

- **Project:** Node.js
- **Upstream:** https://nodejs.org/
- **License:** MIT
- **Installation source:** NodeSource APT repository (deb.nodesource.com)

### Nginx

- **Project:** Nginx
- **Upstream:** https://nginx.org/
- **License:** 2-clause BSD
- **Installation source:** Ubuntu APT repository

### System Packages (Ubuntu 24.04 APT Repositories)

- curl, ca-certificates, gnupg, lsb-release, git, build-essential, python3, make, g++
- ufw, fail2ban, htop, jq, tar, unzip, openssl, chrony
- unattended-upgrades, apt-listchanges

Each package is distributed under its respective open-source license.

## Custom SmartExplorer Assets

The installer downloads custom SmartExplorer overlay files from:
https://github.com/SmartCashCMTY/SmartExplorer/

These files (templates, routes, scripts, configuration) are the intellectual
property of SmartCashCMTY and are distributed under the MIT License.

## Trademarks

"SmartCash", "Bitcoin", "Iquidus", "MongoDB", "Node.js", "Nginx", and other
names and logos are trademarks of their respective owners. This project is not
affiliated with or endorsed by any of the upstream projects.
