#!/usr/bin/env python3
"""
prepare_demiurge_bundles.py — Fetch public-domain citations for the Demiurge.

Queries Wikiquote API and Project Gutenberg to build sector-specific JSON
bundles with ≥200 citations per sector for "All That Is" (Tutto Ciò Che È).

Usage:
    python tools/prepare_demiurge_bundles.py [--output-dir assets/texts/demiurge]

Sources (all public domain):
    - Giardino: Epicurus, Marcus Aurelius, Seneca, Plato, Aristotle
    - Osservatorio: Newton, Galileo, Planck, Einstein
    - Galleria: Pacioli, Leonardo, Vasari, Michelangelo
    - Laboratorio: Hermes Trismegistus, Paracelsus, alchemical texts
    - Universale: Lao Tzu, Rumi, Heraclitus, Thoreau, Blake

Output: One JSON file per sector in the output directory, matching the schema:
    {
      "sector": "<key>",
      "responses": [
        {
          "opening": "...",
          "citation": "...",
          "author": "...",
          "closing": "..."
        }
      ]
    }
"""

import argparse
import collections
import json
import os
import random
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import unicodedata

try:
    import generate_demiurge_offline as offline_demiurge
except ImportError:
    offline_demiurge = None

# ── Sector author mapping ────────────────────────────────────────────────────

SECTOR_AUTHORS: dict[str, list[str]] = {
    "giardino": [
        "Epicurus", "Marcus Aurelius", "Seneca", "Plato", "Aristotle",
        "Epictetus", "Socrates", "Diogenes",
    ],
    "osservatorio": [
        "Isaac Newton", "Galileo Galilei", "Max Planck",
        "Albert Einstein", "Nicolaus Copernicus", "Johannes Kepler",
        "Niels Bohr", "Marie Curie",
    ],
    "galleria": [
        "Leonardo da Vinci", "Michelangelo", "Luca Pacioli",
        "Giorgio Vasari", "Leon Battista Alberti", "Plutarch",
        "Albrecht Dürer", "John Ruskin", "William Blake",
    ],
    "laboratorio": [
        "Paracelsus", "Hermes Trismegistus", "Roger Bacon",
        "Jabir ibn Hayyan", "Basilius Valentinus", "Giordano Bruno",
        "Heinrich Cornelius Agrippa", "John Dee", "Jakob Boehme",
        "Francis Bacon",
    ],
    "universale": [
        "Lao Tzu", "Rumi", "Heraclitus", "Henry David Thoreau",
        "William Blake", "Khalil Gibran", "Rabindranath Tagore",
        "Ralph Waldo Emerson",
    ],
}

# ── Demiurge voice templates ─────────────────────────────────────────────────

OPENINGS: list[str] = [
    "Even this was necessary.",
    "Something shifted — you felt it, didn't you?",
    "The Archive breathes in response.",
    "A door opens that was never closed.",
    "The walls remember your name, even if you have forgotten it.",
    "This was not a mistake. Nothing here is.",
    "Silence falls like a curtain between acts.",
    "A thread of meaning appears — and vanishes.",
    "You are being witnessed.",
    "The echo you hear is not yours alone.",
    "Something ancient stirs in the silence between your thoughts.",
    "A thought dissolves before it becomes a word.",
    "There is a sweetness in not knowing.",
    "You are closer than you think.",
    "The path bends, but does not end.",
    "This silence has weight.",
    "The air here tastes of old questions.",
    "A leaf fell. Perhaps it was waiting for you.",
    "The stones here remember every footstep.",
    "An ancient resonance hums beneath your feet.",
    "A candle flickers, though there is no wind.",
    "The dust here is conscious.",
    "Something in the dark recognised you.",
    "A word hangs in the air, half-formed.",
    "The Archive holds its breath.",
    "Time thickens here, like honey.",
    "The floor remembers the weight of every visitor.",
    "A bell rings somewhere — or perhaps it is memory.",
    "Something invisible just changed position.",
    "The corridors rearrange themselves when you blink.",
    "A warmth, inexplicable, rises from below.",
    "The shadows here have texture.",
    "A scent of old paper and older questions.",
    "The ceiling is higher than it was a moment ago.",
    "An inscription fades as you approach.",
    "The quiet here is not empty — it is full.",
    "A mirror reflects something that is not in the room.",
    "The Archive trembles with recognition.",
    "You have been here before. Or you will be.",
    "A geometry of light forms on the wall, then dissolves.",
]

