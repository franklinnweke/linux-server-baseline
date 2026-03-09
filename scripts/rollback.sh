#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

require_root
command_exists jq || die 'jq is required for rollback.'

PROJECT_DIR="${PROJECT_DIR:-/opt/linux-server-baseline}"
STATE_FILE="$PROJECT_DIR/.deploy-state"
[ -f "$STATE_FILE" ] || die 'Missing .deploy-state file.'

previous_tag="$(jq -r '.previous_tag // empty' "$STATE_FILE")"
current_tag="$(jq -r '.current_tag // empty' "$STATE_FILE")"
app_image="$(jq -r '.app_image // empty' "$STATE_FILE")"
domain="$(jq -r '.domain // empty' "$STATE_FILE")"

[ -n "$previous_tag" ] || die 'No previous_tag available. Cannot rollback first deploy.'

export APP_TAG="$previous_tag"
export APP_IMAGE="$app_image"
export DOMAIN="$domain"
export LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-ops@example.com}"

deploy_flags=()
if [ "$DRY_RUN" = true ]; then
  deploy_flags+=(--dry-run)
fi
"$ROOT_DIR/scripts/deploy.sh" "${deploy_flags[@]}"

if [ "$DRY_RUN" = false ]; then
  tmp="$(mktemp)"
  jq --arg cur "$previous_tag" --arg prev "$current_tag" '.current_tag=$cur | .previous_tag=$prev' "$STATE_FILE" > "$tmp"
  mv "$tmp" "$STATE_FILE"
fi

log_success "Rollback completed to tag: $previous_tag"
