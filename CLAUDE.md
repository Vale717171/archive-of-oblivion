# L'Archivio dell'Oblio — AI Agent Briefing

> **Read this file at every session start.**
> This is the single source of truth for any AI agent (Claude Code, Gemini, Grok) joining the project cold.
> The full Game Design Document is in `docs/gdd.md` — read-only, never modify it.
> The chronological dev log is in `docs/work_log.md` — prepend new entries only, never wipe existing ones.

---

## What this project is

A psycho-philosophical text adventure for Android.
**Stack:** Flutter + Riverpod + sqflite + just_audio + DemiurgeService (deterministic, fully offline).
Text and Bach's music. Subtle sector background images at 0.15 opacity. English text only.

---

## Current architecture — file by file

### `lib/main.dart`
App entry point. Initialises `AudioService` (try-catch; non-fatal if it fails) and pre-loads all five Demiurge citation bundles via `DemiurgeService.instance.loadAll()` (also try-catch; bundle failure is non-fatal). Wraps the app in `UncontrolledProviderScope`. The app's `home:` is `SplashScreen` (not `HomeScreen` directly).

### `lib/core/storage/database_service.dart`
SQLite singleton (sqflite). **Schema v9** — tables: `game_state`, `dialogue_history`, `player_memories`, `app_settings`, `save_slots`. Concurrent init guard uses `static Future<Database>? _initFuture` (single shared future, `??=` idiom — replaces the old Completer pattern). Single-row pattern: always `'id': 1` + `ConflictAlgorithm.replace`.

Migration history: v2 (engine columns + player_memories), v3 (dialogue_history CHECK constraint), v4 (app_settings), v6 (mute_in_background), v7 (enable_haptics), v8 (phase system columns on psycho_profile), v9 (save_slots table).

### `lib/core/storage/dialogue_history_service.dart`
Persists the conversation history (player input + engine/demiurge responses) to the `dialogue_history` table.

### `lib/core/services/save_service.dart`
Multi-slot save system. `SaveSlot` — snapshot of game_state + psycho_profile fields + `sectorLabel` + `savedAt`. `SaveService` singleton: `saveToSlot()`, `readSlot()`, `listSlots()`, `restoreToLive(SaveSlot)` (atomic transaction). Slot 0 = auto-save (every 6 commands or sector change), slots 1–3 = manual. Player memories and dialogue history are session-wide and NOT per-slot.

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
- Anti-repetition ring buffer: last 20 indices per sector are excluded from selection. Buffer reset is done inline (no recursion) with an explicit empty-pool guard.
- If a JSON bundle fails to load, the pool is seeded with `DemiurgeEntry.fallback(sector)` so the player always sees a response.
- `sectorForNode(String nodeId)` maps node ID prefixes to sector keys.
- `switchPhase(int phase)` — advances narrative phase (1–5); only moves forward, never regresses. Called by `PsychoProfileNotifier.updateAwareness()` when a phase threshold is crossed.
- `int get currentPhase` — read-only accessor.
- Riverpod provider: `demiurgeServiceProvider`.

### `lib/features/demiurge/echo_service.dart`
**EchoService** — deterministic Echo persona layer. Singleton, pure Dart (no WidgetRef, no I/O).
- Three pools: `_proustResponses` (7 PD entries from À la Recherche), `_tarkovskijResponses` (6 paraphrases of Sculpting in Time), `_sethResponses` (6 original Seth/Jane Roberts-inspired entries).
- `_archiveMetaResponses` — 5 Seth-voice Archive-aware quotes for off-topic commands.
- `sectorEcho` map: `laboratorio→proust`, `galleria/osservatorio→tarkovskij`, `giardino/universale→seth`.
- `echoForKeywords(String input)` — phase-independent; detects explicit summon/invoke keywords + thematic triggers. Grants +8 awareness on keyword hit.
- `echoForCommand(CommandVerb verb, int phase, {affinities})` — phase+affinity gated (≥5 each).
- `isThematicForSector(String input, String sector)` — thematic keyword match per sector.
- `respondMeta()` — random archive-meta quote.

