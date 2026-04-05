# L'Archivio dell'Oblio — Claude Code Project Instructions

> This file is read automatically by Claude Code at session start.
> The full Game Design Document is in `docs/gdd.md` — read-only, never modify it.

---

## What this project is

A psycho-philosophical text adventure for Android.
Stack: **Flutter + Riverpod + sqflite + just_audio + DemiurgeService (deterministic, offline)**.
No images — only text and Bach's music.

The full Game Design Document is in `docs/gdd.md`.
The development log is in `docs/work_log.md`.

---

## Codebase conventions

| Convention | Detail |
|---|---|
| State management | Riverpod `AsyncNotifier` — never `StateNotifier` |
| SQLite | Single-row pattern: always `'id': 1` + `ConflictAlgorithm.replace` |
| Riverpod outside widget tree | `ProviderContainer` + `container.listen` (not `.select().listen`) |
| Audio crossfade | Manual `_rampVolume()` — `just_audio` has no `setVolume(duration:)` |
| Demiurge narrator | `DemiurgeService.instance.respond()` in `game_engine_provider.dart` — deterministic, no LLM needed |
| Target Android | API 26+, mid-range 3 GB RAM |
| Game text language | English only |
| Demiurge bundles | `assets/texts/demiurge/*.json` — enigmatic openings, public-domain citations, ambiguous closings |

---

## File structure

```
lib/
├── main.dart
├── core/storage/
│   ├── database_service.dart
│   └── dialogue_history_service.dart
└── features/
    ├── audio/audio_service.dart
    ├── demiurge/demiurge_service.dart      ← "All That Is" deterministic narrator
    ├── game/game_engine_provider.dart      ← DemiurgeService replaces _callLlm()
    ├── llm/llm_context_service.dart        ← [legacy — kept for reference]
    ├── parser/parser_service.dart
    ├── parser/parser_state.dart
    ├── state/game_state_provider.dart
    ├── state/psycho_provider.dart
    └── ui/game_screen.dart

docs/
├── gdd.md                                  ← full GDD (source of truth)
├── work_log.md                             ← chronological dev log
└── prompts/
    ├── role_cards.md                       ← persistent system prompts
    └── universal_session_prompt.md

tools/
├── prepare_demiurge_bundles.py             ← fetch citations from Wikiquote/Gutenberg
└── fase_0_omega/                           ← [legacy LLM validation — superseded]
    └── CLAUDE_CODE_PROMPT.md
```

---

## Priority order

1. ~~Fix simulacra inventory bug in `game_engine_provider.dart`~~ ✅ **FIXED** — items granted regardless of `weightDelta`; weight increment skipped only when `weightDelta == 0`.
2. ~~JSON text bundles (`assets/texts/*.json`) — populate game content~~ ✅ **DONE** — 7 bundles in `assets/texts/`, 3 prompt templates in `assets/prompts/`.
3. ~~Remaining sectors: East (Observatory), South (Gallery), West (Lab)~~ ✅ **DONE** — all 4 sectors fully implemented.
4. ~~La Zona procedural engine (LLM-driven, uses stub until step 6)~~ ✅ **DONE** — probabilistic activation, 8 verses, 8 environments, 8 questions.
5. ~~Fifth Sector (Memory/Proust) + Final Boss~~ ✅ **DONE** — 6 Quinto nodes + 4 Finale nodes, three endings.
6. ~~LLM integration~~ **SUPERSEDED** — replaced by **DemiurgeService** ("All That Is"). See architectural decision in `docs/work_log.md`.
7. **DemiurgeService integration** — wire `DemiurgeService.respond()` into `game_engine_provider.dart`, replacing `_callLlm()`. Populate `assets/texts/demiurge/` with ≥200 curated citations per sector using `tools/prepare_demiurge_bundles.py`.

---

## Rules

- Never wipe or replace existing `docs/work_log.md` entries — only prepend new ones.
- Never suggest adding images or visual assets.
- The Demiurge ("All That Is") is the game's narrative voice — fully deterministic, no LLM required.
- End every session with a work log entry (see format in `docs/work_log.md`).
