# 08 — UX, languages and accessibility catalogue

**Status:** proposed native experience, preserving confirmed branding and user journeys. **Traceability:** FR-01–12, UJ-01–07, AC-01–14.

## Product surface

Keep the full-screen sky as the primary experience, with a closed-by-default menu and floating/collapsible object, location and time controls. Retain the grey/burgundy palette: `#3C3F43`, `#9EA1A6`, `#8B2333`, `#C9B6A6`, `#F7F1E6`. Reuse the supplied brand sources with platform-specific exports. A native application does not require replacing the existing visual identity with generic platform styling.

Main destinations remain Sky, Tonight, Calendar and My Notebook. Do not reintroduce the redundant Explore link or the removed Today destination. Account-free exploration remains available; saving personal inventory leads to a simple account flow. Side panels need a clear Back path and a separate close-to-map action.

## Pointing journey

Recommended user-facing flow:

1. Select an object or open Point at the sky.
2. Confirm Live mode and an actual/manual observer; show useful fix quality without forcing a long diagnostic panel.
3. Request only the capability being activated, with a short explanation and a manual fallback.
4. Show a concise calibration/quality state and a visible stop action.
5. Guide toward the target with direction and altitude; explain a below-horizon state.
6. Offer camera preview separately; expose recalibration and zoom without hiding the target.

Do not hide uncertainty behind a convincing visual. The AR view must not imply that an object below Earth's horizon or behind a building is physically visible. Virtual exploration with transparent illustrative terrain remains a distinct valid mode. No compulsory camera, location permission or equipment is introduced for ordinary exploration.

The earlier [competitor study](../../arastirma-stellarium-skyview-2026-11-04.md) informs these proposals; no competitor task-completion study was performed.

## Object information and observing guidance

Prioritize identity/type, a source-backed image, a short explanation and practical observing context. Expand physical fields, coordinates and detailed credits on demand. Keep photographs separate from calculated previews. Explain night visibility, direction and height in beginner language while retaining precise values and glossary access. Weather/obstruction uncertainty is not a successful visibility prediction.

Search accepts names, aliases and identifiers in both languages. A constellation named Andromeda and the galaxy M31 have different types/IDs; the Milky Way is an extended feature. Native search must inherit these distinctions and preserve the selected scientific context.

## English and Turkish

Use Flutter's localization workflow, ARB resources, plural/select rules and generated localization classes; use locale-aware number/date formatting. The SDK supports this workflow but translations and completeness remain our responsibility. [Flutter internationalization](https://docs.flutter.dev/ui/internationalization).

Use shared stable content/term IDs, with independent EN/TR text and source metadata. API error codes remain machine-readable; display localized messages. Preserve English-by-default and the shared account preference. Turkish dotted/dotless I, diacritic-insensitive aliases, long translated labels, units, screen-reader phrases and time-zone displays need explicit cases.

Research documentation being English does not change the bilingual product requirement. Transactional email remains English under the existing decision. Do not silently translate personal notebook text.

## Controls and accessible alternatives

The owner requested custom dropdown/date controls. Native implementations may be branded, but must provide meaningful semantics, focus order, large text support, selection state and predictable cancellation/Back behaviour. Avoid a purely painted selection control without accessibility nodes.

A canvas full of stars is not an accessible object list by itself. Provide a nearby/visible-object list, textual target direction, Tonight intervals and reachable object detail as alternative paths. Throttle spoken updates: every sensor tick should not trigger a screen-reader announcement. Test TalkBack and VoiceOver on physical devices. Flutter supplies accessibility facilities and a release checklist; framework support does not make a custom sky automatically accessible. [Flutter accessibility](https://docs.flutter.dev/ui/accessibility).

Validate contrast on the moving day/night/camera background, not only on a static colour swatch. Ensure clear focus, touch targets, reduced motion, orientation flexibility, safe areas, keyboard input where relevant, text enlargement and a non-colour-only tracking status. Night mode should cover menus/cards as well as the map; avoid claiming a particular screen colour guarantees dark adaptation.

## Mobile-specific acceptance tasks

Find Jupiter from Tonight; find M31 from either alias; explain why a selected target is below the horizon; change time and return to Live; deny sensor/camera permission and continue manually; open/collapse/restore panels in landscape; search/read a glossary term with TalkBack/VoiceOver; change account language on one client and observe it on another; reopen the base sky in airplane mode.

Measure success, confusion and recovery rather than assigning a speculative UX percentage. User satisfaction with the existing S23 PWA is useful feedback, but does not establish native permission, lens, performance or accessibility acceptance.
