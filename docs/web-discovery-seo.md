# Global Web discovery and responsible measurement — K-057

Owner request: 6 November 2026. Grow Yorungez's global visibility and sourced public knowledge library while preserving the fast full-screen sky, open-source code, free/ad-free direction and shared native app. Native Android/iOS release is **coming soon**; do not invent store links or legal charity/tax status.

## Delivery contract

1. Fix the persistent floating “Update ready” indicator. Explain the PWA update in its menu, preserve unsaved work/multi-tab safeguards, and remove build-only update churn where possible. Never clear personal browser data or silently reload an active draft.
2. Use English examples only in the Web search placeholder, including Turkish UI; bilingual search remains available.
3. Add complete EN/TR metadata, reciprocal canonicals/hreflang, Open Graph/Twitter previews, indexable sourced library/about/mobile/privacy pages, sitemap, robots and truthful structured data. Protect account/lab/API paths from indexing; preserve genuine 404s.
4. Expand educational content with primary sources, clear review dates, modest claims and links into the existing glossary/sky. Public content must be meaningful without JavaScript. Avoid thin generated catalogue pages, fabricated expertise/reviews, hidden keyword text and ranking promises.
5. Register and verify the owner's requested Google Search Console, Bing Webmaster Tools, GA4 and Tag Manager properties using the accessible existing owner accounts; add verification tags/records and submit the real sitemap. Use free services, avoid unrelated property changes, paid plans, extra access grants and session replay. Record concrete provider outcomes; a pending verification is not completion.
6. Measurement is optional and consent-gated. Never send credentials, account/notebook data, search text, exact observer coordinates, sensor data or query/hash parameters. Keep advertising features off; native analytics remains a separate decision. Publish a clear measurement/privacy explanation and a way to change the choice.
7. AI search discovery follows readable, sourced, linked public HTML and crawl access. `llms.txt` is a convenience index, not an established ranking requirement or a substitute for HTML/sitemaps. Search crawling and model training are different controls. Record the current Google Search generative-AI choice and Bing AI-report availability where exposed.
8. Validate metadata/JSON-LD/sitemap parity, private-path exclusions, consent boundaries, update lifecycle, responsive UI, production build, offline public reopening and live routes before reporting success. Preserve all existing FR/UJ/AC identities and open physical/store gates.

## Primary guidance

