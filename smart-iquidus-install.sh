#!/usr/bin/env bash
set -euo pipefail

SMARTCASH_VERSION="3.0.0"
CORE_RELEASE_BASE="https://github.com/SmartCashCMTY/Node-Client-Wallet/releases/download/v3.0.0"
CORE_ARCHIVE="smartcash3-3.0.0-x86_64-linux-gnu.tar.gz"
CORE_SHA256="d05b8dcb75e88a70d8c280ffb32533bf680a4ed29a9fb3e48b3dcbad59ba6bd4"
EXPLORER_REPO="https://github.com/iquidus/explorer.git"
INSTALL_ROOT="/opt/smartcash3"
EXPLORER_DIR="/opt/smartcash3/explorer"
DATADIR="/var/lib/smartcash3"
CONFDIR="/etc/smartcash3"
SMARTCASH_USER="smartcash"
EXPLORER_USER="iquidus"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash smart-iquidus-install.sh" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "Installing SmartCash ${SMARTCASH_VERSION} SmartExplorer on Ubuntu 24.04"

apt-get update
apt-get -y upgrade
apt-get install -y curl ca-certificates gnupg lsb-release git build-essential python3 make g++ ufw fail2ban htop jq tar unzip openssl nginx chrony unattended-upgrades apt-listchanges

timedatectl set-timezone UTC
systemctl enable --now chrony

cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

if ! swapon --show | grep -q '^'; then
  fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
fi

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs
fi

if ! command -v mongod >/dev/null 2>&1; then
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-8.0.gpg
  echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" >/etc/apt/sources.list.d/mongodb-org-8.0.list
  apt-get update
  apt-get install -y mongodb-org
fi

systemctl enable --now mongod

id "$SMARTCASH_USER" >/dev/null 2>&1 || useradd --system --home "$DATADIR" --shell /usr/sbin/nologin "$SMARTCASH_USER"
id "$EXPLORER_USER" >/dev/null 2>&1 || useradd --system --home "$EXPLORER_DIR" --shell /usr/sbin/nologin "$EXPLORER_USER"
install -d -m 0750 -o "$SMARTCASH_USER" -g "$SMARTCASH_USER" "$DATADIR"
install -d -m 0755 "$CONFDIR"
install -d -m 0755 "$INSTALL_ROOT"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"
curl -fL -o "$CORE_ARCHIVE" "$CORE_RELEASE_BASE/$CORE_ARCHIVE"
printf '%s  %s\n' "$CORE_SHA256" "$CORE_ARCHIVE" | sha256sum -c -
tar -xzf "$CORE_ARCHIVE"
install -m 0755 linux-x86_64/smartcashd /usr/local/bin/smartcashd
install -m 0755 linux-x86_64/smartcash-cli /usr/local/bin/smartcash-cli
install -m 0755 linux-x86_64/smartcash-tx /usr/local/bin/smartcash-tx

RPCUSER="smartcashrpc"
RPCPASSWORD="$(openssl rand -hex 32)"
EXTERNAL_IP="${EXTERNAL_IP:-$(curl -fsS4 https://ifconfig.me || true)}"

cat >"$CONFDIR/smartcash.conf" <<EOF
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
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
externalip=${EXTERNAL_IP}:29678
addnode=151.252.59.32:29678
addnode=151.252.59.33:29678
EOF
chown root:"$SMARTCASH_USER" "$CONFDIR/smartcash.conf"
chmod 0640 "$CONFDIR/smartcash.conf"

cat >/etc/systemd/system/smartcash3.service <<'EOF'
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

systemctl daemon-reload
systemctl enable --now smartcash3

if [[ ! -d "$EXPLORER_DIR/.git" ]]; then
  git clone "$EXPLORER_REPO" "$EXPLORER_DIR"
fi

cd "$EXPLORER_DIR"
npm install --production

cat >settings.json <<EOF
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
  "index": {
    "show_hashrate": true,
    "show_market_cap": false,
    "show_market_cap_over_price": false,
    "difficulty": "POW",
    "last_txs": 100,
    "txs_per_page": 10
  },
  "markets": {
    "coin": "SMART",
    "exchange": "USD",
    "enabled": [],
    "default": ""
  },
  "nethash": "getnetworkhashps",
  "nethash_units": "H"
}
EOF

chown -R "$EXPLORER_USER:$EXPLORER_USER" "$EXPLORER_DIR"

cat >/etc/systemd/system/iquidus-explorer.service <<'EOF'
[Unit]
Description=SmartCash 3.0.0 SmartExplorer
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
EOF

cat >/etc/nginx/sites-available/smart-iquidus-explorer <<'EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 16m;

    location /explorer/ {
        proxy_pass http://127.0.0.1:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
EOF

ln -sf /etc/nginx/sites-available/smart-iquidus-explorer /etc/nginx/sites-enabled/smart-iquidus-explorer
rm -f /etc/nginx/sites-enabled/default
nginx -t

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 29678/tcp
ufw --force enable
systemctl enable --now fail2ban
systemctl daemon-reload
systemctl enable --now iquidus-explorer
systemctl restart nginx

cat <<'EOF'

Installation finished.

Initial Explorer database sync commands:
  cd /opt/smartcash3/explorer
  sudo -u iquidus node scripts/sync.js index update
  sudo -u iquidus node scripts/peers.js

Useful status commands:
  systemctl status smartcash3 --no-pager
  systemctl status mongod --no-pager
  systemctl status iquidus-explorer --no-pager
  journalctl -u iquidus-explorer -f

Open the Explorer:
  http://YOUR_SERVER_IP/explorer/
EOF
