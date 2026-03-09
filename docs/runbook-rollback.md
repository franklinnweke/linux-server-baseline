# Runbook: Rollback

1. Check state: `cat /opt/linux-server-baseline/.deploy-state`.
2. Run: `sudo ./scripts/rollback.sh`.
3. Verify: `sudo ./scripts/verify.sh`.
