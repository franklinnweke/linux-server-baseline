#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

PROJECT_DIR="${PROJECT_DIR:-/opt/linux-server-baseline}"
STATE_FILE="$PROJECT_DIR/.deploy-state"
DOMAIN="${DOMAIN:-}"

fail=0
pass() { printf '[✓] %s\n' "$1"; }
err() { printf '[x] %s\n' "$1"; fail=1; }

if sshd -T 2>/dev/null | grep -q '^passwordauthentication no$'; then pass 'SSH hardened'; else err 'SSH not hardened'; fi
if ufw status | grep -q 'Status: active'; then pass 'UFW active'; else err 'UFW inactive'; fi
if systemctl is-active --quiet docker; then pass 'Docker running'; else err 'Docker not running'; fi
if [ -f "$PROJECT_DIR/docker-compose.yml" ] && docker compose -f "$PROJECT_DIR/docker-compose.yml" --env-file "$PROJECT_DIR/.env" ps >/dev/null 2>&1; then pass 'Compose stack healthy'; else err 'Compose stack check failed'; fi
if nginx -t >/dev/null 2>&1; then pass 'Nginx config valid'; else err 'Nginx config invalid'; fi

if [ -f "$STATE_FILE" ]; then
  if command_exists jq && jq -e '.current_tag and .app_image and .domain' "$STATE_FILE" >/dev/null; then
    pass '.deploy-state valid'
    [ -n "$DOMAIN" ] || DOMAIN="$(jq -r '.domain' "$STATE_FILE")"
  else
    err '.deploy-state invalid'
  fi
else
  err '.deploy-state missing'
fi

if [ -n "$DOMAIN" ]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' "https://$DOMAIN" || true)"
  case "$code" in
    2*|3*|401|403) pass "HTTPS reachable (status $code)" ;;
    *) err "HTTPS check failed (status $code)" ;;
  esac
else
  err 'DOMAIN unavailable for HTTPS check'
fi

if [ "$fail" -eq 0 ]; then
  log_success 'All checks passed.'
  exit 0
fi

log_error 'One or more checks failed.'
exit 1
