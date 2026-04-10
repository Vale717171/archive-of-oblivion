#!/usr/bin/env python3
"""
generate_audio_assets.py
========================
Generates all 22 audio assets for L'Archivio dell'Oblio using exclusively
public-domain Bach works from the music21 corpus.

Pipeline for each track:
  music21 (score) → MIDI → FluidSynth (WAV) → ffmpeg (OGG)

Requirements (all open-source, no copyrighted content):
  pip install music21
  sudo apt-get install fluidsynth fluid-soundfont-gm ffmpeg

Usage:
  python tools/generate_audio_assets.py [--output-dir assets/audio]

Each Bach piece used here is taken from music21's bundled corpus which
contains only public-domain scores (chorales from BWV 244/245/248, BWV 846,
and hundreds of other cantata chorales). No recordings are downloaded.
The synthesised audio is generated from MIDI data using the free FluidR3_GM
soundfont (LGPL licence) — entirely copyright-clean.
"""

import argparse
import os
import subprocess
import sys
import tempfile

# ---------------------------------------------------------------------------
# Track specifications
# Format: output_filename -> (corpus_key, tempo_scale, trim_secs_or_None)
#
# Thematic rationale per sector:
#   soglia      → BWV 846 Prelude in C major — bright, contemplative opening
#   giardino    → BWV 155.5 chorale — gentle, pastoral E minor
#   osservatorio→ BWV 227.1 motet (opening) — polyphonic, mathematical
#   galleria    → BWV 244.46 chorale — poignant, B minor (art / beauty / loss)
#   laboratorio → BWV 244.3 chorale — systematic, purposeful
#   memoria     → BWV 244.62 chorale — final chorale of St Matthew Passion, profound
#   zona        → BWV 244.17 chorale — haunting minor-key
#   siciliano   → BWV 244.15 chorale — slow, lyrical (siciliana-like arc)
#   aria_goldberg→ BWV 244.10 chorale — flowing, aria-like
#   oblivion    → BWV 245.37 chorale — sparse, atmospheric (St John Passion finale)
# ---------------------------------------------------------------------------
TRACK_SPECS = {
    # ── Sector base tracks ──────────────────────────────────────────────────
    "bach_bwv846_soglia.ogg":             ("bach/bwv846",      1.00, None),
    "bach_goldberg_giardino.ogg":         ("bach/bwv155.5",    0.90, None),
    "bach_contrapunctus_observatory.ogg": ("bach/bwv227.1",    1.05, None),
    "bach_bwv846_galleria.ogg":           ("bach/bwv244.46",   1.00, None),
    "bach_bwv1008_laboratorio.ogg":       ("bach/bwv244.3",    0.85, None),
    "bach_memoria_theme.ogg":             ("bach/bwv244.62",   0.85, None),
    "bach_fugue_883_zona.ogg":            ("bach/bwv244.17",   1.10, None),
    # ── Special / event tracks ──────────────────────────────────────────────
    "bach_siciliano_bwv1017.ogg":         ("bach/bwv244.15",   0.70, None),
    "bach_aria_goldberg.ogg":             ("bach/bwv244.10",   0.80, None),
    "echo_chamber.ogg":                   ("bach/bwv245.37",   0.65, None),
    # ── Room-override variations (each a distinct BWV piece) ─────────────────
    "garden_fountain_variation.ogg":      ("bach/bwv248.12-2", 1.10, None),
    "garden_stelae_variation.ogg":        ("bach/bwv244.29-a", 0.90, None),
    "observatory_calibration_variation.ogg": ("bach/bwv245.5", 1.15, None),
    "observatory_dome_variation.ogg":     ("bach/bwv245.11",   1.00, None),
    "gallery_dark_variation.ogg":         ("bach/bwv245.17",   0.80, None),
    "gallery_light_variation.ogg":        ("bach/bwv245.14",   1.10, None),
    "gallery_mirror_variation.ogg":       ("bach/bwv245.22",   1.00, None),
    "lab_bain_marie_variation.ogg":       ("bach/bwv245.26",   0.75, None),
    "lab_sealed_variation.ogg":           ("bach/bwv245.28",   0.70, None),
    "memory_ritual_variation.ogg":        ("bach/bwv245.40",   0.65, None),
    "zona_eternal_variation.ogg":         ("bach/bwv244.54",   0.90, None),
    # ── SFX (short snippet from BWV 846 Prelude, first 3 s) ─────────────────
    "sfx_proustian_trigger.ogg":          ("bach/bwv846",      1.00, 3),
}

SOUNDFONT_PATHS = [
    "/usr/share/sounds/sf2/FluidR3_GM.sf2",
    "/usr/share/sounds/sf2/default-GM.sf2",
    "/usr/share/soundfonts/FluidR3_GM.sf2",
]

OGG_QUALITY = "5"       # libvorbis quality: 4-6 is transparent for music
SAMPLE_RATE = "44100"   # standard CD quality


def find_soundfont() -> str:
    for path in SOUNDFONT_PATHS:
        if os.path.isfile(path):
            return path
    sys.exit(
        "ERROR: No GM soundfont found. Install with:\n"
        "  sudo apt-get install fluid-soundfont-gm"
    )


