# PRD: Linux Server Baseline (DevOps Portfolio Project)

## 1. Document Control
- Project: `linux-server-baseline`
- Version: `v1.0`
- Author: Franklin Nweke
- Date: 2026-03-07
- Status: Approved for implementation

## 2. Executive Summary
Build a production-style Linux server baseline that can harden a fresh Ubuntu host and deploy an app stack with secure defaults, repeatable automation, and operational runbooks.

The project demonstrates practical DevOps capabilities:
- Linux administration
- security hardening
- deployment automation
- reverse proxy/TLS
- health checks, backups, and rollback

## 3. Problem Statement
Most beginner server setups are manual and non-repeatable. This creates:
- configuration drift
- weak security defaults
- slow recovery when systems fail
- poor team handoff due to missing runbooks

This project solves that by codifying a consistent baseline usable on a fresh droplet/VM.

## 4. Goals
### 4.1 Primary Goals
- Provision and harden Ubuntu server with safe SSH defaults
- Deploy containerized app behind Nginx reverse proxy
- Support HTTPS with Let’s Encrypt
- Provide one-command deploy/update flow
- Include backup + restore + rollback paths
- Include clear verification and operational runbooks

### 4.2 Non-Goals (v1)
- Kubernetes
- Multi-node HA architecture
- Centralized monitoring stack (Prometheus/Grafana) as mandatory
- Multi-cloud abstraction

## 5. Users and Stakeholders
- Primary user: Junior DevOps engineer (project owner)
- Secondary users: Hiring managers / technical interviewers
- Stakeholders: Small startup teams needing quick secure baseline

## 6. Scope
### 6.1 In Scope
- Ubuntu 24.04 LTS target host
- SSH hardening + firewall baseline
- Docker Engine + Compose plugin
- Single app service deployment (n8n or sample Node app)
- Nginx reverse proxy with TLS
- Daily backup script for app data
- Restore script
- Rollback script (previous image tag)
- CI checks for scripts and config linting
- Complete README, architecture diagram, and runbooks

### 6.2 Out of Scope
- Auto-scaling
- Service mesh
- Complex secrets manager integration
- Full SIEM/log pipeline

## 7. Success Criteria (Acceptance)
Project is accepted when all criteria pass:
1. Fresh Ubuntu server can be configured using repo scripts/playbook without manual config edits.
2. SSH password login is disabled; key-based login works.
3. Firewall allows only required inbound ports (`22`, `80`, `443`).
4. App is reachable via domain over valid HTTPS cert.
5. Health check endpoint returns HTTP 200.
6. Backup script produces timestamped archive and restore script can recover app state.
7. Rollback to previous image tag is successful.
8. CI pipeline passes on pull requests.
9. README allows an engineer to reproduce setup in under 60 minutes.

## 8. Functional Requirements
### FR-1: Host Bootstrap
- Install required packages: `curl`, `git`, `ufw`, `fail2ban`, `nginx`, `docker-ce`, `docker-compose-plugin`.
- Create deploy user (e.g., `ops`) with sudo.
- Add SSH public key for deploy user.

### FR-2: SSH Hardening
- `PasswordAuthentication no`
- `PubkeyAuthentication yes`
- `PermitRootLogin no` (or `prohibit-password` during migration phase)
- Restart SSH safely with pre-check (`sshd -t`).

### FR-3: Firewall Baseline
- Enable UFW defaults:
  - deny incoming
  - allow outgoing
- Allow `22`, `80`, `443`
- Optional: restrict `22` to admin CIDR if provided.

### FR-4: App Deployment
- Deploy `docker-compose.yml` stack under `/opt/linux-server-baseline`.
- Support `.env` with required app variables.
- App runs with `restart: unless-stopped`.
- Health check configured.

### FR-5: Reverse Proxy + TLS
- Nginx server block proxies domain traffic to app internal port.
- Certbot obtains and renews certificates.
- HTTP redirected to HTTPS.

### FR-6: Backup and Restore
- Daily cron/systemd timer for backup script.
- Backup target includes app data volumes and environment metadata.
- Restore script documented and tested.

### FR-7: Rollback
- Deployment stores prior image tag in metadata file.
- `rollback.sh` redeploys previous known-good tag.

### FR-8: Verification
- `verify.sh` validates:
  - SSH config state
  - firewall rules
  - Docker health
  - Nginx config test
  - HTTPS endpoint availability

## 9. Non-Functional Requirements
### NFR-1: Security
- No secrets committed to Git.
- `.env.example` only, real `.env` excluded.
- Principle of least privilege for runtime containers.

### NFR-2: Reliability
- Scripts idempotent where feasible.
- Failed step exits non-zero with clear message.

### NFR-3: Maintainability
- Shell scripts use strict mode (`set -euo pipefail`).
- Functions are modular and commented minimally where needed.

### NFR-4: Portability
- Tested on Ubuntu 24.04 LTS.
- Avoid distro-specific assumptions beyond declared support.

## 10. Architecture
### 10.1 Logical Flow
1. User hits `https://n8n.example.com`
2. DNS resolves to droplet public IP
3. Nginx handles TLS and reverse proxy
4. App container serves request
5. Persistent data stored in Docker volume or bind mount

### 10.2 Components
- Ubuntu host (DigitalOcean droplet)
- OpenSSH server
- UFW + Fail2ban
- Docker Engine + Compose
- Nginx + Certbot
- App container (n8n/sample app)
- Backup/restore scripts