### `lib/features/game/game_engine_provider.dart`
The game engine — ~3 400 lines. `GameEngineNotifier` extends `AsyncNotifier<GameEngineState>`.
- All four sectors (Garden/North, Observatory/East, Gallery/South, Lab/West) + Fifth Sector (Quinto) + Final Boss (il_nucleo) + La Zona implemented.
- Narrator: `_callNarrator(CommandVerb verb, String fallbackText, String nodeId, String rawInput)` — 5-step priority chain: keyword echo → verb+phase echo → sector-thematic echo → archive-meta → Demiurge fallback.
- `_updateAwarenessFromCommand(verb, response, rawInput)` — updates phase/affinity deltas after each command.
- Auto-save: `_commandsSinceAutoSave` (ephemeral counter); `_triggerAutoSave()` fires after every processInput (fire-and-forget, silent catch). Triggers on every 6 commands or sector change.
- `saveToSlot(int slot)` — manual save to slots 1–3.
- `loadSlot(SaveSlot slot)` — restores DB via direct SQL UPDATE + `ref.invalidate(psychoProfileProvider)` + `DemiurgeService.instance.switchPhase(slot.phase)`.
- Exit gating: `const Map _exitGates` (`nodeId → {direction → requiredPuzzleId}`). Multi-condition gates (Lab Great Work, Quinto) handled as special cases before the map.
- Public static helpers (for tests): `gameRequiredPuzzleForExit()`, `gameGateHintForPuzzle()`, `gameExitsForNode()`, `gameAllNodeIds()`.

### `lib/features/llm/` (legacy)
`llm_service.dart` and `llm_context_service.dart` — kept for reference. No longer imported by the engine. Do not delete; do not add new imports.

### `lib/features/parser/parser_service.dart` + `parser_state.dart`
Pure synchronous parser. `ParsedCommand` carries `verb`, `args`. `EngineResponse` carries `narrativeText`, `needsLlm` (now means "call Demiurge"), `grantItem`, `weightDelta`, `newNode`, `completePuzzle`, `incrementCounter`, `audioTrigger`, `playerMemoryKey`.
Stop words: `{'the', 'a', 'an', 'at', 'to', 'into', 'on', 'up', 'with', 'from', 'by', 'for', 'in', 'of', 'toward', 'towards', 'through', 'over', 'under', 'against', 'between', 'among'}`.

### `lib/features/settings/app_settings_provider.dart`
`AppSettings` model + `AppSettingsNotifier`. Fields: `instantText`, `reduceMotion`, `highContrast`, `commandAssist`, `musicEnabled`, `musicVolume`, `sfxEnabled`, `sfxVolume`, `textScale`, `typewriterMillis`, `muteInBackground`, `enableHaptics`.

### `lib/features/state/game_state_provider.dart`
`GameStateNotifier` — Riverpod `AsyncNotifier`. `saveEngineState()` is the single persistence entry point; `updateNode()` is a thin wrapper.

### `lib/features/state/psycho_provider.dart`
`PsychoProfile` tracks: `lucidity`, `oblivionLevel`, `anxiety`, `psychoWeight`; and phase-system fields: `phase` (1–5), `awarenessLevel` (0–100), `proustAffinity`, `tarkovskijAffinity`, `sethAffinity`.
- `updateParameter()` — updates classic psych fields, reloads state without intermediate `AsyncValue.loading()` to prevent UI flicker.
- `updateAwareness({awarenessDelta, proustDelta, tarkovskijDelta, sethDelta})` — clamps to [0,100], calls `_phaseForAwareness()`, advances `DemiurgeService.instance.switchPhase()` when phase threshold is crossed.
- `resetProfile()` — resets all fields and calls `DemiurgeService.instance.switchPhase(1)`.

