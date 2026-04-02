# Work Log — L'Archivio dell'Oblio
*Registro cronologico delle sessioni di sviluppo. Non modificare le voci esistenti.*
*GDD completo: [`claude.md`](../claude.md)*

---

### 2026-04-02 — Grok (Audio & Immersion Specialist)
**Role:** Flutter/Audio specialist + ottimizzazione bassa RAM
**Done:**
- Corretto bug `GameStateNotifier.updateNode()`: infinite row growth → single-row con `ConflictAlgorithm.replace` + `'id': 1`
- Implementato `AudioService` reattivo a `psychoProfileProvider` (crossfade automatico calm/anxious/oblivion)
- Gestione SFX separata con `AudioPlayer` usa-e-getta + auto-dispose
- Fallback silenzioso per asset mancanti (no crash su 3 GB RAM)
- Creato `main.dart` con `ProviderContainer` pre-`runApp` + `UncontrolledProviderScope`

**Key decisions:**
- Audio è priorità #1: zero immagini = sound design come protagonista
- Singolo `AudioPlayer` in background (leggerissimo su RAM)
- `ConflictAlgorithm.replace` richiede `'id': 1` esplicito per funzionare con AUTOINCREMENT (fix applicato da Claude al momento del commit)
- `ProviderContainer` passato ad `AudioService.initialize()` — i provider Riverpod non sono Stream, non si può usare `.listen()` direttamente (fix applicato da Claude: `container.listen` invece di `provider.select().listen()`)
- Crossfade manuale via `_rampVolume()` — `just_audio.setVolume()` non accetta `duration` (fix applicato da Claude)

**Files created/modified:**
- `lib/features/state/game_state_provider.dart` (bug fix: single-row + ConflictAlgorithm)
- `lib/features/audio/audio_service.dart` (new)
- `lib/main.dart` (new)

**Next suggested step:** UI testuale base — schermata parser + display testo narrativo reattivo al `psychoProfileProvider`

---

### 2026-04-02 — Gemini 2.5 Pro
**Role:** Flutter/Android specialist
**Done:**
- Defined SQLite schema strategy for state management and context window optimization
- Implemented `DatabaseService` (Singleton) with tables: `game_state`, `psycho_profile`, `dialogue_history`
- Developed Riverpod `AsyncNotifier` for `PsychoProfile` to map DB reads/writes to UI/Audio state
- Developed Riverpod `AsyncNotifier` for `GameState` to track the player's current narrative node
- Engineered `LlmContextService` to dynamically assemble System Prompts based on real-time psychological parameters and game location

**Key decisions:**
- Rejected larger LLM (1.5B+) due to strict 3GB RAM mid-range target — Android LMK crashes and unacceptable token/sec latency. Committing fully to 0.5B model + aggressive Dynamic System Prompting
- Grouped state/storage commits into a single batch to streamline developer workflow

**Files created/modified:**
- `lib/core/storage/database_service.dart` (Created)
- `lib/features/state/psycho_provider.dart` (Created)
- `lib/features/state/game_state_provider.dart` (Created)
- `lib/features/llm/llm_context_service.dart` (Created)

**Next suggested step:** TBD — Audio Engine integration or Base UI implementation

---

### 2026-04-02 — Claude Sonnet 4.5
**Role:** Architettura generale, setup repository, coordinamento multi-LLM
**Done:**
- Creata cartella di progetto `~/Development/archive-of-oblivion/`
- Struttura cartelle Flutter (`lib/`, `assets/`, `docs/`, `tools/`)
- `claude.md` — GDD completo trascritto e versionato
- `.gitignore` — configurato per Flutter (file `.gguf` LLM esclusi da git)
- Repository GitHub creato e pushato: https://github.com/Vale717171/archive-of-oblivion
- Progettato protocollo di collaborazione multi-LLM
- Creati: `docs/work_log.md`, `docs/prompts/universal_session_prompt.md`, `docs/prompts/role_cards.md`

**Key decisions:**
- `assets/llm/*.gguf` escluso da git — i modelli LLM vanno scaricati separatamente
- `claude.md` = GDD puro (fonte di verità), `docs/work_log.md` = registro storico separato
- Ogni LLM aggiorna il log alla fine della sessione, il maintainer umano fa il commit

**Files created/modified:**
- `claude.md` (aggiunto header multi-LLM)
- `docs/work_log.md` (questo file)
- `docs/prompts/universal_session_prompt.md`
- `docs/prompts/role_cards.md`

**Next suggested step:**
Fase 0-omega — validazione LLM su device fisico Android.
Modello consigliato per questo task: **o3** (ragionamento su sistemi, valutazione tecnica).
In alternativa: eseguire tu stesso i test con `flutter_llama` seguendo la sezione 17 del GDD.

---
