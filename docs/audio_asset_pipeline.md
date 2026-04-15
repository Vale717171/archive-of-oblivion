# Audio Asset Pipeline

This project already contains the runtime audio infrastructure and the planned catalog in [assets/audio/manifest.json](assets/audio/manifest.json). What is still missing is the actual set of shipped masters.

This document defines the safe path for adding them.

## Goal

Add real audio files for Android playtesting and release candidates without introducing licensing ambiguity or mismatches between the repository and the runtime catalog.

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

## Recommended Import Flow

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

## Fastest Lawful Path For Device Testing

If you want audio on the phone immediately, the safest option is not to download third-party recordings first. Generate temporary placeholder assets locally.

The repository now includes [tools/generate_placeholder_audio.py](../tools/generate_placeholder_audio.py), which synthesizes `.ogg` files matching the planned catalog using `ffmpeg`.

Run:

```bash
python3 tools/generate_placeholder_audio.py --overwrite
python3 tools/audit_audio_assets.py
flutter analyze
flutter test
```

This gives you a fully lawful, redistributable-for-internal-testing audio set because the files are generated locally rather than downloaded from an external recording source.

Later, when you choose final licensed masters, replace the generated placeholders file by file.

## Minimum First Audio Drop

If you want the fastest useful first pass, do not try to fill the whole catalog at once. Start with:

- `bach_bwv846_soglia.ogg`
- `bach_goldberg_giardino.ogg`
- `bach_contrapunctus_observatory.ogg`
- `bach_bwv846_galleria.ogg`
- `bach_bwv1008_laboratorio.ogg`
- `bach_memoria_theme.ogg`
- `bach_fugue_883_zona.ogg`
- `bach_siciliano_bwv1017.ogg`
- `bach_aria_goldberg.ogg`
- `echo_chamber.ogg`

That set is enough to validate the main sector flow and the special finale/memory cues before investing in room-specific variations.

If you use the placeholder generator, it can create the whole declared catalog in one pass, so you do not need to stop at the minimum set unless you prefer to curate manually.

## Attribution Record

Whenever real audio is added, update [assets/audio/ATTRIBUTION.md](../assets/audio/ATTRIBUTION.md) with:

- track key
- file name
- source URL or production source
- performer / recording author
- license name
- proof of reuse terms if applicable

That file now exists and should remain the canonical provenance record.

## What This Enables Now

The project is already ready for audio integration at the code level:

- missing files fail safely
- runtime audio routing is already sector-aware
- special track triggers are implemented
- persistent music and SFX controls exist in settings

So once the files exist and pass audit, Android-side audio playtesting can begin immediately.
