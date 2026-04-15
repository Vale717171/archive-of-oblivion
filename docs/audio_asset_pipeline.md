# Audio Asset Pipeline

This project already contains the runtime audio infrastructure and now ships a
fully curated `CC0` runtime music catalog in [assets/audio/manifest.json](assets/audio/manifest.json).

This document now defines the safe path for maintaining and polishing that
catalog without introducing licensing ambiguity or runtime mismatches.

## Goal

Maintain, replace, or polish audio files for Android playtesting and release
candidates without introducing licensing ambiguity or mismatches between the
repository and the runtime catalog.

## Important Constraint

The compositions referenced by the project are public-domain works, but recordings are not automatically public-domain.

Do not add downloaded recordings unless one of these is true:

- the recording is your own original production
- the recording is explicitly licensed for redistribution in the app and repository
- the recording source clearly allows the intended commercial/non-commercial use, modification, and distribution

## Repository Source Of Truth

- Planned catalog: [assets/audio/manifest.json](assets/audio/manifest.json)
- Provenance record: [assets/audio/ATTRIBUTION.md](../assets/audio/ATTRIBUTION.md)
- Replacement shortlist: [docs/audio_master_candidates.md](audio_master_candidates.md)
- Runtime routing: [lib/features/audio/audio_track_catalog.dart](lib/features/audio/audio_track_catalog.dart)
- Runtime playback and settings: [lib/features/audio/audio_service.dart](lib/features/audio/audio_service.dart)
- Verification tool: [tools/audit_audio_assets.py](tools/audit_audio_assets.py)

## Recommended Import Or Replacement Flow

1. Choose the recording source and verify license terms.
2. Convert or render each file to the repository target format, currently `.ogg`.
3. Name the files exactly as declared in [assets/audio/manifest.json](assets/audio/manifest.json).
4. Place them under [assets/audio](assets/audio).
5. Run the audit tool:

```bash
python3 tools/audit_audio_assets.py
```

6. Run application checks:

```bash
flutter analyze
flutter test
```

7. On device, verify:
- startup audio behavior
- special triggers such as `siciliano`, `aria_goldberg`, `oblivion`
- settings-panel toggles and volume sliders
- behavior when music is disabled but SFX remains enabled

## Current Polish Focus

The main remaining work is no longer licensing or catalog completion. It is:

- loudness balancing across curated masters
- fade and loop behavior during transitions
- physical-device validation of startup, room changes, and finale triggers
- deciding whether any long room-level cues should be shortened or faded for repetition control

## Attribution Record

Whenever audio is added or replaced, update [assets/audio/ATTRIBUTION.md](../assets/audio/ATTRIBUTION.md) with:

- track key
- file name
- source URL or production source
- performer / recording author
- license name
- proof of reuse terms if applicable

That file now exists and should remain the canonical provenance record.

## What This Enables Now

The project is already ready for ongoing audio polish at the code level:

- missing files fail safely
- runtime audio routing is already sector-aware
- special track triggers are implemented
- persistent music and SFX controls exist in settings
- per-track mix compensation can be tuned in `AudioTrackCatalog` without refactoring playback

So the next meaningful gains come from Android-side listening passes rather than
new asset acquisition.
