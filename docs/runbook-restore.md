# Runbook: Restore

1. Locate archive in `/opt/backups`.
2. Stop app: `cd /opt/linux-server-baseline && sudo docker compose down`
3. Run: `sudo BACKUP_FILE=/opt/backups/<file>.tar.gz ./scripts/restore.sh`.
4. Restore volume data if needed:
   ```bash
   sudo docker run --rm -v n8n_data:/data -v /opt/backups:/backup busybox \
     sh -c "cd /data && tar -xzf /backup/n8n_data-TIMESTAMP.tar.gz"
   ```
5. Redeploy: `sudo ./scripts/deploy.sh`.
