#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
ASSUME_YES=false

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*"; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
log_success() { printf '[OK] %s\n' "$*"; }

die() {
  log_error "$*"
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_root() {
  [ "$(id -u)" -eq 0 ] || die 'Run as root (use sudo).'
}

require_env() {
  local var_name="$1"
  [ -n "${!var_name:-}" ] || die "Missing required env var: $var_name"
}

parse_common_flags() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --yes)
        ASSUME_YES=true
        shift
        ;;
      *)
        break
        ;;
    esac
  done
}

confirm_action() {
  local prompt="$1"
  if [ "$ASSUME_YES" = true ]; then
    return 0
  fi
  read -r -p "$prompt [y/N]: " reply
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    printf '[DRY-RUN] %s\n' "$*"
    return 0
  fi
  "$@"
}

require_ubuntu_2404() {
  [ -f /etc/os-release ] || die 'Cannot detect OS.'
  # shellcheck disable=SC1091
  . /etc/os-release
  [ "${ID:-}" = 'ubuntu' ] || die "Unsupported distro: ${ID:-unknown}"
  case "${VERSION_ID:-}" in
    24.04) ;;
    *) die "Unsupported Ubuntu version: ${VERSION_ID:-unknown}; expected 24.04" ;;
  esac
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1
  pwd
}
