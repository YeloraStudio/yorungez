# Public source publication review

Date: 2026-11-01. Scope: the current Yorungez monorepo, intended for `YeloraStudio/yorungez`. User authorized public publication and explicitly selected Apache-2.0. This is a repository/publication hygiene review, not a full .NET/Next.js security audit, penetration test or production certification.

## Public and private boundary

Original backend/frontend/tooling/tests/docs, schema migrations, source provenance, lockfiles and generic local Compose are public. Live `.env`, local/production settings, signing/SMTP/database secrets, data-protection key rings, local logs/dumps, real personal inventory and Portainer/private deployment configuration are excluded. Sanitized `.env.example` is a template, not a usable production secret file.

Operational SMTP account text was replaced with `sender@example.com` in public examples and historical summaries. Private runtime files were preserved. Historical SMTP TLS/AUTH success describes a private local check; it does not assert authentication for the example address. No real-recipient test email was sent for publication.

Screenshots use public city-centre examples and synthetic accounts, as recorded in their QA reports. Physical GPS data was not collected for those developer checks. Screenshot review is separate from text secret detection.

## Licence boundary

Original code/project documentation: Apache-2.0, LICENSE/NOTICE. Upstream licences are preserved: MIT/BSD and other dependency licences, CC BY-SA catalogue content, Free Art License artwork, Commons/GeoNames attribution and the documented landscape licence discrepancy. No Stellarium runtime engine code is imported. Redis remains a separate service under its own selected licence. Dependency inventory is scoped evidence, not a complete release-specific legal certification of every future transitive package.

## Automated controls

- Explicit ignored private paths plus index inspection of actual Git blobs; no symlinks/submodules in the reviewed package.
- Local private `.env` values compared against indexed content without printing matched values, including compact/spaced app-password forms.
- Gitleaks 8.30.1 downloaded from its official release and checked against its published SHA-256; scans are redacted. CI independently pins the Linux archive checksum and scans full Git history.
- Original PRD archive checksum and all local Markdown targets/FR-UJ-AC identities verified by `scripts/verify_docs.py`.
- Git attributes preserve source/reference/archive/media bytes across checkout.
- CI uses GitHub-hosted Ubuntu runners, readonly default permissions, SHA-pinned official actions, locked package restores, captured test email and no deployment secrets. CodeQL adds static analysis for C#, TypeScript/JavaScript, Python and Actions. No `pull_request_target` job executes contributor code.
- Dependabot proposes weekly dependency/action updates; MediatR ≥13 is excluded to preserve the explicit 12.5.0 Apache-2.0 decision. Updates are not automatically merged.

## Verification record

Pre-publication checks completed locally:

- Indexed package: 551 reviewed files, approximately 28.1 MB; forbidden private paths absent; comparison against local private environment values passed without recording values.
- Negative control: a deliberately staged synthetic `.env.canary` path was blocked and then removed from both index and workspace.
- Gitleaks 8.30.1 staged scan: no findings. Full initial-commit history is checked separately before the first push.
- Documentation: 672 local links and all 12 FR / 7 UJ / 14 AC identities/trace rows verified; original archive SHA-256 remains `6d748df5dd0777b5570401f1f5bb163b94c2d51567f55c7139b9d42fd4c7c1fc`.
- Five email-branding tests passed in Debug after public sender-placeholder substitution. An initial Release attempt was blocked by the running local API's DLL lock; the user application was left running.
- `npm audit --omit=dev`: zero reported vulnerabilities at review time. NuGet vulnerable-package check including transitives: no reported findings. These are advisory snapshots, not future guarantees or a complete vulnerability audit.
- GitHub YAML parsed locally. Hosted application/scientific checks, CodeQL and platform settings are verified after the first push; workflow presence alone is not a passing result.

## Remaining work

Credential rotation is required if an actual exposure is found; deletion/history rewriting alone is insufficient. Generic passwords are not guaranteed to match provider scanners. This task does not establish backup restoration, operating-system/browser/device acceptance, production hardening or full application vulnerability coverage. The original product roadmap and scientific exceptions remain in force.

[ADR-0014](adr/0014-acik-kaynak-yayin-ve-apache-2.md) · [Security reporting](../SECURITY.md) · [Requirements](urun-gereksinimleri.md) · [Roadmap](yol-haritasi.md)