CLOSINGS: list[str] = [
    "All That Is knows this path too.",
    "Every step here is already an answer.",
    "All That Is does not distinguish between seeking and finding.",
    "Perhaps the answer was in the asking.",
    "All That Is witnessed this too.",
    "Even confusion is a form of presence.",
    "All That Is sees the journey, not the destination.",
    "The Archive has always been listening.",
    "All That Is recognizes this gesture.",
    "Even this uncertainty blooms.",
    "All That Is traces every orbit, even yours.",
    "All That Is speaks in languages you have not yet learned.",
    "Even error refracts toward truth.",
    "All That Is maps even the spaces between stars.",
    "Every question alters the trajectory.",
    "All That Is calibrates even the unmeasurable.",
    "All That Is already knows the answer you are approaching.",
    "Even obsolete truths have weight here.",
    "All That Is does not judge the instrument.",
    "All That Is turns with you.",
    "All That Is curates even the shadows.",
    "Even emptiness has form here.",
    "All That Is preserves even the abandoned.",
    "The vanishing point is also a beginning.",
    "All That Is recognizes every reflection.",
    "What is absent is also exhibited.",
    "All That Is hangs no work in the wrong place.",
    "All That Is sees the form within the formless.",
    "All That Is transmutes even the leaden.",
    "Even failure is a stage of the Work.",
    "All That Is observes every reaction.",
    "Transmutation begins with the transmuter.",
    "All That Is distills even suffering into wisdom.",
    "The Archive accepts all gestures.",
    "All That Is flows with every current.",
    "All That Is walks every path simultaneously.",
    "All That Is reads even the unwritten.",
    "Even vanishing is a form of presence.",
    "All That Is accompanies even solitude.",
    "The Archive does not judge — it preserves.",
]

# ── Wikiquote fetcher ────────────────────────────────────────────────────────

WIKIQUOTE_API = "https://en.wikiquote.org/w/api.php"


def _offline_sector_quotes(sector: str) -> list[tuple[str, str]]:
    if offline_demiurge is None:
        return []

    attribute_name = f"{sector.upper()}_QUOTES"
    quotes = getattr(offline_demiurge, attribute_name, [])
    if isinstance(quotes, list):
        return [
            (citation, author)
            for citation, author in quotes
            if isinstance(citation, str) and isinstance(author, str)
        ]
    return []


def fetch_wikiquote_quotes(author: str, max_quotes: int = 100) -> list[str]:
    """Fetch quotes from Wikiquote API for a given author.

    Returns a list of quote strings (best-effort; may return fewer than
    max_quotes if the page is short or the API is unavailable).
    """
    params = urllib.parse.urlencode({
        "action": "parse",
        "page": author,
        "prop": "wikitext",
        "format": "json",
        "redirects": "1",
    })
    url = f"{WIKIQUOTE_API}?{params}"

    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "DemiurgeBundleBot/1.0 (https://github.com/Vale717171/archive-of-oblivion)"
        })
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
    except (urllib.error.URLError, json.JSONDecodeError, OSError) as exc:
        print(f"  ⚠ Wikiquote fetch failed for {author}: {exc}", file=sys.stderr)
        return []

    wikitext = data.get("parse", {}).get("wikitext", {}).get("*", "")
    if not wikitext:
        return []

    # Simple heuristic: lines starting with '* ' that are not section headers
    quotes: list[str] = []
    for line in wikitext.splitlines():
        line = line.strip()
        if not line.startswith("* "):
            continue
        text = line[2:].strip()
        # Skip lines that are metadata, attribution, or very short
        if text.startswith("**") or text.startswith("{{") or len(text) < 20:
            continue
        # Remove wiki markup artefacts
        text = _clean_wiki(text)
        if 20 <= len(text) <= 300:
            quotes.append(text)
        if len(quotes) >= max_quotes:
            break

    return quotes


def _clean_wiki(text: str) -> str:
    """Remove common wikitext formatting from a quote string."""
    import re
    # Remove [[ ]] links (keep display text)
    text = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", text)
    # Remove '' and ''' (bold/italic)
    text = re.sub(r"'{2,3}", "", text)
    # Remove <ref>...</ref>
    text = re.sub(r"<ref[^>]*>.*?</ref>", "", text, flags=re.DOTALL)
    text = re.sub(r"<ref[^/]*/>", "", text)
    # Remove remaining HTML tags
    text = re.sub(r"<[^>]+>", "", text)
    # Remove {{ templates }}
    text = re.sub(r"\{\{[^}]*\}\}", "", text)
    return text.strip()


