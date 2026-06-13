# SmartExplorer 3.0.0 Complete Guide

This guide explains how to install, configure and operate a SmartCash 3.0.0
Iquidus Explorer on Ubuntu Server 24.04 LTS using copy/paste commands.

The installer uses the original Iquidus Explorer footer. It does not apply the
custom footer used on the current community-hosted explorer.

## 1. Introduction

### What Is The Iquidus Explorer?

Iquidus Explorer is a Node.js blockchain explorer. It connects to a coin daemon
through RPC, reads block and transaction data, stores indexed data in MongoDB and
serves web pages and API routes through Express.

### How A Blockchain Explorer Works

1. The SmartCash Core daemon syncs the blockchain from the peer-to-peer network.
2. The Explorer calls SmartCash Core RPC methods such as block, transaction and
   peer queries.
3. The Explorer stores derived data in MongoDB collections.
4. The web process reads MongoDB and RPC data and renders HTML/API responses.

### Architecture And Components

- Ubuntu Server 24.04 LTS
- SmartCash Core 3.0.0 daemon
- Iquidus Explorer Node.js application
- MongoDB database
- Nginx reverse proxy
- systemd services for SmartCash, MongoDB and Explorer

### Connection To Smart Core Wallet / Smart Node

The Explorer uses local RPC:

- SmartCash RPC host: `127.0.0.1`
- RPC port: `29679`
- P2P port: `29678`
- Database: MongoDB `smartcash3`

The local SmartCash daemon must run with transaction indexing enabled. The guide
uses:

```ini
txindex=1
addressindex=1
spentindex=1
timestampindex=1
```

TODO: Confirm whether every index flag above is required for all Iquidus pages on
future SmartCash 3.0.0 builds. The current recovery build supports the address
RPC/index calls used by the deployed Explorer.

### Advantages And Use Cases

- Public block, transaction and address lookup.
- API endpoint for community tools.
- Network visibility for peers and chain height.
- Richlist and movement pages after full historical indexing.
- Independent monitoring of SmartCash 3.0.0 chain state.

## 2. Hardware Requirements

### Minimum

- CPU: 2 vCPU
- RAM: 4 GB
- Swap: 4 GB
- SSD: 100 GB
- Network: public IPv4, 10 Mbit/s+
- Use case: testing or small private explorer

### Recommended

- CPU: 4 vCPU
- RAM: 8-16 GB
- Swap: 4 GB
- SSD/NVMe: 160 GB+
- Network: public IPv4, 100 Mbit/s+
- Use case: public community explorer

### Production

- CPU: 6-8 vCPU
- RAM: 24-32 GB
- Swap: 4-8 GB
- NVMe: 250 GB+
- Network: static public IPv4, 1 Gbit/s preferred
- Monitoring: systemd, disk, MongoDB, SmartCash daemon, Nginx

### VPS, Dedicated Server And Cloud Recommendations

- VPS is acceptable if disk I/O is stable and SSD/NVMe-backed.
- Dedicated servers are preferred for public production explorers.
- Cloud instances are acceptable if they provide stable public IPv4 and enough
  disk I/O.
- Avoid HDD-only servers for full historical indexing.

### Estimated Costs

- Testing VPS: approximately 10-25 EUR/month.
- Recommended public VPS: approximately 25-80 EUR/month.
- Production dedicated/NVMe server: approximately 80-200 EUR/month.

Prices vary by provider and region.

## 3. Server Preparation On Ubuntu 24.04

Update and reboot:

```bash
sudo apt update
sudo apt -y upgrade
sudo reboot
```

Install base packages:

```bash
sudo apt install -y curl ca-certificates gnupg lsb-release git build-essential python3 make g++ ufw fail2ban htop jq tar unzip openssl nginx chrony unattended-upgrades apt-listchanges
```

Configure timezone:

```bash
sudo timedatectl set-timezone UTC
sudo systemctl enable --now chrony
timedatectl
```

