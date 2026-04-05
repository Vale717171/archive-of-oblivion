# L'Archivio dell'Oblio — AI Agent Briefing

> **Read this file at every session start.**
> This is the single source of truth for any AI agent (Claude Code, Gemini, Grok) joining the project cold.
> The full Game Design Document is in `docs/gdd.md` — read-only, never modify it.
> The chronological dev log is in `docs/work_log.md` — prepend new entries only, never wipe existing ones.

---

## What this project is

A psycho-philosophical text adventure for Android.
**Stack:** Flutter + Riverpod + sqflite + just_audio + DemiurgeService (deterministic, fully offline).
No images — only text and Bach's music. English text only.

---

## Current architecture — file by file

### `lib/main.dart`
App entry point. Initialises `AudioService` (try-catch; non-fatal if it fails) and pre-loads all five Demiurge citation bundles via `DemiurgeService.instance.loadAll()` (also try-catch; bundle failure is non-fatal). Wraps the app in `UncontrolledProviderScope`.

### `lib/core/storage/database_service.dart`
SQLite singleton (sqflite). Schema v2 — tables: `game_state`, `dialogue_history`, `player_memories`. Uses a static `Completer` guard to prevent concurrent `_initDatabase()` races. Single-row pattern: always `'id': 1` + `ConflictAlgorithm.replace`.

### `lib/core/storage/dialogue_history_service.dart`
Persists the conversation history (player input + engine/demiurge responses) to the `dialogue_history` table.

### `lib/features/audio/audio_service.dart`
Manages Bach BGM and SFX via `just_audio`. Key details:
- Profile-driven ambience: `_updateAmbienceFromProfile()` (async, calls `_crossfadeTo()`).
- Crossfade: manual `_rampVolume()` loop — `just_audio` has no `setVolume(duration:)`.
- Special tracks (`siciliano`, `aria_goldberg`, `silence`) are in `_specialTracks` and block profile-driven overrides.
- `audioTrigger` in `EngineResponse` is consumed by `AudioService().handleTrigger()` inside `processInput`.
- SFX disposal: 30 s timeout + `catchError`.

### `lib/features/demiurge/demiurge_service.dart`
**"All That Is"** — deterministic narrator replacing the on-device LLM. Singleton.
- Loads from `assets/texts/demiurge/{sector}.json` (5 sector keys: `giardino`, `osservatorio`, `galleria`, `laboratorio`, `universale`).
- API: `respond({required String sector, required String fallbackText})` → formatted string.
- Anti-repetition ring buffer: last 20 indices per sector are excluded from selection.
- `sectorForNode(String nodeId)` maps node ID prefixes to sector keys:
  - `garden*` / `la_soglia` → `giardino`
  - `obs_*` → `osservatorio`
  - `gal_*` → `galleria`
  - `lab_*` → `laboratorio`
  - everything else → `universale`
- Falls back to `universale` pool if the sector pool is empty; falls back to `fallbackText` if both are empty.
- Riverpod provider: `demiurgeServiceProvider`.

### `lib/features/game/game_engine_provider.dart`
The game engine — ~3 200 lines. `GameEngineNotifier` extends `AsyncNotifier<GameEngineState>`.
- All four sectors (Garden/North, Observatory/East, Gallery/South, Lab/West) + Fifth Sector (Quinto) + Final Boss (il_nucleo) + La Zona implemented.
- Narrator: `_callDemiurge(String fallbackText, String nodeId)` (sync) — replaces the old `_callLlm()`.
- Exit gating: `const Map _exitGates` (`nodeId → {direction → requiredPuzzleId}`). Multi-condition gates (Lab Great Work, Quinto) handled as special cases before the map.
- Puzzle state: `GameEngineState.completedPuzzles` (`Set<String>`) + `puzzleCounters` (`Map<String,int>`). Driven by `EngineResponse.completePuzzle` and `.incrementCounter`.
- La Zona: activated probabilistically; uses `puzzleCounters['zone_encounters']` (1-based) and `'consecutive_transits'`.
- Inventory: items added via `response.grantItem`; simulacra (`ataraxia`, `the constant`, `the proportion`, `the catalyst`) are weightless (`weightDelta == 0`).
- `playerMemoryKey` in `EngineResponse` triggers a save to `player_memories` table.

### `lib/features/llm/` (legacy)
`llm_service.dart` and `llm_context_service.dart` — kept for reference. No longer imported by the engine. Do not delete; do not add new imports.

