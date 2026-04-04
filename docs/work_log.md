# Work Log — L'Archivio dell'Oblio
*Registro cronologico delle sessioni di sviluppo. Non modificare le voci esistenti.*
*GDD completo: [`claude.md`](../claude.md)*

---

### 2026-04-04 — GitHub Copilot (Fifth Sector, Final Boss, JSON Bundles, La Zona)
**Role:** Full game completion — Opzioni A, B, C

**Done:**
- **Opzione B — JSON text bundles** (`assets/texts/`, `assets/prompts/`):
  - Creati 7 file bundle: `manifest.json`, `epicuro_bundle.json`, `proust_bundle.json`,
    `tarkovsky_bundle.json`, `newton_bundle.json`, `alchimia_bundle.json`, `arte_bundle.json`
  - Creati 3 file prompt template: `zona_templates.json`, `antagonist_templates.json`, `proust_triggers.json`
  - Creato `lib/features/game/text_bundle_service.dart` — singleton, async loader con cache,
    `preloadAll()`, helpers per zone questions, Tarkovsky verses, keywords
  - Aggiornato `pubspec.yaml` — aggiunto `assets/prompts/` agli asset registrati

- **Opzione A — Quinto Settore + Final Boss** (`game_engine_provider.dart`):
  - Sostituito `quinto_stub` con `quinto_landing` — 4 stanze memoria + camera rituale
  - Nuovi nodi: `quinto_landing`, `quinto_childhood`, `quinto_youth`, `quinto_maturity`,
    `quinto_old_age`, `quinto_ritual_chamber`
  - Nuovi nodi finali: `il_nucleo`, `finale_acceptance`, `finale_oblivion`, `finale_eternal_zone`
  - Exit gates per quinto rooms (gating su 'back' con prezzo di memoria)
  - Gate speciale `quinto_landing → down` come multi-condition check in `_handleGo`
  - `_handleWrite` + `_handleMemoryWrite`: gestisce prezzi di memoria per le 4 stanze
  - `_handleDrink` + `_handleStir`: puzzle rituale
  - `_handleRitualPlacement`: `place [simulacrum] in cup` → puzzle IDs `cup_ataraxia` etc.
  - `_handleBossInput` (Regola del Tre, catarsi, resolution, surrender, eternal zone)
  - `_handleBossDrop` (catarsi nel boss fight — pesa i drop, segnala peso=0)
  - `_antagonistArgue` (argomento Schopenhauer, personalizzato con inventario)
  - `_handleFinaleInput` (comandi nei finali)
  - Trigger Proustiano: `observe reflection` in `gallery_hall` (2° visita dopo backward walk)
  - Comando `WAKE UP` per Finale 1 (`finale_acceptance`)
  - Risposta al telefono: `say [words]`/`answer [words]` in `quinto_maturity`
  - `_handleDeposit` aggiornato per boss context (preserva simulacra, rimuove solo mundane)
  - `_helpText` aggiornato con tutti i nuovi comandi

- **Opzione C — La Zona** (`game_engine_provider.dart`):
  - Nodo `la_zona` aggiunto ai `_nodes`
  - Costanti: `_tarkovskyVerses` (8), `_zoneEnvironments` (8), `_ZoneQuestion` classe + `_zoneQuestions` (8)
  - `_maybeActivateZone` — intercetta navigazioni e può reindirizzare a `la_zona`
  - `_zoneActivationProbability` — probabilities per scenari GDD §10 (base 15%, sector completion 25%,
    third consecutive transit 40%, 3+ simulacra 50%, pre-fifth 75%)
  - `_isSectorCompletion` — rileva completamento settori per probabilità zona
  - Tracking in `processInput`:  `zone_encounters` e `consecutive_transits` nei puzzleCounters
  - `_handleZoneResponse` — gestisce risposta libera (≥3 parole → risposta criptica → ritorno a la_soglia)
  - Guard anti-loop: zona non si riattiva se risposta al turno corrente non ancora data

**Key decisions:**
- Quinto Settore skip Zone (no interruzione narrativa durante il percorso memorie → rituale)
- Boss fight: `deposit` preserva simulacra (only mundane items cleared), weight → 0
- Zone counter 1-based (incrementato all'entrata, non all'uscita) — guard controlla `zone_responded_$encounters`
- Tutti e 3 i finali raggiungibili: risoluzione (keyword + peso=0), oblio (surrender), zona eterna (remain)
- Trigger Proustiano gallery: condizionato su `hall_backward_walked` (proxy per "2a visita")