Configure UFW:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 29678/tcp
sudo ufw --force enable
sudo ufw status verbose
```

Install and enable Fail2Ban:

```bash
sudo systemctl enable --now fail2ban
sudo systemctl status fail2ban --no-pager
```

Create swap:

```bash
if ! swapon --show | grep -q '^'; then
  sudo swapoff /swapfile 2>/dev/null || true
  sudo rm -f /swapfile
  sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=none
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile > /dev/null
  if sudo swapon /swapfile 2>/dev/null; then
    echo "Swap enabled"
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  elif sudo modprobe loop 2>/dev/null && LOOPDEV=$(sudo losetup -f 2>/dev/null) && [ -n "$LOOPDEV" ]; then
    sudo losetup "$LOOPDEV" /swapfile
    sudo swapon "$LOOPDEV"
    echo "Swap enabled via loop device"
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  else
    sudo rm -f /swapfile
    echo "WARNING: Could not enable swap (ZFS/LXC). Continuing without."
  fi
fi
free -h
```

Enable automatic security updates:

```bash
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
sudo systemctl restart unattended-upgrades
```

## 4. Install Dependencies

Install Git, curl and build tools:

```bash
sudo apt install -y git curl ca-certificates build-essential python3 make g++
```

Install Node.js 20.x LTS:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs
node --version
npm --version
```

Node.js 20.x LTS is used because it has been tested with the current SmartCash 3.0.0
Explorer deployment environment. TODO: Validate newer Node.js LTS versions before
recommending them for production.

Install MongoDB 8.0 for Ubuntu 24.04:

```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /etc/apt/keyrings/mongodb-server-8.0.gpg
echo 'deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod
sudo systemctl status mongod --no-pager
```

## 5. Install Smart Core Wallet / Smart Node

Create users and directories:

```bash
sudo useradd --system --home /var/lib/smartcash3 --shell /usr/sbin/nologin smartcash || true
sudo install -d -m 0750 -o smartcash -g smartcash /var/lib/smartcash3
sudo install -d -m 0755 /etc/smartcash3
```

Download SmartCash Core 3.0.0 Linux binaries from GitHub:

```bash
cd /tmp
curl -fLO https://github.com/SmartCashCMTY/SmartNode/releases/download/v3.0.0/smartcash3-3.0.0-x86_64-linux-gnu.tar.gz
printf '%s  %s\n' 'd53c8195768490808c88d178cfb387102b8e69ab452e4c7baddf9af5c44993eb' 'smartcash3-3.0.0-x86_64-linux-gnu.tar.gz' | sha256sum -c -
tar -xzf smartcash3-3.0.0-x86_64-linux-gnu.tar.gz
sudo install -m 0755 linux-x86_64/smartcashd /usr/local/bin/smartcashd
sudo install -m 0755 linux-x86_64/smartcash-cli /usr/local/bin/smartcash-cli
sudo install -m 0755 linux-x86_64/smartcash-tx /usr/local/bin/smartcash-tx
```

Create SmartCash RPC configuration:

```bash
RPCPASSWORD="$(openssl rand -hex 32)"
EXTERNAL_IP="$(curl -fsS4 https://ifconfig.me || true)"
sudo tee /etc/smartcash3/smartcash.conf >/dev/null <<EOF
daemon=1
server=1
listen=1
txindex=1
addressindex=1
spentindex=1
timestampindex=1
maxconnections=128
port=29678
rpcport=29679
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
rpcuser=smartcashrpc
rpcpassword=${RPCPASSWORD}
externalip=${EXTERNAL_IP}:29678
addnode=151.252.59.32:29678
addnode=151.252.59.33:29678
EOF
sudo chown root:smartcash /etc/smartcash3/smartcash.conf
sudo chmod 0640 /etc/smartcash3/smartcash.conf
```

Install SmartCash systemd service:

```bash
sudo tee /etc/systemd/system/smartcash3.service >/dev/null <<'EOF'
[Unit]
Description=SmartCash 3.0.0 daemon
After=network-online.target
Wants=network-online.target

[Service]
User=smartcash
Group=smartcash
Type=forking
PIDFile=/var/lib/smartcash3/smartcashd.pid
ExecStart=/usr/local/bin/smartcashd -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 -pid=/var/lib/smartcash3/smartcashd.pid
ExecStop=/usr/local/bin/smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 stop
Restart=always
RestartSec=10
TimeoutStartSec=600
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now smartcash3
```

