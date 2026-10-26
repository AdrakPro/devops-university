#!/usr/bin/env bash
#
# install-devops-toolchain.sh
#
# Installs VirtualBox, Packer, Vagrant and Ansible on Debian/Ubuntu hosts.
# Idempotent: anything already present is detected and skipped.
#
# Usage:
#   ./install-devops-toolchain.sh              # install everything missing
#   ./install-devops-toolchain.sh packer       # install only listed components
#   FORCE=1 ./install-devops-toolchain.sh      # reinstall even if detected
#
set -euo pipefail

# ---------------------------------------------------------------- config ----

VIRTUALBOX_REPO_KEY="https://www.virtualbox.org/download/oracle_vbox_2016.asc"
VIRTUALBOX_REPO="deb [arch=amd64 signed-by=%KEYRING%] https://download.virtualbox.org/virtualbox/debian %CODENAME% contrib"

HASHICORP_REPO_KEY="https://apt.releases.hashicorp.com/gpg"
HASHICORP_REPO="deb [arch=amd64 signed-by=%KEYRING%] https://apt.releases.hashicorp.com %CODENAME% main"

ANSIBLE_PPA="ppa:ansible/ansible"

APT_OPTS=(-y -o Dpkg::Progress-Fork=false -o Dpkg::Use-Pty=0)
export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------------------- logging ----

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_INFO=$'\033[1;34m'; C_OK=$'\033[1;32m'
  C_WARN=$'\033[1;33m'; C_ERR=$'\033[1;31m'
else
  C_RESET=""; C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""
fi

info() { printf '%s==>%s %s\n' "$C_INFO" "$C_RESET" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$C_OK" "$C_RESET" "$*"; }
skip() { printf '%sskip%s %s\n' "$C_WARN" "$C_RESET" "$*"; }
warn() { printf '%swarn%s %s\n' "$C_WARN" "$C_RESET" "$*" >&2; }
die()  { printf '%serr %s %s\n' "$C_ERR" "$C_RESET" "$*" >&2; exit 1; }

# ----------------------------------------------------------------- sudo ----

SUDO=""
if [[ $EUID -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || die "not root and sudo is not installed"
  info "Requesting sudo credentials"
  sudo -v || die "sudo authentication failed"
  SUDO="sudo"
fi
as_root() { $SUDO "$@"; }

# -------------------------------------------------------------- helpers ----

# cmd_present <binary> -- true when the tool is on PATH
cmd_present() { command -v "$1" >/dev/null 2>&1; }

# apt_pkg_present <package> -- true when dpkg knows the package as installed
apt_pkg_present() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"; }

# add_keyring <url> <keyring-path>
# apt's signed-by expects a binary OpenPGP key, while both vendor URLs serve
# ASCII-armored keys. Dearmor when needed so apt can actually use the keyring.
add_keyring() {
  local url="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    skip "keyring already present: $dest"
    return 0
  fi
  info "Fetching key -> $dest"
  local tmp dearmored
  tmp="$(mktemp)"
  dearmored="$(mktemp)"
  curl -fsSL "$url" -o "$tmp" || { rm -f "$tmp" "$dearmored"; die "failed to download key: $url"; }
  if gpg --dearmor --yes -o "$dearmored" "$tmp" 2>/dev/null; then
    mv "$dearmored" "$tmp"
  else
    rm -f "$dearmored"
  fi
  as_root install -D -m 0644 -o root -g root "$tmp" "$dest"
  rm -f "$tmp"
}

# add_repo <repo-file-name> <deb-line>
add_repo() {
  local name="$1" line="$2" dest="/etc/apt/sources.list.d/$1"
  if [[ -f "$dest" ]]; then
    skip "apt repo already configured: $dest"
  else
    info "Adding apt repo: $name"
    printf '%s\n' "$line" | as_root tee "$dest" >/dev/null
  fi
}

apt_update() {
  info "apt-get update"
  as_root apt-get update "${APT_OPTS[@]}" -qq || warn "apt-get update reported errors; continuing"
}

apt_install() {
  info "apt-get install $*"
  as_root apt-get install "${APT_OPTS[@]}" "$@"
}

# --------------------------------------------------------- distro check ----

[[ -r /etc/os-release ]] || die "/etc/os-release not found; unsupported system"
# shellcheck disable=SC1091
. /etc/os-release

case "${ID:-}" in
  ubuntu|debian) ;;
  *)
    case "${ID_LIKE:-}" in
      *debian*) warn "untested derivative: ${PRETTY_NAME:-$ID}" ;;
      *) die "unsupported distribution: ${PRETTY_NAME:-unknown} (Debian/Ubuntu only)" ;;
    esac
    ;;
esac

CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
[[ -n "$CODENAME" ]] || die "could not determine distro codename"
[[ "$(dpkg --print-architecture)" == "amd64" ]] || die "these packages are wired for amd64 only"

info "Host: ${PRETTY_NAME:-$ID} ($CODENAME, amd64)"

# ------------------------------------------------------------ components ----

