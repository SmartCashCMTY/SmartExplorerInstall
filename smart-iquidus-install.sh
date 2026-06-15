#!/usr/bin/env bash
set -euo pipefail

SMARTCASH_VERSION="3.0.0"
CORE_RELEASE_BASE="https://github.com/SmartCashCMTY/Node-Client-Wallet/releases/download/v3.0.0"
CORE_ARCHIVE="smartcash3-3.0.0-x86_64-linux-gnu.tar.gz"
CORE_SHA256="d53c8195768490808c88d178cfb387102b8e69ab452e4c7baddf9af5c44993eb"
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
  swapoff /swapfile 2>/dev/null || true
  rm -f /swapfile
  dd if=/dev/zero of=/swapfile bs=1M count=4096 status=none
  chmod 600 /swapfile
  mkswap /swapfile > /dev/null
  if swapon /swapfile 2>/dev/null; then
    echo "Swap enabled via /swapfile"
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
  elif modprobe loop 2>/dev/null && LOOPDEV=$(losetup -f 2>/dev/null) && [ -n "$LOOPDEV" ]; then
    losetup "$LOOPDEV" /swapfile
    swapon "$LOOPDEV"
    echo "Swap enabled via loop device $LOOPDEV"
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
  else
    rm -f /swapfile
    echo "WARNING: Could not enable swap (ZFS/LXC limitation). Continuing without swap."
  fi
fi

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi

if ! command -v mongod >/dev/null 2>&1; then
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://pgp.mongodb.com/server-8.0.asc | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-8.0.gpg
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

echo "Downloading SmartCash logo..."
curl -fsSL -o public/images/logo.png https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/public/images/logo.png 2>/dev/null || true
curl -fsSL -o public/favicon.ico https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/public/favicon.ico 2>/dev/null || true

echo "Downloading custom layout, lib, routes and SmartNodes files..."
curl -fsSL -o views/layout.pug https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/views/layout.pug 2>/dev/null || true
curl -fsSL -o views/smartnodes.pug https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/views/smartnodes.pug 2>/dev/null || true
curl -fsSL -o lib/explorer.js https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/lib/explorer.js 2>/dev/null || true
curl -fsSL -o routes/index.js https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/routes/index.js 2>/dev/null || true