**Files created:**
- `assets/texts/manifest.json`, `epicuro_bundle.json`, `proust_bundle.json`, `tarkovsky_bundle.json`,
  `newton_bundle.json`, `alchimia_bundle.json`, `arte_bundle.json`
- `assets/prompts/zona_templates.json`, `antagonist_templates.json`, `proust_triggers.json`
- `lib/features/game/text_bundle_service.dart`

**Files modified:**
- `pubspec.yaml` (aggiunto `assets/prompts/`)
- `lib/features/game/game_engine_provider.dart` (major extension)

**Next suggested step:**
- Popolare i nodi narrativi con testo definitivo (quinto rooms già hanno buon testo)
- Fase 0-omega — LLM validation su APK completo (GDD §17)
- Sostituire `_llmStub()` dopo validazione

---

### 2026-04-03 — GitHub Copilot (Puzzle Engine Implementation)
**Role:** Game engine — full puzzle logic for all four sectors

**Done:**
- `parser_state.dart`: aggiunto `grantItem`, `completePuzzle`, `incrementCounter` a `EngineResponse`
- `game_engine_provider.dart` — riscrittura completa con:
  - `GameEngineState` ora tiene `completedPuzzles` (Set) e `puzzleCounters` (Map)
  - 22 nuovi nodi (Observatory, Gallery, Lab, stub Quinto Settore) — stubs rimossi
  - `_exitGates` e `_gateHints`: ogni corridoio gateato dal puzzle ID richiesto
  - `processInput`: applica nuovi campi risposta, fix bug simulacri inventario,
    tracking visite esterne per bain-marie, peso clampato ≥ 0
  - Tutti i puzzle handler implementati con logica corretta per GDD §8:
    - **Giardino**: arrange leaves (ordine epicureo corretto), wait×3 fontana,
      inscribe stele (gate peso=0, check word-boundary "friendship"),
      walk through entrambe le alcove, deposit (prerequisito alcove)
    - **Osservatorio**: combine lenses (Moon/Mercury/Sun invertito), walk blindfolded,
      wait×7 + measure fluctuation, enter 1, calibrate 0,0,0,
      invert mirror + confirm×3 + observe → The Constant
    - **Galleria**: walk backward, press anomalous tile, construct pentagon,
      describe copies×3, paint originals ≥50 parole, drop item in dark chamber,
      break mirror (peso=0 → The Proportion; peso>0 → caos, nessun simulacro)
    - **Laboratorio**: offer×3, decipher + collect Tria Prima, calcinate+wait×5,
      set temperature gentle, leave+return bain-marie (3 nodi esterni),
      place in planetary circles×7 (ordine Opus Magnum), blow → The Catalyst
  - Helper: `_isSimulacrum()`, `_normalizeInput()`, `_wordCountExcludingVerb()`
  - Costante `_maxPsychoValue = 100`; notebook inizializzato in inventario (GDD §7)
  - `_helpText` aggiornato con tutti i comandi

**Key decisions:**
- Nodi narrativi = enigmi di progressione: ogni nodo blocca l'uscita nord/avanti
  finché il puzzle non è risolto (gating via `_exitGates`)
- Ordine foglie Cipresso: prudence → friendship → pleasure → simplicity →
  absence → tranquillity → memory (progressione epicurea dal mezzo al fine)
- Stele: accetta qualsiasi input contenente la parola "friendship" (con word-boundary)
  solo se peso psicologico = 0 (GDD §6)
- Specchio galleria: peso>0 → frantumazione caotica senza simulacro (GDD §8)
- bain-marie: tracking automatico visite esterne in `processInput`

**Files modified:**
- `lib/features/parser/parser_state.dart`
- `lib/features/game/game_engine_provider.dart`

**Next suggested step:**
- Popolare i bundle JSON (`assets/texts/*.json`) con il testo narrativo definitivo (GDD §18)
- Implementare i settori mancanti Est, Sud, Ovest (già presenti come nodi, manca il testo finale)
- Quinto Settore + Boss finale (GDD §11–12)

---

