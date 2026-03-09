#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

require_root

PROJECT_DIR="${PROJECT_DIR:-/opt/linux-server-baseline}"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/backup-$TIMESTAMP.tar.gz"

run_cmd install -d -m 755 "$BACKUP_DIR"

if [ "$DRY_RUN" = true ]; then
  printf '[DRY-RUN] Would archive %s/.env %s/docker-compose.yml %s/.deploy-state and optional n8n_data volume\n' "$PROJECT_DIR" "$PROJECT_DIR" "$PROJECT_DIR"
  exit 0
fi

backup_items=()
for item in .env docker-compose.yml .deploy-state; do
  if [ -f "$PROJECT_DIR/$item" ]; then
    backup_items+=("$item")
  else
    log_warn "Missing backup item: $PROJECT_DIR/$item"
  fi
done

[ "${#backup_items[@]}" -gt 0 ] || die 'No backup source files found; refusing to create empty backup.'
tar -czf "$ARCHIVE" -C "$PROJECT_DIR" "${backup_items[@]}"
[ -s "$ARCHIVE" ] || die "Backup archive was not created correctly: $ARCHIVE"

if docker volume ls --format '{{.Name}}' | grep -qx 'n8n_data'; then
  docker run --rm -v n8n_data:/data -v "$BACKUP_DIR":/backup busybox sh -c "tar -czf /backup/n8n_data-$TIMESTAMP.tar.gz -C /data ."
fi

find "$BACKUP_DIR" -type f -name '*.tar.gz' -mtime +"$RETENTION_DAYS" -delete
log_success "Backup complete: $ARCHIVE"
