#!/usr/bin/env python3
"""Audit existing Demiurge bundles for schema, count, and duplicate issues."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from prepare_demiurge_bundles import _normalize_quote_key


def _find_repeated_blocks(
    responses: list[dict[str, str]],
    min_block_size: int = 5,
) -> list[str]:
    issues: list[str] = []
    normalized_pairs = [
        (
            _normalize_quote_key(response["citation"]),
            response["author"].strip().lower(),
        )
        for response in responses
    ]

    max_block_size = len(normalized_pairs) // 2
    for block_size in range(max_block_size, min_block_size - 1, -1):
        found_for_size = False
        for start in range(0, len(normalized_pairs) - (block_size * 2) + 1):
            left = normalized_pairs[start:start + block_size]
            right = normalized_pairs[start + block_size:start + (block_size * 2)]
            if left != right:
                continue

            issues.append(
                "entries "
                f"{start + 1}-{start + block_size} repeat as a contiguous block in "
                f"entries {start + block_size + 1}-{start + (block_size * 2)}"
            )
            found_for_size = True
        if found_for_size:
            break

    return issues


def audit_bundle(path: Path, target: int) -> list[str]:
    issues: list[str] = []
    with path.open(encoding="utf-8") as handle:
        bundle = json.load(handle)

    responses = bundle.get("responses")
    if not isinstance(responses, list):
        return ["responses must be a list"]

    if len(responses) < target:
        issues.append(f"count {len(responses)} is below target {target}")

    exact_seen: dict[tuple[str, str], int] = {}
    normalized_seen: dict[tuple[str, str], int] = {}
    for index, response in enumerate(responses, start=1):
        if set(response.keys()) != {"opening", "citation", "author", "closing"}:
            issues.append(f"entry {index} has unexpected keys")
            continue
        if not all(
            isinstance(response[field], str) and response[field].strip()
            for field in ("opening", "citation", "author", "closing")
        ):
            issues.append(f"entry {index} has blank or non-string fields")
            continue

        exact_key = (
            response["citation"].strip().lower(),
            response["author"].strip().lower(),
        )
        if exact_key in exact_seen:
            issues.append(
                f"entry {index} repeats exact citation+author from entry {exact_seen[exact_key]}"
            )
        else:
            exact_seen[exact_key] = index

        normalized_key = (
            _normalize_quote_key(response["citation"]),
            response["author"].strip().lower(),
        )
        if normalized_key in normalized_seen:
            issues.append(
                "entry "
                f"{index} repeats normalized citation+author from entry {normalized_seen[normalized_key]}"
            )
        else:
            normalized_seen[normalized_key] = index

    issues.extend(_find_repeated_blocks(responses))

    return issues


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit Demiurge bundles already stored in assets/texts/demiurge."
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
        help="Minimum expected response count per bundle.",
    )
    args = parser.parse_args()

    bundle_dir = Path(args.bundle_dir)
    paths = sorted(bundle_dir.glob("*.json"))
    if not paths:
        print(f"No JSON bundles found in {bundle_dir}", file=sys.stderr)
        return 1

    has_issues = False
    for path in paths:
        issues = audit_bundle(path, args.target)
        if issues:
            has_issues = True
            print(f"{path}:")
            for issue in issues:
                print(f"  - {issue}")
        else:
            print(f"{path}: OK")

    return 1 if has_issues else 0


if __name__ == "__main__":
    raise SystemExit(main())