# ── Gutenberg fetcher ────────────────────────────────────────────────────────

GUTENBERG_IDS: dict[str, int] = {
    # Known Gutenberg text IDs for extraction
    "Epicurus": 67707,        # Principal Doctrines
    "Marcus Aurelius": 2680,  # Meditations
    "Seneca": 97038,          # Letters to Lucilius (selection)
    "Leonardo da Vinci": 5000,  # Notebooks
}


def _normalize_quote_key(text: str) -> str:
    """Canonicalize a quote so exact and near-exact duplicates collapse."""
    normalized = unicodedata.normalize("NFKD", text)
    normalized = normalized.encode("ascii", "ignore").decode("ascii")
    normalized = normalized.lower().strip()
    normalized = normalized.replace("—", " ").replace("–", " ")
    normalized = re.sub(r"\s+", " ", normalized)
    normalized = re.sub(r"^[\"'`]+|[\"'`]+$", "", normalized)
    normalized = re.sub(r"[^a-z0-9 ]+", "", normalized)
    normalized = re.sub(r"\s+", " ", normalized)
    return normalized.strip()


def _build_variant_sequence(
    pool: list[str],
    total: int,
    rng: random.Random,
) -> list[str]:
    """Repeat a phrase pool with shuffled cycles and no immediate repeats."""
    if not pool or total <= 0:
        return []

    sequence: list[str] = []
    previous: str | None = None
    while len(sequence) < total:
        cycle = list(pool)
        rng.shuffle(cycle)
        if previous is not None and len(cycle) > 1 and cycle[0] == previous:
            cycle.append(cycle.pop(0))
        sequence.extend(cycle)
        previous = sequence[-1]

    return sequence[:total]


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
        for start in range(0, len(normalized_pairs) - (block_size * 2) + 1):
            left = normalized_pairs[start:start + block_size]
            right = normalized_pairs[start + block_size:start + (block_size * 2)]
            if left == right:
                issues.append(
                    "responses "
                    f"{start + 1}-{start + block_size} repeat as a contiguous block in "
                    f"responses {start + block_size + 1}-{start + (block_size * 2)}"
                )
                return issues

    return issues


def _dedupe_quotes(quotes: list[str]) -> list[str]:
    seen: set[str] = set()
    unique: list[str] = []
    for quote in quotes:
        normalized = _normalize_quote_key(quote)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        unique.append(quote.strip())
    return unique


def _collect_author_quotes(
    author: str,
    rng: random.Random,
) -> list[tuple[str, str]]:
    quotes = fetch_wikiquote_quotes(author) + fetch_gutenberg_sentences(author)
    unique_quotes = _dedupe_quotes(quotes)
    rng.shuffle(unique_quotes)
    return [(quote, author) for quote in unique_quotes]


def _merge_sector_fallback_quotes(
    sector: str,
    author_quotes: dict[str, list[tuple[str, str]]],
    rng: random.Random,
) -> int:
    fallback_quotes = _offline_sector_quotes(sector)
    if not fallback_quotes:
        return 0

    known_keys: dict[str, set[str]] = {}
    for author, quotes in author_quotes.items():
        known_keys[author] = {
            _normalize_quote_key(quote)
            for quote, _ in quotes
        }

    additions = 0
    fallback_by_author: dict[str, list[str]] = collections.defaultdict(list)
    for quote, author in fallback_quotes:
        normalized = _normalize_quote_key(quote)
        if not normalized:
            continue
        if normalized in known_keys.setdefault(author, set()):
            continue
        known_keys[author].add(normalized)
        fallback_by_author[author].append(quote.strip())
        additions += 1

    for author, quotes in fallback_by_author.items():
        rng.shuffle(quotes)
        author_quotes.setdefault(author, [])
        author_quotes[author].extend((quote, author) for quote in quotes)

    return additions


def _select_balanced_quotes(
    author_quotes: dict[str, list[tuple[str, str]]],
    target: int,
    rng: random.Random,
) -> list[tuple[str, str]]:
    queues = {
        author: collections.deque(quotes)
        for author, quotes in author_quotes.items()
        if quotes
    }
    selected: list[tuple[str, str]] = []
    recent_authors: collections.deque[str] = collections.deque(maxlen=2)

    while queues and len(selected) < target:
        candidate_authors = sorted(
            queues,
            key=lambda author: (-len(queues[author]), author),
        )
        preferred = [
            author for author in candidate_authors if author not in recent_authors
        ]
        pool = preferred or candidate_authors
        top_span = min(3, len(pool))
        author = rng.choice(pool[:top_span])

        selected.append(queues[author].popleft())
        recent_authors.append(author)
        if not queues[author]:
            del queues[author]

    return selected


