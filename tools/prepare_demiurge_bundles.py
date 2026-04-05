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
import json
import os
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

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
    ],
    "laboratorio": [
        "Paracelsus", "Hermes Trismegistus", "Roger Bacon",
        "Jabir ibn Hayyan", "Basilius Valentinus",
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


def fetch_wikiquote_quotes(author: str, max_quotes: int = 60) -> list[str]:
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
        req = urllib.request.Request(url, headers={"User-Agent": "DemiurgeBundleBot/1.0"})
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


def fetch_gutenberg_sentences(author: str, max_quotes: int = 40) -> list[str]:
    """Fetch notable sentences from a Project Gutenberg text.

    This is a best-effort extraction: it downloads the plain-text version
    and picks sentences that look aphoristic (short, standalone).
    """
    gid = GUTENBERG_IDS.get(author)
    if gid is None:
        return []

    url = f"https://www.gutenberg.org/files/{gid}/{gid}-0.txt"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "DemiurgeBundleBot/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, OSError) as exc:
        # Try mirror URL format
        url_alt = f"https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.txt"
        try:
            req = urllib.request.Request(url_alt, headers={"User-Agent": "DemiurgeBundleBot/1.0"})
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
    import re
    sentences = re.split(r"(?<=[.!?])\s+", raw)
    candidates: list[str] = []
    for s in sentences:
        s = s.strip().replace("\n", " ").replace("  ", " ")
        if 40 <= len(s) <= 200 and s[0].isupper() and s[-1] in ".!?":
            candidates.append(s)
    random.shuffle(candidates)
    return candidates[:max_quotes]


# ── Bundle builder ───────────────────────────────────────────────────────────

def build_sector_bundle(
    sector: str,
    authors: list[str],
    target: int = 200,
) -> dict:
    """Build a complete Demiurge sector bundle with ≥target entries."""
    all_quotes: list[tuple[str, str]] = []  # (quote, author)

    for author in authors:
        print(f"  Fetching: {author}...")
        # Wikiquote
        wq = fetch_wikiquote_quotes(author)
        for q in wq:
            all_quotes.append((q, author))
        # Gutenberg (supplementary)
        gb = fetch_gutenberg_sentences(author)
        for q in gb:
            all_quotes.append((q, author))
        # Be polite to APIs
        time.sleep(1)

    # Deduplicate
    seen: set[str] = set()
    unique: list[tuple[str, str]] = []
    for quote, author in all_quotes:
        key = quote.lower().strip()
        if key not in seen:
            seen.add(key)
            unique.append((quote, author))

    random.shuffle(unique)
    print(f"  → {len(unique)} unique quotes for sector '{sector}' "
          f"(target: {target})")

    # Build responses with random opening/closing pairs
    responses: list[dict[str, str]] = []
    openings_pool = list(OPENINGS)
    closings_pool = list(CLOSINGS)

    for i, (quote, author) in enumerate(unique[:max(target, len(unique))]):
        opening = openings_pool[i % len(openings_pool)]
        closing = closings_pool[i % len(closings_pool)]
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
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    for sector, authors in SECTOR_AUTHORS.items():
        print(f"\n{'='*60}")
        print(f"Building sector: {sector}")
        print(f"{'='*60}")
        bundle = build_sector_bundle(sector, authors, target=args.target)
        out_path = os.path.join(args.output_dir, f"{sector}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(bundle, f, indent=2, ensure_ascii=False)
        print(f"  ✓ Wrote {len(bundle['responses'])} entries → {out_path}")

    print(f"\n{'='*60}")
    print("Done. Review the output files and curate as needed.")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