def check_dependencies():
    for cmd in ("fluidsynth", "ffmpeg"):
        if subprocess.run(["which", cmd], capture_output=True).returncode != 0:
            sys.exit(f"ERROR: '{cmd}' not found. Install it first.")
    try:
        import music21  # noqa: F401
    except ImportError:
        sys.exit("ERROR: music21 not installed. Run: pip install music21")


def generate_ogg(corpus_key: str, tempo_scale: float, trim_secs, output_path: str,
                 soundfont: str, tmp_dir: str) -> bool:
    """
    Load a Bach score from the music21 corpus, export to MIDI, synthesise
    with FluidSynth, and encode as OGG Vorbis.
    Returns True on success.
    """
    from music21 import corpus, tempo as m21tempo

    safe_name = os.path.basename(output_path).replace(".ogg", "")
    midi_path = os.path.join(tmp_dir, f"{safe_name}.mid")
    wav_path  = os.path.join(tmp_dir, f"{safe_name}.wav")

    # ── 1. Load from corpus ──────────────────────────────────────────────────
    try:
        score = corpus.parse(corpus_key)
    except Exception as exc:
        print(f"  ✗ Could not load '{corpus_key}': {exc}", file=sys.stderr)
        return False

    # ── 2. Apply tempo scaling ───────────────────────────────────────────────
    if tempo_scale != 1.0:
        marks = list(score.flatten().getElementsByClass(m21tempo.MetronomeMark))
        numeric_marks = [m for m in marks if m.number is not None]
        if numeric_marks:
            for mark in numeric_marks:
                mark.number = max(20, min(300, round(mark.number * tempo_scale)))
        else:
            # No explicit numeric tempo mark — insert one at the start
            score.parts[0].insert(0, m21tempo.MetronomeMark(number=round(96 * tempo_scale)))

    # ── 3. Export to MIDI ────────────────────────────────────────────────────
    try:
        score.write("midi", fp=midi_path)
    except Exception as exc:
        print(f"  ✗ MIDI export failed for '{corpus_key}': {exc}", file=sys.stderr)
        return False

    # ── 4. Synthesise with FluidSynth ────────────────────────────────────────
    fs_cmd = [
        "fluidsynth", "-ni",
        soundfont, midi_path,
        "-F", wav_path,
        "-r", SAMPLE_RATE,
        "-q",
    ]
    result = subprocess.run(fs_cmd, capture_output=True, text=True, timeout=120)
    if result.returncode != 0 or not os.path.isfile(wav_path):
        print(f"  ✗ FluidSynth failed for '{corpus_key}': {result.stderr[:200]}", file=sys.stderr)
        return False

    # ── 5. Encode to OGG (optionally trimmed for SFX) ───────────────────────
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-i", wav_path,
    ]
    if trim_secs is not None:
        ffmpeg_cmd += ["-t", str(trim_secs)]
    ffmpeg_cmd += [
        "-c:a", "libvorbis",
        "-q:a", OGG_QUALITY,
        "-ar", SAMPLE_RATE,
        "-ac", "2",
        # Tag the file so its provenance is clear
        "-metadata", "comment=Generated from Bach public-domain score via music21+FluidSynth",
        "-metadata", f"title={corpus_key}",
        "-metadata", "composer=Johann Sebastian Bach",
        "-metadata", "copyright=Public Domain",
        output_path,
    ]
    result2 = subprocess.run(ffmpeg_cmd, capture_output=True, text=True, timeout=60)
    if result2.returncode != 0:
        print(f"  ✗ ffmpeg failed for '{corpus_key}': {result2.stderr[-300:]}", file=sys.stderr)
        return False

    size_kb = os.path.getsize(output_path) // 1024
    print(f"  ✓ {os.path.basename(output_path)}  ({size_kb} KB)")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir", default="assets/audio",
        help="Directory to write OGG files (default: assets/audio)",
    )
    parser.add_argument(
        "--only", nargs="*",
        help="Regenerate only the listed filenames (e.g. echo_chamber.ogg)",
    )
    args = parser.parse_args()

    check_dependencies()
    soundfont = find_soundfont()
    print(f"Soundfont : {soundfont}")
    print(f"Output dir: {args.output_dir}")
    print()

    os.makedirs(args.output_dir, exist_ok=True)

    specs = TRACK_SPECS
    if args.only:
        specs = {k: v for k, v in TRACK_SPECS.items() if k in args.only}
        if not specs:
            sys.exit(f"None of {args.only} found in TRACK_SPECS.")

    ok = err = 0
    with tempfile.TemporaryDirectory(prefix="bach_audio_") as tmp_dir:
        for filename, (corpus_key, tempo_scale, trim_secs) in specs.items():
            output_path = os.path.join(args.output_dir, filename)
            print(f"[{corpus_key}] → {filename}")
            success = generate_ogg(
                corpus_key=corpus_key,
                tempo_scale=tempo_scale,
                trim_secs=trim_secs,
                output_path=output_path,
                soundfont=soundfont,
                tmp_dir=tmp_dir,
            )
            if success:
                ok += 1
            else:
                err += 1

    print()
    print(f"Done: {ok} generated, {err} failed.")
    if err:
        sys.exit(1)


if __name__ == "__main__":
    main()
