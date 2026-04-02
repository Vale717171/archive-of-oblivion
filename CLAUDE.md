# L'Archivio dell'Oblio — Claude Code Project Instructions

> This file is read automatically by Claude Code at session start.
> The full Game Design Document is in `docs/gdd.md` — read-only, never modify it.

---

## What this project is

A psycho-philosophical text adventure for Android.
Stack: **Flutter + Riverpod + sqflite + just_audio + on-device LLM 0.5B (offline)**.
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
| LLM integration | `_llmStub()` in `game_engine_provider.dart` — placeholder until full APK is ready for device testing |
| Target Android | API 26+, mid-range 3 GB RAM |
| Game text language | English only |
| LLM prompt format | Qwen `<\|system\|>/<\|user\|>/<\|assistant\|>` — unless MediaPipe/Gemma wins at final validation |

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
    ├── game/game_engine_provider.dart      ← _llmStub() lives here
    ├── llm/llm_context_service.dart
    ├── parser/parser_service.dart
    ├── parser/parser_state.dart
    ├── state/game_state_provider.dart
    ├── state/psycho_provider.dart
    └── ui/game_screen.dart

docs/
├── gdd.md                                  ← full GDD (source of truth, read-only)
├── work_log.md                             ← chronological dev log
└── prompts/
    ├── role_cards.md                       ← persistent system prompts for each LLM
    └── universal_session_prompt.md

tools/fase_0_omega/                         ← LLM validation (run LAST, on full APK)
└── CLAUDE_CODE_PROMPT.md                   ← session prompt for final LLM integration
```

---

## Known bug (unfixed)

In `game_engine_provider.dart`: simulacra (`weightDelta=0`) are never added to inventory
because `processInput` only adds items when `weightDelta > 0`. Fix: add items regardless
of `weightDelta`; only skip the weight increment when `weightDelta == 0`.

---

## Priority order

1. Fix simulacra inventory bug in `game_engine_provider.dart`
2. JSON text bundles (`assets/texts/*.json`) — populate game content
3. Remaining sectors: East (Observatory), South (Gallery), West (Lab)
4. La Zona procedural engine (LLM-driven, uses stub until step 6)
5. Fifth Sector (Memory/Proust) + Final Boss
6. **LLM validation on full APK** — replace `_llmStub()` once the complete game is playable on device (`tools/fase_0_omega/CLAUDE_CODE_PROMPT.md`)

---

## Rules

- Never wipe or replace existing `docs/work_log.md` entries — only prepend new ones.
- Never suggest adding images or visual assets.
- The LLM is not optional (GDD §1 — NOTA CRITICA) — but `_llmStub()` is fine throughout development.
- End every session with a work log entry (see format in `docs/work_log.md`).
