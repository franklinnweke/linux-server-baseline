# linux-server-baseline

Production-style Ubuntu baseline for secure app deployment: SSH hardening, firewall, Docker Compose app, Nginx reverse proxy, TLS, backup/restore, rollback, and verification.

## Quick Start

1. Clone repo on target Ubuntu 24.04 host.
2. Copy env file:
   - `cp compose/.env.example compose/.env`
3. Edit values in `compose/.env`.
4. Run:
   - `sudo ./setup.sh --domain n8n.example.com --email you@example.com`

## Dry Run
- `sudo ./setup.sh --domain n8n.example.com --email you@example.com --dry-run`

## Manual Flow
- `sudo ./scripts/bootstrap.sh`
- `sudo ./scripts/harden-ssh.sh --dry-run && sudo ./scripts/harden-ssh.sh`
- `sudo ./scripts/setup-firewall.sh --dry-run && sudo ./scripts/setup-firewall.sh`
- `sudo ./scripts/deploy.sh`
- `sudo ./scripts/verify.sh`

## Safety Notes
- Keep one active SSH session open while applying SSH hardening.
- Validate deploy-user login before setting `PermitRootLogin no`.
- Prefer pinned app tags, never `latest`.
