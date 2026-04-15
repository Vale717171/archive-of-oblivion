# Audio Attribution

This repository currently ships a hybrid audio catalog:

- some cues are curated external masters with explicit `CC0` release
- the remaining cues are lawful in-repo renders synthesized from
  public-domain Bach score data

## Curated External Masters

### `soglia`

- File: `assets/audio/bach_bwv846_soglia.ogg`
- Work: *The Well-Tempered Clavier*, Book 1, Prelude No. 1 in C major, BWV 846
- Performer: Kimiko Ishizaka
- Source pool: Open Well-Tempered Clavier
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_Bach_-_Well-Tempered_Clavier,_Book_1_-_01_Prelude_No._1_in_C_major,_BWV_846.ogg)
- Upstream project: [welltemperedclavier.org](https://welltemperedclavier.org/)
- License: `CC0 1.0 Universal`
- Reuse basis: the Wikimedia file page explicitly marks the recording as `CC0`

### `giardino`

- File: `assets/audio/bach_goldberg_giardino.ogg`
- Work: *Goldberg Variations*, BWV 988, Aria
- Performer: Kimiko Ishizaka
- Source pool: Open Goldberg Variations
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Goldberg_Variations_01_Aria.ogg)
- Upstream project: [opengoldbergvariations.org](https://www.opengoldbergvariations.org/)
- License: `CC0 1.0 Universal`
- Reuse basis: the Wikimedia file page explicitly marks the performance as `CC0`

### `aria_goldberg`

- File: `assets/audio/bach_aria_goldberg.ogg`
- Work: *Goldberg Variations*, BWV 988, Aria da Capo e Fine
- Performer: Kimiko Ishizaka
- Source pool: Open Goldberg Variations
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_J.S._Bach-_-Open-_Goldberg_Variations,_BWV_988_(Piano)_-_31_Aria_da_Capo_%C3%A8_Fine.mp3)
- Upstream project: [opengoldbergvariations.org](https://www.opengoldbergvariations.org/)
- Repository note: the checked-in `.ogg` asset is a local transcode of the `CC0`
  source MP3 to match the app catalog format
- License: `CC0 1.0 Universal`
- Reuse basis: the Wikimedia file page explicitly marks the performance as `CC0`

### `osservatorio`

- File: `assets/audio/bach_contrapunctus_observatory.ogg`
- Work: *The Well-Tempered Clavier*, Book 1, Fugue No. 1 in C major, BWV 846
- Performer: Kimiko Ishizaka
- Source pool: Open Well-Tempered Clavier
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_Bach_-_Well-Tempered_Clavier,_Book_1_-_02_Fugue_No._1_in_C_major,_BWV_846.ogg)
- Upstream project: [welltemperedclavier.org](https://welltemperedclavier.org/)
- License: `CC0 1.0 Universal`
- Reuse basis: the Wikimedia file page explicitly marks the recording as `CC0`

### `laboratorio`

- File: `assets/audio/bach_bwv1008_laboratorio.ogg`
- Work: *The Well-Tempered Clavier*, Book 1, Prelude No. 2 in C minor, BWV 847
- Performer: Kimiko Ishizaka
- Source pool: Open Well-Tempered Clavier
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_Bach_-_Well-Tempered_Clavier,_Book_1_-_03_Prelude_No._2_in_C_minor,_BWV_847.ogg)
- Upstream project: [welltemperedclavier.org](https://welltemperedclavier.org/)
- License: `CC0 1.0 Universal`
- Reuse basis: the Wikimedia file page explicitly marks the recording as `CC0`

### `oblivion`

- File: `assets/audio/echo_chamber.ogg`
- Work: *The Well-Tempered Clavier*, Book 1, Fugue No. 24 in B minor, BWV 869
- Performer: Kimiko Ishizaka
- Source pool: Open Well-Tempered Clavier
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_Bach_-_Well-Tempered_Clavier,_Book_1_-_48_Fugue_No._24_in_B_minor,_BWV_869.ogg)
- Upstream project: [welltemperedclavier.org](https://welltemperedclavier.org/)
- License: `CC0 1.0 Universal`
- Reuse basis: the Wikimedia file page explicitly marks the recording as `CC0`

### `galleria`

- File: `assets/audio/bach_bwv846_galleria.ogg`
- Work: *Goldberg Variations*, BWV 988, Variatio 25 a 2 Clav.
- Performer: Kimiko Ishizaka
- Source pool: Open Goldberg Variations
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_26_-_Variatio_25_a_2_Clav.ogg)
- Upstream project: [opengoldbergvariations.org](https://www.opengoldbergvariations.org/)
- License: `CC0 1.0 Universal`
- Reuse basis: the file metadata and file page claim `CC0`; note that the
  Wikimedia page is still marked `license review needed`

### `siciliano`

- File: `assets/audio/bach_siciliano_bwv1017.ogg`
- Work: *Goldberg Variations*, BWV 988, Variatio 13 a 2 Clav.
- Performer: Kimiko Ishizaka
- Source pool: Open Goldberg Variations
- Source page: [Wikimedia Commons file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_14_-_Variatio_13_a_2_Clav.ogg)
- Upstream project: [opengoldbergvariations.org](https://www.opengoldbergvariations.org/)
- License: `CC0 1.0 Universal`
- Reuse basis: the file metadata and file page claim `CC0`; note that the
  Wikimedia page is still marked `license review needed`

## Remaining Synthesized Repository Audio

All other current music cues still come from the in-repo synthesis pipeline:

- Composition source: public-domain works by Johann Sebastian Bach
- Score source: `music21` bundled corpus
- Score corpus license: MIT
- Rendering pipeline: `music21` -> MIDI -> `FluidSynth` -> OGG Vorbis
- Default soundfont used by the generation tool: `FluidR3_GM`
- Generation script: [tools/generate_audio_assets.py](../../tools/generate_audio_assets.py)
- Track catalog: [assets/audio/manifest.json](./manifest.json)

## Important Note

The remaining synthesized tracks are legally safe for redistribution, but they
are still provisional from an artistic standpoint. Their "MIDI-like" quality
comes from the synthesis chain, not from the compositions themselves.

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
