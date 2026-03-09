# Runbook: Restore

1. Locate archive in `/opt/backups`.
2. Run: `sudo BACKUP_FILE=/opt/backups/<file>.tar.gz ./scripts/restore.sh`.
3. Redeploy if needed: `sudo ./scripts/deploy.sh`.
