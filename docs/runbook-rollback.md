# Runbook: Rollback

1. Check state: `cat /opt/linux-server-baseline/.deploy-state | jq .`
2. Run: `sudo ./scripts/rollback.sh`.
3. Verify: `sudo ./scripts/verify.sh`.

**Limitations:** Can't rollback first deployment (no previous tag). If the new version ran database migrations, rollback might break things - test carefully.
