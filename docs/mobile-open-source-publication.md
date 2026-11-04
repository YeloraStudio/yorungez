# Mobile open-source scope and publication — K-053

On **5 November 2026**, the owner explicitly authorized committing, pushing and publishing the current project. Delivery covers the Flutter Android/iOS source, mobile research and evidence, scientific adapters/data provenance, public ISS endpoint and verification workflow. The existing protected-secret GitHub Actions pipeline deploys the API and Web after merging to `main`. This record does not claim a completed deployment before the workflow and public checks finish.

## Licensing and distribution

Original Yorungez code and documentation remain Apache-2.0 under the root [license](../LICENSE). Flutter is BSD-3-Clause, and Flutter's official guidance permits commercial and store distribution subject to each component's own licence and platform rules. Open source is compatible with our free, advertising-free Android/iOS direction; it is not a store-approval guarantee.

Apache-2.0 permits reuse, modification and redistribution, including commercial reuse, with the licence/notice obligations retained. It does not grant rights to the project's trademarks. Other developers may fork the code. Public availability does not transfer ownership of the original work.

Third-party code, astronomical catalogues, photographs, constellation figures and music retain their own licences and attribution requirements. They are not relicensed as Apache-2.0. The [third-party notices](../THIRD_PARTY_NOTICES.md), source manifests and generated in-app offline notices remain part of distribution. Competitor screenshots are private research references under ignored `.local/`, not redistributable application assets.

## Publication boundaries and gates

- Stage only intended source, public data, original documentation and attributed assets. Scan the exact index for forbidden paths and known local private values; run Gitleaks on staged changes and Git history. Preserve upstream scientific source and data bytes.
- Keep environment files, SMTP/database/JWT credentials, server keyrings, deployment SSH keys, Android/iOS production signing material and private reference captures outside Git. Do not embed server secrets in the mobile client; obfuscation does not protect embedded secrets.
- Require publication/docs, application/science, production-container, mobile analysis/tests/native parity/APK and CodeQL checks before merging the delivery PR. Follow the main deployment workflow and inspect public health/Web/ISS contracts afterwards. Never waive failed checks merely to publish.
- Do not upload development-signed test APKs as store releases. Play/App Store identities, signing, privacy declarations, native release builds, physical pointing/camera/performance acceptance and review remain separate gates. The existing development APK is for owner testing.
- Preserve the [open feature/physical acceptance work](mobile-immersive-discovery-evidence.md). Publishing source and the shared backend does not complete native accounts, inventory, secure language synchronization, Tonight/calendar/glossary parity or iOS acceptance.

## Primary references

- [Flutter FAQ: licensing, package notices and store distribution](https://docs.flutter.dev/resources/faq)
- [Apache License 2.0: permissions, redistribution and trademarks](https://www.apache.org/licenses/LICENSE-2.0)
- [Flutter code obfuscation: secrets and reverse-engineering limitations](https://docs.flutter.dev/deployment/obfuscate)

Implementation and local verification evidence: [mobile foundation](mobile-foundation.md), [sky-first delivery](mobile-sky-first-evidence.md), [immersive discovery](mobile-immersive-discovery-evidence.md), and [screen-awake/one-second dwell polish](mobile-screen-awake-and-polish.md). GitHub PR checks and the main deployment run provide the subsequent publication outcome.
