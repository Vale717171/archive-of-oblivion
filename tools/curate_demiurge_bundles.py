#!/usr/bin/env python3
"""Curate existing Demiurge bundles by deduplicating and capping entries."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from prepare_demiurge_bundles import (
    CLOSINGS,
    OPENINGS,
    _build_variant_sequence,
    _normalize_quote_key,
    _validate_bundle,
)


EXPECTED_KEYS = {"opening", "citation", "author", "closing"}


def curate_bundle(
    path: Path,
    target: int,
    refresh_voice: bool,
    seed: int,
) -> tuple[dict, list[str]]:
    with path.open(encoding="utf-8") as handle:
        bundle = json.load(handle)

    responses = bundle.get("responses")
    if not isinstance(responses, list):
        return bundle, ["responses must be a list"]

    curated: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    issues: list[str] = []

    for index, response in enumerate(responses, start=1):
        if set(response.keys()) != EXPECTED_KEYS:
            issues.append(f"entry {index} has unexpected keys")
            continue
        if not all(
            isinstance(response[field], str) and response[field].strip()
            for field in ("opening", "citation", "author", "closing")
        ):
            issues.append(f"entry {index} has blank or non-string fields")
            continue

        normalized_key = (
            _normalize_quote_key(response["citation"]),
            response["author"].strip().lower(),
        )
        if normalized_key in seen:
            continue

        seen.add(normalized_key)
        curated.append({
            "opening": response["opening"].strip(),
            "citation": response["citation"].strip(),
            "author": response["author"].strip(),
            "closing": response["closing"].strip(),
        })

        if len(curated) >= target:
            break

    if refresh_voice and curated:
        import random

        rng = random.Random(seed)
        openings = _build_variant_sequence(OPENINGS, len(curated), rng)
        closings = _build_variant_sequence(CLOSINGS, len(curated), rng)
        for index, response in enumerate(curated):
            response["opening"] = openings[index]
            response["closing"] = closings[index]

    bundle["responses"] = curated
    issues.extend(_validate_bundle(bundle, target))

    if len(curated) < target:
        shortage_issue = (
            f"only {len(curated)} unique responses remain after deduplication; target is {target}"
        )
        if shortage_issue not in issues:
            issues.append(shortage_issue)

    return bundle, issues


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Deduplicate and cap existing Demiurge bundles in-place."
    )
    parser.add_argument(
        "bundle_dir",
        nargs="?",
        default="assets/texts/demiurge",
        help="Directory containing sector JSON bundles.",
    )
    parser.add_argument(
        "--target",
        type=int,
        default=200,
        help="Maximum number of unique responses to keep per bundle.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report planned changes without writing files.",
    )
    parser.add_argument(
        "--refresh-voice",
        action="store_true",
        help="Reassign canonical Demiurge openings/closings after deduplication.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=20260408,
        help="Deterministic seed used when refreshing opening/closing variants.",
    )
    args = parser.parse_args()

    bundle_dir = Path(args.bundle_dir)
    paths = sorted(bundle_dir.glob("*.json"))
    if not paths:
        print(f"No JSON bundles found in {bundle_dir}")
        return 1

    failed = False
    for path in paths:
        with path.open(encoding="utf-8") as handle:
            original_bundle = json.load(handle)
        original_count = len(original_bundle.get("responses", []))

        curated_bundle, issues = curate_bundle(
            path,
            args.target,
            args.refresh_voice,
            args.seed,
        )
        curated_count = len(curated_bundle.get("responses", []))

        print(f"{path}: {original_count} -> {curated_count}")
        if issues:
            failed = True
            for issue in issues:
                print(f"  - {issue}")

        if not args.dry_run:
            with path.open("w", encoding="utf-8") as handle:
                json.dump(curated_bundle, handle, indent=2, ensure_ascii=False)
                handle.write("\n")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())