Check sync:

```bash
smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 getblockcount
smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 getconnectioncount
```

## 6. Install Iquidus Explorer

Clone the Explorer:

```bash
sudo install -d -m 0755 /opt/smartcash3
sudo git clone https://github.com/iquidus/explorer.git /opt/smartcash3/explorer
cd /opt/smartcash3/explorer
sudo npm install --production
```

Create Explorer user:

```bash
sudo useradd --system --home /opt/smartcash3/explorer --shell /usr/sbin/nologin iquidus || true
sudo chown -R iquidus:iquidus /opt/smartcash3/explorer
```

Create `settings.json`. Use the same RPC values from `/etc/smartcash3/smartcash.conf`:

```bash
RPCUSER="$(sudo awk -F= '/^rpcuser=/{print $2}' /etc/smartcash3/smartcash.conf)"
RPCPASSWORD="$(sudo awk -F= '/^rpcpassword=/{print $2}' /etc/smartcash3/smartcash.conf)"
cd /opt/smartcash3/explorer
sudo tee settings.json >/dev/null <<EOF
{
  "title": "SmartCash 3.0 Explorer",
  "address": "127.0.0.1:3001",
  "coin": "SmartCash",
  "symbol": "SMART",
  "theme": "Cerulean",
  "port": 3001,
  "dbsettings": {
    "user": "",
    "password": "",
    "database": "smartcash3",
    "address": "127.0.0.1",
    "port": 27017
  },
  "wallet": {
    "host": "127.0.0.1",
    "port": 29679,
    "user": "${RPCUSER}",
    "pass": "${RPCPASSWORD}"
  },
  "confirmations": 10,
  "locale": "locale/en.json",
  "display": {
    "api": true,
    "markets": false,
    "richlist": true,
    "movement": true,
    "network": true
  },
  "index": {"show_hashrate": true, "show_market_cap": false, "show_market_cap_over_price": false, "difficulty": "POW", "last_txs": 100, "txs_per_page": 10},
  "markets": {"coin": "SMART", "exchange": "USD", "enabled": [], "default": ""},
  "nethash": "getnetworkhashps",
  "nethash_units": "H"
}
EOF
sudo chown iquidus:iquidus settings.json
```

Initialize database and peer data:

```bash
cd /opt/smartcash3/explorer
sudo -u iquidus node scripts/sync.js index update
sudo -u iquidus node scripts/peers.js
```

## 7. Blockchain Import, Reindex And Rescan

Initial import:

```bash
cd /opt/smartcash3/explorer
sudo -u iquidus node scripts/sync.js index update
```

Update after initial import:

```bash
cd /opt/smartcash3/explorer
sudo -u iquidus node scripts/sync.js index update
sudo -u iquidus node scripts/peers.js
```

If Core indexing flags were changed after first sync, stop Core and reindex:

```bash
sudo systemctl stop smartcash3
sudo -u smartcash /usr/local/bin/smartcashd -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 -reindex
```

Wait until reindex finishes, then restart normal service:

```bash
sudo pkill smartcashd || true
sudo systemctl start smartcash3
```

For Explorer DB rebuild, drop MongoDB database and run full import again:

```bash
mongosh smartcash3 --eval 'db.dropDatabase()'
cd /opt/smartcash3/explorer
sudo -u iquidus node scripts/sync.js index update
```

If `mongosh` is not installed:

```bash
sudo apt install -y mongodb-mongosh
```

## 8. Full Copy/Paste Installation

Use the installer:

```bash
wget https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/main/smart-iquidus-install.sh
sudo bash ./smart-iquidus-install.sh
```

The script installs packages, Node.js, MongoDB, SmartCash Core, Iquidus Explorer,
systemd services, Nginx and firewall rules. After installation, run initial DB
sync:

