# Runbook: Deploy

1. Ensure DNS A record points to droplet public IP.
2. `cp compose/.env.example compose/.env` and update values.
3. Run `sudo ./setup.sh --domain <domain> --email <email>`.
4. Run `sudo ./scripts/verify.sh`.