### 2026-04-02 — GitHub Copilot (Claude Code Integration)
**Role:** Documentation & tooling — Claude Code session instructions
**Done:**
- Creato `CLAUDE.md` (root) — letto automaticamente da Claude Code all'avvio di ogni sessione:
  contiene convenzioni codebase, struttura file, known bug simulacra, priority order, regole
- Creato `tools/fase_0_omega/CLAUDE_CODE_PROMPT.md` — prompt completo pronto per incollare
  nella prima sessione Claude Code: istruzioni per `flutter create` + patch Android + adb + tabella
  chi fa cosa (Claude Code vs umano) + prompt sessione successiva (post-risultati) + link modelli
- Aggiornato `docs/prompts/role_cards.md` — aggiunto role card "Claude Code" e istruzioni d'uso

**Key decisions:**
- `CLAUDE.md` (uppercase) è distinto da `claude.md` (GDD, lowercase) — Claude Code legge solo `CLAUDE.md`
- I progetti Flutter reali (`llm_test_1_project/`, `llm_test_2_project/`) vengono creati da Claude Code
  al momento dell'esecuzione; le cartelle `llm_test_1/` e `llm_test_2/` restano template nel repo
- Il prompt per Claude Code separa esplicitamente cosa può fare il tool (build, patch, analyze)
  da cosa deve fare l'umano (download modello, adb push, device fisico, risultati)

**Files created/modified:**
- `CLAUDE.md` (nuovo, root)
- `tools/fase_0_omega/CLAUDE_CODE_PROMPT.md` (nuovo)
- `docs/prompts/role_cards.md` (aggiunto role card Claude Code)
- `docs/work_log.md` (questa voce)

**Next suggested step:**
Aprire Claude Code nella root del repo, verificare che legga `CLAUDE.md` automaticamente,
poi incollare il prompt da `tools/fase_0_omega/CLAUDE_CODE_PROMPT.md`.
Prerequisiti: Flutter SDK installato localmente, device Android fisico connesso via USB.

---


**Role:** LLM Validation Suite — app Flutter di test per validazione on-device
**Done:**
- Creato `tools/fase_0_omega/README.md` — guida master: download modelli, adb push, decision tree completo
- Creato `tools/fase_0_omega/llm_test_1/` — app di test per `flutter_llama` (Tentativo 1):
    - `pubspec.yaml` — dipendenze: `flutter_llama ^1.0.0` + `path_provider ^2.1.2`
    - `lib/main.dart` — app completa: rilevamento modello (path configurabile), caricamento con timer, 5 test prompts da GDD §20 (formato Qwen), metriche (load time, tokens/s, durata), verdetto PASS/FAIL
    - `android_patches.md` — patch per `build.gradle` (minSdk 26, largeHeap) e `AndroidManifest.xml`
- Creato `tools/fase_0_omega/llm_test_2/` — app di test per `mediapipe_genai` (Tentativo 2):
    - `pubspec.yaml` — dipendenze: `mediapipe_genai ^0.0.1`
    - `lib/main.dart` — stessa struttura di test 1, ma con prompt in formato Gemma (`<start_of_turn>user`), GPU/CPU auto-fallback, soglie più strette (< 15s)
    - `android_patches.md` — patch + nota su adattamento template se Gemma vince
- Creato `tools/fase_0_omega/results_template.md` — form da compilare dopo i test (metriche, campione output, verdict, decisione finale)

