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

## GitHub publication and repository controls

Initial source snapshot `32ca1df` was pushed to the public [YeloraStudio/yorungez repository](https://github.com/YeloraStudio/yorungez). Its full one-commit Gitleaks history scan had no findings. A Git source ZIP contained 551 public files, excluded private runtime files and preserved the archived PRD hash. GitHub identified the code licence as Apache-2.0.

Read back from GitHub after configuration:

- Provider secret scanning and secret push protection: enabled. Non-provider patterns/validity checks were not enabled; no claim that every Gmail app password is detected by GitHub.
- Dependabot vulnerability alerts/security updates and private vulnerability reporting: enabled.
- Actions default token: read; workflow approval of PR reviews: disabled. Repository CI contains no deployment secrets.
- Main branch: PR required, all six named application/publication/CodeQL checks required from the GitHub Actions app, branch up-to-date required, administrator enforcement enabled, linear history and resolved conversations required. Force push and deletion disabled.
- Required human approval count is zero for the current solo maintainer; no claim of independent human review. CODEOWNERS identifies the maintainer. Squash merging is enabled; automatic merging is disabled.

The first CodeQL run reported incomplete multi-character tag stripping in the external article formatter. The consumer renders React text nodes, not raw HTML; exploitability was not established by this finding alone. A follow-up removes all angle brackets including malformed/nested fragments while retaining ordinary credit text, with an adversarial regression check. Static analysis must rerun on that change; the alert must not be dismissed merely to obtain a clean dashboard.

Hosted initial-snapshot results:

- [CI run 41296049358](https://github.com/YeloraStudio/yorungez/actions/runs/41296049358): publication safety, 18 core + 19 astronomy + 88 API tests (125 total), 44 client tests, typecheck, production PWA build, frozen-reference integrity and C#/JavaScript scientific parity passed.
- [CodeQL run 41296049386](https://github.com/YeloraStudio/yorungez/actions/runs/41296049386): all four analyses completed successfully; one tag-stripping alert was reported. Successful analysis execution alone does not mean zero findings.
- [Follow-up PR #4](https://github.com/YeloraStudio/yorungez/pull/4) adds the 45th client test and fixes the formatter. The subsequent JavaScript analysis marked the follow-up alert fixed; the patch will merge only after all six required checks pass. The final default-branch alert state remains independently inspectable in the Security tab.
- The local application remained available: frontend and API readiness returned HTTP 200 after publication. No user service was stopped or production deployment performed.

## Remaining work

Credential rotation is required if an actual exposure is found; deletion/history rewriting alone is insufficient. Generic passwords are not guaranteed to match provider scanners. This task does not establish backup restoration, operating-system/browser/device acceptance, production hardening or full application vulnerability coverage. The original product roadmap and scientific exceptions remain in force.

[ADR-0014](adr/0014-acik-kaynak-yayin-ve-apache-2.md) · [Security reporting](../SECURITY.md) · [Requirements](urun-gereksinimleri.md) · [Roadmap](yol-haritasi.md)