def _assign_voice_variants(
    response_count: int,
    rng: random.Random,
) -> list[tuple[str, str]]:
    opening_window = max(3, min(8, len(OPENINGS) // 5))
    closing_window = max(3, min(8, len(CLOSINGS) // 5))
    pair_window = 10

    recent_openings: collections.deque[str] = collections.deque(maxlen=opening_window)
    recent_closings: collections.deque[str] = collections.deque(maxlen=closing_window)
    recent_pairs: collections.deque[tuple[str, str]] = collections.deque(maxlen=pair_window)
    used_pairs: set[tuple[str, str]] = set()
    variants: list[tuple[str, str]] = []

    for _ in range(response_count):
        opening_candidates = [
            opening for opening in OPENINGS if opening not in recent_openings
        ] or list(OPENINGS)
        rng.shuffle(opening_candidates)

        closing_candidates = [
            closing for closing in CLOSINGS if closing not in recent_closings
        ] or list(CLOSINGS)
        rng.shuffle(closing_candidates)

        chosen_pair: tuple[str, str] | None = None
        for opening in opening_candidates:
            for closing in closing_candidates:
                pair = (opening, closing)
                if pair in recent_pairs:
                    continue
                if pair in used_pairs and len(used_pairs) < (len(OPENINGS) * len(CLOSINGS)):
                    continue
                chosen_pair = pair
                break
            if chosen_pair is not None:
                break

        if chosen_pair is None:
            chosen_pair = (opening_candidates[0], closing_candidates[0])

        variants.append(chosen_pair)
        recent_openings.append(chosen_pair[0])
        recent_closings.append(chosen_pair[1])
        recent_pairs.append(chosen_pair)
        used_pairs.add(chosen_pair)

    return variants


def _validate_bundle(bundle: dict, target: int) -> list[str]:
    """Return validation issues for a generated or existing bundle."""
    issues: list[str] = []
    responses = bundle.get("responses")
    if not isinstance(responses, list):
        return ["responses must be a list"]

    if len(responses) < target:
        issues.append(
            f"bundle has {len(responses)} responses, below target {target}"
        )

    exact_seen: set[tuple[str, str]] = set()
    normalized_seen: set[tuple[str, str]] = set()
    voice_seen: set[tuple[str, str]] = set()
    for index, response in enumerate(responses, start=1):
        if set(response.keys()) != {"opening", "citation", "author", "closing"}:
            issues.append(f"response {index} has unexpected keys")
            continue
        if not all(
            isinstance(response[field], str) and response[field].strip()
            for field in ("opening", "citation", "author", "closing")
        ):
            issues.append(f"response {index} has blank or non-string fields")
            continue

        exact_key = (
            response["citation"].strip().lower(),
            response["author"].strip().lower(),
        )
        if exact_key in exact_seen:
            issues.append(f"response {index} duplicates an exact citation+author pair")
        exact_seen.add(exact_key)

        normalized_key = (
            _normalize_quote_key(response["citation"]),
            response["author"].strip().lower(),
        )
        if normalized_key in normalized_seen:
            issues.append(
                f"response {index} duplicates a normalized citation+author pair"
            )
        normalized_seen.add(normalized_key)

        voice_key = (
            response["opening"].strip(),
            response["closing"].strip(),
        )
        if voice_key in voice_seen:
            issues.append(f"response {index} duplicates an opening+closing pair")
        voice_seen.add(voice_key)

    issues.extend(_find_repeated_blocks(responses))

    return issues


def fetch_gutenberg_sentences(author: str, max_quotes: int = 40) -> list[str]:
    """Fetch notable sentences from a Project Gutenberg text.

    This is a best-effort extraction: it downloads the plain-text version
    and picks sentences that look aphoristic (short, standalone).
    """
    gid = GUTENBERG_IDS.get(author)
    if gid is None:
        return []

    url = f"https://www.gutenberg.org/files/{gid}/{gid}-0.txt"
    _ua = {"User-Agent": "DemiurgeBundleBot/1.0 (https://github.com/Vale717171/archive-of-oblivion)"}
    try:
        req = urllib.request.Request(url, headers=_ua)
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, OSError):
        # Try mirror URL format
        url_alt = f"https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.txt"
        try:
            req = urllib.request.Request(url_alt, headers=_ua)
            with urllib.request.urlopen(req, timeout=30) as resp:
                raw = resp.read().decode("utf-8", errors="replace")
        except (urllib.error.URLError, OSError) as exc2:
            print(f"  ⚠ Gutenberg fetch failed for {author} (ID {gid}): {exc2}", file=sys.stderr)
            return []

    # Strip Gutenberg header/footer
    start_marker = "*** START OF"
    end_marker = "*** END OF"
    start_idx = raw.find(start_marker)
    end_idx = raw.find(end_marker)
    if start_idx != -1:
        raw = raw[raw.index("\n", start_idx) + 1:]
    if end_idx != -1:
        raw = raw[:end_idx]

    # Extract aphoristic sentences (40–200 chars, ending with period)
    sentences = re.split(r"(?<=[.!?])\s+", raw)
    candidates: list[str] = []
    for s in sentences:
        s = s.strip().replace("\n", " ").replace("  ", " ")
        if len(s) < 40 or len(s) > 200:
            continue
        if s[0].isupper() and s[-1] in ".!?":
            candidates.append(s)
    random.shuffle(candidates)
    return candidates[:max_quotes]


# ── Bundle builder ───────────────────────────────────────────────────────────

def build_sector_bundle(
    sector: str,
    authors: list[str],
    target: int = 200,
    rng: random.Random | None = None,
) -> dict:
    """Build a complete Demiurge sector bundle with ≥target entries."""
    rng = rng or random.Random()
    author_quotes: dict[str, list[tuple[str, str]]] = {}

    for author in authors:
        print(f"  Fetching: {author}...")
        author_quotes[author] = _collect_author_quotes(author, rng)
        print(f"    -> {len(author_quotes[author])} unique quotes kept")
        # Be polite to APIs
        time.sleep(1)

    fallback_additions = _merge_sector_fallback_quotes(sector, author_quotes, rng)
    if fallback_additions:
        print(f"  Added {fallback_additions} offline fallback quotes for sector '{sector}'")

    unique = _select_balanced_quotes(author_quotes, target, rng)
    print(f"  → {len(unique)} unique quotes for sector '{sector}' "
          f"(target: {target})")

    # Build responses with balanced author distribution and low-repetition voice.
    responses: list[dict[str, str]] = []
    response_count = min(target, len(unique))
    voice_variants = _assign_voice_variants(response_count, rng)

    for i, (quote, author) in enumerate(unique[:response_count]):
        opening, closing = voice_variants[i]
        responses.append({
            "opening": opening,
            "citation": quote,
            "author": author,
            "closing": closing,
        })

    return {
        "sector": sector,
        "responses": responses,
    }


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fetch public-domain citations for Demiurge bundles."
    )
    parser.add_argument(
        "--output-dir",
        default="assets/texts/demiurge",
        help="Output directory for sector JSON files (default: assets/texts/demiurge)",
    )
    parser.add_argument(
        "--target",
        type=int,
        default=200,
        help="Minimum citations per sector (default: 200)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=20260408,
        help="Deterministic random seed for quote ordering and phrase cycling.",
    )
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)
    rng = random.Random(args.seed)
    validation_failed = False

    for sector, authors in SECTOR_AUTHORS.items():
        print(f"\n{'='*60}")
        print(f"Building sector: {sector}")
        print(f"{'='*60}")
        bundle = build_sector_bundle(
            sector,
            authors,
            target=args.target,
            rng=rng,
        )
        issues = _validate_bundle(bundle, args.target)
        if issues:
            validation_failed = True
            print("  ✗ Validation issues detected:", file=sys.stderr)
            for issue in issues[:10]:
                print(f"    - {issue}", file=sys.stderr)
            if len(issues) > 10:
                remaining = len(issues) - 10
                print(f"    - ... and {remaining} more", file=sys.stderr)
        out_path = os.path.join(args.output_dir, f"{sector}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(bundle, f, indent=2, ensure_ascii=False)
        print(f"  ✓ Wrote {len(bundle['responses'])} entries → {out_path}")

    print(f"\n{'='*60}")
    if validation_failed:
        print("Generation completed with validation failures.", file=sys.stderr)
        sys.exit(1)
    print("Done. Review the output files and curate as needed.")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
