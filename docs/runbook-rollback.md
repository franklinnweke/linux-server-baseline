# Runbook: Rollback

1. Check state: `cat /opt/linux-server-baseline/.deploy-state | jq .`
2. Run: `sudo ./scripts/rollback.sh`.
3. Verify: `sudo ./scripts/verify.sh`.

**Limitations:** Rollback is unavailable on the first deployment because there is no previous tag. If the new version ran database migrations, confirm application compatibility before rolling back.
