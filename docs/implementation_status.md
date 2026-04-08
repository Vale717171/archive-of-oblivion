# Implementation Status

This document maps the current repository state against the main improvement themes discussed during pre-release planning.

## Implemented

- Home/title flow with continue/new game and supporting panels.
- Intro, how-to-play, settings, and credits surfaces.
- Saved-run summary on the home screen.
- In-game menu, session card, room/sector labeling, autosave-facing UI.
- Contextual quick commands and last-command recall.
- Instant text, reduced motion, high contrast, command assist, text scaling, typewriter pace.
- Persistent audio controls for music and SFX levels/toggles, even before final masters are added.
- Parser expansion with more verbs, synonyms, hint tiers, and movement affordances.
- Demiurge content pipeline hardening and validated 200-entry bundles for all sectors.
- Analyzer-clean workspace and passing automated tests.
- Analyzer-clean workspace and passing automated tests with additional manifest/helper regression coverage.
- Device playtest checklist.
- Standalone browser trial slice in HTML for lightweight sharing and tone validation.
- Audio import pipeline and repository-side asset audit tooling.
- Lawful placeholder-audio generation path for immediate on-device sound testing.

## Partially Implemented

- Onboarding: available, but not yet a full progressive or optional tutorial flow.
- Accessibility: good baseline options exist, but not a full screen-reader/semantics/accessibility-profile pass.
- Visual identity: stronger than the prototype, but not yet a final branded product presentation.
- Parser ergonomics: much better, but still lacks richer disambiguation and “nearly understood” suggestions.
- Documentation coherence: substantially improved, but not yet fully unified across all project-facing materials.
- Automated test coverage: present, but still narrow relative to engine complexity.

## Still Missing Or Not Ready

- Real audio masters in the app package.
- Typewriter/haptic controls and release-level audio balancing.
- Widget tests and broader regression coverage for puzzles, transitions, and finale routing.
- End-to-end or smoke automation for long-form progression.
- Full Flutter web port with web-safe persistence and complete gameplay parity.
- Editorial release assets: store copy, screenshots, icon polish, media kit.
- Meta-systems such as archive/journal/quote log/chapter view/reflection mode.
- Large engine refactor toward more data-driven progression.

## Next Practical Pre-Release Priorities

1. Add licensed audio assets or intentionally ship a text-first/silent-reading build.
2. Run full physical-device playtest using [docs/device_playtest_checklist.md](docs/device_playtest_checklist.md).
3. Add targeted regression tests for puzzle gates, boss/finale transitions, and Demiurge helper behavior.
4. Prepare minimal release-facing editorial assets and README-level product framing.