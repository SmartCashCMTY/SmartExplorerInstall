#!/usr/bin/env bash
set -euo pipefail

EXPLORER_INSTALL_URL="https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/main/smart-iquidus-install.sh"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash ./SmartInstallExplorer.sh" >&2
  exit 1
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_curl_if_missing() {
  if command_exists curl; then
    return
  fi

  apt-get update
  apt-get install -y curl ca-certificates
}

echo "SmartCash SmartExplorerInstall 3.0.0"
echo
echo "This installer downloads the official Explorer installer from:"
echo "$EXPLORER_INSTALL_URL"
echo

install_curl_if_missing

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -fsSL -o "$tmpdir/smart-iquidus-install.sh" "$EXPLORER_INSTALL_URL"
chmod +x "$tmpdir/smart-iquidus-install.sh"

bash "$tmpdir/smart-iquidus-install.sh"

echo
echo "SmartExplorerInstall finished."
echo "Check status with: systemctl status iquidus-explorer --no-pager"
