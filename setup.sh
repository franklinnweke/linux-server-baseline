#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"

DOMAIN="${DOMAIN:-}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
FORWARD_FLAGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --email)
      LETSENCRYPT_EMAIL="$2"
      shift 2
      ;;
    --dry-run|--yes)
      FORWARD_FLAGS+=("$1")
      shift
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

require_root
require_ubuntu_2404

[ -n "$DOMAIN" ] || die 'Missing --domain or DOMAIN env var.'
[ -n "$LETSENCRYPT_EMAIL" ] || die 'Missing --email or LETSENCRYPT_EMAIL env var.'

export DOMAIN LETSENCRYPT_EMAIL

phases=(
  "scripts/bootstrap.sh"
  "scripts/harden-ssh.sh"
  "scripts/setup-firewall.sh"
  "scripts/deploy.sh"
  "scripts/verify.sh"
)

for phase in "${phases[@]}"; do
  log_info "Starting phase: $phase"
  "$ROOT_DIR/$phase" "${FORWARD_FLAGS[@]}"
  log_success "Completed phase: $phase"
done