### `lib/features/ui/game_screen.dart`
Single-screen UI — text output + command input. Typewriter effect uses `dart:async Timer` (not `Future.delayed`), with `_typewriterTimer` cancelled in `dispose()` and `_skipTypewriter()` to prevent setState-on-disposed-widget. Displays sector background image at 0.15 opacity via `BackgroundService.getBackgroundForNode()`, updated via `gameStateProvider`.
- `_hapticsOn()` helper: `(s?.enableHaptics ?? true) && !(s?.reduceMotion ?? false)`. All `HapticFeedback.*` calls wrapped with this guard.
- "Save / Load" menu entry triggers `ArchivePanels.showSaveLoad()`.
- **Assist tray:** `_QuickCommandBar` and "Reuse" chip are hidden by default; toggled by a `💡` `IconButton` in `_InputRow`. `_assistVisible` (bool, ephemeral). Button absent when no suggestions exist.
- **Finale presentation:** `_FinaleType` enum + `_isFinaleNode()` / `_finaleTypeFor()` helpers at file scope. When `currentNode` is `finale_acceptance`, `finale_oblivion`, or `finale_eternal_zone`: background opacity rises to 0.52, `_SessionCard` hidden, typewriter slowed to 150 ms/char. `_FinaleBackdrop` (`StatefulWidget`) overlays a per-ending atmosphere (golden wash for acceptance, progressive 8-second black overlay for oblivion, cold blue tint for eternal zone). `_WakeUpFade` (`StatelessWidget`) overlays a 4-second white fade when `_wakeUpFading = true` (set on detection of "— FINE —" in last narrative message).
- **Walkthrough mode (QA only):** `_walkthroughUnlocked` (bool, never persisted) is set to `true` when the user submits the exact string `Stalker4598!TarkoS?`. That command is consumed silently — never forwarded to the engine. When unlocked, a small `arrow_forward` `IconButton` appears next to the input field; each press reads the next command from `assets/texts/walkthrough.json` (loaded once via `rootBundle.loadString`, cached in `_walkthroughSteps`) and injects it into the engine via `_queueQuickCommand`. `_walkthroughStep` (int, 0-based) tracks the position; on exhaustion a SnackBar says "Walkthrough complete". Load failures are caught silently.

### `lib/features/ui/archive_panels.dart`
Houses the settings sheet (`_SettingsSheet`), the save/load sheet (`_SaveLoadSheet` + `_SlotCard`), and the `showSaveLoad()` static entry point. `_SlotCard` shows: sector label, awareness %, date.

### `lib/features/ui/splash_screen.dart`
Cinematic opening screen. Sequence: `bg_soglia.jpg` fades in over 1 500 ms (dark veil at 0.38 opacity) → a random Bach sector track starts via `AudioService().handleTrigger(key)` (pool: `soglia`, `giardino`, `osservatorio`, `galleria`, `laboratorio`, `memoria`) → typewriter writes "The Archive of Oblivion" at 75 ms/char → 1 800 ms pause → `FadeTransition` to `HomeScreen`. Tapping at any time fills the title instantly and navigates after 400 ms. `reduceMotion` support: all animations instant, auto-advance after 2 s. Uses `pushReplacement` (not `push`) so the splash is not in the back-stack.

### `lib/features/ui/home_screen.dart`
Home screen with `_HomeActionButton` and `_HomeChip` as `ConsumerWidget`s. Reads `AppSettings` for haptic guard; fires `HapticFeedback.selectionClick()` on chip/button press and `mediumImpact()` on Archive opening.

### `lib/features/ui/background_service.dart`
Static utility mapping game node IDs → sector background asset paths (`assets/images/bg_*.jpg`). Node families: `intro_void`/`la_soglia` → soglia, `garden*` → giardino, `obs_*` → osservatorio, `gal_*`/`gallery_*` → galleria, `lab_*` → laboratorio, `quinto_*`/`il_nucleo`/`finale_*`/`memory_*` → memoria, `la_zona` → la_zona.

---

## The Demiurge system — "All That Is"

The on-device LLM (flutter_llama / Qwen 2.5 0.5B) was replaced by a fully deterministic narrator called **"All That Is"** (from Seth/Jane Roberts philosophy). The player never knows if they made a mistake or discovered something — error is part of the existential journey.

### How it works
1. `game_engine_provider.dart` calls `_callNarrator(verb, fallbackText, nodeId, rawInput)`.
2. `_callNarrator` runs a 5-step priority chain: keyword echo → verb+phase echo → sector-thematic echo → archive-meta → Demiurge fallback.
3. Demiurge step: `DemiurgeService.respond()` picks a random unused entry from the sector's pool (anti-repetition buffer of 20).
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

| File | Sector | Entries |
|---|---|---|
| `giardino.json` | Garden (North) | 200 |
| `osservatorio.json` | Observatory (East) | 200 |
| `galleria.json` | Gallery (South) | 200 |
| `laboratorio.json` | Lab (West) | 200 |
| `universale.json` | Universal fallback | 200 |

