#!/usr/bin/env bash
set -euo pipefail

EXPLORER_INSTALL_COMMIT="0dfdd507f6c3ee1c62560ff1cfcc2c3c936e802f"
EXPLORER_INSTALL_URL="https://raw.githubusercontent.com/SmartCashCMTY/SmartExplorerInstall/${EXPLORER_INSTALL_COMMIT}/smart-iquidus-install.sh"

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

echo "Verifying installer checksum..."
EXPECTED_INSTALLER_SHA256="4286dbc12c8b7a5a82ba23c2c4e41746f69bc3705f1e5a3d5f27e7733b549dd4"
computed_hash="$(sha256sum "$tmpdir/smart-iquidus-install.sh" | awk '{print $1}')"
if [[ "$computed_hash" != "$EXPECTED_INSTALLER_SHA256" ]]; then
  echo "ERROR: Installer checksum mismatch! Installation aborted." >&2
  echo "  Expected: $EXPECTED_INSTALLER_SHA256" >&2
  echo "  Got:      $computed_hash" >&2
  exit 1
fi
echo "Installer checksum verified OK."

chmod +x "$tmpdir/smart-iquidus-install.sh"

bash "$tmpdir/smart-iquidus-install.sh"

echo
echo "SmartExplorerInstall finished."
echo "Check status with: systemctl status iquidus-explorer --no-pager"
