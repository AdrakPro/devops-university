#!/usr/bin/env bash
#
# generate-keys.sh
#
# Creates the project SSH key used by Packer, Vagrant and Ansible.
# The private key stays local and is ignored by git.
#
# Usage:
#   ./scripts/generate-keys.sh
#   FORCE=1 ./scripts/generate-keys.sh   # replace an existing key
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_DIR="$ROOT/keys"
KEY="$KEY_DIR/id_ed25519"
PUB="$KEY.pub"
COMMENT="devops-university-vm-pipeline"

if [[ -f "$KEY" && "${FORCE:-0}" != "1" ]]; then
  echo "Key already exists: $KEY"
  echo "Use FORCE=1 to replace it."
else
  command -v ssh-keygen >/dev/null 2>&1 || {
    echo "ssh-keygen is not installed" >&2
    exit 1
  }

  mkdir -p "$KEY_DIR"
  chmod 700 "$KEY_DIR"
  rm -f "$KEY" "$PUB"
  ssh-keygen -q -t ed25519 -f "$KEY" -N "" -C "$COMMENT"
  chmod 600 "$KEY"
  chmod 644 "$PUB"
  echo "Created: $KEY"
fi

[[ -f "$PUB" ]] || {
  echo "Public key missing: $PUB" >&2
  exit 1
}

echo
echo "Public key:"
cat "$PUB"
echo
echo "Fingerprint:"
ssh-keygen -lf "$PUB"
