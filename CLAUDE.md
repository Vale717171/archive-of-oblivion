# L'Archivio dell'Oblio — Claude Code Project Instructions

> This file is read automatically by Claude Code at session start.
> Do NOT modify the GDD (`docs/gdd.md`) — it is the read-only source of truth.

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
| LLM integration | `_llmStub()` in `game_engine_provider.dart` — permanent placeholder; replaced only when game is complete on physical device |
| Target Android | API 26+, mid-range 3 GB RAM |
| Game text language | English only |
| LLM prompt format | Qwen `<\|system\|>/<\|user\|>/<\|assistant\|>` — unless Tentativo 2 (Gemma) wins |

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

tools/fase_0_omega/                         ← LLM validation suite (run LAST — after game is complete)
├── README.md                               ← start here
├── llm_test_1/                             ← flutter_llama test app
├── llm_test_2/                             ← mediapipe_genai test app
└── results_template.md                     ← fill in after tests
```

---

## Priority order

1. JSON text bundles (`assets/texts/*.json`)
2. Remaining sectors (East, South, West)
3. Full game playable end-to-end → APK installable on physical device
4. **Fase 0-omega** — replace `_llmStub()` with real LLM integration (validated on device)

---

## Rules

- Never wipe or replace existing `docs/work_log.md` entries — only prepend new ones.
- Never suggest adding images or visual assets.
- The LLM is not optional (GDD §1 — NOTA CRITICA).
- End every session with a work log entry (see format in `docs/work_log.md`).
