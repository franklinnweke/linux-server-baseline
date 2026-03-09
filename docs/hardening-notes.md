# Hardening Notes

- SSH uses key-based auth, password disabled.
- UFW allows only 22, 80, 443.
- Fail2ban is installed for SSH brute-force protection.
- Root login defaults to `prohibit-password` (key-only) for safe migration. Set `PERMIT_ROOT_LOGIN_POLICY=no` env var to fully disable root SSH after verifying deploy-user access.
