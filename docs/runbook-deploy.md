# Runbook: Deploy

1. Ensure DNS A record points to droplet public IP.
2. `cp compose/.env.example compose/.env` and update values.
3. Run `sudo ./setup.sh --domain <domain> --email <email>`.
4. Run `sudo ./scripts/verify.sh`.

**Note:** Certbot may fail if DNS isn't propagated yet. Wait 5 min and re-run `deploy.sh` if needed.

## Updating

Change `APP_TAG` in `/opt/linux-server-baseline/.env`, then re-run deploy from repo:
```bash
cd ~/linux-server-baseline  # Or wherever you cloned the repo
sudo ./scripts/deploy.sh
```
