# linux-server-baseline

Production-style Ubuntu baseline for secure app deployment: SSH hardening, firewall, Docker Compose app, Nginx reverse proxy, TLS, backup/restore, rollback, and verification.

> This uses n8n as the example app, but the infrastructure scripts work for any Docker Compose stack. Just swap out the compose file.

## Why This Exists

I built this to avoid repeating ad-hoc server setup on every new VPS. The goal is a practical baseline I can run on a fresh Ubuntu host and trust in production-like conditions:
- secure remote access
- predictable deployment steps
- rollback path
- backup and restore basics
- explicit verification checks

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

## Design Decisions

- `PermitRootLogin` defaults to `prohibit-password` first:
  - avoids lockout during initial migration
  - move to `no` after deploy-user SSH is verified
- `setup-firewall.sh` resets UFW to a known baseline:
  - this removes drift
  - script now requires confirmation unless `--yes` is passed
- `.deploy-state` is JSON:
  - easy to parse with `jq`
  - keeps current/previous deployment metadata for rollback
- app binds to `127.0.0.1` in compose:
  - app is not exposed directly
  - nginx is the only public entrypoint

## Known Limitations

- Backup volume logic currently expects `n8n_data` by name.
- This is single-host only (no HA/failover).
- Monitoring is minimal (verify script + service logs), not full observability stack.

## What I Would Build Next

- Auto-detect and back up named volumes from compose instead of hardcoding.
- Add staged deployments with automatic rollback on failed health checks.
- Add optional Prometheus/Grafana profile.
- Add minimal integration test job that provisions an ephemeral host and runs setup.

## Common Issues

**SSH lockout:** Keep an active session open when running `harden-ssh.sh`.

**Certbot fails:** Check DNS points to your server (`dig +short your-domain.com`). Port 80 must be open.

**Container won't start:** Check logs with `docker compose logs`. Usually port conflicts or bad env vars.
