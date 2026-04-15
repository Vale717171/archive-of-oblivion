# L'Archivio dell'Oblio

A psycho-philosophical text adventure for Android built with Flutter.

The project is a deterministic parser narrative about memory, burden, ritual, and oblivion. It currently includes four main sectors, a fifth memory sector, La Zona, and three endings.

## Current State

- Core game loop implemented: parser input, puzzle gating, inventory, psycho-weight, persistence.
- Narrative layer implemented: deterministic Demiurge narrator with curated public-domain bundles.
- UI shell implemented: home screen, introduction/how-to-play/settings/credits panels, in-game menu, contextual quick commands, autosave-facing session UI.
- Automated verification in active use: `flutter test` green, with `flutter analyze` kept as a release gate.
- Device playtest still pending as the next major milestone.

## Stack

- Flutter
- Riverpod (`AsyncNotifier`-based state)
- sqflite
- just_audio

## Project Structure

- [lib/main.dart](lib/main.dart): app bootstrap, audio init, Demiurge preload
- [lib/features/game/game_engine_provider.dart](lib/features/game/game_engine_provider.dart): main game engine and progression logic
- [lib/features/parser/parser_service.dart](lib/features/parser/parser_service.dart): text parser
- [lib/features/demiurge/demiurge_service.dart](lib/features/demiurge/demiurge_service.dart): deterministic narrator
- [lib/features/ui/home_screen.dart](lib/features/ui/home_screen.dart): title/home experience
- [lib/features/ui/game_screen.dart](lib/features/ui/game_screen.dart): main game interface
- [docs/device_playtest_checklist.md](docs/device_playtest_checklist.md): physical-device QA checklist
- [docs/work_log.md](docs/work_log.md): chronological development log
- [CLAUDE.md](CLAUDE.md): current project briefing and source of truth for agent sessions

## Run And Verify

```bash
flutter pub get
flutter analyze
flutter test
```

## Browser Trial

A standalone browser-playable vertical slice lives in [docs/web_trial_demo.html](docs/web_trial_demo.html).

It is not a full web port of the Flutter app. It is a self-contained HTML teaser that proves tone, parser feel, local persistence, and a small Garden puzzle without depending on mobile-only persistence infrastructure.

## Content Pipeline

Demiurge bundles live in [assets/texts/demiurge](assets/texts/demiurge).

Relevant tools:

- [tools/prepare_demiurge_bundles.py](tools/prepare_demiurge_bundles.py): online generation with balancing and fallback supplementation
- [tools/audit_demiurge_bundles.py](tools/audit_demiurge_bundles.py): schema/count/duplicate/repeated-block validation
- [tools/curate_demiurge_bundles.py](tools/curate_demiurge_bundles.py): local repair of checked-in bundles
- [tools/audit_audio_assets.py](tools/audit_audio_assets.py): verify declared audio assets against the repository

## Known Gaps Before Release

- Physical Android playtest not completed yet.
- Release-quality audio masters are still missing; the repository currently ships lawful synthesized Bach renders plus [assets/audio/manifest.json](assets/audio/manifest.json), so runtime wiring can already be tested on device.
- Test coverage is still limited compared to the size of the game engine.
- Editorial release materials (store text, screenshots, media kit) are not prepared yet.

## Audio Note

The compositions referenced by the project are public-domain works, but recordings are not automatically safe to download and ship. Any real audio assets added to the app should be verified for licensing before inclusion.

See [docs/audio_asset_pipeline.md](docs/audio_asset_pipeline.md) for the recommended import and verification flow.

The current checked-in audio is lawful and redistributable. Eight key cues now ship with curated `CC0` Bach masters, while the rest of the catalog remains provisional synthesized audio. See [assets/audio/ATTRIBUTION.md](assets/audio/ATTRIBUTION.md), [docs/audio_asset_pipeline.md](docs/audio_asset_pipeline.md), and [docs/audio_master_candidates.md](docs/audio_master_candidates.md) for provenance and the remaining replacement shortlist.
