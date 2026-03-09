#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

require_root

PROJECT_DIR="${PROJECT_DIR:-/opt/linux-server-baseline}"
APP_IMAGE="${APP_IMAGE:-docker.n8n.io/n8nio/n8n}"
APP_TAG="${APP_TAG:-1.87.1}"
APP_PORT_INTERNAL="${APP_PORT_INTERNAL:-5678}"
DOMAIN="${DOMAIN:-${DOMAIN_NAME:-}}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
DEPLOY_USER="${DEPLOY_USER:-ops}"

require_env DOMAIN
require_env LETSENCRYPT_EMAIL

run_cmd install -d -m 755 "$PROJECT_DIR"
run_cmd cp -f "$ROOT_DIR/compose/docker-compose.yml" "$PROJECT_DIR/docker-compose.yml"
if [ ! -f "$PROJECT_DIR/.env" ]; then
  if [ -f "$ROOT_DIR/compose/.env" ]; then
    run_cmd cp "$ROOT_DIR/compose/.env" "$PROJECT_DIR/.env"
  else
    run_cmd cp "$ROOT_DIR/compose/.env.example" "$PROJECT_DIR/.env"
  fi
fi

if [ "$DRY_RUN" = false ]; then
  sed -i.bak \
    -e "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" \
    -e "s|^LETSENCRYPT_EMAIL=.*|LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL|" \
    -e "s|^APP_IMAGE=.*|APP_IMAGE=$APP_IMAGE|" \
    -e "s|^APP_TAG=.*|APP_TAG=$APP_TAG|" \
    -e "s|^APP_PORT_INTERNAL=.*|APP_PORT_INTERNAL=$APP_PORT_INTERNAL|" \
    "$PROJECT_DIR/.env"
  rm -f "$PROJECT_DIR/.env.bak"
fi

if [ "$DRY_RUN" = false ]; then
  export DOMAIN APP_PORT_INTERNAL
  envsubst '${DOMAIN} ${APP_PORT_INTERNAL}' < "$ROOT_DIR/nginx/site.conf.template" > /etc/nginx/sites-available/linux-server-baseline.conf
  ln -sfn /etc/nginx/sites-available/linux-server-baseline.conf /etc/nginx/sites-enabled/linux-server-baseline.conf
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl restart nginx
fi

run_cmd docker compose -f "$PROJECT_DIR/docker-compose.yml" --env-file "$PROJECT_DIR/.env" pull
run_cmd docker compose -f "$PROJECT_DIR/docker-compose.yml" --env-file "$PROJECT_DIR/.env" up -d

if [ "$DRY_RUN" = false ]; then
  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$LETSENCRYPT_EMAIL" --redirect || log_warn 'Certbot failed; verify DNS A record and retry.'
fi

STATE_FILE="$PROJECT_DIR/.deploy-state"
prev_tag=''
if [ -f "$STATE_FILE" ] && command_exists jq; then
  prev_tag="$(jq -r '.current_tag // empty' "$STATE_FILE")"
fi

if [ "$DRY_RUN" = false ]; then
  cat > "$STATE_FILE" <<JSON
{
  "current_tag": "$APP_TAG",
  "previous_tag": "$prev_tag",
  "app_image": "$APP_IMAGE",
  "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployed_by": "${SUDO_USER:-root}",
  "compose_file": "docker-compose.yml",
  "domain": "$DOMAIN"
}
JSON
  chown "$DEPLOY_USER":"$DEPLOY_USER" "$STATE_FILE" 2>/dev/null || true
  chmod 640 "$STATE_FILE"
fi

log_success 'Deploy completed.'