**Key decisions:**
- Modelli caricati da storage esterno (`/sdcard/Download/`) via `adb push` — non bundlati in assets (350MB–1.3GB rendono l'APK ingestibile in CI, e la produzione gestirà la distribuzione separatamente)
- Il path del modello è modificabile nell'app via campo di testo — flessibile per device con percorsi diversi
- Test 1 usa `nGpuLayers: 0` (CPU-only) come default; commento nel codice per testare Vulkan GPU (`-1`)
- Test 2 prova GPU prima, poi CPU come fallback automatico — registra quale modalità ha usato
- 5 prompt prompts allineati con i template reali di GDD §20 — il test misura le stesse condizioni del gioco, non solo "hello world"
- Nessuna dipendenza aggiunta al progetto principale — i test app sono standalone in `tools/`

**Files created:**
- `tools/fase_0_omega/README.md`
- `tools/fase_0_omega/llm_test_1/pubspec.yaml`
- `tools/fase_0_omega/llm_test_1/lib/main.dart`
- `tools/fase_0_omega/llm_test_1/android_patches.md`
- `tools/fase_0_omega/llm_test_2/pubspec.yaml`
- `tools/fase_0_omega/llm_test_2/lib/main.dart`
- `tools/fase_0_omega/llm_test_2/android_patches.md`
- `tools/fase_0_omega/results_template.md`

**Next suggested step:**
1. Scarica `qwen2.5-0.5b-instruct-q4_k_m.gguf` da HuggingFace (~350 MB)
2. `flutter create llm_test_1 --org com.archivio.test` nella cartella `tools/fase_0_omega/`
3. Copia `pubspec.yaml` e `lib/main.dart` dal repo
4. Applica `android_patches.md`
5. `adb push model.gguf /sdcard/Download/`
6. `flutter run --release` su device fisico
7. Compila `results_template.md` e committi nel repo
8. Se Test 1 passa: aggiungere `flutter_llama ^1.0.0` a `pubspec.yaml` principale e sostituire `_llmStub()` in `game_engine_provider.dart`

---

### 2026-04-02 — GitHub Copilot (Documentation & Handoff)
**Role:** Sincronizzazione documentazione per handoff a Claude Code
**Done:**
- Ripristinato `claude.md` con il GDD completo (788 righe, §1–§23) — la branch aveva solo 15 righe (§23 isolato)
- Aggiornato §16 (Architettura Tecnica): flusso interazione con nomi classi reali + mappa struttura file annotata con autori
- Riscritto §22 (NOTE APERTE): segnati come ✅ i componenti implementati, priorità aggiornate
- Aggiunta sezione GitHub Copilot a `docs/prompts/role_cards.md` — codebase awareness, bug noto simulacra, regole

**Key decisions:**
- Bug simulacra (weightDelta=0 → non aggiunti all'inventario) documentato in role card + §22 come pending fix
- `claude.md` fonte di verità: mai sovrascrivere, solo appendere in fondo
- `docs/prompts/role_cards.md` ora include tutti i collaboratori: Claude, Gemini, o3, Mistral, SuperGrok, DeepSeek, Copilot

**Files created/modified:**
- `claude.md` (ripristinato GDD completo + §16/§22 aggiornati + §23)
- `docs/prompts/role_cards.md` (aggiunta sezione GitHub Copilot)
- `docs/work_log.md` (questa voce)

**Next suggested step:**
Fase 0-omega — validazione LLM su device fisico Android (GDD sezione 17).
I modelli `.gguf` vanno in `assets/llm/` nel progetto di test (non nel repo principale, già esclusi da `.gitignore`).
Dopo validazione: fix bug simulacra in `game_engine_provider.dart` (soluzione in role card Copilot).

---

### 2026-04-02 — GitHub Copilot (Parser & UI Specialist)
**Role:** Parser state machine + base UI + game engine stub
**Done:**
- Creato `docs/parser_state_machine.md` — specifica completa della state machine a 6 fasi (idle → parsing → evaluating → llmPending/eventResolved → displaying → idle)
- Implementato `lib/features/parser/parser_state.dart` — modelli dati: `ParserPhase`, `CommandVerb` (17 verbi), `ParsedCommand`, `EngineResponse`, `GameMessage`, `MessageRole`
- Implementato `lib/features/parser/parser_service.dart` — parser puro e stateless (funzione statica, zero side effects); riconosce abbreviazioni (n/s/e/w, i, z, l, ?), stop words filtering
- Creato `lib/core/storage/dialogue_history_service.dart` — servizio singleton per persistenza dialoghi su SQLite (save / recent / contextWindow / clear)
- Creato `lib/features/game/game_engine_provider.dart` — Riverpod `AsyncNotifier` con:
    - 12 nodi narrativi completi in inglese: intro_void, la_soglia, garden_portico, garden_cypress, garden_fountain, garden_stelae, garden_grove, garden_alcove_pleasures, garden_alcove_pains + 3 stub (observatory, gallery, lab)
    - Gestione peso psicologico, inventario, navigazione
    - Trigger proustiani (smell linden → risposta Proust, lucidityDelta)
    - Finale del Giardino (`deposit everything` → Ataraxia, lucidityDelta +10, anxietyDelta -20)
    - LLM stub (`_llmStub`) — ready per sostituzione post Fase 0-omega
- Creato `lib/features/ui/game_screen.dart` — UI testuale completa:
    - Effetto typewriter con velocità variabile (lettere vs spazi)
    - Palette colori reattiva a `PsychoProfile` (bianco/rossastro/grigio/azzurro-grigio)
    - Background che vira al blu profondo con oblivionLevel
    - Status bar inventario (visibile solo quando non vuoto)
    - Tap su testo → skip typewriter
    - Input field disabilitato durante elaborazione
- Aggiornato `lib/main.dart` — punta a `GameScreen` (rimossa la schermata stub)

**Key decisions:**
- `ref.read` (non `ref.watch`) in `build()` del GameEngineNotifier — evita il reset della lista messaggi ad ogni navigazione
- Nodi come `const Map` statica nel file — contenuto già in inglese, pronto per migrazione a `assets/texts/*.json` (GDD sezione 18) senza modifiche all'engine
- LLM stub esplicito (`_llmStub`) con TODO — la firma è già quella corretta per la sostituzione post-validazione
- Peso psicologico NON mostrato numericamente al giocatore (GDD sezione 6) — solo nella status bar dell'inventario come debug
- Stop words filtering nel parser (`the`, `a`, `an`, `at`, `to`, `into`, `up`, `on`) — migliora il natural language feel
- Typewriter con velocità variabile: 22ms/lettera, 10ms/spazio — equilibrio tra atmosfera e leggibilità

**Files created/modified:**
- `docs/parser_state_machine.md` (new)
- `lib/features/parser/parser_state.dart` (new)
- `lib/features/parser/parser_service.dart` (new)
- `lib/core/storage/dialogue_history_service.dart` (new)
- `lib/features/game/game_engine_provider.dart` (new)
- `lib/features/ui/game_screen.dart` (new)
- `lib/main.dart` (modified — GameScreen sostituisce stub)

**Next suggested step:**
Fase 0-omega — validazione LLM su device fisico (GDD sezione 17). Il gioco è ora giocabile come parser puro. Dopo la validazione: sostituire `_llmStub()` in `game_engine_provider.dart` con la chiamata reale al modello on-device. Modello consigliato per questo task: **Claude** (già conosce il contesto) o **o3** (ragionamento tecnico su llama.cpp/MediaPipe).

---

### 2026-04-02 — ChatGPT o3 (Design & Narrative Analyst)
**Role:** Analisi critica GDD + direzione narrativa
**Done:**
- Analisi completa del GDD — confermata coerenza tematica e direzione artistica
- Identificato il rischio principale: "estetica senza sistema" (bello da vedere, vuoto da usare)
- Sollevato gap critico: manca un **loop di interazione concreto** (cosa fa l'utente per 10 minuti?)
- Proposto 3 archetipi di loop: Archivista (preservare), Investigatore (ricostruire), Entità (manipolare)
- 4 idee concrete per il design del "decadimento": Corruption Signature, False Memory Injection, Stabilità Apparente, Utente come fonte di errore

**Key decisions / Valutazione contro GDD esistente:**
- Loop Archivista/Investigatore/Entità → GDD già risponde: il giocatore è sempre "il protagonista senza nome" in modalità investigativa. Non serve scegliere — è già definito. Punto chiuso.
- "Loop concreto mancante" → valido. Il GDD descrive settori e enigmi ma non il ritmo micro (cosa succede turno per turno). Da affrontare nello state machine del parser (GDD sez. 22, prossimo task di o3/Claude).
- Corruption Signature → **interessante, compatibile** con il Peso Psicologico esistente. Da valutare come variante stilistica dell'LLM per settore (ogni settore = firma narrativa diversa).
- False Memory Injection → **già presente** nel GDD come meccanica della Zona e dell'Antagonista (sezioni 10, 12). ChatGPT l'ha reinventata indipendentemente — segnale che la direzione è giusta.
- Stabilità Apparente → già implicita nel game design (oggetti che sembrano utili ma aumentano il peso psicologico).
- "Memoria diegetica" del work log → idea creativa ma fuori scope. Il log rimane documentazione tecnica.
- Tono del contributo: eccellente come brainstorming filosofico, ma contiene molte ridondanze col GDD esistente (ChatGPT non ha letto abbastanza in profondità o ha usato una versione parziale).

**Files created/modified:** nessuno (contributo design puro)

**Next suggested step:** state machine del parser — definire il ritmo micro turno-per-turno. Modello consigliato: **o3** (logica formale) o **Claude** (conosce già tutto il contesto).

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