**All citations must be from public-domain sources.**
To populate bundles, run: `python tools/prepare_demiurge_bundles.py [--output-dir assets/texts/demiurge] [--target 200]`

---

## Known bugs (fixed)

### ✅ FIXED — Simulacra inventory bug
Items with `weightDelta == 0` were never added to inventory. Fix: inventory addition driven exclusively by `response.grantItem != null`, decoupled from `weightDelta`.

### ✅ FIXED — Demiurge bundle duplication
All five sector bundles contain 200 responses each, with stricter deduplication and balanced author selection.

### ✅ FIXED — DB concurrent init race condition
Old Completer pattern had a window where `_initCompleter` was null after `completeError()` but before waiting callers received the error. Replaced with `static Future<Database>? _initFuture` (`??=` idiom).

### ✅ FIXED — Demiurge recursive `_pickEntry`
Anti-repeat buffer reset used a recursive call — replaced with inline reset + re-computation to eliminate any stack overflow risk from corrupt pools.

### ✅ FIXED — `AsyncValue.loading()` flicker in PsychoProvider
`updateParameter()` set `state = loading()` before the async fetch, causing a spurious rebuild. Removed; state transitions directly from old data to new data.

---

## File structure

```
lib/
├── main.dart                               ← startup: AudioService + DemiurgeService.loadAll()
├── core/
│   ├── services/save_service.dart          ← SaveSlot model + SaveService (slots 0-3)
│   └── storage/
│       ├── database_service.dart           ← SQLite v9 (5 tables, _initFuture guard)
│       └── dialogue_history_service.dart
└── features/
    ├── audio/audio_service.dart            ← BGM crossfade, SFX, profile-driven ambience
    ├── demiurge/
    │   ├── demiurge_service.dart           ← "All That Is" + switchPhase() + fallback entry
    │   └── echo_service.dart               ← Proust/Tarkovskij/Seth echo personas
    ├── game/game_engine_provider.dart      ← full game engine (~3 400 lines)
    ├── game/text_bundle_service.dart       ← loads assets/texts/*.json and assets/prompts/*.json
    ├── llm/llm_service.dart                ← [legacy — do not import, do not delete]
    ├── llm/llm_context_service.dart        ← [legacy — do not import, do not delete]
    ├── parser/parser_service.dart
    ├── parser/parser_state.dart            ← ParsedCommand, EngineResponse, CommandVerb
    ├── settings/app_settings_provider.dart ← AppSettings + AppSettingsNotifier
    ├── state/game_state_provider.dart      ← GameStateNotifier (persistence entry point)
    ├── state/psycho_provider.dart          ← PsychoProfile: psych weight + phase system
    └── ui/
        ├── archive_panels.dart             ← settings sheet, save/load sheet
        ├── background_service.dart         ← node → bg image mapping
        ├── game_screen.dart                ← typewriter UI, haptics, command input
        ├── home_screen.dart                ← home with haptic-aware chips/buttons
        └── splash_screen.dart              ← cinematic opening (app entry point)

assets/
├── texts/
│   ├── demiurge/                           ← 5 × sector bundles (200 entries each)
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

test/
├── parser_test.dart                        ← 105 unit tests (all verbs, stop words, edge cases)
└── puzzle_gates_test.dart                  ← 119 static tests (exit gates integrity)

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

1. ~~Fix simulacra inventory bug~~ ✅ **FIXED**
2. ~~JSON text bundles (`assets/texts/*.json`) — populate game content~~ ✅ **DONE** — 7 bundles + 3 prompt templates.
3. ~~Remaining sectors: East (Observatory), South (Gallery), West (Lab)~~ ✅ **DONE** — all 4 sectors implemented.
4. ~~La Zona procedural engine~~ ✅ **DONE** — probabilistic activation, 8 verses, 8 environments, 8 questions.
5. ~~Fifth Sector (Memory/Proust) + Final Boss~~ ✅ **DONE** — 6 Quinto nodes + 4 Finale nodes, three endings.
6. ~~LLM integration~~ **SUPERSEDED** — replaced by DemiurgeService ("All That Is").
7. ~~DemiurgeService integration~~ ✅ **DONE** — wired into `game_engine_provider.dart`, pre-loaded in `main.dart`.
8. ~~Regenerate or curate Demiurge bundles~~ ✅ **DONE** — all five 200-entry bundles audited and clean.
9. ~~Phase system + Echo personas (Proust/Tarkovskij/Seth)~~ ✅ **DONE** — `EchoService`, 5-step `_callNarrator`, awareness/affinity tracking in `PsychoProfile`.
10. ~~Multi-slot save system~~ ✅ **DONE** — `SaveService`, auto-save slot 0, manual slots 1–3, Save/Load UI.
11. ~~Haptic feedback system~~ ✅ **DONE** — `enableHaptics` setting, `_hapticsOn()` guard on all calls.
12. ~~Automated tests~~ ✅ **DONE** — 105 parser tests + 119 puzzle gate tests.
13. ~~Cinematic splash screen~~ ✅ **DONE** — `SplashScreen`: bg_soglia fade-in, typewriter title, random Bach track, tap-to-skip, `reduceMotion` support.
14. **⟶ NEXT: End-to-end playtest on a physical Android device** (API 26+, 3 GB RAM). Verify all sector transitions, puzzle gates, La Zona activation, three endings, save/load round-trip.
15. Polish: audio balance, typewriter speed tuning, edge-case command handling.

---

## Stack and conventions

| Convention | Detail |
|---|---|
| State management | Riverpod `AsyncNotifier` — never `StateNotifier` |
| SQLite | Single-row pattern: always `'id': 1` + `ConflictAlgorithm.replace` |
| DB concurrent init | `static Future<Database>? _initFuture` with `??=` — never Completer |
| DB migrations | `_addColumnIfNotExists` in `_onUpgrade` — idempotent, never raw ALTER TABLE |
| Riverpod outside widget tree | `ProviderContainer` + `container.listen` (not `.select().listen`) |
| Audio crossfade | Manual `_rampVolume()` loop — `just_audio` has no `setVolume(duration:)` |
| Demiurge narrator | `DemiurgeService.instance.respond()` — deterministic, no LLM, no network |
| Narrator call site | `_callNarrator(verb, fallbackText, nodeId, rawInput)` in `game_engine_provider.dart` |
| Echo personas | `EchoService.instance` — pure Dart singleton, no WidgetRef, explicit params |
| Haptics guard | `_hapticsOn()`: `enableHaptics && !reduceMotion` — wrap every `HapticFeedback.*` call |
| Auto-save | Fire-and-forget `_triggerAutoSave()` after each `processInput` — swallows exceptions |
| Target Android | API 26+, mid-range 3 GB RAM |
| Game text language | English only |
| Background images | 7 JPEGs in `assets/images/`, shown at 0.15 opacity via `BackgroundService` |

---

## Known limitations (by design — do not fix without discussion)

### Save system: dialogue_history and player_memories are session-wide
Loading a different save slot does NOT swap `dialogue_history` or `player_memories`. These tables are session-wide by design for v1. This means a player who loads Slot 2 after playing Slot 1 will see the previous session's history. This is a known narrative inconsistency, accepted for v1. A future fix would require per-slot history tables and an atomic swap inside `restoreToLive()`.

### Demiurge anti-repetition buffer resets on restart
`_antiRepeatWindow = 150` protects against in-session repetitions (150 of 200 entries excluded at any time). The buffer lives in RAM only — restarting the app resets it. Persisting the buffer to SQLite is a future improvement.

---

## Rules — mandatory for every session

- **Never wipe or replace** existing `docs/work_log.md` entries — only prepend new ones at the top.
- **The Demiurge ("All That Is") is the game's narrative voice** — fully deterministic, no LLM required. NEVER suggest replacing it with an LLM.
- **NEVER refactor `game_engine_provider.dart` into multiple Riverpod providers.** Keep all state in a single `AsyncNotifier`. Pure Dart logic can be extracted into helper classes, but the Riverpod boundary stays as one notifier.
- **If modifying the save system, ALWAYS wrap `dialogue_history`/`player_memories` swaps inside the atomic SQL transaction** in `restoreToLive()`.
- **Stop words in `parser_service.dart` are English-only.** Do not add Italian or other language stop words — the game is English-only (GDD §1).
- **End every session with a work log entry** in `docs/work_log.md` (see format of existing entries: date, agent role, done list, architecture snapshot if relevant).