### `lib/features/parser/parser_service.dart` + `parser_state.dart`
Pure synchronous parser. `ParsedCommand` carries `verb`, `args`. `EngineResponse` carries `narrativeText`, `needsLlm` (now means "call Demiurge"), `grantItem`, `weightDelta`, `newNode`, `completePuzzle`, `incrementCounter`, `audioTrigger`, `playerMemoryKey`.

### `lib/features/state/game_state_provider.dart`
`GameStateNotifier` — Riverpod `AsyncNotifier`. `saveEngineState()` is the single persistence entry point; `updateNode()` is a thin wrapper.

### `lib/features/state/psycho_provider.dart`
Tracks psychological weight (0–100). Drives the psycho-profile used for audio ambience selection.

### `lib/features/ui/game_screen.dart`
Single-screen UI — text output + command input. Typewriter effect uses `dart:async Timer` (not `Future.delayed`), with `_typewriterTimer` cancelled in `dispose()` and `_skipTypewriter()` to prevent setState-on-disposed-widget.

---

## The Demiurge system — "All That Is"

The on-device LLM (flutter_llama / Qwen 2.5 0.5B) was replaced by a fully deterministic narrator called **"All That Is"** (from Seth/Jane Roberts philosophy). The player never knows if they made a mistake or discovered something — error is part of the existential journey.

### How it works
1. `game_engine_provider.dart` calls `_callDemiurge(fallbackText, nodeId)` when `response.needsLlm == true`.
2. `_callDemiurge` resolves the sector via `DemiurgeService.sectorForNode(nodeId)`.
3. `DemiurgeService.respond()` picks a random unused entry from the sector's pool (anti-repetition buffer of 20).
4. The entry is formatted as: `opening\n\n"citation"\n— author\n\nclosing`.

### JSON structure (`assets/texts/demiurge/{sector}.json`)
```json
{
  "sector": "galleria",
  "responses": [
    {
      "opening": "The frame is empty. Or perhaps it frames you.",
      "citation": "The painter has the universe in his mind and hands.",
      "author": "Leonardo da Vinci",
      "closing": "All That Is sees every canvas, even the blank ones."
    }
  ]
}
```

### Current bundle status

| File | Sector | Entries now | Target |
|---|---|---|---|
| `giardino.json` | Garden (North) | 12 | ≥ 200 |
| `osservatorio.json` | Observatory (East) | 12 | ≥ 200 |
| `galleria.json` | Gallery (South) | 12 | ≥ 200 |
| `laboratorio.json` | Lab (West) | 12 | ≥ 200 |
| `universale.json` | Universal fallback | 12 | ≥ 200 |

**All citations must be from public-domain sources.**
To populate bundles, run: `python tools/prepare_demiurge_bundles.py [--output-dir assets/texts/demiurge] [--target 200]`
The script fetches from Wikiquote API and Project Gutenberg.

---

## Known bugs (fixed and open)

### ✅ FIXED — Simulacra inventory bug
**Was:** Items with `weightDelta == 0` (simulacra) were never added to inventory because the old guard was `if (weightDelta > 0) { addToInventory }`.
**Fix:** Inventory addition is now driven exclusively by `response.grantItem != null` (line ~1168 in `game_engine_provider.dart`), completely decoupled from `weightDelta`. Weight increment is still correctly skipped when `weightDelta == 0`.

### ⚠️ OPEN — Demiurge bundles under-populated
Each sector has only 12 entries. With the anti-repetition window of 20, a player will see all 12 entries before any reset and may notice repetition quickly. **Priority: populate each bundle to ≥200 citations.**

---

## File structure