install_virtualbox() {
  info "VirtualBox"
  if cmd_present VBoxManage && [[ "${FORCE:-0}" != "1" ]]; then
    skip "VirtualBox already installed: $(VBoxManage --version 2>/dev/null || echo present)"
    return 0
  fi

  # Ubuntu's own 'virtualbox' package is often stale; prefer Oracle's repo.
  add_keyring "$VIRTUALBOX_REPO_KEY" /usr/share/keyrings/oracle-virtualbox-2016.gpg
  add_repo "virtualbox.list" \
    "$(sed "s|%KEYRING%|/usr/share/keyrings/oracle-virtualbox-2016.gpg|; s|%CODENAME%|$CODENAME|" <<<"$VIRTUALBOX_REPO")"
  apt_update

  # Pick the newest virtualbox-7.* the repo offers instead of pinning a
  # version that may have been superseded.
  local pkg
  pkg="$(apt-cache search --names-only '^virtualbox-7\.[0-9]+$' 2>/dev/null \
        | awk '{print $1}' | sort -V | tail -n1)"
  [[ -n "$pkg" ]] || die "no virtualbox-7.x package found in Oracle repo"

  # Kernel modules are built through DKMS, which needs matching headers.
  local kver
  kver="$(uname -r)"
  if ! apt_pkg_present "linux-headers-$kver"; then
    apt_install "linux-headers-$kver" || warn "could not install linux-headers-$kver; DKMS build may fail"
  fi
  apt_pkg_present build-essential || apt_install build-essential
  apt_pkg_present dkms || apt_install dkms

  apt_install "$pkg"
  ok "VirtualBox installed ($pkg)"
}

# Shared HashiCorp apt repo used by both Packer and Vagrant.
setup_hashicorp_repo() {
  local keyring=/usr/share/keyrings/hashicorp-archive-keyring.gpg
  add_keyring "$HASHICORP_REPO_KEY" "$keyring"
  add_repo "hashicorp.list" \
    "$(sed "s|%KEYRING%|$keyring|; s|%CODENAME%|$CODENAME|" <<<"$HASHICORP_REPO")"
  apt_update
}

install_packer() {
  info "Packer"
  if cmd_present packer && [[ "${FORCE:-0}" != "1" ]]; then
    skip "Packer already installed: $(packer version 2>/dev/null | head -n1)"
    return 0
  fi

  setup_hashicorp_repo
  apt_install packer
  ok "Packer installed ($(packer version 2>/dev/null | head -n1))"
}

install_vagrant() {
  info "Vagrant"
  if cmd_present vagrant && [[ "${FORCE:-0}" != "1" ]]; then
    skip "Vagrant already installed: $(vagrant --version 2>/dev/null)"
    return 0
  fi

  setup_hashicorp_repo
  apt_install vagrant
  ok "Vagrant installed ($(vagrant --version 2>/dev/null))"
}

install_ansible() {
  info "Ansible"
  if cmd_present ansible && [[ "${FORCE:-0}" != "1" ]]; then
    skip "Ansible already installed: $(ansible --version 2>/dev/null | head -n1)"
    return 0
  fi

  if apt_pkg_present software-properties-common; then
    :
  else
    apt_install software-properties-common
  fi

  if as_root add-apt-repository -y "$ANSIBLE_PPA"; then
    apt_update
    # The PPA's 'ansible' package pulls in ansible-core; remove the conflicting
    # distro 'ansible' first if it is already installed.
    if apt_pkg_present ansible && ! apt_pkg_present ansible-core; then
      as_root apt-get remove -y ansible
    fi
    apt_install ansible-core ansible
  else
    warn "Ansible PPA unavailable; falling back to the distro package"
    apt_install ansible
  fi
  ok "Ansible installed ($(ansible --version 2>/dev/null | head -n1))"
  if cmd_present ansible-galaxy; then
    ansible-galaxy collection install community.general >/dev/null 2>&1 \
      || warn "could not install community.general collection"
  fi
}

# ------------------------------------------------------------------ main ----

ALL_COMPONENTS=(virtualbox packer vagrant ansible)
COMPONENTS=("$@")
if [[ ${#COMPONENTS[@]} -eq 0 ]]; then
  COMPONENTS=("${ALL_COMPONENTS[@]}")
fi

for c in "${COMPONENTS[@]}"; do
  found=0
  for known in "${ALL_COMPONENTS[@]}"; do
    [[ "$c" == "$known" ]] && found=1
  done
  [[ $found -eq 1 ]] || die "unknown component: $c (expected: ${ALL_COMPONENTS[*]})"
done

for c in "${COMPONENTS[@]}"; do
  "install_$c"
done

info "Summary"
for c in "${ALL_COMPONENTS[@]}"; do
  case "$c" in
    virtualbox) v="$(VBoxManage --version 2>/dev/null || echo 'not installed')" ;;
    packer)     v="$(packer version 2>/dev/null | head -n1 || echo 'not installed')" ;;
    vagrant)    v="$(vagrant --version 2>/dev/null || echo 'not installed')" ;;
    ansible)    v="$(ansible --version 2>/dev/null | head -n1 || echo 'not installed')" ;;
  esac
  printf '  %-11s %s\n' "$c" "${v:-not installed}"
done
