#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

require_root

ROOT_POLICY="${PERMIT_ROOT_LOGIN_POLICY:-prohibit-password}"
DROPIN='/etc/ssh/sshd_config.d/99-linux-server-baseline.conf'
CONTENT="PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin ${ROOT_POLICY}
"

log_info 'Preparing SSH hardening drop-in config.'
if [ "$DRY_RUN" = true ]; then
  printf '[DRY-RUN] Would write %s with:\n%s' "$DROPIN" "$CONTENT"
  exit 0
fi

printf '%s' "$CONTENT" > "$DROPIN"
sshd -t
systemctl restart ssh
log_success "SSH hardened. PermitRootLogin=${ROOT_POLICY}"