```
lib/
├── main.dart                               ← startup: AudioService + DemiurgeService.loadAll()
├── core/storage/
│   ├── database_service.dart               ← SQLite v2 (game_state, dialogue_history, player_memories)
│   └── dialogue_history_service.dart
└── features/
    ├── audio/audio_service.dart            ← BGM crossfade, SFX, profile-driven ambience
    ├── demiurge/demiurge_service.dart      ← "All That Is" deterministic narrator
    ├── game/game_engine_provider.dart      ← full game engine (~3 200 lines)
    ├── game/text_bundle_service.dart       ← loads assets/texts/*.json and assets/prompts/*.json
    ├── llm/llm_service.dart                ← [legacy — do not import, do not delete]
    ├── llm/llm_context_service.dart        ← [legacy — do not import, do not delete]
    ├── parser/parser_service.dart
    ├── parser/parser_state.dart            ← ParsedCommand, EngineResponse, CommandVerb
    ├── state/game_state_provider.dart      ← GameStateNotifier (persistence entry point)
    ├── state/psycho_provider.dart          ← psychological weight + audio profile
    └── ui/game_screen.dart                 ← typewriter UI, command input

assets/
├── texts/
│   ├── demiurge/                           ← 5 × sector bundles (12 entries each, target 200+)
│   │   ├── giardino.json
│   │   ├── osservatorio.json
│   │   ├── galleria.json
│   │   ├── laboratorio.json
│   │   └── universale.json
│   ├── alchimia_bundle.json
│   ├── arte_bundle.json
│   ├── epicuro_bundle.json
│   ├── newton_bundle.json
│   ├── proust_bundle.json
│   ├── tarkovsky_bundle.json
│   └── manifest.json
└── prompts/
    ├── antagonist_templates.json
    ├── proust_triggers.json
    └── zona_templates.json

docs/
├── gdd.md                                  ← full GDD (source of truth — read-only)
├── work_log.md                             ← chronological dev log (prepend only)
└── prompts/
    ├── role_cards.md
    └── universal_session_prompt.md

tools/
├── prepare_demiurge_bundles.py             ← populate demiurge bundles from Wikiquote/Gutenberg
└── fase_0_omega/                           ← [legacy LLM validation — superseded]
    └── CLAUDE_CODE_PROMPT.md
```

---

## Priority order (what to do next)

1. ~~Fix simulacra inventory bug~~ ✅ **FIXED** — `grantItem`-based, decoupled from `weightDelta`.
2. ~~JSON text bundles (`assets/texts/*.json`) — populate game content~~ ✅ **DONE** — 7 bundles + 3 prompt templates.
3. ~~Remaining sectors: East (Observatory), South (Gallery), West (Lab)~~ ✅ **DONE** — all 4 sectors implemented.
4. ~~La Zona procedural engine~~ ✅ **DONE** — probabilistic activation, 8 verses, 8 environments, 8 questions.
5. ~~Fifth Sector (Memory/Proust) + Final Boss~~ ✅ **DONE** — 6 Quinto nodes + 4 Finale nodes, three endings.
6. ~~LLM integration~~ **SUPERSEDED** — replaced by DemiurgeService ("All That Is").
7. ~~DemiurgeService integration~~ ✅ **DONE** — wired into `game_engine_provider.dart`, pre-loaded in `main.dart`.
8. **⟶ NEXT: Populate Demiurge bundles to ≥200 citations per sector.** Run `tools/prepare_demiurge_bundles.py` or add entries manually. Public domain only. Format: `{opening, citation, author, closing}` objects in the `responses` array.
9. End-to-end playtest on a physical Android device (API 26+, 3 GB RAM). Verify all sector transitions, puzzle gates, La Zona activation, three endings.
10. Polish: audio balance, typewriter speed tuning, edge-case command handling.

---

## Stack and conventions

| Convention | Detail |
|---|---|
| State management | Riverpod `AsyncNotifier` — never `StateNotifier` |
| SQLite | Single-row pattern: always `'id': 1` + `ConflictAlgorithm.replace` |
| Riverpod outside widget tree | `ProviderContainer` + `container.listen` (not `.select().listen`) |
| Audio crossfade | Manual `_rampVolume()` loop — `just_audio` has no `setVolume(duration:)` |
| Demiurge narrator | `DemiurgeService.instance.respond()` — deterministic, no LLM, no network |
| Demiurge call site | `_callDemiurge(fallbackText, nodeId)` in `game_engine_provider.dart` (sync) |
| Target Android | API 26+, mid-range 3 GB RAM |
| Game text language | English only |
| No images | Text-only UI — never suggest adding images or visual assets |

---

## Rules — mandatory for every session

- **Never wipe or replace** existing `docs/work_log.md` entries — only prepend new ones at the top.
- **Never suggest adding images** or any visual assets.
- **The Demiurge ("All That Is") is the game's narrative voice** — fully deterministic, no LLM required.
- **End every session with a work log entry** in `docs/work_log.md` (see format of existing entries: date, agent role, done list, architecture snapshot if relevant).
