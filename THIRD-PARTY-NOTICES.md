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
- **Pinned commit:** 064134c760fbf09db207449c01635202a0e7d1d1
- **License:** BSD 3-Clause
- **Copyright:** Copyright (c) 2015 Iquidus Technology; Copyright (c) 2015 Luke Williams
- **No-endorsement clause:** The BSD 3-Clause license prohibits use of Iquidus or contributor names for endorsement of derivative products without specific prior written permission.
- **Installation:** Cloned via git from upstream at install time (`git clone` + `git checkout <commit>`)
- **Dependencies:** npm packages installed via `npm install --production`
- **Reproducibility note:** The upstream Iquidus repository does not include a package-lock.json. Dependencies are resolved from package.json version ranges on each install. This means builds are not fully reproducible across different points in time. The Iquidus commit is pinned to mitigate code changes, but npm dependency resolution may vary. Use of Node.js 20.x LTS and a documented npm version is recommended for consistent builds.

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
