#!/usr/bin/env bash
#
# build-box.sh
#
# Builds the Ubuntu base box with Packer. The project SSH public key is
# substituted into the autoinstall user-data so the vagrant user is created
# with key-only access.
#
# Usage:
#   ./scripts/build-box.sh [iso-path]
#   HEADLESS=true ./scripts/build-box.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-${ISO:-$HOME/Downloads/ubuntu-24.04.5-live-server-amd64.iso}}"
KEY="$ROOT/keys/id_ed25519"
PUB="$KEY.pub"
HTTP_DIR="$ROOT/packer/http"
BOX="$ROOT/packer/base-ubuntu.box"
HEADLESS="${HEADLESS:-false}"

die() { echo "error: $*" >&2; exit 1; }

command -v packer >/dev/null 2>&1 || die "packer is not installed"
[[ -f "$ISO" ]] || die "ISO not found: $ISO"

if [[ ! -f "$PUB" ]]; then
  echo "Public key missing; generating the project key"
  "$ROOT/scripts/generate-keys.sh"
fi
[[ -f "$PUB" ]] || die "public key not found: $PUB"

# Inject the current public key into the autoinstall user-data.
sed "s#__SSH_PUBLIC_KEY__#$(cat "$PUB")#" \
  "$HTTP_DIR/user-data.tmpl" > "$HTTP_DIR/user-data"

avail_gb="$(df -BG --output=avail "$ROOT" | tail -n1 | tr -dc '0-9')"
if [[ -n "$avail_gb" && "$avail_gb" -lt 20 ]]; then
  echo "warning: only ${avail_gb}G free under $ROOT; the build needs about 20G" >&2
fi

echo "ISO:    $ISO"
echo "Box:    $BOX"
echo "Public: $PUB"

cd "$ROOT/packer"
packer init .
packer validate -var "iso_url=$ISO" .
packer build -var "iso_url=$ISO" -var "headless=$HEADLESS" .
