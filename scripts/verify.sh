#!/usr/bin/env bash
#
# verify.sh
#
# End-to-end verification of the three-tier deployment. Runs
# ansible/verify.yml, which reads the same inventory and group_vars as the
# provisioning playbook, so no addresses or ports are duplicated here.
#
# Usage:
#   ./scripts/verify.sh
#   ./scripts/verify.sh -e db_password=change-me
#   make verify
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v ansible-playbook >/dev/null 2>&1 || {
  echo "error: ansible-playbook is not installed" >&2
  exit 1
}

cd "$ROOT/ansible"
exec ansible-playbook verify.yml "$@"