```bash
cd /opt/smartcash3/explorer
sudo -u iquidus node scripts/sync.js index update
sudo -u iquidus node scripts/peers.js
```

## 9. systemd Service

Explorer service file:

```ini
[Unit]
Description=SmartCash 3.0.0 Iquidus Explorer
After=network-online.target mongod.service smartcash3.service
Wants=network-online.target

[Service]
User=iquidus
Group=iquidus
WorkingDirectory=/opt/smartcash3/explorer
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
TimeoutStartSec=120
TimeoutStopSec=30
LimitNOFILE=65536
MemoryMax=2G
CPUQuota=200%
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

Install it:

```bash
sudo curl -fsSL -o /etc/systemd/system/iquidus-explorer.service https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/main/iquidus-explorer.service
sudo systemctl daemon-reload
sudo systemctl enable --now iquidus-explorer
```

## 10. Operation And Monitoring

Start Explorer:

```bash
sudo systemctl start iquidus-explorer
```

Stop Explorer:

```bash
sudo systemctl stop iquidus-explorer
```

Restart Explorer:

```bash
sudo systemctl restart iquidus-explorer
```

Status:

```bash
systemctl status iquidus-explorer --no-pager
systemctl status smartcash3 --no-pager
systemctl status mongod --no-pager
```

Logs:

```bash
journalctl -u iquidus-explorer -f
sudo tail -f /var/lib/smartcash3/debug.log
```

MongoDB monitoring:

```bash
mongosh smartcash3 --eval 'db.stats()'
mongosh smartcash3 --eval 'db.txes.countDocuments()'
```

Node monitoring:

```bash
smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 getblockcount
smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 getconnectioncount
```

Optional Prometheus/Grafana:

- Use `node_exporter` for system metrics.
- Use MongoDB exporter for MongoDB metrics.
- Use custom scripts for SmartCash block height and connection count.
- TODO: Add a ready-made Grafana dashboard after community metrics naming is
  finalized.

## 11. Reverse Proxy And Domain

### Nginx

Install config:

```bash
sudo curl -fsSL -o /etc/nginx/sites-available/smart-iquidus-explorer https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/main/nginx.conf
sudo ln -sf /etc/nginx/sites-available/smart-iquidus-explorer /etc/nginx/sites-enabled/smart-iquidus-explorer
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

For a real domain, replace `server_name _;` with your domain:

```nginx
server_name explorer.example.org;
```

### Apache Alternative

```bash
sudo apt install -y apache2
sudo a2enmod proxy proxy_http headers ssl
```

Example virtual host:

```apache
<VirtualHost *:80>
    ServerName explorer.example.org
    ProxyPreserveHost On
    ProxyPass /explorer/ http://127.0.0.1:3001/
    ProxyPassReverse /explorer/ http://127.0.0.1:3001/
</VirtualHost>
```

