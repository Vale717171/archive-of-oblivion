# Audio Master Candidates

This document is the practical replacement shortlist for the current
repository audio.

The project already ships lawful Bach renders generated from public-domain
scores, but they are still provisional in musical quality. The goal here is to
replace them with stronger masters while keeping licensing unambiguous.

## Current Status

As of 2026-04-15, the first three curated replacements have already been
integrated into the repository:

- `soglia`
- `giardino`
- `aria_goldberg`

## Verified Source Pools

### 1. Open Well-Tempered Clavier

- Performer: Kimiko Ishizaka
- Work: Book 1 of *The Well-Tempered Clavier*
- Licensing status: `CC0`
- Primary sources:
  - [Official project site](https://welltemperedclavier.org/)
  - [Wikimedia Commons category](https://commons.wikimedia.org/wiki/Category:Open_Well-Tempered_Clavier)
  - [Audio files category](https://commons.wikimedia.org/wiki/Category:Audio_files_of_Open_Well-Tempered_Clavier,_Book_1)
  - [BWV 846 Prelude No. 1 file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_Bach_-_Well-Tempered_Clavier,_Book_1_-_01_Prelude_No._1_in_C_major,_BWV_846.ogg)

### 2. Open Goldberg Variations

- Performer: Kimiko Ishizaka
- Work: *Goldberg Variations*, BWV 988
- Licensing status: `CC0`
- Primary sources:
  - [Official project site](https://www.opengoldbergvariations.org/)
  - [Wikimedia Commons category](https://commons.wikimedia.org/wiki/Category:Open_Goldberg_Variations)
  - [Aria file page](https://commons.wikimedia.org/wiki/File:Goldberg_Variations_01_Aria.ogg)
  - [Variatio 25 file page](https://commons.wikimedia.org/wiki/File:Goldberg_Variations_26_Variatio_25_a_2_Clav.ogg)
  - [Aria da Capo file page](https://commons.wikimedia.org/wiki/File:Kimiko_Ishizaka_-_J.S._Bach-_-Open-_Goldberg_Variations,_BWV_988_(Piano)_-_31_Aria_da_Capo_%C3%A8_Fine.mp3)

## Source Policy

Use the two source pools above as the default acquisition path.

They are preferable to generic public-domain aggregators because:

- the performer and project are explicit
- the release intent is explicit
- the CC0 status is easy to verify from primary pages

## Musopen: Useful, But Not First Choice

Musopen is still useful for scouting, but it should remain a fallback source
for this project.

Reason:

- the front page presents the catalog as available "without copyright restrictions"
- the FAQ also says Musopen cannot guarantee every user-uploaded recording is in
  fact public domain and encourages independent verification

For this project that means:

- good for discovery
- not good enough as the primary ingestion path unless the specific recording has
  independently verified provenance

## Recommended First Replacement Pass

These replacements are the highest-confidence path for a first audio upgrade.
They intentionally focus on the main sector loop and special cues before room
variations.

| Runtime key | Current role | Recommended master | Source pool | Confidence |
|---|---|---|---|---|
| `soglia` | opening threshold | Prelude No. 1 in C major, BWV 846 | Open WTC | high |
| `giardino` | contemplative / luminous | Goldberg Aria | Open Goldberg | high |
| `osservatorio` | architectural / cerebral | Fugue No. 1 in C major, BWV 846 | Open WTC | high |
| `galleria` | elegiac / reflective | Variatio 25 a 2 Clav. | Open Goldberg | high |
| `laboratorio` | methodical / ritual | Prelude No. 2 in C minor, BWV 847 | Open WTC | high |
| `memoria` | return / tenderness / recollection | Aria da Capo è Fine | Open Goldberg | high |
| `zona` | haunted / unstable / liminal | Fugue No. 24 in B minor, BWV 869 | Open WTC | high |
| `aria_goldberg` | acceptance ending | Goldberg Aria | Open Goldberg | high |
| `siciliano` | Quinto landing / memory cue | Variatio 13 a 2 Clav. | Open Goldberg | medium |
| `oblivion` | nucleus / aftermath / dark hush | Variatio 25 a 2 Clav. or Fugue No. 24 in B minor, BWV 869 | Open Goldberg / Open WTC | medium |

## Notes On Fit

- `soglia` is the easiest upgrade: BWV 846 from Open WTC is both legally clean
  and aesthetically stronger than the current synth render.
- `giardino` and `aria_goldberg` should almost certainly come from the Goldberg
  Aria pool.
- `galleria` and `oblivion` can share a source family, but they should not ship
  the exact same master. If one uses `Variatio 25`, the other should use the B
  minor WTC material instead.
- `siciliano` is the least literal mapping in the shortlist. It is there because
  the emotional contour fits the use case, not because it matches the current
  filename.

## Filename Strategy

There are two viable implementation paths.

### Fast path

Keep the existing asset filenames and runtime keys, but replace the binary
content with the new masters.

Pros:

- zero code changes
- fastest way to audition on device

Cons:

- filenames may stop matching the underlying piece names

### Clean release path

After the musical direction is approved, rename the assets and update:

- `assets/audio/manifest.json`
- `lib/features/audio/audio_track_catalog.dart`
- `assets/audio/ATTRIBUTION.md`

This is the better release-state option.

## Suggested Next Execution Order

1. Replace the 7 base tracks first.
2. Replace `aria_goldberg`, `siciliano`, and `oblivion`.
3. Normalize loudness and trim/fade each master for looping behavior.
4. Only after the sector identity feels right, replace room-variation tracks.

## Minimum Deliverable For The Next Session

If you want the fastest audible win, start with these three:

- `bach_bwv846_soglia.ogg` -> Open WTC Prelude No. 1 in C major
- `bach_goldberg_giardino.ogg` -> Goldberg Aria
- `bach_aria_goldberg.ogg` -> Goldberg Aria or Aria da Capo

That alone should materially change the perceived quality of the project.
