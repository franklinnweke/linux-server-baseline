# Hardening Notes

- SSH uses key-based auth, password disabled.
- UFW allows only 22, 80, 443.
- Fail2ban is installed for SSH brute-force protection.
- Root login should move from `prohibit-password` to `no` after deploy-user verification.
