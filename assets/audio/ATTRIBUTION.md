# Audio Attribution

This repository currently ships lawful, redistributable Bach audio renders that
were synthesized from public-domain score data rather than downloaded from
third-party recordings.

## Current Repository Audio

- Composition source: public-domain works by Johann Sebastian Bach
- Score source: `music21` bundled corpus
- Score corpus license: MIT
- Rendering pipeline: `music21` -> MIDI -> `FluidSynth` -> OGG Vorbis
- Default soundfont used by the generation tool: `FluidR3_GM`
- Generation script: [tools/generate_audio_assets.py](../../tools/generate_audio_assets.py)
- Track catalog: [assets/audio/manifest.json](./manifest.json)

## Important Note

These files are legally safe for redistribution, but they are still provisional
from an artistic standpoint. Their "MIDI-like" quality comes from the
synthesized rendering chain, not from the compositions themselves.

## Replacement Policy For Final Masters

When replacing any shipped track, record the following for each new asset:

- track key
- file name
- source URL
- performer / recording author
- exact license
- proof that redistribution inside the app and repository is allowed

Prefer `CC0` or clearly public-domain-compatible recordings for final release
masters.
