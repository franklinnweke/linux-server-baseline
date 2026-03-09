#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

require_root

SSH_ALLOWED_CIDR="${SSH_ALLOWED_CIDR:-}"

if [ "$DRY_RUN" = true ]; then
  printf '[DRY-RUN] ufw default deny incoming\n'
  printf '[DRY-RUN] ufw default allow outgoing\n'
  if [ -n "$SSH_ALLOWED_CIDR" ]; then
    printf '[DRY-RUN] ufw allow from %s to any port 22 proto tcp\n' "$SSH_ALLOWED_CIDR"
  else
    printf '[DRY-RUN] ufw allow 22/tcp\n'
  fi
  printf '[DRY-RUN] ufw allow 80/tcp\n'
  printf '[DRY-RUN] ufw allow 443/tcp\n'
  printf '[DRY-RUN] ufw --force enable\n'
  exit 0
fi

log_warn 'Resetting UFW to baseline (existing rules will be cleared)'
if [ "$ASSUME_YES" != true ]; then
  confirm_action 'Proceed with UFW reset and baseline rule application?' || die 'Aborted firewall reset.'
fi
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
if [ -n "$SSH_ALLOWED_CIDR" ]; then
  ufw allow from "$SSH_ALLOWED_CIDR" to any port 22 proto tcp
else
  ufw allow 22/tcp
fi
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
log_success 'UFW firewall baseline applied.'
