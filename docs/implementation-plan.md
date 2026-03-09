# Implementation Plan (Ticketized)

## Epic 1: Foundation
- [ ] T1.1 Initialize repository structure
- [ ] T1.2 Implement `lib/common.sh`
- [ ] T1.3 Add `setup.sh` orchestration

## Epic 2: Security Baseline
- [ ] T2.1 Implement `bootstrap.sh`
- [ ] T2.2 Implement `harden-ssh.sh` with `--dry-run`
- [ ] T2.3 Implement `setup-firewall.sh` with `--dry-run`

## Epic 3: Deploy Runtime
- [ ] T3.1 Implement compose and env templates
- [ ] T3.2 Implement `deploy.sh` and Nginx template
- [ ] T3.3 Implement deploy-state metadata

## Epic 4: Operability
- [ ] T4.1 Implement `backup.sh`
- [ ] T4.2 Implement `restore.sh`
- [ ] T4.3 Implement `rollback.sh`
- [ ] T4.4 Implement `verify.sh`

## Epic 5: Quality + Docs
- [ ] T5.1 Add CI workflow
- [ ] T5.2 Add runbooks and architecture docs
- [ ] T5.3 Execute live deployment test on DO droplet
