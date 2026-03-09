#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

require_root

PROJECT_DIR="${PROJECT_DIR:-/opt/linux-server-baseline}"
BACKUP_FILE="${BACKUP_FILE:-}"
[ -n "$BACKUP_FILE" ] || die 'Set BACKUP_FILE=/path/to/backup.tar.gz'
[ -f "$BACKUP_FILE" ] || die "Backup file not found: $BACKUP_FILE"

if [ "$DRY_RUN" = true ]; then
  printf '[DRY-RUN] Would restore project files from %s to %s\n' "$BACKUP_FILE" "$PROJECT_DIR"
  exit 0
fi

install -d -m 755 "$PROJECT_DIR"
tar -xzf "$BACKUP_FILE" -C "$PROJECT_DIR"
log_success 'Restore completed. Re-run deploy.sh if needed.'
