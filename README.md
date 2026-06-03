# linux-server-baseline

A production-style Ubuntu server baseline for running a single Docker Compose app behind Nginx and Let's Encrypt.

The default example deploys n8n, but the baseline is intentionally plain: SSH hardening, UFW, Docker, Nginx/TLS, backups, restore, rollback, and verification. Swap the Compose file and environment values to use it for another single-host app.

## What It Builds

- Ubuntu 24.04 host bootstrap with Docker Engine, Compose plugin, Nginx, Certbot, UFW, Fail2ban, and basic tooling
- Deploy user setup with SSH key installation
- Key-only SSH hardening through an OpenSSH drop-in file
- Firewall baseline: deny inbound by default, allow SSH/HTTP/HTTPS
- Docker Compose deployment under `/opt/linux-server-baseline`
- Nginx reverse proxy to a local-only app port
- Let's Encrypt certificate issuance and HTTP-to-HTTPS redirect
- Daily systemd backup timer
- Restore, rollback, and verification scripts

## Repository Layout

```text
compose/        Example app stack and environment template
docs/           Architecture notes and operational runbooks
lib/            Shared shell helpers
nginx/          Site template rendered by deploy.sh
scripts/        Bootstrap, hardening, deploy, backup, restore, rollback, verify
systemd/        Backup service and timer units
setup.sh        End-to-end setup entrypoint
```

## Requirements

- Fresh Ubuntu 24.04 LTS server
- DNS A record pointing your domain to the server
- Root or sudo access
- SSH public key for the deploy user
- Ports `22`, `80`, and `443` reachable from the network

The scripts assume a single host. They do not configure high availability, external secrets management, or centralized monitoring.

## Quick Start

Clone the repo on the target server, then create the app environment file:

```bash
cp compose/.env.example compose/.env
```

Edit `compose/.env` with the domain, Let's Encrypt email, app image tag, and timezone. Do not commit this file.

Run the full setup:

```bash
sudo ./setup.sh --domain n8n.example.com --email you@example.com
```

Dry-run the same flow before making changes:

```bash
sudo ./setup.sh --domain n8n.example.com --email you@example.com --dry-run
```

## Manual Flow

Use the individual scripts when you want to apply one phase at a time:

```bash
sudo ./scripts/bootstrap.sh
sudo ./scripts/harden-ssh.sh --dry-run
sudo ./scripts/harden-ssh.sh
sudo ./scripts/setup-firewall.sh --dry-run
sudo ./scripts/setup-firewall.sh
sudo ./scripts/deploy.sh
sudo ./scripts/verify.sh
```

Useful environment variables:

```bash
DEPLOY_USER=ops
DEPLOY_PUBKEY_PATH=/root/.ssh/authorized_keys
PERMIT_ROOT_LOGIN_POLICY=prohibit-password
SSH_ALLOWED_CIDR=203.0.113.10/32
PROJECT_DIR=/opt/linux-server-baseline
BACKUP_DIR=/opt/backups
```

## Operations

Deployment state is written to `/opt/linux-server-baseline/.deploy-state`. Rollback uses that file to return to the previous app tag.

Backups run daily through `linux-server-baseline-backup.timer` and write timestamped archives to `/opt/backups` by default. Project metadata is backed up, and the default n8n Docker volume is archived when it exists.

Runbooks:

- [Deploy](docs/runbook-deploy.md)
- [Restore](docs/runbook-restore.md)
- [Rollback](docs/runbook-rollback.md)
- [Architecture](docs/architecture.md)
- [Hardening notes](docs/hardening-notes.md)

## Safety Notes

- Keep an active SSH session open while applying SSH hardening.
- Verify deploy-user login before setting `PERMIT_ROOT_LOGIN_POLICY=no`.
- `setup-firewall.sh` resets UFW rules to the baseline. Use `--dry-run` first.
- Pin app tags instead of using `latest`.
- Keep real environment files out of Git. Only `compose/.env.example` belongs in the repository.

## Validation

Local checks:

```bash
bash -n setup.sh lib/*.sh scripts/*.sh
shellcheck setup.sh lib/*.sh scripts/*.sh
yamllint compose/docker-compose.yml .github/workflows/ci.yml .yamllint.yml
make validate-nginx
```

GitHub Actions runs shell syntax checks, ShellCheck, YAML linting, and Nginx template validation on pushes to `main` and pull requests.

## Current Limits

- Backup volume handling is specific to the default `n8n_data` volume.
- This is a single-host baseline, not a high-availability platform.
- Monitoring is limited to health checks, service status, and logs.
