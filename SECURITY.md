# Security policy

Yorungez is experimental and under active development. The maintained line is latest `main`; there are no long-term support releases or response-time guarantees. Public source and passing CI are not a penetration-test certificate or production-readiness claim.

## Report privately

Use [GitHub private vulnerability reporting](https://github.com/YeloraStudio/yorungez/security/advisories/new) under **Security → Report a vulnerability**. Include revision, impact, minimal reproduction and a suggested fix if available. Use synthetic accounts/locations. Never submit active credentials, real personal records or private precise coordinates.

If the form is unavailable, open an issue requesting a private channel **without exploit details or sensitive data**. There is no bug-bounty promise. Allow investigation and coordinated disclosure.

## Repository safeguards

- Private environments, local settings, key rings, dumps and live deployment overrides are excluded from Git. Public examples contain placeholders only.
- `scripts/check_publication.py` checks indexed files and can compare private local values without displaying them. Gitleaks checks history in CI. GitHub supported-pattern scanning adds a layer; arbitrary passwords are not comprehensively detected.
- PR CI runs on GitHub-hosted runners with scoped permissions. No production credentials or deployment workflow is included. Actions use pinned commit SHAs; dependency changes remain reviewable.
- Account/notebook changes must retain owner scoping, verification, revocable sessions, same-origin safeguards and exclusion from shared/offline caches.

See the [publication review](docs/open-source-publication.md) for scope and evidence.

## Operating a deployment

Keep SMTP credentials, signing keys, database/cache credentials and data-protection keys in private server configuration. Use distinct secrets per environment, restrict infrastructure network access, serve the application over HTTPS, maintain backups and test restoration. Local Compose is not production hardening.

If a real credential is disclosed, revoke/rotate it at the provider and coordinate history remediation. Deleting a file or rewriting history alone does not invalidate an exposed credential.