### Let's Encrypt SSL

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d explorer.example.org
```

Force HTTPS when Certbot asks, or add a redirect server block manually.

## 12. Updates And Rollback

Update Explorer:

```bash
cd /opt/smartcash3/explorer
sudo systemctl stop iquidus-explorer
sudo git pull
sudo npm install --production
sudo chown -R iquidus:iquidus /opt/smartcash3/explorer
sudo systemctl start iquidus-explorer
```

Update MongoDB:

```bash
sudo apt update
sudo apt install --only-upgrade mongodb-org
sudo systemctl restart mongod
```

Update Node.js:

```bash
sudo apt update
sudo apt install --only-upgrade nodejs
node --version
sudo systemctl restart iquidus-explorer
```

Update SmartCash Core:

```bash
sudo systemctl stop smartcash3
# Download and verify the new SmartCash release before replacing binaries.
sudo systemctl start smartcash3
```

Rollback Explorer:

```bash
cd /opt/smartcash3/explorer
sudo git log --oneline -5
sudo git checkout PREVIOUS_COMMIT_HASH
sudo npm install --production
sudo systemctl restart iquidus-explorer
```

## 13. Troubleshooting

### 1. Explorer Does Not Start

```bash
systemctl status iquidus-explorer --no-pager
journalctl -u iquidus-explorer --since "30 minutes ago" --no-pager
```

Check `settings.json` JSON syntax:

```bash
node -e 'JSON.parse(require("fs").readFileSync("/opt/smartcash3/explorer/settings.json"))'
```

### 2. MongoDB Is Not Running

```bash
systemctl status mongod --no-pager
sudo systemctl restart mongod
journalctl -u mongod --since "30 minutes ago" --no-pager
```

### 3. RPC Authentication Failed

Compare `/etc/smartcash3/smartcash.conf` and Explorer `settings.json` wallet
user/pass values.

```bash
sudo grep '^rpc' /etc/smartcash3/smartcash.conf
sudo grep -A6 '"wallet"' /opt/smartcash3/explorer/settings.json
```

### 4. Explorer Shows No Blocks

Run index update:

```bash
cd /opt/smartcash3/explorer
sudo -u iquidus node scripts/sync.js index update
```

### 5. Core Node Has No Peers

```bash
smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 getconnectioncount
sudo ufw status verbose
```

Ensure `29678/tcp` is open.

### 6. `Loading block index...`

The SmartCash daemon is still starting. Wait and retry:

```bash
sleep 60
smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 getblockcount
```

### 7. MongoDB Disk Usage Too High

```bash
df -h
sudo du -sh /var/lib/mongodb
```

Increase disk size. Avoid deleting MongoDB files manually while `mongod` is
running.

### 8. Initial Import Is Very Slow

Use faster NVMe storage, more CPU, and enough RAM. Keep only one indexer process
running against one MongoDB database.

### 9. Explorer Lock File Exists

Check for running indexer first:

```bash
ps aux | grep 'scripts/sync.js' | grep -v grep || true
```

If no indexer runs, remove stale locks:

```bash
sudo rm -f /opt/smartcash3/explorer/tmp/index.pid /opt/smartcash3/explorer/tmp/db_index.pid
```

### 10. Nginx Returns 502

Check Explorer process:

```bash
systemctl status iquidus-explorer --no-pager
curl -I http://127.0.0.1:3001/
sudo nginx -t
```

### 11. Address Pages Are Incomplete

Wait for full historical indexing to finish. Richlist and address views depend on
the Explorer database.

### 12. Package Installation Fails

```bash
sudo apt update
sudo apt --fix-broken install
sudo dpkg --configure -a
```

## 14. FAQ

### 1. Is this the same Explorer deployed for SmartCash 3.0.0?

It uses the same Iquidus Explorer base and SmartCash Core 3.0.0 network settings,
but this guide keeps the original Iquidus footer as requested.

### 2. Does this install a SmartNode?

No. It installs a SmartCash Core node for Explorer RPC and indexing. A SmartNode
can be installed separately.

### 3. Which ports are public?

HTTP `80/tcp` and SmartCash P2P `29678/tcp`. RPC `29679` stays local.

### 4. Which database is used?

MongoDB database `smartcash3`.

### 5. Can I run the Explorer without MongoDB?

No. Iquidus stores indexed chain data in MongoDB.

### 6. Can I use another Node.js version?

Node.js 20.x LTS is recommended for this guide. Other versions need separate testing.

### 7. Why is the first import slow?

The Explorer reads historical blocks and transactions and writes derived data to
MongoDB. This can take days on large chains or slow disks.

### 8. Can I run multiple indexers at once?

Do not run multiple historical indexers against the same MongoDB database.

### 9. Where are logs stored?

Explorer service logs are in `journalctl -u iquidus-explorer`. SmartCash Core
logs are in `/var/lib/smartcash3/debug.log`.

### 10. How do I change the domain?

Edit `/etc/nginx/sites-available/smart-iquidus-explorer`, change `server_name`,
run `nginx -t`, then restart Nginx.

### 11. Does this guide include HTTPS?

Yes, via Certbot commands in the reverse proxy section.

### 12. Does this guide modify the footer?

No. The original Iquidus footer remains unchanged.
