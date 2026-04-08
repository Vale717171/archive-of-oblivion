#!/usr/bin/env python3
"""Generate lawful placeholder audio assets for local/device playtests.

This script does not download third-party recordings. It synthesizes simple
ambient loops and one-shot cues with ffmpeg so the app can be tested with real
audio files before licensed final masters are selected.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


DEFAULT_DURATION = 48
DEFAULT_SAMPLE_RATE = 48000


TRACK_RECIPES: dict[str, dict[str, float | int | str]] = {
    "soglia": {"tone": 73.42, "noise": 0.020, "cutoff": 900, "duration": 42},
    "giardino": {"tone": 196.00, "noise": 0.014, "cutoff": 1800, "duration": 50},
    "osservatorio": {"tone": 110.00, "noise": 0.012, "cutoff": 1500, "duration": 52},
    "galleria": {"tone": 164.81, "noise": 0.010, "cutoff": 2200, "duration": 46},
    "laboratorio": {"tone": 92.50, "noise": 0.024, "cutoff": 1200, "duration": 54},
    "memoria": {"tone": 146.83, "noise": 0.015, "cutoff": 1400, "duration": 44},
    "zona": {"tone": 65.41, "noise": 0.028, "cutoff": 800, "duration": 56},
    "oblivion": {"tone": 55.00, "noise": 0.035, "cutoff": 600, "duration": 60},
    "siciliano": {"tone": 220.00, "noise": 0.008, "cutoff": 2600, "duration": 36},
    "aria_goldberg": {"tone": 246.94, "noise": 0.006, "cutoff": 3000, "duration": 34},
    "giardino_fountain": {"tone": 207.65, "noise": 0.016, "cutoff": 2000, "duration": 34},
    "giardino_stelae": {"tone": 174.61, "noise": 0.013, "cutoff": 1900, "duration": 34},
    "osservatorio_calibration": {"tone": 123.47, "noise": 0.011, "cutoff": 1300, "duration": 34},
    "osservatorio_dome": {"tone": 98.00, "noise": 0.014, "cutoff": 1100, "duration": 36},
    "galleria_dark": {"tone": 130.81, "noise": 0.014, "cutoff": 1600, "duration": 34},
    "galleria_light": {"tone": 196.00, "noise": 0.010, "cutoff": 2400, "duration": 34},
    "galleria_mirror": {"tone": 155.56, "noise": 0.012, "cutoff": 1700, "duration": 34},
    "laboratorio_bain_marie": {"tone": 82.41, "noise": 0.022, "cutoff": 1000, "duration": 40},
    "laboratorio_sealed": {"tone": 77.78, "noise": 0.026, "cutoff": 900, "duration": 40},
    "memoria_ritual": {"tone": 138.59, "noise": 0.014, "cutoff": 1500, "duration": 38},
    "zona_eternal": {"tone": 61.74, "noise": 0.030, "cutoff": 700, "duration": 60},
    "proustian_trigger": {"kind": "sfx", "tone": 523.25, "duration": 3},
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate local placeholder OGG assets for the planned audio catalog."
    )
    parser.add_argument(
        "manifest",
        nargs="?",
        default="assets/audio/manifest.json",
        help="Path to the audio manifest JSON file.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite files that already exist.",
    )
    args = parser.parse_args()

    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
      print("ffmpeg is required but was not found on PATH.", file=sys.stderr)
      return 1

    manifest_path = Path(args.manifest)
    if not manifest_path.exists():
        print(f"Manifest not found: {manifest_path}", file=sys.stderr)
        return 1

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    tracks = data.get("tracks")
    if not isinstance(tracks, list):
        print("Manifest is missing a valid 'tracks' list.", file=sys.stderr)
        return 1

    repo_root = manifest_path.parent.parent.parent
    generated = 0
    skipped = 0

    for entry in tracks:
        key = entry.get("key")
        asset = entry.get("asset")
        if not isinstance(key, str) or not isinstance(asset, str):
            print(f"Skipping invalid manifest entry: {entry}", file=sys.stderr)
            continue

        recipe = TRACK_RECIPES.get(key)
        if recipe is None:
            print(f"No synthesis recipe for key '{key}', skipping.", file=sys.stderr)
            skipped += 1
            continue

        output_path = repo_root / asset
        output_path.parent.mkdir(parents=True, exist_ok=True)
        if output_path.exists() and not args.overwrite:
            print(f"Skipping existing file: {asset}")
            skipped += 1
            continue

        if recipe.get("kind") == "sfx":
            build_sfx(ffmpeg, output_path, recipe)
        else:
            build_ambience(ffmpeg, output_path, recipe)
        print(f"Generated {asset}")
        generated += 1

    print(f"Done. Generated {generated} file(s), skipped {skipped}.")
    return 0


def build_ambience(ffmpeg: str, output_path: Path, recipe: dict[str, float | int | str]) -> None:
    tone = float(recipe["tone"])
    noise = float(recipe["noise"])
    cutoff = int(recipe["cutoff"])
    duration = int(recipe.get("duration", DEFAULT_DURATION))
    secondary = tone * 1.4983

    cmd = [
        ffmpeg,
        "-y",
        "-f",
        "lavfi",
        "-i",
        f"sine=frequency={tone}:sample_rate={DEFAULT_SAMPLE_RATE}:duration={duration}",
        "-f",
        "lavfi",
        "-i",
        f"sine=frequency={secondary}:sample_rate={DEFAULT_SAMPLE_RATE}:duration={duration}",
        "-f",
        "lavfi",
        "-i",
        f"anoisesrc=color=pink:sample_rate={DEFAULT_SAMPLE_RATE}:duration={duration}:amplitude={noise}",
        "-filter_complex",
        (
            "[0:a]volume=0.045[a0];"
            "[1:a]volume=0.018[a1];"
            f"[2:a]lowpass=f={cutoff},volume=0.75[a2];"
            "[a0][a1][a2]amix=inputs=3:normalize=0,"
            f"afade=t=in:st=0:d=2,afade=t=out:st={max(duration - 2, 1)}:d=2"
        ),
        "-c:a",
        "libvorbis",
        str(output_path),
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def build_sfx(ffmpeg: str, output_path: Path, recipe: dict[str, float | int | str]) -> None:
    tone = float(recipe["tone"])
    duration = int(recipe.get("duration", 3))
    cmd = [
        ffmpeg,
        "-y",
        "-f",
        "lavfi",
        "-i",
        f"sine=frequency={tone}:sample_rate={DEFAULT_SAMPLE_RATE}:duration={duration}",
        "-f",
        "lavfi",
        "-i",
        f"anoisesrc=color=white:sample_rate={DEFAULT_SAMPLE_RATE}:duration={duration}:amplitude=0.004",
        "-filter_complex",
        (
            "[0:a]volume=0.12[a0];"
            "[1:a]highpass=f=1800,volume=0.25[a1];"
            "[a0][a1]amix=inputs=2:normalize=0,"
            "afade=t=in:st=0:d=0.05,afade=t=out:st=2.2:d=0.6"
        ),
        "-c:a",
        "libvorbis",
        str(output_path),
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    raise SystemExit(main())