cat >settings.json <<EOF
{
  "title": "SmartCash 3.0 Explorer",
  "address": "127.0.0.1:3001",
  "coin": "SmartCash",
  "symbol": "SMART",
  "theme": "Cyborg",
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
    "richlist": false,
    "smartnodes": true,
    "movement": true,
    "network": true
  },
  "index": {
    "show_hashrate": true,
    "show_smartcash_price": true,
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

cat >/etc/systemd/system/smartcash3-explorer-tip-sync.service <<'EOF'
[Unit]
Description=SmartCash 3.0 Explorer tip sync
After=mongod.service smartcash3.service

[Service]
Type=oneshot
WorkingDirectory=/opt/smartcash3/explorer
ExecStart=/usr/bin/node scripts/sync-tip.js 250
TimeoutStartSec=5min
EOF

cat >/etc/systemd/system/smartcash3-explorer-tip-sync.timer <<'EOF'
[Unit]
Description=Run SmartCash 3.0 Explorer tip sync
After=mongod.service smartcash3.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=60s
AccuracySec=1s
Unit=smartcash3-explorer-tip-sync.service

[Install]
WantedBy=timers.target
EOF

systemctl enable smartcash3-explorer-tip-sync.timer
systemctl start smartcash3-explorer-tip-sync.timer 2>/dev/null || true

# CMC API endpoint
cat >/opt/smartcash3/cmc-api.js <<'CMCEOF'
const http = require('http');
const exec = require('child_process').exec;
const CLI = '/usr/local/bin/smartcash-cli';
let cache = null, cacheTime = 0;

function getSupply(cb) {
  if (cache && (Date.now() - cacheTime) < 300000) return cb(cache);
  exec(CLI + ' -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 gettxoutsetinfo 2>/dev/null', {timeout: 120000}, (e, stdout) => {
    let supply = 3167797400;
    try {
      const d = JSON.parse(stdout);
      supply = Math.floor(d.total_amount);
    } catch(ex) {}
    cache = supply;
    cacheTime = Date.now();
    cb(supply);
  });
}

http.createServer((req, res) => {
  if (req.url === '/cmc' || req.url === '/') {
    getSupply(function(supply) {
      res.writeHead(200, {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'});
      res.end(JSON.stringify({circulating_supply: supply, total_supply: supply, max_supply: 5000000000}) + '\n');
    });
  } else { res.writeHead(404); res.end('Not Found\n'); }
}).listen(3002, () => console.log('CMC API on :3002'));
CMCEOF

cat >/etc/systemd/system/smartcash3-cmc-api.service <<'EOF'
[Unit]
Description=SmartCash CMC API
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/smartcash3/cmc-api.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable smartcash3-cmc-api
systemctl start smartcash3-cmc-api 2>/dev/null || true

cat >/etc/nginx/sites-available/smart-iquidus-explorer <<'EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 16m;

    location = /cmc {
        proxy_pass http://127.0.0.1:3002/cmc;
        proxy_http_version 1.1;
        proxy_read_timeout 120s;
    }

    location = /favicon.ico {
        alias /opt/smartcash3/explorer/public/images/logo.png;
        default_type image/png;
    }

    location = /explorer/favicon.ico {
        alias /opt/smartcash3/explorer/public/images/logo.png;
        default_type image/png;
    }

    location = /explorer {
        return 301 /explorer/;
    }

    location /explorer/ {
        rewrite ^/explorer/?(.*)$ /$1 break;
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }

    location / {
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

sed -i 's/^IPV6=yes/IPV6=no/' /etc/default/ufw
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

Starting initial blockchain index sync in the background.
This may take 24-48 hours for ~4.2 million blocks.
The Explorer shows live data once the sync completes.

Progress commands:
  cd /opt/smartcash3/explorer
  sudo -u iquidus node -e "require('mongodb').MongoClient.connect('mongodb://127.0.0.1:27017/smartcash3',(e,c)=>{c.db().collection('txes').countDocuments().then(n=>{console.log('Transactions indexed:',n);c.close()})})"

Useful status commands:
  systemctl status smartcash3 --no-pager
  systemctl status mongod --no-pager
  systemctl status iquidus-explorer --no-pager
  systemctl status smartcash3-explorer-tip-sync.timer --no-pager
  journalctl -u iquidus-explorer -f
  tail -f /var/lib/smartcash3/debug.log

Open the Explorer:
  http://YOUR_SERVER_IP/
  http://YOUR_SERVER_IP/explorer/
EOF

curl -fsSL -o scripts/sync-tip.js https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/scripts/sync-tip.js 2>/dev/null || true
echo "Seeding initial coin supply (retries until ready)..."
curl -fsSL -o /tmp/seed-supply.js https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorer/main/scripts/seed-supply.js 2>/dev/null
cd "$EXPLORER_DIR"
node /tmp/seed-supply.js > /tmp/seed-supply.log 2>&1 &
SEED_PID=$!

echo "Indexing last 500 blocks for immediate data..."
sudo -u "$EXPLORER_USER" node scripts/sync-tip.js 500 > /tmp/sync-tip-init.log 2>&1

echo "Populating peer data..."
sudo -u "$EXPLORER_USER" node scripts/peers.js > /tmp/peers-init.log 2>&1

echo "Starting full blockchain index sync (background)..."
sudo -u "$EXPLORER_USER" node scripts/sync.js index update > /tmp/smartcash3-explorer-sync.log 2>&1 &

wait $SEED_PID 2>/dev/null
echo "Seed supply result:"
cat /tmp/seed-supply.log 2>/dev/null

echo "Installation complete. Explorer shows data as sync progresses."
