#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT_DIR/lib/common.sh"
parse_common_flags "$@"

require_root
require_ubuntu_2404

DEPLOY_USER="${DEPLOY_USER:-ops}"
DEPLOY_PUBKEY_PATH="${DEPLOY_PUBKEY_PATH:-$HOME/.ssh/do_root.pub}"

log_info 'Installing baseline packages.'
run_cmd apt-get update -y
run_cmd apt-get install -y curl git ufw fail2ban nginx jq ca-certificates gnupg lsb-release apt-transport-https software-properties-common certbot python3-certbot-nginx gettext-base

if ! command_exists docker; then
  log_info 'Installing Docker repository.'
  run_cmd install -m 0755 -d /etc/apt/keyrings
  if [ "$DRY_RUN" = false ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
  else
    printf '[DRY-RUN] Configure Docker apt repository\n'
  fi
  run_cmd apt-get update -y

  docker_pin="$(apt-cache madison docker-ce | awk '{print $3}' | grep '^5:27\.' | head -n1 || true)"
  compose_pin="$(apt-cache madison docker-compose-plugin | awk '{print $3}' | grep '^2\.29\.' | head -n1 || true)"

  if [ -z "$docker_pin" ]; then
    log_warn 'Pinned Docker 5:27.* not found; using latest available docker-ce.'
    run_cmd apt-get install -y docker-ce docker-ce-cli containerd.io
  else
    run_cmd apt-get install -y "docker-ce=$docker_pin" "docker-ce-cli=$docker_pin" containerd.io
  fi

  if [ -z "$compose_pin" ]; then
    log_warn 'Pinned Compose 2.29.* not found; using latest available docker-compose-plugin.'
    run_cmd apt-get install -y docker-compose-plugin
  else
    run_cmd apt-get install -y "docker-compose-plugin=$compose_pin"
  fi
fi

if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
  log_info "Creating deploy user: $DEPLOY_USER"
  run_cmd useradd -m -s /bin/bash "$DEPLOY_USER"
fi

run_cmd usermod -aG sudo,docker "$DEPLOY_USER"

if [ -f "$DEPLOY_PUBKEY_PATH" ]; then
  log_info "Installing SSH key for $DEPLOY_USER from $DEPLOY_PUBKEY_PATH"
  run_cmd install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
  if [ "$DRY_RUN" = false ]; then
    touch "/home/$DEPLOY_USER/.ssh/authorized_keys"
    grep -qxF "$(cat "$DEPLOY_PUBKEY_PATH")" "/home/$DEPLOY_USER/.ssh/authorized_keys" || cat "$DEPLOY_PUBKEY_PATH" >> "/home/$DEPLOY_USER/.ssh/authorized_keys"
    chown "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh/authorized_keys"
    chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"
  else
    printf '[DRY-RUN] Add key to /home/%s/.ssh/authorized_keys\n' "$DEPLOY_USER"
  fi
else
  log_warn "Deploy pubkey not found at $DEPLOY_PUBKEY_PATH. Set DEPLOY_PUBKEY_PATH to avoid login issues."
fi

run_cmd systemctl enable --now docker
log_success 'Bootstrap completed.'
