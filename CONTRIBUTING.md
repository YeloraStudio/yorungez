# Contributing to Yorungez

Read the [overview](README.md), [requirements](docs/urun-gereksinimleri.md), [roadmap](docs/yol-haritasi.md) and applicable [AGENTS.md](AGENTS.md). Most detailed records are Turkish; contributions and discussions may be in English or Turkish.

## Issues and pull requests

Describe the problem, expected behaviour, reproduction and environment. Scientific comparisons need the UTC instant, frame, units, model, refraction/horizon assumptions, independent source and tolerance. Use public example locations and synthetic accounts. Vulnerabilities belong in the private channel described in [SECURITY.md](SECURITY.md).

Keep changes focused and link applicable FR/UJ/AC IDs. Distinguish plans, implementations, sampled evidence and completed acceptance. Preserve documented exceptions; do not loosen tolerances to make comparisons pass. Physical acceptance cannot be replaced by desktop mocks.

## Implementation rules

- Domain/Application do not reference Infrastructure, ASP.NET or EF Core; modules do not read each other's tables. Commands and queries use distinct handlers.
- Keep version pins/lockfiles together. MediatR **12.5.0** is an explicit Apache-2.0 decision; major upgrades require licence review.
- Develop complete English/Turkish UI/API/accessibility text together. Default English; transactional email is branded English in either UI language. Add paired sourced terms and update their content version.
- Use shared custom SelectField/DateField/DateTimeField controls; preserve keyboard/focus behaviour, DST ambiguity and drafts.
- Personal saves require verified accounts and owner-scoped PostgreSQL persistence. No anonymous browser notebook, private offline queue or account-response cache.
- Keep location/compass optional and permission-driven, with stale-data guards, true-north/alignment rules and manual alternatives. Never silently send private coordinates to external services.
- Preserve source manifests, original attributions/licences and upstream bytes. Generated copies are not source of truth. Normal tests/builds do not download reference datasets; refreshes are explicit.
- Keep the original requirements archive unchanged.

Frontend work follows [its AGENTS.md](src/Yorungez.Web/AGENTS.md) and installed Next.js documentation. Avoid simultaneous builds in one output directory. Do not stop another developer's services; use a separate preview directory/port when needed.

## Checks

See [local setup](README.md#run-locally). Run checks relevant to the change:

```powershell
python scripts/verify_docs.py
./scripts/Verify-Backend.ps1
./scripts/Verify-Web.ps1
./scripts/Verify-Science.ps1 -Offline
```

Offline science assumes installed dependencies. Integration tests use local randomly named test databases and captured email. Do not send QA messages to real recipients. Documentation-only work generally needs the link/requirements check rather than a full rebuild.

Review the staged diff and run `python scripts/check_publication.py` before committing. It checks indexed blobs and compares local private values without displaying them. CI checks history with Gitleaks; neither guarantees complete detection. Keep credentials, private locations, personal data, logs, dumps and live deployment configuration out of commits/issues/output. Only sanitized templates belong in Git.

PRs run on GitHub-hosted runners without production secrets or deployment access. Review workflow/dependency changes carefully. Explain what changed, why, relevant verification and remaining uncertainty.

## Licences and collaboration

Original contributions are submitted under [Apache-2.0](LICENSE). Declare provenance/licences for added code, data and media, and preserve third-party conditions. Do not copy assets just because they are visible online; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Discuss evidence respectfully. Avoid harassment, personal attacks and publishing private information. Maintainers may close, edit or remove content that makes collaboration unsafe or unproductive. No response time or paid support is promised.