## 11. Repository Specification
```text
linux-server-baseline/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── runbook-deploy.md
│   ├── runbook-rollback.md
│   ├── runbook-restore.md
│   └── hardening-notes.md
├── scripts/
│   ├── bootstrap.sh
│   ├── harden-ssh.sh
│   ├── setup-firewall.sh
│   ├── deploy.sh
│   ├── rollback.sh
│   ├── backup.sh
│   ├── restore.sh
│   └── verify.sh
├── nginx/
│   └── site.conf.template
├── compose/
│   ├── docker-compose.yml
│   └── .env.example
├── systemd/
│   ├── backup.service
│   └── backup.timer
└── .github/
    └── workflows/
        └── ci.yml
```

## 12. Detailed Engineering Plan
### Phase 1: Foundation
- Initialize repo
- Add shell lint config (`shellcheck`) and formatting rules
- Create script harness (`lib/common.sh` optional)

### Phase 2: Security Baseline
- Implement `bootstrap.sh`, `harden-ssh.sh`, `setup-firewall.sh`
- Validate non-interactive execution

### Phase 3: Runtime + App
- Install Docker and Compose
- Add compose file and deploy script
- Add Nginx template and TLS bootstrap

### Phase 4: Operations
- Add backup timer + restore
- Add rollback logic
- Add verification script

### Phase 5: CI + Docs
- CI checks (`shellcheck`, `bash -n`, `nginx -t` on template rendering)
- Final runbooks and architecture docs

## 13. Script Contracts
### `scripts/bootstrap.sh`
Inputs:
- `DEPLOY_USER`
- `DEPLOY_PUBKEY`
Outputs:
- user created
- sudo configured
- baseline packages installed

### `scripts/deploy.sh`
Inputs:
- `DOMAIN`
- `EMAIL`
- `APP_IMAGE`
- `APP_TAG`
Outputs:
- compose stack running
- nginx configured
- cert issued/renewed

### `scripts/backup.sh`
Inputs:
- `BACKUP_DIR`
- `PROJECT_DIR`
Outputs:
- `backup-YYYYmmdd-HHMMSS.tar.gz`

### `scripts/rollback.sh`
Inputs:
- `PREV_TAG` from metadata
Outputs:
- app restored to prior image

## 14. Configuration Specification
### Required environment variables
- `DOMAIN`
- `LETSENCRYPT_EMAIL`
- `APP_IMAGE`
- `APP_TAG`
- `TZ`

### Optional
- `SSH_ALLOWED_CIDR`
- `BACKUP_RETENTION_DAYS` (default 7)
- `APP_PORT_INTERNAL` (default app-specific)

## 15. Security Specification
- SSH private keys never stored in repo
- file permissions:
  - `~/.ssh` => `700`
  - `authorized_keys` => `600`
- Root login policy documented and enforced
- UFW enabled before exposure of web services
- Fail2ban jail for `sshd`

## 16. Observability (v1 minimal)
- `docker compose ps`
- `journalctl -u ssh -n 100`
- nginx/access logs available via runbook
- health endpoint check integrated into `verify.sh`

## 17. Testing Strategy
### 17.1 Local Static Checks (CI)
- `shellcheck scripts/*.sh`
- `bash -n scripts/*.sh`
- basic YAML lint on compose/workflows

### 17.2 Integration Test (Manual)
- Fresh droplet
- Run bootstrap/hardening/deploy
- Validate HTTPS and health check
- Execute backup + restore smoke test
- Execute rollback smoke test

## 18. Deployment Procedure (Reference)
1. Create Ubuntu 24.04 droplet
2. Add SSH key
3. Clone repo onto control machine
4. Set env vars in deployment shell
5. Run:
   - `./scripts/bootstrap.sh`
   - `./scripts/harden-ssh.sh`
   - `./scripts/setup-firewall.sh`
   - `./scripts/deploy.sh`
6. Run `./scripts/verify.sh`

## 19. Risks and Mitigations
- Risk: SSH lockout after hardening
  - Mitigation: keep active session open; test new session before closing
- Risk: TLS issuance fails due to DNS
  - Mitigation: preflight DNS check in deploy script
- Risk: Upgrades break runtime
  - Mitigation: pinned app tag + rollback script
- Risk: Disk fills from backups
  - Mitigation: retention policy + pruning

## 20. Milestones and Timeline (5 days)
- Day 1: Repo skeleton + bootstrap + hardening
- Day 2: Docker + app deploy + nginx template
- Day 3: TLS + verify script
- Day 4: backup/restore/rollback + tests
- Day 5: docs polish + CI + demo screenshots

## 21. Deliverables
- Public GitHub repository with code + docs
- One successful deployment to existing DO droplet
- README quickstart + architecture diagram
- Demo evidence:
  - HTTPS endpoint screenshot
  - `verify.sh` success output
  - backup archive sample

## 22. Resume/Portfolio Mapping
After completion, resume bullets can credibly include:
- Automated Ubuntu server hardening and app deployment with Bash/Ansible patterns
- Implemented SSH key-only access, firewall policy, and fail2ban protection
- Deployed containerized service behind Nginx with TLS and rollback workflow
- Authored operational runbooks for deploy, backup/restore, and incident recovery

## 23. Definition of Done
- All success criteria in Section 7 met
- Scripts work on a fresh host without manual file editing
- Documentation enables third-party reproduction
- Security and rollback controls verified
