#!/usr/bin/env python3
"""Audit planned audio assets against the repository manifest and filesystem."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate assets/audio/manifest.json against actual audio files."
    )
    parser.add_argument(
        "manifest",
        nargs="?",
        default="assets/audio/manifest.json",
        help="Path to the audio manifest JSON file.",
    )
    args = parser.parse_args()

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
    seen_keys: set[str] = set()
    referenced_assets: set[Path] = set()
    missing: list[tuple[str, str]] = []
    duplicate_keys: list[str] = []

    for entry in tracks:
        key = entry.get("key")
        asset = entry.get("asset")
        if not isinstance(key, str) or not isinstance(asset, str):
            print(f"Invalid manifest entry: {entry}", file=sys.stderr)
            return 1
        if key in seen_keys:
            duplicate_keys.append(key)
        seen_keys.add(key)

        asset_path = repo_root / asset
        referenced_assets.add(asset_path.resolve())
        if not asset_path.exists():
            missing.append((key, asset))

    audio_dir = repo_root / "assets" / "audio"
    unexpected = sorted(
        path for path in audio_dir.glob("**/*")
        if path.is_file()
        and path.name != "manifest.json"
        and path.resolve() not in referenced_assets
    )

    print(f"Manifest: {manifest_path}")
    print(f"Tracks declared: {len(tracks)}")
    print(f"Missing files: {len(missing)}")
    print(f"Unexpected files: {len(unexpected)}")

    if duplicate_keys:
      print("Duplicate keys:")
      for key in duplicate_keys:
          print(f"  - {key}")

    if missing:
        print("Missing assets:")
        for key, asset in missing:
            print(f"  - {key}: {asset}")

    if unexpected:
        print("Unexpected files not declared in manifest:")
        for path in unexpected:
            print(f"  - {path.relative_to(repo_root)}")

    return 1 if duplicate_keys or missing else 0


if __name__ == "__main__":
    raise SystemExit(main())