- [Google AI features and sites](https://developers.google.com/search/docs/appearance/ai-features)
- [Google generative-AI optimization guide](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide)
- [Search Console generative-AI control](https://support.google.com/webmasters/answer/16908024)
- [Bing AI Performance](https://blogs.bing.com/webmaster/2026/2/Introducing-AI-Performance-in-Bing-Webmaster-Tools-Public-Preview/)
- [Bing IndexNow](https://www.bing.com/indexnow/getstarted)
- [OpenAI crawlers](https://developers.openai.com/api/docs/bots)

## Traceability

FR-03/04/08/09/11; UJ-01/02/03/07; AC-01/02/03/08/09/10/11/12/13. Existing scientific catalogue/ephemeris limits and private server-owned record rules remain unchanged. Detailed implementation/provider evidence is added as each gate is actually completed.

## Implementation and pre-rollout evidence — 6 November 2026

- Eight curated guides in `data/knowledge/guides.json`, each with paired EN/TR text, primary scientific sources and a real content review date. Five use existing licensed archive images with credit and licence links. No scientific catalogue or ephemeris model changed.
- Twenty-eight static public language/page combinations: the sky, glossary, library index/eight articles, about/science, mobile coming soon and privacy. Page-specific canonical URLs, reciprocal EN/TR/x-default, Open Graph/Twitter, truthful WebSite/Organization/WebApplication/Article JSON-LD, sitemap and robots are checked against the built HTML. Unknown articles return 404. Account pages have `noindex,nofollow`; API/account/lab paths are excluded from discovery. Robots is not an access-control mechanism.
- The initially closed map menu contains real public guide/project/mobile/privacy links. The sky remains the home screen. English-only search examples preserve bilingual catalogue matching. Public static pages remain readable without client JavaScript; the interactive map still needs JavaScript.
- Optional `llms.txt` links to public knowledge and states scientific/privacy limits. It is not a special AI ranking mechanism. Search/training robots settings have not been conflated.
- The floating update-ready badge was removed; the menu shows a small new-version indicator and explains safe explicit reload. Existing draft/multiple-tab activation guards remain. A Web-specific content fingerprint replaces random build IDs. Two consecutive production builds produced the **same** offline pack `b56a761b858f46006de5`, with no changed core files; backend/native/private files do not enter the build fingerprint. The verified public pack remains 5.3 MiB core / 14.1 MiB optional images. New educational HTML pages are online content, not a claim of newly cached offline articles.
- All **77 Web tests**, TypeScript and production build passed, including frozen astronomical tests already in the suite. A new build gate checks all 28 public HTML/canonical/language/schema/sitemap variants. Local HTTP checks confirmed public 200, unknown-article 404, account noindex and robots/sitemap responses. Responsive article, language switching, map menu and public-pack-ready states were inspected in Brave; this is not a new physical-device acceptance claim.

## Provider registry and operation

Only the newly requested Yorungez resources are changed. Private owner account identifiers, screenshots and deployment details stay in ignored `.local/seo-evidence/`; public measurement/verification IDs are intentionally visible in Web source.

| Service | Setup |
| --- | --- |
| Google Search Console | `yorungez.com` Domain property, ownership verified using one public Cloudflare DNS TXT record. Existing routing/mail/security records were not changed. Search generative-AI preference visibly reads **Include**, its default. |
| Google Analytics 4 | `Yorungez — Web`, Web stream `https://yorungez.com`, measurement ID `G-WFZDK36X46`. Reporting zone Europe/Istanbul. Enhanced measurement, Google Signals, detailed location/device collection and ad personalisation are off. Event/user retention is two months, with retention reset disabled. |
| Google Tag Manager | Owner-approved Terms/Data Processing Terms accepted; `Yorungez` / `yorungez.com`, container `GTM-NMRWNHQF`. Published empty baseline version 2: no tags/triggers or advertising. |
| Bing Webmaster Tools | `https://yorungez.com/` added manually; public `msvalidate.01` meta verification supplied in both home-page heads. Complete provider verification against the deployed tag during rollout. No broad Search Console OAuth import grant or Clarity/session replay enabled. |
| IndexNow | Public host-ownership proof plus a bounded 28-URL submission tool. Dry-run by default; `python scripts/submit_indexnow.py --submit` checks the live proof before posting. Acceptance is not an indexing guarantee; this is not Google's Indexing API. |

GA4 is installed **once**, directly through the consent-gated client. The independently managed GTM container is deliberately empty to avoid duplicate pageviews. Both load only after explicit analytics opt-in on the production hostname and a public allowlisted path. Before consent/after decline, no measurement scripts are loaded. Query/hash parameters, referrers, selected objects, search text, observer/sensor values and account/notebook data are not included. Standard GA4 session/engagement events can accompany manually emitted sanitized pageviews after consent. Necessary sessions/language and the optional six-month choice cookie are separate; no browser personal-record persistence is introduced.

Future GTM tags must undergo the same review; do not add an automatic GA4 tag while the direct integration exists. Privacy settings offer a choice-change action; withdrawal clears first-party GA cookies and reloads to discard loaded measurement code. Existing server records and user language remain intact.

Withdrawal also sets Google's documented per-measurement opt-out flag immediately. Open tabs synchronize the non-personal consent choice through BroadcastChannel, with focus/visibility fallback; other tabs stop measurement without automatically reloading an unsaved notebook draft. Private/non-production paths keep the measurement opt-out flag enabled. [Google privacy controls](https://developers.google.com/tag-platform/security/guides/privacy).

### Rollout protocol

After merge through the existing approved CI: verify live canonicals/robots/sitemap/public pages and the Bing meta tag; verify the Bing property, submit `https://yorungez.com/sitemap.xml` in Google/Bing, then submit the bounded IndexNow URL set. Check the visible provider outcomes and production consent flow before the delivery report. New properties need time to populate; do not fabricate traffic, citations, ranking changes or indexing completion. Ongoing work is source-based library growth and real Search Console/Bing AI-performance/Core Web Vitals evidence after traffic accumulates.

Measurement implementation follows [Google manual pageviews](https://developers.google.com/analytics/devguides/collection/ga4/views), [basic consent](https://developers.google.com/tag-platform/security/guides/consent) and [configuration/privacy fields](https://developers.google.com/analytics/devguides/collection/ga4/reference/config).
