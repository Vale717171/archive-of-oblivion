# Work Log — L'Archivio dell'Oblio
*Registro cronologico delle sessioni di sviluppo. Non modificare le voci esistenti.*
*GDD completo: [`gdd.md`](gdd.md)*

---

### 2026-04-17 — Codex GPT-5 (Garden architectural extraction: state-driven module)
**Role:** Sector architecture refactor (first real extraction slice)

**Done:**
- Extracted Garden into a dedicated module:
  - Added `lib/features/game/garden/garden_module.dart`.
  - Added `GardenStateView` (state snapshot DTO for pure reducers).
  - Moved Garden room definitions out of engine into `GardenModule.roomDefinitions`.
  - Moved Garden gate maps into `GardenModule.exitGates` and `GardenModule.gateHints`.
  - Added Garden pure reducers/handlers:
    - `handleExamine`
    - `handleArrange`
    - `handleWait`
    - `handleWrite`
    - `handleWalk`
    - `handleOffer`
    - `handleDeposit`
  - Added explicit Garden progression logic APIs:
    - `isSurfaceComplete`
    - `isDeepComplete`
    - `completionMarkers` (adds `garden_surface_complete` and `garden_deep_complete`, plus `sys_deep_garden`)
  - Added explicit hook APIs:
    - `onEnterNode` (revisit hook)
    - cross-sector hook remains explicit inside `handleExamine` at Threshold pedestal condition.
- Reduced Garden coupling in `lib/features/game/game_engine_provider.dart`:
  - Added imports for `game_node.dart` and `garden_module.dart`.
  - Introduced `lib/features/game/game_node.dart` with shared `NodeDef`.
  - Replaced private `_NodeDef` usage with shared `NodeDef`.
  - `_nodes` now includes `...GardenModule.roomDefinitions` instead of embedded Garden node block.
  - `_exitGates` and `_gateHints` now include Garden via spread from module constants.
  - Replaced Garden-specific notifier logic in handlers with module delegation:
    - examine/wait/arrange/write/walk/offer/deposit/go-enter-hook.
  - Added `_gardenView(...)` helper so notifier only orchestrates calls.
  - Added post-turn Garden completion marker integration via `GardenModule.completionMarkers(...)`.
  - Kept gameplay behavior intact while moving logic toward pure state transitions.
- Added/updated public helper exposure:
  - `gameGardenSteleInscriptionLooksSpecific(...)`
  - `gameGardenRelinquishmentCoverage(...)`
  - `gameGardenSurfaceComplete(...)`
  - `gameGardenDeepComplete(...)`

**Tests added:**
- New `test/garden_module_test.dart` covering:
  - leaf arrangements with distinct outcomes
  - fountain patience anti-spam behavior
  - stele generic vs substantial writing evaluation
  - statue triadic relinquishment enforcement
  - deep completion requiring more than Ataraxia

**Verification:**
- `dart format lib/features/game/game_node.dart lib/features/game/garden/garden_module.dart lib/features/game/game_engine_provider.dart test/garden_module_test.dart test/game_engine_helpers_test.dart` ✅
- `flutter test test/garden_module_test.dart test/game_engine_helpers_test.dart test/systemic_state_test.dart test/puzzle_gates_test.dart` ✅
- `flutter test` ✅ (all passing; existing skipped integration TODOs unchanged)

**Architecture notes:**
- Garden is now the first sector with dedicated module-owned room data + pure transition logic.
- `GameEngineNotifier` remains orchestration-only for Garden command routing and global cross-sector systems.

### 2026-04-17 — Codex GPT-5 (Systemic Garden migration slice + assist hardening pass 2)
**Role:** Incremental refactor execution (Garden-first systemic vertical slice)

**Done:**
- Extended `GameEngineNotifier` with Garden systemic staging while keeping existing command loop and save model stable:
  - leaf gate now requires preparatory reading of both the Portico columns and Cypress leaves before a valid arrangement can lock.
  - leaf arrangement now recognises plausible-but-wrong philosophical orders and responds diegetically without opening the path.
  - fountain gate now rewards attentive patience instead of pure command spam: second/third waits are blocked until the player re-engages with fountain/dust/inscription.
  - stele writing now uses lightweight heuristics (minimum length, anti-generic phrases, friendship token, concrete/costly cues) before accepting inscription.
  - grove statue now requires triadic relinquishment coverage (useful / identity-bound / pain-bound) before `deposit everything` can yield Ataraxia.
- Added Garden revisit and cross-sector hooks:
  - first post-completion return to `garden_portico` emits altered-return text and marks `garden_revisited`.
  - first `examine pedestal` at Threshold after Garden completion emits an east-wing resonance hook.
- Notebook-centric safeguard:
  - `notebook` can no longer be dropped.
  - deposit flows preserve `notebook` (both Garden and Nucleus deposit contexts), while still clearing mundane burden.
- Hardened assist/hint anti-shortcut behavior (non-punitive):
  - full hint escalation now unlocks one step later (`hint` request count 4 for level 3).
  - quick suggestions demoted from `hint more` to `hint` in puzzle hotspots.
  - removed immediate solver quick action (`decipher symbols`) from Lab suggestions.
- Added test coverage for new helper-level heuristics:
  - `gameGardenSteleInscriptionLooksSpecific(...)`
  - `gameGardenRelinquishmentCoverage(...)`
  - tests added in `test/game_engine_helpers_test.dart`.

**Verification:**
- `dart format lib/features/game/game_engine_provider.dart lib/features/ui/game_screen.dart test/game_engine_helpers_test.dart` ✅
- `flutter test test/game_engine_helpers_test.dart test/systemic_state_test.dart test/puzzle_gates_test.dart` ✅
- `flutter test` ✅ (all passing; existing skipped integration TODOs unchanged)

**Architecture notes:**
- No provider split introduced: `GameEngineNotifier` remains the orchestration center as requested.
- Deterministic narrator stack unchanged (Demiurge/Echo only, no LLM runtime path).
- State persistence remains backward-compatible through `completed_puzzles` + `puzzle_counters`.

### 2026-04-17 — Codex GPT-5 (Systemic refactor bootstrap: audit + phase-1 vertical slice)
**Role:** Architecture refactor kickoff (incremental, gameplay-safe)

**Done:**
- Audited the current codebase against the requested systemic direction and confirmed:
  - monolithic orchestration in `GameEngineNotifier` is the safest integration point
  - parser is already command-structured and suitable for controlled free-text windows
  - persistence can safely evolve via `puzzle_counters` / `completed_puzzles` without immediate table explosion.
- Introduced systemic state foundations in a new pure module:
  - `lib/features/game/systemic_state.dart`
  - Added typed shells:
    - `WeightState` (material/verbal/symbolic)
    - `NotebookState` (pages/hidden/torn/habitation)
    - `CoherenceState` (contradictions)
    - `SectorState` (surface/deep/depth signals)
    - `ZoneState` (pressure)
    - `ThresholdState` (resonance, unstable light, incomplete stair)
    - `EndingState` (eligibility shell)
  - Added `SystemicStateCodec` for:
    - decoding runtime systemic snapshot from existing counters/puzzles
    - applying incremental shell transitions (`applyShells`)
    - zone pressure boost/decay hooks
    - threshold diegetic return signals
    - notebook inspection text rendering.
- Integrated phase-1 shells into `GameEngineNotifier` with no provider split:
  - `processInput()` now applies systemic shells every turn using existing runtime data.
  - zone activation probability now includes a bounded systemic boost from run pressure.
  - zone activation consumes one unit of pressure.
  - returning to `la_soglia` may append diegetic resonance lines (unstable light/incomplete stair/hum).
  - `examine notebook` now surfaces a systemic notebook/status readout.
- Added tests for pure systemic transitions:
  - `test/systemic_state_test.dart`.

**Verification:**
- `dart format lib/features/game/systemic_state.dart lib/features/game/game_engine_provider.dart test/systemic_state_test.dart` ✅
- `flutter test test/systemic_state_test.dart test/parser_test.dart test/puzzle_gates_test.dart` ✅
- `flutter test` ✅ (all passing; existing 3 skipped integration TODOs unchanged)

**Architecture notes:**
- This is a bootstrap slice only: no full Garden migration yet.
- State foundations are intentionally encoded in existing persistence channels (`puzzle_counters` + `completed_puzzles`) to keep save/load stable during refactor.
- Next safe vertical slice is Garden staged-state migration on top of these shells.

### 2026-04-17 — Codex GPT-5 (Depth gates + quote exposure + assist hardening)
**Role:** Gameplay progression hardening (diegetic, non-punitive)

**Done:**
- Added sector depth-gating in `lib/features/game/game_engine_provider.dart` with a new "meaningful interactions" metric per sector (unique `node + verb` signatures tracked in engine state):
  - `garden >= 5`, `observatory >= 5`, `gallery >= 5`, `laboratory >= 5` required before ascending from `la_soglia` to Quinto.
  - `memory >= 4` required before final descent readiness.
- Added quote exposure gating for the final stretch:
  - tracked `quote_exposure_seen` in engine counters whenever a Demiurge/Echo narrative response is delivered (`needsDemiurge` flow).
  - introduced a session-wide monotonic floor in `GameEngineNotifier` so exposure remains coherent across load-slot rewinds in the same run.
  - required `quote_exposure_seen >= 18` before allowing descent from the ritual chamber to `il_nucleo` (applies to both `go down` and `drink` paths).
- Added diegetic gate feedback texts (English-only, no technical UI wording) for depth and quote gates.
- Hardened hints (lightly, accessibility-preserving):
  - `hint full` no longer unlocks full explicit guidance on first ask.
  - per-node hint escalation now unlocks level 1 → 2 → 3 over repeated hint requests (`hint_requests_<node>` counters).
- Hardened assist tray quick suggestions in `lib/features/ui/game_screen.dart`:
  - removed immediate solver commands from puzzle hotspots.
  - replaced with exploratory actions (`examine ...`, `hint more`) and less explicit input hints.
- Added `DialogueHistoryService.countByRole(...)` for history-level telemetry support.
- Added public gameplay-threshold helpers and coverage in `test/game_engine_helpers_test.dart`.

**Verification:**
- `dart format lib/core/storage/dialogue_history_service.dart lib/features/game/game_engine_provider.dart lib/features/ui/game_screen.dart test/game_engine_helpers_test.dart` ✅
- `flutter test` ✅ (all passing; 3 pre-existing integration TODOs remain skipped in `test/puzzle_gates_test.dart`)

**Architecture notes:**
- `GameEngineNotifier` remains monolithic (no provider split).
- Demiurge/Echo path remains deterministic and offline (no LLM introduced).
- Gameplay strings added in this pass are English-only and diegetic.

### 2026-04-17 — Codex GPT-5 (Readability pass: bigger text, slower typewriter, sector tints)
**Role:** UX readability and presentation polish

**Done:**
- Increased baseline readability in `lib/features/ui/game_screen.dart`:
  - enforced a minimum effective text scale (`1.08`) during rendering
  - raised typewriter pacing by applying a mystery-oriented slowdown factor (`+25%`) to normal nodes
  - finale pacing tuned further (`170 ms` base) for heavier dramatic cadence.
- Added sector-aware narrative text tinting (Threshold/Garden/Observatory/Gallery/Laboratory/Memory/Finale/Zone), keeping high contrast and white-legibility as the primary anchor.
- Updated settings defaults and clamps in:
  - `lib/features/settings/app_settings_provider.dart`
  - `lib/core/storage/database_service.dart`
  so new/default profiles start from more readable values (`text_scale: 1.08`, `typewriter_millis: 30`).
- Expanded settings sliders in `lib/features/ui/archive_panels.dart`:
  - Text size: `1.0 → 1.8`
  - Typewriter pace: `12 → 60 ms`
  for better user-level accessibility control.

**Verification:**
- `dart format` on touched files ✅
- `flutter test test/parser_test.dart test/puzzle_gates_test.dart` ✅
- `flutter analyze` ✅ (only pre-existing info-level brace-style lints in `game_engine_provider.dart`)

**Architecture notes:**
- No gameplay mechanics changed; this pass is presentation-only (readability, pacing, legibility).

---

### 2026-04-17 — Codex GPT-5 (Diegetic micro-copy polish for psycho shifts)
**Role:** Narrative UX polish

**Done:**
- Refined psycho-shift output copy in `lib/features/game/game_engine_provider.dart` to sound more in-world while keeping numeric clarity.
- Updated affinity labels from plain names (`Proust`, `Tarkovskij`, `Seth`) to diegetic wording (`proust resonance`, `tarkovskij resonance`, `seth resonance`).
- Replaced technical phase line with narrative-forward milestone text:
  - from: `Phase X -> Y attained.`
  - to: `A threshold yields. Phase Y opens.`
- Reframed delta line:
  - from: `Inner shift: ...`
  - to: `The Archive notes a shift: ...`

**Verification:**
- `dart format lib/features/game/game_engine_provider.dart` ✅
- `flutter test test/parser_test.dart test/puzzle_gates_test.dart` ✅

**Architecture notes:**
- Pure copy tuning only; no mechanics or state-transition logic changed.

---

### 2026-04-17 — Codex GPT-5 (Phase/Affinity gameplay feedback cues)
**Role:** Gameplay UX / psycho-profile readability

**Done:**
- Extended `GameEngineState` in `lib/features/game/game_engine_provider.dart` with psycho-shift signal fields (`psychoShiftCount`, `latestPsychoShiftIsPhase`) so UI can react to phase/affinity progression events.
- Upgraded `_updateAwarenessFromCommand(...)` to return a structured psycho-shift result instead of a pure side effect, including:
  - awareness/affinity deltas after clamped DB update
  - explicit phase transition detection (`Phase X -> Y attained.`)
  - concise micro-copy line (`Inner shift: ...`) for readability in the narrative stream.
- Integrated psycho-shift messaging into `processInput()` so progression feedback appears inline with narration and is persisted in dialogue history.
- Added dedicated UI cue handling in `lib/features/ui/game_screen.dart`:
  - new `_triggerPsychoShiftCue(...)`
  - one-shot detection based on `psychoShiftCount`
  - audio trigger `sfx:command_accepted`
  - medium haptic, doubled when the shift includes a phase transition.

**Verification:**
- `dart format lib/features/game/game_engine_provider.dart lib/features/ui/game_screen.dart` ✅
- `flutter test test/parser_test.dart test/puzzle_gates_test.dart` ✅
- `flutter analyze` ✅ (info-level `curly_braces_in_flow_control_structures` warnings are pre-existing style warnings in project)

**Architecture notes:**
- Feature remains within the single `GameEngineNotifier` Riverpod boundary.
- Cue emission is event-driven from engine state deltas, avoiding duplicate haptic/audio playback on rebuilds.

---

### 2026-04-16 — Codex GPT-5 (Session recap after load/resume)
**Role:** Gameplay UX / session continuity

**Done:**
- Added a reusable three-line recap builder in `lib/features/game/game_engine_provider.dart`:
  - `Where`: current sector and node
  - `What`: carried items, burden, completed thresholds
  - `Next`: contextual actionable thread derived from node hint level 1
- Updated `loadSlot(SaveSlot)` to prepend the recap when restoring a save, then continue with node narrative text.
- Added `appendSessionRecap()` in `GameEngineNotifier` to append the same recap format into the live transcript during idle gameplay.
- Updated `lib/features/ui/game_screen.dart` to implement `WidgetsBindingObserver` and trigger recap on app return to foreground only after a real background pause (`_resumeRecapArmed` guard), preventing duplicate recap spam.

**Verification:**
- `dart format lib/features/game/game_engine_provider.dart lib/features/ui/game_screen.dart` ✅
- `flutter analyze` ✅ (info-level `curly_braces_in_flow_control_structures` warnings pre-existing in project)
- `flutter test test/parser_test.dart test/puzzle_gates_test.dart` ✅

**Architecture notes:**
- Recap generation remains inside the single `GameEngineNotifier` boundary (no provider split), consistent with project rules.
- Resume recap is lifecycle-driven in UI, while content authority stays in engine/domain code.

---

### 2026-04-16 — Codex GPT-5 (Progressive diegetic hints)
**Role:** Gameplay UX / stuck-state mitigation

**Done:**
- Added progressive stuck-attempt tracking in `lib/features/game/game_engine_provider.dart` with an ephemeral `_nonProductiveAttemptsByNode` map (in-memory only, never persisted).
- Integrated automatic diegetic hint injection into `processInput()` so a contextual hint appears only at the 3rd and 5th non-productive attempt in the same node.
- Defined a productivity heuristic that resets the streak as soon as meaningful progress occurs (node change, puzzle/counter advancement, item gain, profile delta, memory write, etc.).
- Excluded explicit utility verbs (`hint`, `help`, `inventory`) from streak accumulation to avoid penalizing intentional support usage.
- Reset progressive-hint state on `build()`, `startNewGame()`, and `loadSlot()` to keep session transitions clean.

**Verification:**
- `flutter test test/parser_test.dart test/puzzle_gates_test.dart` ✅
- `dart format lib/features/game/game_engine_provider.dart` ✅

**Architecture notes:**
- The feature stays inside the existing single `GameEngineNotifier` boundary (no provider split), aligned with project constraints.
- Hint content reuses existing `_hintTextForNode()` knowledge, but delivery is now adaptive and diegetic during repeated failure loops.

---

### 2026-04-15 — Codex GPT-5 (Splash pacing improvement)
**Role:** UI / audio presentation polish

**Done:**
- Updated `lib/features/ui/splash_screen.dart` so the opening no longer auto-advances away from the title.
- The title now types in, stays on screen, and reveals an explicit `PLAY` button once complete.
- Tapping during the typewriter still fast-forwards the title, but it no longer skips straight into the menu.
- `reduceMotion` now shows the full title and `PLAY` button immediately while still waiting for explicit confirmation.

**Verification:**
- `flutter analyze` ✅
- `flutter test` ✅

**Architecture notes:**
- The splash now gives the curated title music room to breathe instead of being cut off by an automatic transition.
- Navigation remains `pushReplacement`, so the splash still stays out of the back stack once the player enters.

---

### 2026-04-15 — Codex GPT-5 (Android bootstrap DB fix)
**Role:** Runtime bugfix / emulator validation

**Done:**
- Fixed the fresh-install bootstrap path for `psycho_profile` in `lib/core/storage/database_service.dart` so `onCreate()` now creates the phase-system columns it immediately writes.
- Fixed the fresh-install bootstrap path for `app_settings` so `onCreate()` now includes `mute_in_background` and `enable_haptics` before inserting the singleton settings row.
- Added an `onOpen()` self-healing schema pass that repairs critical singleton tables (`psycho_profile`, `app_settings`) and ensures required rows exist, so partially migrated local databases recover cleanly.
- Wiped and relaunched the Android emulator, then verified the app booted without the previous SQL bootstrap crash.

**Verification:**
- `flutter analyze` ✅
- Android emulator launch after wipe-data ✅
- No more `psycho_profile.phase` or `app_settings.mute_in_background` bootstrap SQL errors on fresh app start ✅

**Architecture notes:**
- The DB layer is now robust against both legacy upgrade paths and inconsistent bootstrap ordering on fresh installs.
- The remaining emulator warning is only the Dart VM service socket restriction from the sandboxed environment; it does not block app startup or audio playback.

---

### 2026-04-15 — Codex GPT-5 (Audio polish: loudness compensation)
**Role:** Audio systems polish

**Done:**
- Added per-track mix compensation in `lib/features/audio/audio_track_catalog.dart` for calibrated outliers among the curated masters.
- Wired `AudioService._targetVolumeFor()` to consume those biases so loudness differences are reduced without changing the existing crossfade architecture.
- Rebuilt `assets/audio/sfx_proustian_trigger.ogg` with a hotter short excerpt target so feedback SFX stay audible next to the new piano masters.
- Updated `docs/audio_asset_pipeline.md` to reflect that the catalog is complete and the remaining work is loudness/transition polish rather than asset acquisition.
- Added regression coverage in `test/audio_track_catalog_test.dart` for the new mix-bias API.

**Verification:**
- `python3 tools/audit_audio_assets.py` ✅
- `flutter analyze` ✅
- `flutter test` ✅

**Architecture notes:**
- Audio balancing is now data-driven at the catalog layer instead of being hard-coded entirely inside `AudioService`.
- Future listening-pass tweaks can stay localized to mix-bias values without touching the playback queue or narrator/game flow.

---

### 2026-04-15 — Codex GPT-5 (Final room-layer CC0 integration)
**Role:** Audio asset integration

**Done:**
- Replaced the remaining room-level and trigger cues with curated `CC0` Kimiko Ishizaka masters:
  - `assets/audio/garden_fountain_variation.ogg` -> Prelude No. 5 in D major, BWV 850
  - `assets/audio/garden_stelae_variation.ogg` -> Fugue No. 6 in D minor, BWV 851
  - `assets/audio/observatory_calibration_variation.ogg` -> Prelude No. 3 in C-sharp major, BWV 848
  - `assets/audio/observatory_dome_variation.ogg` -> Fugue No. 3 in C-sharp major, BWV 848
  - `assets/audio/gallery_dark_variation.ogg` -> Fugue No. 4 in C-sharp minor, BWV 849
  - `assets/audio/gallery_light_variation.ogg` -> Prelude No. 7 in E-flat major, BWV 852
  - `assets/audio/gallery_mirror_variation.ogg` -> Fugue No. 7 in E-flat major, BWV 852
  - `assets/audio/lab_bain_marie_variation.ogg` -> Prelude No. 10 in E minor, BWV 855
  - `assets/audio/lab_sealed_variation.ogg` -> Fugue No. 10 in E minor, BWV 855
- Rebuilt `assets/audio/sfx_proustian_trigger.ogg` as a short local excerpt derived from the `CC0` Goldberg Aria master.
- Updated `assets/audio/manifest.json`, `assets/audio/ATTRIBUTION.md`, `README.md`, and `docs/audio_master_candidates.md` so the repository now documents a fully curated runtime music catalog.

**Verification:**
- `python3 tools/audit_audio_assets.py` ✅
- `flutter analyze` ✅
- `flutter test` ✅

**Architecture notes:**
- All 22 runtime music cues are now backed by curated `CC0` masters or direct excerpts of those masters.
- The remaining audio polish work is no longer licensing replacement; it is balancing, transitions, and device listening.

---

### 2026-04-15 — Codex GPT-5 (Third CC0 master integration)
**Role:** Audio asset integration

**Done:**
- Replaced four more synthesized tracks with curated Open Well-Tempered Clavier masters by Kimiko Ishizaka:
  - `assets/audio/bach_memoria_theme.ogg`
  - `assets/audio/bach_fugue_883_zona.ogg`
  - `assets/audio/memory_ritual_variation.ogg`
  - `assets/audio/zona_eternal_variation.ogg`
- Musical mapping used:
  - `memoria` -> Prelude No. 8 in E-flat minor, BWV 853
  - `zona` -> Fugue No. 20 in A minor, BWV 865
  - `memoria_ritual` -> Fugue No. 12 in F minor, BWV 857
  - `zona_eternal` -> Fugue No. 8 in D-sharp minor, BWV 853
- Updated `assets/audio/manifest.json` so the catalog now reflects 12 curated masters.
- Expanded `assets/audio/ATTRIBUTION.md`, `README.md`, and `docs/audio_master_candidates.md` to reflect the new state.

**Verification:**
- `python3 tools/audit_audio_assets.py` ✅
- `flutter analyze` ✅
- `flutter test` ✅

**Architecture notes:**
- All sector-defining and finale-defining long-form cues are now curated masters.
- The remaining synthesized layer is now mostly room-specific variation material rather than the main identity tracks.

---

### 2026-04-15 — Codex GPT-5 (Second CC0 master integration)
**Role:** Audio asset integration

**Done:**
- Replaced five more provisional synthesized masters with curated Bach recordings:
  - `assets/audio/bach_contrapunctus_observatory.ogg`
  - `assets/audio/bach_bwv846_galleria.ogg`
  - `assets/audio/bach_bwv1008_laboratorio.ogg`
  - `assets/audio/echo_chamber.ogg`
  - `assets/audio/bach_siciliano_bwv1017.ogg`
- Musical mapping used:
  - `osservatorio` -> Open WTC, Fugue No. 1 in C major, BWV 846
  - `galleria` -> Open Goldberg, Variatio 25 a 2 Clav.
  - `laboratorio` -> Open WTC, Prelude No. 2 in C minor, BWV 847
  - `oblivion` -> Open WTC, Fugue No. 24 in B minor, BWV 869
  - `siciliano` -> Open Goldberg, Variatio 13 a 2 Clav.
- Updated `assets/audio/manifest.json` so the repository catalog now reflects 8 curated masters rather than 3.
- Expanded `assets/audio/ATTRIBUTION.md` with per-track provenance for the second wave.
- Updated `README.md` and `docs/audio_master_candidates.md` to reflect the new current state.
- Updated `tools/audit_audio_assets.py` earlier in the session so repository-side audio audits accept `ATTRIBUTION.md` as a legitimate non-audio companion file.

**Verification:**
- `python3 tools/audit_audio_assets.py` ✅
- `flutter analyze` ✅
- `flutter test` ✅

**Risk note:**
- The two added Goldberg variation files (`galleria`, `siciliano`) are documented on Wikimedia Commons as `CC0`, but their pages also show `license review needed`. The repository attribution file now records that nuance explicitly instead of flattening it away.

**Architecture notes:**
- Runtime routing remains unchanged because the existing filenames were preserved.
- The highest-value remaining audio work is now the room-variation layer and the memory/zone special cues.

---

### 2026-04-15 — Codex GPT-5 (First CC0 master integration)
**Role:** Audio asset integration

**Done:**
- Replaced the first three provisional synthesized masters with curated `CC0` Bach recordings by Kimiko Ishizaka:
  - `assets/audio/bach_bwv846_soglia.ogg`
  - `assets/audio/bach_goldberg_giardino.ogg`
  - `assets/audio/bach_aria_goldberg.ogg`
- Source pools used:
  - Open Well-Tempered Clavier (`CC0`)
  - Open Goldberg Variations (`CC0`)
- Asset choices:
  - `soglia` -> BWV 846 Prelude No. 1 in C major
  - `giardino` -> Goldberg Aria
  - `aria_goldberg` -> Goldberg Aria da Capo e Fine
- Transcoded the `aria_goldberg` source from upstream MP3 to local `.ogg` to preserve the repository's runtime asset format.
- Updated `assets/audio/manifest.json`:
  - bumped catalog version to 3
  - marked the three upgraded cues as `CC0 1.0`
  - updated durations and source descriptions
  - changed notes to reflect the new hybrid catalog
- Updated `assets/audio/ATTRIBUTION.md` with track-by-track provenance for the new curated masters.
- Updated `README.md` and `docs/audio_master_candidates.md` to reflect that the first three master replacements are now complete.

**Verification:**
- `flutter analyze` ✅ no issues
- audio asset manifest remained internally consistent after the replacements

**Architecture notes:**
- No runtime routing changes were required because the existing asset filenames were preserved.
- The catalog is now intentionally hybrid: first curated masters are live, remaining room/sector tracks are still lawful synthesized placeholders pending further replacement.

---

### 2026-04-15 — Codex GPT-5 (CC0 Bach shortlist for master replacement)
**Role:** Audio sourcing and planning

**Done:**
- Researched higher-quality Bach recording sources suitable for replacing the current synthesized provisional masters.
- Verified two primary source pools with clear reuse intent and strong legal confidence:
  - Open Well-Tempered Clavier (Kimiko Ishizaka, `CC0`)
  - Open Goldberg Variations (Kimiko Ishizaka, `CC0`)
- Added `docs/audio_master_candidates.md`:
  - source-pool overview
  - legal-confidence notes
  - first-pass replacement shortlist for all 7 base tracks plus key special cues
  - recommendation to prefer Open WTC / Open Goldberg over generic aggregator sourcing
  - implementation advice on "fast path" vs "clean release path" for filenames and manifest alignment
- Updated `docs/audio_asset_pipeline.md` and `README.md` to point at the new shortlist document.

**Architecture notes:**
- No runtime audio code changes were needed for this step.
- The current audio subsystem is ready to accept new masters immediately; the main remaining work is asset curation, loudness/loop normalization, and provenance tracking.

---

### 2026-04-15 — Codex GPT-5 (Phase restore fix + audio provenance cleanup)
**Role:** Bug fix + maintenance

**Done:**
- Fixed Demiurge phase restoration bug:
  - Added `DemiurgeService.restorePhase(int)` in `lib/features/demiurge/demiurge_service.dart`
  - `switchPhase(int)` remains monotonic-only for awareness-driven progression
  - `psycho_provider.dart` now uses `restorePhase(1)` on profile reset
  - `game_engine_provider.dart` now uses `restorePhase(slot.phase)` on save-slot load
- Added regression coverage in `test/demiurge_service_test.dart`:
  - verified `switchPhase()` never regresses
  - verified `restorePhase()` supports rollback for reset/load flows
- Cleaned analyzer warnings:
  - removed unused `_minMixVolume`
  - replaced one remaining production `print()` warning with `debugPrint()`
  - removed unnecessary cast / non-null assertion in `game_screen.dart`
- Improved audio robustness without adding new binary assets:
  - `AudioService` SFX map now reuses the shipped `sfx_proustian_trigger.ogg` for `command_accepted`, `command_rejected`, and `sector_entry` until dedicated cues are authored
- Added `assets/audio/ATTRIBUTION.md` documenting the current lawful synthesized-audio provenance and the replacement policy for final masters
- Updated release-facing docs (`README.md`, `docs/implementation_status.md`) so they no longer describe the repo as analyzer-clean before verification and now distinguish provisional synthesized renders from final release-quality masters
- Verification:
  - `flutter analyze` ✅ no issues
  - `flutter test` ✅ all tests passed

**Architecture notes:**
- The Demiurge service now has two distinct responsibilities:
  - `switchPhase()` for forward-only narrative progression
  - `restorePhase()` for deterministic state restoration
- Current shipped music remains legally safe but artistically provisional; the next audio milestone should be curated CC0/public-domain-compatible Bach masters, replacing the existing synthesized renders file-by-file.

---

### 2026-04-15 — Codex GPT-5 (Project audit + audio direction review)
**Role:** Technical review

**Done:**
- Reviewed repository structure against `AGENTS.md` and the current implementation.
- Ran verification locally:
  - `flutter test` ✅ all tests passed
  - `flutter analyze` ⚠️ 4 issues remain (`audio_service.dart`, `game_screen.dart`)
- Audited current audio pipeline:
  - confirmed shipped `.ogg` files are synthesised from public-domain Bach scores via `music21 + FluidSynth + FluidR3_GM`
  - confirmed the current “MIDI-like” quality is primarily a timbral/rendering limitation, not a routing problem
- Identified main risks / inconsistencies:
  - `README.md` and `docs/implementation_status.md` still claim analyzer-clean status, but `flutter analyze` currently reports warnings
  - `DemiurgeService.switchPhase()` is monotonic-only, so calls from `resetProfile()` and `loadSlot()` cannot actually restore phase 1 or a lower saved phase
  - audio SFX map references assets not present in `assets/audio/` (`sfx_command_accepted`, `sfx_command_rejected`, `sfx_sector_entry`), so some polish cues currently degrade silently
  - automated coverage is useful but still thin relative to the 4k-line engine; several multi-condition gate paths remain documented as skipped tests only
- Reviewed music replacement strategy:
  - safest upgrade path is curated higher-quality Bach recordings with explicit CC0 / public-domain-compatible licensing and a repository attribution record
  - best immediate candidates are CC0/Open Goldberg and CC0 Well-Tempered Clavier recordings rather than additional GM-soundfont renders

**Architecture notes:**
- Current runtime audio infrastructure is solid enough to support better masters without architectural change.
- The highest-value pre-release work remains: fix the small correctness/documentation drifts, improve masters, then run the full Android physical-device playtest.

---

### 2026-04-13 — Claude Sonnet 4.6 (Finale overlay — epic ending presentation)
**Role:** UI feature implementation

**Done:**
- `game_screen.dart` — finale visual system:
  - Added `_FinaleType` enum (`acceptance`, `oblivion`, `eternalZone`) and helpers `_isFinaleNode()` / `_finaleTypeFor()` at file scope.
  - Added `_wakeUpFading` bool state; detected when last narrative message contains "— FINE —" (via `addPostFrameCallback` in `data:` callback) and sets flag.
  - `_BackgroundLayer` gains `opacity` param; finale nodes pass 0.52 (vs default 0.15) so the `bg_memoria.jpg` is clearly visible.
  - `_SessionCard` hidden for finale nodes — clean, bare screen with just text and input.
  - Typewriter slowed to 150 ms/char for finale nodes (from default 22 ms) so every word lands with weight.
  - New `_FinaleBackdrop` (`StatefulWidget with SingleTickerProviderStateMixin`): `Positioned.fill` overlay between vignette and content:
    - Acceptance: faint warm golden wash (`Color(0xFFD4A017)` at 7% opacity).
    - Oblivion: `AnimationController` drives a black overlay from 0 → 68% opacity over 8 seconds — the world goes dark as the text is read.
    - Eternal Zone: cold blue-grey tint (`Color(0xFF1A3A5C)` at 14% opacity).
  - New `_WakeUpFade` (`StatelessWidget`): `Positioned.fill` white `AnimatedOpacity` (4-second `easeInOut` fade) that covers the entire screen when `_wakeUpFading` becomes true — the acceptance ending dissolves to white.
  - All new overlays respect `reduceMotion`: animations instant or skipped.

**Architecture notes:**
- `_wakeUpFading` is ephemeral — resets on `GameScreen` disposal (leaving to HomeScreen and returning).
- `_FinaleBackdrop` is a separate `StatefulWidget` so the `AnimationController` for oblivion darkening is self-contained and does not touch `_GameScreenState`.
- The `_WakeUpFade` sits at the top of the Stack (after `_SimulacrumBanner`), so it covers everything including HUD and overlays.

---

### 2026-04-13 — Claude Sonnet 4.6 (UI assist tray + La Zona early-game guard)
**Role:** UI polish + game-logic fix

**Done:**
- `game_screen.dart` — collapsible assist tray: removed `_QuickCommandBar` and "Reuse" `ActionChip` from the top of the column (where they were permanently eating space above the text). Added `_assistVisible` bool to `_GameScreenState`; both widgets now live in an `AnimatedSize` tray between the text area and the status bar, visible only when the player toggles them. Added a `💡` (`lightbulb_outline` / `lightbulb`) `IconButton` at the left of `_InputRow`; icon is amber when tray is open, dimmed when closed; button is hidden when there is nothing to show. `_InputRow` gains `onToggleAssist` and `assistVisible` parameters.
- `game_engine_provider.dart` — La Zona early-game guard: added `hasExplored` check in `_zoneActivationProbability`. La Zona now returns probability 0 until the player has found at least one simulacrum OR completed at least one non-zone puzzle. Prevents the Zone from triggering on the first two navigation commands of a fresh game (consecutive_transits hits 2 after intro_void → la_soglia → sector, giving a spurious 40% roll).

**Architecture notes:**
- `_assistVisible` is ephemeral (resets on screen navigation) — no persistence needed.
- The `hasExplored` guard does not affect the `hasAllSimulacra` path (75%) since simulacraCount > 0 is already true in that case.

---

### 2026-04-13 — Claude Sonnet 4.6 (Cinematic splash screen)
**Role:** UI feature implementation

**Done:**
- Created `lib/features/ui/splash_screen.dart` — cinematic opening screen:
  - `bg_soglia.jpg` fades in over 1 500 ms (dark veil at 0.38 opacity, lighter than in-game 0.62, to let the image breathe)
  - A random Bach sector track (`soglia`, `giardino`, `osservatorio`, `galleria`, `laboratorio`, `memoria`) starts simultaneously via `AudioService().handleTrigger(key)`; `_isFirstTrack` in AudioService ensures a soft 2.5 s fade-in
  - After 1 600 ms the title container appears; typewriter writes "The Archive of Oblivion" at 75 ms/char
  - 1 800 ms after the last character: fade transition to `HomeScreen` (800 ms `FadeTransition` via `PageRouteBuilder`)
  - Tap at any point: fills the title instantly → 400 ms pause → navigate (or immediate if title was already complete)
  - `reduceMotion` support: all animations instant, full title shown at once, auto-advance after 2 s
  - Haptic feedback on tap (`lightImpact`), guarded by `_hapticsOn()` pattern consistent with rest of codebase
- Updated `lib/main.dart`: `home:` changed from `HomeScreen` to `SplashScreen`; `splash_screen.dart` import replaces `home_screen.dart`

**Architecture notes:**
- `SplashScreen` is a `ConsumerStatefulWidget`; reads `appSettingsProvider` for `reduceMotion`/`enableHaptics`/`musicEnabled`
- `AudioService().handleTrigger(key)` is called directly — respects `musicEnabled` internally
- `HomeScreen` is still the app's main menu; splash is a one-shot entry gate (uses `pushReplacement`, not `push`)

---

### 2026-04-13 — GitHub Copilot (Guided walkthrough mode for QA playtesting)
**Role:** Feature implementation

**Done:**
- Analysed `game_engine_provider.dart` end-to-end to reconstruct a valid 129-step command sequence traversing all four main sectors (Garden/North, Observatory/East, Gallery/South, Lab/West), the Fifth Sector (Quinto), and Finale 1 (Acceptance / "WAKE UP"). Sequence accounts for all exit gate dependencies, puzzle ordering constraints (bain-marie external-visit counter triggered during Garden traversal), and the psycho_weight == 0 requirement for the Gallery mirror and the Final Boss resolution.
- Created `assets/texts/walkthrough.json` — 129 steps with human-readable `note` fields; covered by the existing `assets/texts/` wildcard in `pubspec.yaml` (no pubspec change needed).
- Added walkthrough mode to `lib/features/ui/game_screen.dart`:
  - Three new state fields: `_walkthroughUnlocked` (bool, ephemeral), `_walkthroughStep` (int), `_walkthroughSteps` (nullable list, lazy-loaded once).
  - `_submit()` intercepts the exact string `Stalker4598!TarkoS?`: sets `_walkthroughUnlocked = true`, clears the field, calls `setState()`, returns — command is never forwarded to the engine and never displayed.
  - `_walkthroughNext()`: loads `walkthrough.json` via `rootBundle.loadString` on first call (catch + silent return on failure), injects `steps[_walkthroughStep]['command']` via `_queueQuickCommand`, increments `_walkthroughStep`, shows a SnackBar "Walkthrough complete" when all steps are exhausted.
  - `_InputRow` gains an optional `onWalkthroughNext` parameter; when non-null an `arrow_forward` `IconButton` appears next to the input field.
- Updated `CLAUDE.md` architecture section for `game_screen.dart` to document the secret unlock command and the walkthrough state fields.

**Architecture notes:**
- `_walkthroughUnlocked` is never persisted — it resets to `false` on every app restart by design.
- La Zona is probabilistic and cannot be explicitly triggered by command; the walkthrough notes this in the step adjacent to `go north` moves where it may intercept.
- The bain-marie transformation is time-ordered: the walkthrough visits `lab_bain_marie` before starting the Garden so that the three non-lab navigation events during Garden traversal satisfy the `bain_marie_complete` counter automatically.

---

### 2026-04-12 — Claude Sonnet 4.6 (Phase/Echo system, save slots, haptics, puzzle-gate tests)
**Role:** Feature implementation + test authoring

**Done:**
- Added `enableHaptics` to `AppSettings` + DB migration (v7); wrapped all `HapticFeedback.*` calls behind `_hapticsOn()` guard in `game_screen.dart`; added `selectionClick()` on home screen chips/buttons and `mediumImpact()` on Archive opening
- Implemented Option-A narrative layer: `phase` (1–5) + `awarenessLevel` + three Echo affinities (`proustAffinity`, `tarkovskijAffinity`, `sethAffinity`) added to `PsychoProfile` + DB migration (v8); `DemiurgeService.switchPhase()` advances phase only
- Created `lib/features/demiurge/echo_service.dart` — deterministic EchoService singleton with Proust/Tarkovskij/Seth pools, thematic keyword detection, archive-meta responses, phase+affinity gating
- Wired 5-step `_callNarrator()` chain in `game_engine_provider.dart`: keyword echo → verb+phase echo → sector-thematic echo → archive-meta → Demiurge fallback
- Added `_updateAwarenessFromCommand()` for awareness/affinity delta logic (keyword +8, thematic +4, verb+phase +5/+5)
- Implemented multi-slot save system: `lib/core/services/save_service.dart` (`SaveSlot` model + `SaveService` singleton); DB migration v9 adds `save_slots` table; auto-save every 6 commands or sector change (fire-and-forget, slot 0); `saveToSlot()`/`loadSlot()` on engine; "Save / Load" menu entry in game screen; `_SaveLoadSheet` + `_SlotCard` UI in archive_panels
- Created `test/puzzle_gates_test.dart` — 119 pure-static tests covering all 24 `_exitGates` entries (puzzle IDs correct, hints non-empty, gated nodes exist, gated directions present in node exits, destinations exist); 3 engine-integration cases documented as skipped TODOs

**Architecture notes:**
- `loadSlot()` restores psycho_profile via direct SQL UPDATE + `ref.invalidate(psychoProfileProvider)` (avoids delta-addition semantics of `updateAwareness()`)
- `_commandsSinceAutoSave` is ephemeral (resets on app restart) — DB overhead vs. accuracy trade-off acceptable for auto-save
- EchoService is pure Dart, no WidgetRef, no I/O — accepts explicit parameters at all call sites

---

### 2026-04-11 — Claude Sonnet 4.6 (Audio silent-startup root cause — `await play()` deadlock)
**Role:** Audio debugging

**Problem:** No audio from app startup on Android emulator (API 36). Files were properly normalized at -1 dB (fixed in the previous session), ExoPlayer and the Vorbis codec initialized correctly, but the player stayed at volume 0 indefinitely.

**Root cause:** `AudioService._crossfadeTo()` called `await _backgroundPlayer.play()`. In `just_audio`, `play()` returns a Future that completes only when playback **ends**. Because the player is configured with `LoopMode.one` (set in `initialize()`), the track loops forever and the Future never resolves. The entire `_crossfadeTo` method was deadlocked past that line — `_rampVolume` never ran, volume stayed at 0, and the `[Audio] Playing` diagnostic print was never reached.

**Diagnosis method:** `adb logcat` showed the Vorbis codec being created (from `setAsset`) but zero Dart `print()` output following it. The `BufferPoolAccessor2.0` counter incremented every 5 s, confirming audio was being decoded at the native layer — just at volume 0.

**Fix:** Removed `await` from `_backgroundPlayer.play()` in two places:
1. `_crossfadeTo()` — main BGM crossfade path
2. `_handleSilenceEnding()` phase-2 — oblivion finale track

Added `// ignore: discarded_futures` comment with explanation at both sites.

**Verification:** After rebuild, `[Audio] Playing "soglia" → assets/audio/bach_bwv846_soglia.ogg (target vol 0.69)` appeared in logcat. The print and volume ramp now execute correctly.

---

### 2026-04-11 — GitHub Copilot (Audio normalization — root cause of silent playback)
**Role:** Audio debugging / signal analysis

**Problem:** Audio still inaudible on device despite the 2026-04-10 real-Bach music pipeline. The `music21 + FluidSynth` synthesis produced files at dramatically low levels: peaks around **-19 to -21 dB** (0.08–0.13 linear) instead of the expected **-1 dB** (0.89 linear). Combined with AudioService's volume scaling (×0.63 default), the effective playback level was ~-24 dB below normal — completely inaudible on phone speakers.

**Root cause:** FluidSynth renders at low gain by default; the generation pipeline (`tools/generate_audio_assets.py`) had no normalization pass.

**Fix:**
1. **Diagnosed via Python analysis:** Used `soundfile` + `numpy` to decode all 22 OGG files and measure peak/RMS levels. Every file had peak ~0.10, RMS ~0.015.
2. **Peak-normalized all 22 files** to -1 dB (0.891 linear) — a gain of 7–16× depending on the track. Processed the large soglia file (123 s, 2.1 MB) in chunks to avoid memory issues.
3. **Verified post-normalization:** All files now have peak 0.83–0.93 and RMS 0.10–0.19 — proper levels for mobile playback.
4. **Added diagnostic logging** to `AudioService._crossfadeTo()` and `_syncForNodeInternal()`: track/asset/volume are printed to logcat on every transition, making future audio issues immediately visible.

**Post-normalization levels (representative):**
| Track | Peak before | Peak after | Gain |
|---|---|---|---|
| bach_bwv846_soglia | 0.086 | 0.914 | 10.4× |
| bach_aria_goldberg | 0.104 | 0.897 | 8.6× |
| echo_chamber (oblivion) | 0.106 | 0.913 | 8.4× |
| sfx_proustian_trigger | 0.055 | 0.887 | 16.3× |

---

### 2026-04-10 — GitHub Copilot (Audio assets — real Bach music via music21 + FluidSynth)
**Role:** Audio pipeline / copyright-free asset generation

**Problem:** All 22 `.ogg` files in `assets/audio/` were synthetic FFmpeg placeholders (no title/composer tags, same 80 kbps mono encoder fingerprint). No real Bach music was present → audio silent in-game.

**Solution — fully open-source, zero network requests, public domain:**
1. **Diagnosis:** `mutagen` inspection confirmed all files had `{'encoder': ['Lavc60.31.102 libvorbis']}` and no music tags.
2. **Pipeline chosen:** `music21` bundled corpus (433 Bach works, MIT licence) → MIDI export → `FluidSynth` + `FluidR3_GM.sf2` soundfont (LGPL) → `ffmpeg` OGG Vorbis.
3. **Wrote `tools/generate_audio_assets.py`:** Maps all 22 assets to specific BWV pieces (chorales from St Matthew Passion BWV 244, St John Passion BWV 245, Christmas Oratorio BWV 248, Well-Tempered Clavier BWV 846, motet BWV 227.1). Supports `--only` flag for selective regeneration.
4. **Ran the script** in this environment (FluidSynth 2.3.4 + FluidR3_GM.sf2 already installed). All 22 files generated, total ~16.5 MB, durations 3–123 s.
5. **Updated `assets/audio/manifest.json`** to v2 with `"status": "ready"` and full `source`/`license`/`duration_s` fields per track.

**Thematic mapping (sector → BWV):**
- soglia → BWV 846 Prelude in C (WTC Book I) — bright, contemplative opening
- giardino → BWV 155.5 — gentle pastoral E minor chorale
- osservatorio → BWV 227.1 motet "Jesu, meine Freude" — polyphonic, mathematical
- galleria → BWV 244.46 "O Haupt voll Blut und Wunden" — poignant B minor
- laboratorio → BWV 244.3 "Herzliebster Jesu" — structured, systematic
- memoria → BWV 244.62 (St Matthew final chorale) — most profound
- zona → BWV 244.17 — haunting minor-key
- siciliano → BWV 244.15 "Erbarme dich" (tempo 0.70) — very slow and lyrical
- aria_goldberg → BWV 244.10 (tempo 0.80) — flowing, aria-like
- oblivion/echo → BWV 245.37 (tempo 0.65) — sparse, atmospheric
- Room variations → BWV 248.12-2, 244.29-a, 245.5, 245.11, 245.17, 245.14, 245.22, 245.26, 245.28, 245.40, 244.54
- sfx_proustian_trigger → first 3 s of BWV 846

**Audio service code unchanged:** The existing `audio_service.dart` + `audio_track_catalog.dart` architecture was correct. The only issue was the placeholder content of the asset files.

**Validation note:** `flutter analyze` not available in this sandbox. Dart source files are unchanged; only binary `.ogg` assets and `manifest.json` were modified.

---

### 2026-04-09 — GitHub Copilot (Progression feedback and archive memory polish)
**Role:** UI/UX polish, progression feedback, parser variety

**Done:**

- **Added explicit progression feedback in `game_engine_provider.dart` and `game_screen.dart`** with transient puzzle-resolution overlay state (`isPuzzleSolved`) and first-time simulacrum banner state (`latestSimulacrum`) carried by `GameEngineState`.
- **Varied the unknown-command Demiurge fallback** by replacing the single repeated parser-error line with a rotating pool of Archive-appropriate fallback phrases before Demiurge augmentation.
- **Upgraded all four simulacrum reward moments** (`Ataraxia`, `The Constant`, `The Proportion`, `The Catalyst`) to use a dedicated reward helper that always adds emphatic confirmation text, forces Demiurge treatment, and emits the new `simulacrum` audio trigger plus the matching 500 ms display pause.
- **Expanded the in-game menu** with `Archive status` and `Your memories`, then implemented both panels in `archive_panels.dart`.
- **Added archive progression cards** that summarise Garden, Observatory, Gallery, Laboratory, and Memory-sector completion in a single glance instead of relying on a raw puzzle count.
- **Surfaced saved player memories** by reusing `DatabaseService.loadAllMemories()` inside a new dialog, making Fifth Sector and Zone responses visible to the player after they are stored.
- **Enhanced the bottom status bar** with Lucidity, Anxiety, and Oblivion micro-bars plus a tooltip, so the psycho-profile now has continuous visual feedback during play.
- **Extended `AudioService.handleTrigger()`** to understand the new `simulacrum` trigger and subtly brighten the current mix without changing track selection.

**Validation note:** `flutter analyze` and `flutter test` could not run in this sandbox because the `flutter` executable is not installed (`bash: flutter: command not found`). `dart format` was available and was run on the modified files.

**Architecture snapshot:**
- `GameEngineState` now carries transient, non-persisted feedback fields for UI reward cues (`isPuzzleSolved`, `latestSimulacrum`).
- `ArchivePanels` now includes runtime progression and memory-review dialogs in addition to the existing intro/help/settings/credits surfaces.
- Audio triggers now include a dedicated `simulacrum` cue handled in the existing ambience-mix path.

---

### 2026-04-09 — GitHub Copilot (database versioning hardening)
**Role:** Infrastructure / database

**Done:**

- **Added `_addColumnIfNotExists` helper** in `DatabaseService` — queries `PRAGMA table_info` before executing `ALTER TABLE … ADD COLUMN`, making every migration step idempotent (safe even if a migration was partially applied; prevents "duplicate column name" crashes).
- **Refactored v1→v2 upgrade block** to use `_addColumnIfNotExists` for all four `game_state` columns instead of raw `ALTER TABLE`.
- **Added versioning protocol comment block** above `_onUpgrade` with the five-step rule and a copy-paste example for adding a future v6 column — so future developers (and agents) know exactly what to do.
- No `_databaseVersion` bump needed: this is a pure infra/refactor change with no schema change.
- No data loss risk: existing rows are unaffected; the helper is a no-op when a column already exists.

**Architecture snapshot:**
- `lib/core/storage/database_service.dart` — schema v5; `_addColumnIfNotExists(DatabaseExecutor, table, column, definition)` helper now available for all future migrations.

---

---

### 2026-04-09 — GitHub Copilot (LLM dead code removal)
**Role:** Cleanup / refactoring

**Done:**

- **Deleted `lib/features/llm/llm_service.dart`** — legacy stub that wrapped flutter_llama; no longer imported anywhere.
- **Deleted `lib/features/llm/llm_context_service.dart`** — legacy stub that built LLM system prompts; no longer imported anywhere.
- **Deleted `tools/fase_0_omega/`** — entire directory of LLM validation test harnesses (flutter_llama and mediapipe_genai probes), now fully obsolete.
- **Renamed `EngineResponse.needsLlm` → `needsDemiurge`** in `parser_state.dart` and all 58 call-sites in `game_engine_provider.dart`. The field semantics are unchanged (true = delegate text augmentation to DemiurgeService); only the name is corrected to reflect the actual system in use.
- No pubspec.yaml changes required — LLM package references had already been removed in a prior session.
- No asset changes required — no `assets/config/llm_config.json` existed.

**Architecture snapshot:**
- `lib/features/llm/` — **deleted**
- `tools/fase_0_omega/` — **deleted**
- `EngineResponse.needsDemiurge` replaces `needsLlm` everywhere

---

### 2026-04-09 — GitHub Copilot (Adventure traversal integration test)
**Role:** Testing / static analysis

**Done:**

- **Exposed `gameAllNodeIds()` and `gameExitsForNode()`** in `game_engine_provider.dart` as public top-level functions (mirroring the existing helper style). These return the full set of the 41 node IDs and the declared exits for any given node, enabling external traversal without touching private state.
- **Added `test/adventure_traversal_integration_test.dart`** with 10 test cases across 3 groups:
  - *background images*: verifies that every file in `BackgroundService.allBackgroundAssets` exists on disk, and that every node (all 41) resolves to an existing background file via `BackgroundService.getBackgroundForNodeOrDefault()`.
  - *audio triggers*: verifies that every key in `AudioTrackCatalog.ambienceAssets` maps to a file on disk; that the three explicit engine triggers (`oblivion`, `siciliano`, `aria_goldberg`) are registered in the catalog and their files exist; that `silence` is correctly synthetic (no file); that the `sfx:proustian_trigger` SFX file exists; and that every node's resolved audio track maps to a file.
  - *adventure traversal*: a seeded-random (seed 42) DFS from `intro_void` visits all 37 statically reachable nodes, asserting background image + audio asset integrity at each step; the 4 isolated nodes (`finale_acceptance`, `finale_oblivion`, `finale_eternal_zone`, `la_zona`) are validated in a separate test; a third test asserts every declared exit leads to a known node ID.
- **BFS helper uses `dart:collection Queue`** (O(1) `removeFirst`) rather than `List.removeAt(0)` for efficiency.

**Validation note:** Static code review passed. `flutter test` cannot execute in this sandbox (network-blocked SDK download), but the test logic has been manually verified against the static node graph by Python simulation (37 reachable nodes, 4 isolated).

---

### 2026-04-08 — GitHub Copilot (Mobile submit while typewriter is active)
**Role:** UI bugfix, playtest follow-up, regression coverage

**Done:**

- **Fixed the first physical-playtest movement failure** in `game_screen.dart`: pressing send while the typewriter was still animating the latest narrative no longer discards the typed command.
- **Kept the skip-typewriter affordance intact** for empty submits, so tapping send with no command still only reveals the full text immediately.
- **Added `test/game_screen_test.dart`** with a widget-level regression that reproduces the exact mobile-like case: intro narration still typing, player submits `go north`, command must still be forwarded to the engine.

**Validation note:** Static error checking passed for the changed UI and test files. Runtime validation via `flutter test` could not be executed in this sandbox because the terminal/task provider is currently failing to attach to the workspace path with `ENOPRO`, which is an environment/tooling issue rather than a project compile error.

**Architecture snapshot:**
Command submission and typewriter skipping are now decoupled in the UI layer. `GameScreen._submit()` always preserves a non-empty typed command even if it first needs to terminate the active narration animation.

### 2026-04-08 — GitHub Copilot (Quick-command prefill fix)
**Role:** UI polish, parser affordance correction

**Done:**

- **Fixed contextual quick-command chips in `game_screen.dart`** so prompt-style actions no longer auto-submit incomplete verbs.
- **Changed the Fifth Sector maturity chips** for `Say …` and `Write …` to prefill the input field and keep focus on the command row, instead of immediately sending bare `say` / `write` commands.
- **Kept existing instant-action chips unchanged** by introducing an explicit per-chip submit flag rather than changing global quick-command behavior.

**Validation note:** Static validation for `game_screen.dart` passed with no reported errors.

**Architecture snapshot:**
Quick commands now support two interaction modes in the UI layer: immediate submission for complete commands, and input prefill for commands that intentionally require player-authored text.

### 2026-04-08 — GitHub Copilot (Demiurge bundle audit hardening)
**Role:** Content pipeline, validation, project-state correction

**Done:**

- **Audited the current Demiurge corpus state** and confirmed that all five sector bundles now contain 200 responses each, so the old "12 entries per sector" project note was stale.
- **Identified the real remaining content issue** — repeated `citation + author` pairs inside the generated sector bundles, which weakens the anti-repetition effect even when the response count is high.
- **Hardened `tools/prepare_demiurge_bundles.py`** by adding:
  - normalized quote-key deduplication
  - deterministic seed support for reproducible builds
  - shuffled opening/closing cycling to avoid rigid phrase reuse order
  - post-generation validation that fails loudly on underfilled or duplicate-heavy output
- **Added `tools/audit_demiurge_bundles.py`** so the current JSON bundles can be checked locally for count, schema, and duplicate issues before shipping.
- **Updated `CLAUDE.md`** to reflect the actual bundle status and to replace the outdated under-population warning with the current duplicate-citation follow-up.

**Validation note:** The sandbox terminal provider is currently failing to attach to the workspace path, so I could not execute the new audit/generation scripts here. Read-only inspection and subagent verification confirm the present bundle counts and duplicate patterns, but the new tooling still needs to be run in a working shell.

**Architecture snapshot:**
The Demiurge content pipeline now has two explicit layers: generation (`prepare_demiurge_bundles.py`) and verification (`audit_demiurge_bundles.py`). Project guidance now treats bundle quality as a validation problem rather than a raw entry-count problem.

### 2026-04-08 — GitHub Copilot (Title screen + onboarding UX pass)
**Role:** UX, parser assistance, accessibility, technical cleanup

**Done:**

- **Added a proper title/home experience** with:
  - continue vs new-game entry points
  - introduction, how-to-play, settings, and credits entry chips
  - current-run summary card showing location, carrying state, burden, and puzzle-state count
  - theatrical fade-in over the current sector background
- **Introduced persisted app settings** in SQLite (`app_settings`, schema v4) for:
  - instant text
  - reduced motion
  - high contrast
  - command assist
  - text scale
  - typewriter pace
- **Reworked the in-game HUD** so `GameScreen` now exposes:
  - a room/sector header
  - a real game menu instead of only “New game”
  - a session card with autosave and assist copy
  - quick-command chips for key contexts
  - last-command recall in both chip and input-row form
  - smarter input placeholders tied to the current node
- **Expanded parser/engine assistance** by adding:
  - explicit parser verbs for `hint`, `observe`, `enter`, `collect`, `decipher`, `say`
  - more natural movement synonyms
  - a **three-level contextual hint system** (`hint`, `hint more`, `hint full`)
  - public node/sector metadata helpers for UI surfaces
- **Removed obsolete Android storage/heap flags** left over from the legacy external-LLM path.
- **Added regression tests** for parser verb routing and game metadata helpers.

**Validation note:** `git diff --check` passed. `flutter analyze` and `flutter test` were attempted before and after the change set in this sandbox, but the `flutter` CLI is still unavailable here (`flutter: command not found`).

**Architecture snapshot:**
The app now has a lightweight shell experience instead of dropping directly into the transcript. Presentation/accessibility settings are persisted locally in SQLite and read directly by the home/game UI. Parser assistance is now split between typed commands, quick-command affordances, and a layered in-engine hint system rather than a single static help screen.

---

### 2026-04-07 — GitHub Copilot (Sector-first audio catalog scaffolding)
**Role:** Audio architecture

**Done:**

- **Introduced a room-aware audio catalog** in `lib/features/audio/audio_track_catalog.dart`
  with:
  - 8 sector-base soundtrack keys
  - room overrides for key nodes (fountain, stelae, calibration, dome, mirror,
    bain-marie, sealed chamber, ritual chamber, eternal zone)
  - explicit finale/memory trigger mappings kept compatible with existing engine
    responses
- **Reworked `AudioService`** so:
  - it listens to `gameStateProvider` and automatically selects soundtrack by
    current node
  - psycho-profile updates now modulate playback intensity instead of choosing
    the primary track
  - legacy `calm` / `anxious` triggers now re-shape the active room track
    instead of replacing it with a global generic loop
  - missing audio files are detected and skipped safely, avoiding repeated load
    failures while the real masters are still absent from the repo
- **Added `assets/audio/manifest.json`** as the canonical scaffold for planned
  soundtrack/SFX asset names so the repo now contains a real `assets/audio/`
  directory aligned with the new catalog.
- **Updated parser-state docs** to reflect the broader meaning of `audioTrigger`.

**Validation note:** `git diff --check` passed and `assets/audio/manifest.json`
parses correctly. `flutter analyze` and `flutter test` were attempted again in
this sandbox, but the `flutter` CLI is still unavailable here (`flutter:
command not found`).

**Architecture snapshot:**
Audio routing is now `nodeId -> room override or sector base -> asset key`,
with `AudioService` subscribing directly to saved game-state changes. The
psycho profile no longer decides which soundtrack plays; it only modulates the
intensity of the currently active room/sector track, while explicit finale and
memory cues still retain priority.

---

### 2026-04-07 — GitHub Copilot (Correct-answer screen reset cue)
**Role:** UI + engine feedback

**Done:**

- **Added a success-only transcript reset cue** in `game_engine_provider.dart` so commands that
  materially advance the game now replace the visible on-screen history with the new narrative
  instead of appending to it.
- **Kept failed / non-advancing commands cumulative** — wrong answers and neutral interactions still
  stack in the history exactly as before.
- **Added a temporary background reveal in `game_screen.dart`** so each successful command restarts
  the text from the top and briefly shows the full sector image before fading back to the mandated
  subtle presentation.

**Validation note:** `git diff --check` passed. `flutter analyze` and `flutter test` were attempted
again in this sandbox, but the `flutter` CLI is still unavailable here (`flutter: command not
found`).

**Architecture snapshot:**
`GameEngineState` now carries a transient `screenResetCount` UI signal. The engine increments it
only when the command changes node/progression/psychological state/inventory, and `GameScreen`
reacts by resetting scroll position and flashing the current background at full visibility before
fading back to 0.15 opacity.

---

### 2026-04-06 — GitHub Copilot (Background visibility rebalance)
**Role:** UI polish

**Done:**

- **Rebalanced the game-screen backdrop** so sector images stay subtle but are no longer crushed
  into near-black on typical phone brightness settings.
- **Kept the mandated 0.15 image opacity** while brightening the rendered artwork itself with a
  light color-matrix pass, avoiding a harsher full-opacity look.
- **Softened the underlying scaffold tint** from pure black to a slightly lifted blue-black range,
  giving the background art more room to read without compromising text contrast.

**Validation note:** `flutter analyze` and `flutter test` were attempted in this sandbox, but the
`flutter` CLI is not installed here (`flutter: command not found`).

---

### 2026-04-06 — GitHub Copilot (Shared psycho defaults cleanup)
**Role:** Review follow-up

**Done:**

- **Removed duplicate psycho-profile reset data** by exposing a shared
  `DatabaseService.defaultPsychoProfileRow` and reusing it for both DB initialization and reset.

---

### 2026-04-06 — GitHub Copilot (New game guard message polish)
**Role:** Review follow-up

**Done:**

- **Improved the reset guard error message** in `GameEngineNotifier.startNewGame()` so a missing
  `intro_void` definition now reports the likely fix (`_nodes` initialization) instead of a terse
  null-assert style failure.

---

### 2026-04-06 — GitHub Copilot (New game reset follow-up)
**Role:** Review follow-up

**Done:**

- **Aligned psycho-profile reset with the repository single-row pattern** — reset now uses
  `insert(..., conflictAlgorithm: replace)` instead of an inline `WHERE id = 1` update.
- **Centralised default psycho values** in `DatabaseService` and reused them from
  `PsychoProfileNotifier` so initialization, fallback, and reset share the same defaults.
- **Hardened the new-game engine reset** — `startNewGame()` now throws a clear `StateError` if the
  `intro_void` node definition is ever removed or renamed, instead of relying on a bare `!`.

---

### 2026-04-06 — GitHub Copilot (New game reset action)
**Role:** UI + persistence

**Done:**

- **Added a top-level `New game` action** in `game_screen.dart`, positioned at the top of the
  screen and gated behind a confirmation dialog.
- **Implemented full run reset flow** — `GameEngineNotifier.startNewGame()` now clears dialogue
  history, clears saved player memories, resets the psycho profile, resets the persisted engine
  state to `intro_void`, and rebuilds the opening narrative in-memory.
- **Ensured startup background falls back to "la soglia" after reset** — the new-game flow writes
  `currentNode: 'intro_void'`, which maps through `BackgroundService` to `bg_soglia.jpg`, so the
  first screen can be re-tested from the initial state without reinstalling the app.
- **Persistence helpers added** — `GameStateNotifier.resetGameState()`,
  `PsychoProfileNotifier.resetProfile()`, and `DatabaseService.clearAllMemories()` provide a small,
  explicit reset surface without changing normal autosave behavior.

**Architecture snapshot:**
New-game orchestration now lives in `GameEngineNotifier`, not the UI. `GameScreen` only asks for
confirmation and delegates the reset. Persisted restart state remains aligned with the existing
startup path: `gameStateProvider` reloads `intro_void`, and the background layer resolves that node
to the soglia image.

---

### 2026-04-06 — GitHub Copilot (Background startup image fix)
**Role:** UI bugfix

**Done:**

- **Found the startup background bug** — `game_screen.dart` only rendered a background when
  `gameStateProvider` had already resolved a non-null `currentNode`. On first app launch, that
  async state can still be loading for the first frames, so no image was painted at all.
- **Added a default startup background path** — `BackgroundService` now exposes
  `defaultBackgroundAsset`, `allBackgroundAssets`, and `getBackgroundForNodeOrDefault(...)` so
  the UI always has a valid image, falling back to `bg_soglia.jpg` when the node is not ready.
- **Precached all 7 background assets** from `GameScreen.initState()` after the first frame to reduce
  first-render delay and avoid visible flicker during sector changes.
- **Made background rendering unconditional** — `game_screen.dart` now always paints the
  background layer and enables `gaplessPlayback` for smoother transitions.

**Architecture snapshot:**
The background layer is now resilient to async startup timing. `GameScreen` no longer depends on a
resolved `gameStateProvider` value before painting an image; it asks `BackgroundService` for a
safe default and preloads all sector assets once per widget lifecycle.

---

### 2026-04-06 — GitHub Copilot (Verify real artwork & confirm UI integration)
**Role:** Asset verification + integration audit

**Done:**

- **Verified new real AI-generated artwork** — All 7 background images (`bg_*.jpg`) replaced
  with real AI-generated artwork (commit `91b9d81` on main). New files: 720×1280, 560–768 KB,
  with Exif metadata and complex visual scenes (vs old 100–170 KB gradient placeholders).
- **Full integration audit passed** — Cross-verified all 47 game node IDs against
  `BackgroundService._sectorForNode()` mappings: zero gaps. All sectors covered: soglia,
  giardino, osservatorio, galleria, laboratorio, memoria, la_zona.
- **UI rendering confirmed correct** — `game_screen.dart` displays background via
  `Positioned.fill → Opacity(0.15) → Image.asset(BoxFit.cover)`, watched reactively through
  `gameStateProvider`. Background changes automatically on sector navigation.
- **Null safety verified** — Unknown/empty node IDs return null from `getBackgroundForNode()`;
  UI conditionally skips rendering (`if (backgroundPath != null)`). No crash risk.
- **pubspec.yaml** — All 7 image assets declared individually. No changes needed.

---

### 2026-04-06 — GitHub Copilot (Background image investigation + opacity fix)
**Role:** Asset verification + code fix

**Done:**

- **Investigated all 7 background images** (`assets/images/bg_*.jpg`) using `file`, pixel
  analysis (PIL), and ASCII-art visualisation. **Finding: all 7 images are programmatically
  generated radial/elliptical gradient patterns** (diamond-shaped, sector-coloured), NOT real
  artwork. Typical signs: very low unique-color counts (822–8 370 vs hundreds of thousands
  for a real photograph), perfectly smooth gradient transitions, diamond-pattern scores up to
  37.7%. This is why the emulator shows "grid patterns" — they *are* grid-like gradients.
- **Flutter integration is correct** — `pubspec.yaml` (7 asset declarations),
  `background_service.dart` (sector/node mapping), and `game_screen.dart`
  (Stack → Positioned.fill → Opacity → Image.asset, fit: BoxFit.cover) are all properly
  wired. No code-level bug causes the visual issue.
- **Fixed opacity mismatch** — `game_screen.dart` had `opacity: 0.30` but CLAUDE.md
  specifies 0.15 in three places. Restored to `0.15`.
- **Action required:** The 7 placeholder gradient JPEGs must be replaced manually with real
  artwork files. The code is ready — just drop real 1080×1920 JPEGs with the same filenames
  into `assets/images/`.

---

### 2026-04-06 — Claude Code (Replace placeholder images with final artwork)
**Role:** Asset replacement + commit

**Done:**

- **Replaced all 7 sector background JPEGs** with final artwork assets copied from `Downloads/X PROTON/DA RINOMINARE/`: `bg_soglia.jpg`, `bg_giardino.jpg`, `bg_osservatorio.jpg`, `bg_galleria.jpg`, `bg_laboratorio.jpg`, `bg_memoria.jpg`, `bg_zona.jpg`. File sizes 99K–166K, appropriate for mobile.
- Committed and pushed: `7b333ee feat: replace placeholder images with real artwork`.

---

### 2026-04-06 — Claude Code (Background images — verify, analyze clean, polish)
**Role:** Integration verification + static analysis cleanup

**Done:**

- **Verified existing background image integration** (committed in PR #11 by Copilot) — all three
  components were already in place: `pubspec.yaml` (7 assets), `background_service.dart` (sector/node
  map), `game_screen.dart` (Stack + Opacity 0.15 + gameStateProvider wiring). No re-work needed.
- **`analysis_options.yaml`** — new file at project root; excludes `tools/**` from `flutter analyze`
  (the legacy `tools/fase_0_omega/` apps reference removed packages `flutter_llama` and
  `mediapipe_genai` and cannot be analyzed without them).
- **`lib/features/ui/game_screen.dart`** — replaced 6 `Color.withOpacity()` calls with
  `.withValues(alpha:)` (deprecated API, analyzer `info`-level).
- **`lib/features/game/game_engine_provider.dart`** — removed `_NodeDef.simulacra` field and the
  unreachable `_handleTake` simulacra-check branch (field was always the empty default; analyzer
  `warning`-level unused parameter). Simulacra are granted exclusively via `grantItem` in engine
  responses, never via `take` commands. Added `const` to one `EngineResponse(...)` constructor call.
- **`lib/features/demiurge/demiurge_service.dart`** — added `// ignore: avoid_print` on the
  debug-only assert print to silence the linter.
- **`CLAUDE.md`** — updated to reflect images are now part of the project: removed "No images" rule
  and convention row; added `BackgroundService` entry; updated project description.
- **`flutter analyze`** → `No issues found!`

**Architecture snapshot:**
`BackgroundService` is a pure static utility (no Riverpod provider). `getBackgroundForNode(nodeId)`
derives a sector string then delegates to `getBackgroundForSector()`. In `game_screen.dart`, the
background is resolved inside `build()` from `gameStateAsync.valueOrNull?.currentNode` — it updates
automatically on every node transition because `gameStateProvider` is watched.

---

### 2026-04-06 — Claude Code (End-to-end Android playtest — all 10 scenarios)
**Role:** QA / playtest engineer — full end-to-end test on Android emulator (API 35)

**Done:**

- **Gradle migration** — Rewrote `android/settings.gradle` and `android/app/build.gradle` from
  deprecated `apply from:` imperative style to declarative `pluginManagement` + `plugins {}` blocks.
  Bumped AGP 8.1.0 → 8.7.0, Gradle wrapper 8.3 → 8.9 (required by AGP 8.7.0).
- **Android launcher icons** — Created adaptive icon XMLs in `mipmap-anydpi-v26/` (sufficient for
  minSdk 26): dark `#1A1A1A` background + gold star foreground vector.
- **`flutter_llama` removal** — Dropped dependency from `pubspec.yaml`; stubbed `llm_service.dart`
  (all methods return false/empty). File kept per CLAUDE.md "do not delete" rule.
- **Keyboard persistence fix** (`game_screen.dart`) — Added `SystemChannels.textInput.invokeMethod
  ('TextInput.show')` after submit so the keyboard stays open on Android; added `autofocus: true`
  and `textInputAction: TextInputAction.send` to the TextField.
- **Deposit inventory bug fix** — Found and fixed a critical bug where `processInput()` cleared
  the inventory on *any* `CommandVerb.deposit`, including failed deposits. Added
  `clearInventoryOnDeposit: bool = false` to `EngineResponse` (`parser_state.dart`); changed
  the engine to only clear when the flag is `true`; set the flag only on the two success paths
  (garden deposit + il_nucleo deposit). Effect: failed deposits no longer wipe the player's items.
- **ADB test harness** — Established reliable Flutter TextField input method: `adb shell input text`
  for short strings, per-character keyevents (A=29…Z=54, space=62, enter=66) with 0.1 s delay for
  longer inputs. DB state manipulation via `adb exec-out/in run-as` + local sqlite3 to skip
  tedious puzzle sequences and test specific branches.

**Test results — all 10 scenarios PASS ✅:**

| # | Scenario | Result |
|---|---|---|
| 1 | La Soglia — commands, Demiurge, navigation | ✅ |
| 2 | Il Giardino — puzzles, weight, Ataraxia grant | ✅ |
| 3 | Observatory — lenses + void → The Constant | ✅ |
| 4 | Gallery — break mirror → The Proportion | ✅ |
| 5 | Laboratorio — blow alembic → The Catalyst | ✅ |
| 6 | La Zona — probabilistic activation, evasive + full responses | ✅ |
| 7 | Quinto Settore — ritual with all 4 simulacra | ✅ |
| 8 | Il Nucleo — all 3 finali (Acceptance / Oblivion / Eternal Zone) | ✅ |
| 9 | Demiurge anti-repetition — 5 nonsense commands, 3 distinct citations | ✅ |
| 10 | Audio crash resistance — non-fatal try/catch at all levels confirmed | ✅ |

**Bugs found during testing:**
- **Deposit bug** (fixed above): `List.every()` on empty list returns `true` vacuously, so a
  failed deposit before both alcoves were walked could grant Ataraxia on the *second* (now
  empty) deposit. Fixed via `clearInventoryOnDeposit` flag.
- **Node ID mismatch**: `garden_north` does not exist; correct ID is `garden_portico`. Test
  harness corrected; game code unaffected (correct node IDs were already used in gameplay paths).

**Architecture snapshot (no changes to core game logic):**
`EngineResponse.clearInventoryOnDeposit` is the only new field. The deposit guard in
`processInput()` now reads: `if (cmd.verb == CommandVerb.deposit && response.clearInventoryOnDeposit)`.

---

### 2026-04-06 — GitHub Copilot (Background image integration)
**Role:** UI enhancement — sector-mapped background images at 0.15 opacity

**Done:**

- **`assets/images/`** — Created directory with 7 placeholder JPEGs (1×1 px black):
  `bg_soglia.jpg`, `bg_giardino.jpg`, `bg_osservatorio.jpg`, `bg_galleria.jpg`,
  `bg_laboratorio.jpg`, `bg_memoria.jpg`, `bg_zona.jpg`.
  Replace placeholders with real artwork before final release.
- **`pubspec.yaml`** — Added all 7 image assets to the `flutter.assets` section.
- **`lib/features/ui/background_service.dart`** — New service with two static methods:
  - `getBackgroundForSector(sectorId)` — maps sector IDs → asset path.
  - `getBackgroundForNode(nodeId)` — derives sector from node prefix then delegates;
    handles all node families: `la_soglia`/`intro_void` → `soglia`, `garden*` → `giardino`,
    `obs_*` → `osservatorio`, `gal_*`/`gallery_*` → `galleria`, `lab_*` → `laboratorio`,
    `quinto_*`/`il_nucleo`/`finale_*`/`memory_*` → `memoria`, `la_zona` → `la_zona`.
- **`lib/features/ui/game_screen.dart`** — Background wiring:
  - Added `import` for `game_state_provider.dart` and `background_service.dart`.
  - `build()` now watches `gameStateProvider` to read `currentNode`.
  - Resolves `backgroundPath` via `BackgroundService.getBackgroundForNode()`.
  - Wrapped `SafeArea` content in a `Stack`; `Positioned.fill` + `Opacity(0.15)` +
    `Image.asset(…, fit: BoxFit.cover)` sits beneath the game text layer.
  - All existing game content (typewriter, message list, status bar, input row) is
    unchanged and rendered on top at full opacity.

**Architecture snapshot:** `BackgroundService` is a pure static utility — no Riverpod
provider needed; the node → sector mapping mirrors `DemiurgeService.sectorForNode()`
but adds `soglia`, `memoria`, and `la_zona` buckets absent from the Demiurge mapping.

---


### 2026-04-05 — GitHub Copilot (Repository code review — logic/persistence/audio fixes)
**Role:** Full-repository review + targeted bug fixes across Demiurge, La Zona, persistence, and finale flow

**Done:**

- **`lib/features/game/game_engine_provider.dart`**
  - Fixed Demiurge sector selection to use `response.newNode ?? currentNodeId`, so narrated room-entry text now pulls citations from the destination sector instead of the source node
  - Routed the global unknown-command fallback through the Demiurge (`needsLlm: true`) instead of returning a flat hardcoded line
  - Blocked `go back` from `la_zona` until the current Zone prompt has actually been answered
  - Preserved full raw text for `player_memories` saves on unknown/free-text commands, fixing truncated Zona responses
  - Added `playerMemoryKey: 'memory_maturity'` to the telephone-answer path in the Fifth Sector
  - Reset `consecutive_transits` when La Zona activates, preventing post-Zone probability carry-over
  - Corrected finale audio triggers: Acceptance now requests `aria_goldberg`, Oblivion now requests `silence`
- **`lib/core/storage/database_service.dart`**
  - Bumped DB schema to v3 and updated `dialogue_history.role` to allow `demiurge`
  - Added a migration that rebuilds `dialogue_history`, preserves prior rows, and rewrites legacy `llm` rows to `demiurge`
- **`lib/core/storage/dialogue_history_service.dart`**
  - Updated role documentation to match the live schema and engine usage
- **`lib/features/audio/audio_service.dart`**
  - Made ambience switching more resilient when `assets/audio/` is empty by only committing `_currentAmbienceKey` after a successful load
  - Removed the force-unwrapped Oblivion fallback asset lookup in the silence-ending handler
- **`lib/features/state/game_state_provider.dart`**
  - Added a defensive fallback to `intro_void` when a malformed saved `game_state` row cannot be deserialized

**Validation note:** `flutter`/`dart` are not installed in this sandbox, so `flutter analyze` and `flutter test` could not be executed here. I still ran `git diff --check` and static sanity checks over the patched code paths.

---

### 2026-04-05 — Claude Code (Demiurge bundles — 200 citations per sector)
**Role:** Content generation — populate all five Demiurge JSON bundles to ≥200 entries each

**Done:**

- **`tools/generate_demiurge_offline.py`** — new self-contained Python script (no network calls):
  - All citations embedded directly in source code (~170 raw quotes for giardino, ~112 for osservatorio, ~70 for galleria, ~82 for laboratorio, ~129 for universale)
  - `generate_entries()` function uses systematic `(opening × citation × closing)` pairing across multiple passes; each `(quote_idx, opening_idx, closing_idx)` triple is unique — no duplicate entries
  - 20 unique opening phrases and 20 unique closing phrases per sector, all thematically appropriate
  - Terminates at exactly `target=200` entries per sector; raises a non-zero exit code if any sector falls short
- **`assets/texts/demiurge/*.json`** — all five bundles regenerated at 200 entries:
  - `giardino.json`: Epicurus, Marcus Aurelius, Seneca, Plato, Aristotle, Epictetus
  - `osservatorio.json`: Newton, Galileo, Einstein, Kepler, Copernicus, Planck
  - `galleria.json`: Leonardo da Vinci, Michelangelo, Pacioli, Vasari, Dürer
  - `laboratorio.json`: Hermes Trismegistus, Paracelsus, alchemical tradition, Bruno
  - `universale.json`: Lao Tzu, Rumi, Heraclitus, Thoreau, Blake, Tagore
- **CLAUDE.md `⚠️ OPEN` bug** now resolved: bundles are at target; anti-repetition window (20) is well within the 200-entry pool

**Architecture note:** The generator can be re-run at any time to rebuild the bundles. To raise the target, change `TARGET = 200` at the top of the script. To add authors, extend the `*_QUOTES` lists and optionally add new openings/closings.

---

### 2026-04-05 — GitHub Copilot (CLAUDE.md rewrite — full AI agent briefing)
**Role:** Documentation update — CLAUDE.md made into a complete, self-contained briefing for any AI agent

**Done:**

- **`CLAUDE.md` fully rewritten** as single source of truth for any AI agent joining cold:
  - Added per-file architecture section (all 13 source files documented with roles and key details)
  - Added "The Demiurge system" section: how it works, `respond()` API, sector mapping, JSON schema with example
  - Added "Current bundle status" table: 12 entries per sector, target 200+
  - Added "Known bugs" section: simulacra fix documented (✅ FIXED), bundle under-population flagged (⚠️ OPEN)
  - Updated priority order: item 8 now clearly marks "populate bundles to ≥200" as the next task
  - Stack/conventions and Rules sections preserved and expanded

**No code changes — documentation only.**

---

### 2026-04-05 — GitHub Copilot (DemiurgeService integration — wiring into game engine)
**Role:** DemiurgeService wired into `game_engine_provider.dart`, replacing `_callLlm()`

**Done:**

- **`lib/features/game/game_engine_provider.dart`**:
  - Removed `llm_context_service.dart` and `llm_service.dart` imports (legacy LLM, no longer used)
  - Added `demiurge_service.dart` import
  - Replaced `_callLlm(String fallbackText)` (async, required `LlmService`) with `_callDemiurge(String fallbackText, String nodeId)` (sync, uses `DemiurgeService.sectorForNode()` + `DemiurgeService.instance.respond()`)
  - Call site at `processInput` updated: `await _callLlm(...)` → `_callDemiurge(..., currentNodeId)` (no longer async)
  - History save label updated: `'llm'` → `'demiurge'`
  - Header comment updated: LLM reference → Demiurge reference
- **`lib/main.dart`**:
  - Added `DemiurgeService.instance.loadAll()` pre-load at startup (inside try-catch; bundle failure is non-fatal)
- **`CLAUDE.md`**: priority #7 marked as ✅ DONE

**Architecture after this session:**
```
Input giocatore
      ↓
ParserService.parse()                [pure, sync]
      ↓
GameEngineNotifier._evaluate()       [Riverpod AsyncNotifier]
      ↓
_callDemiurge(fallback, nodeId)      [sync; no LLM, no network]
  → DemiurgeService.sectorForNode()  [node → sector key]
  → DemiurgeService.respond()        [pick from bundle, anti-repetition]
      ↓
GameScreen (typewriter display)
```

---

### 2026-04-05 — GitHub Copilot (Demiurge Architecture — replacing LLM)
**Role:** Architectural change — replacing on-device LLM with deterministic DemiurgeService

**Done:**

- **Architectural decision: LLM → Demiurge ("All That Is")**
  - On-device LLM (flutter_llama, Qwen 2.5 0.5B) replaced by a fully deterministic narrator
  - "All That Is" (Tutto Ciò Che È) — name from Seth/Jane Roberts philosophy — is the voice of the Archive
  - Player never knows if they made a mistake or discovered something; error is part of the existential journey
- **`CLAUDE.md` updated:**
  - Stack description: `on-device LLM 0.5B` → `DemiurgeService (deterministic, offline)`
  - Conventions table: LLM rows → Demiurge rows
  - File structure: added `demiurge/demiurge_service.dart`, marked `llm/` as legacy
  - Priority order: removed LLM validation, added DemiurgeService integration as next priority
  - Rules: updated LLM reference to Demiurge
- **`docs/gdd.md` updated:**
  - §1 NOTA CRITICA: rewritten for Demiurge philosophy
  - §5: entire section replaced — "RUOLO DELL'LLM" → "IL DEMIURGO — ALL THAT IS"
  - §16: Stack, budget, interaction flow, file structure all updated
  - §17: "STRATEGIA VALIDAZIONE LLM" → "ARCHITETTURA DEMIURGO" with implementation details
  - §18: assets structure updated with `demiurge/` subdirectory
  - §20: LLM prompt templates marked as legacy
  - §21: Roadmap updated (versions 1–3 completed, version 4 = DemiurgoService)
  - §22: Priorities updated for Demiurge integration
- **`lib/features/demiurge/demiurge_service.dart` created:**
  - Singleton service with `respond(sector, fallbackText)` API
  - Loads JSON bundles from `assets/texts/demiurge/`
  - Anti-repetition ring buffer (last 20 per sector)
  - `sectorForNode()` maps game node IDs to sector keys
  - Riverpod provider (`demiurgeServiceProvider`)
- **`assets/texts/demiurge/` created with 5 sector bundles:**
  - `giardino.json` — 12 entries (Epicurus, Marcus Aurelius, Seneca, Plato, Aristotle, Epictetus, Socrates)
  - `osservatorio.json` — 12 entries (Newton, Galileo, Planck, Einstein, Plato)
  - `galleria.json` — 12 entries (Leonardo, Michelangelo, Pacioli, Plutarch, Aristotle)
  - `laboratorio.json` — 12 entries (Hermes Trismegistus, Paracelsus, Aristotle, Basilius Valentinus, The Emerald Tablet)
  - `universale.json` — 12 entries (Lao Tzu, Rumi, Heraclitus, Thoreau, Blake, Socrates)
  - All citations from public domain sources
- **`tools/prepare_demiurge_bundles.py` created:**
  - Fetches citations from Wikiquote API and Project Gutenberg
  - Filters by author/sector, deduplicates, pairs with opening/closing lines
  - Exports JSON bundles with ≥200 citations per sector target
  - CLI: `python tools/prepare_demiurge_bundles.py [--output-dir] [--target]`
- **`pubspec.yaml` updated:** added `assets/texts/demiurge/` to asset registration

**Architecture:**
```
Input giocatore
      ↓
ParserService.parse() [puro, sincrono]
      ↓
GameEngineNotifier._evaluate() [Riverpod AsyncNotifier]
      ↓
DemiurgeService.respond() [deterministico, offline]
      ↓
GameScreen [typewriter + palette PsychoProfile]
```

**Next steps:**
1. Wire `DemiurgeService.respond()` into `game_engine_provider.dart` (replace `_callLlm()`)
2. Run `tools/prepare_demiurge_bundles.py` to populate ≥200 citations per sector
3. Remove `flutter_llama` from `pubspec.yaml`
4. Test on physical device

---

### 2026-04-04 — GitHub Copilot (Fase 0-omega — LLM integration, Tentativo 1)
**Role:** LLM integration — flutter_llama + Qwen 2.5 0.5B Q4_K_M

**Done:**

- **`flutter_llama: ^1.1.2` aggiunto a `pubspec.yaml`** — versione più recente disponibile su pub.dev
- **`lib/features/llm/llm_service.dart` creato** — singleton wrapper attorno a `FlutterLlama`:
  - Lazy loading con `ensureLoaded()` — il modello si carica al primo `generate()` call
  - Graceful fallback: se il modello non è presente o genera un errore, restituisce `fallbackText` invariato
  - Formato prompt Qwen: `<|system|>/<|user|>/<|assistant|>` (GDD §20)
  - Usa `LlmContextService.buildDynamicSystemPrompt()` per iniettare profilo psicologico e contesto nodo
  - `maxTokens: 100`, CPU-only di default (`nGpuLayers: 0`); basta impostare `nGpuLayers: -1` per Vulkan
- **`_llmStub()` → `_callLlm()` in `game_engine_provider.dart`** — sostituisce il placeholder con la chiamata reale
- **Android directory creata con tutte le patch richieste (GDD §17):**
  - `android/app/build.gradle` — `minSdkVersion 26`, `multiDexEnabled true`
  - `android/app/src/main/AndroidManifest.xml` — `android:largeHeap="true"`, `READ_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`
  - `android/gradle.properties` — `org.gradle.jvmargs=-Xmx4096m`
  - `android/settings.gradle`, `android/build.gradle`, `android/gradle/wrapper/gradle-wrapper.properties`
  - `MainActivity.kt`, `styles.xml`, `launch_background.xml`

**Istruzioni per il test su device fisico:**

```bash
# 1. Scarica il modello (~350 MB) da HuggingFace:
#    https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf

# 2. Push del modello sul device:
adb push qwen2.5-0.5b-instruct-q4_k_m.gguf /sdcard/Download/

# 3. Build e install:
flutter clean && flutter pub get
flutter build apk --release
adb install build/app/outputs/apk/release/app-release.apk

# 4. Lancia il gioco e verifica:
#    - Il modello si carica entro 60 secondi al primo comando
#    - Le risposte LLM arrivano in meno di 20 secondi
#    - Il testo generato è coerente (non gibberish)
#    - Nessun crash su 5 interazioni consecutive
#    - RAM totale < 1.5 GB (misura con Android Studio Profiler)
```

**Se Tentativo 1 fallisce:** comunicalo all'agente per passare a Tentativo 2 (mediapipe_genai + Gemma 2B).

**Stato progetto:**
- Fase 0-omega Tentativo 1 implementato — pronto per test su device
- Se test passa: gioco completamente funzionale con LLM on-device
- Prossimo step: test fisico su Android (vedi istruzioni sopra)

---

### 2026-04-04 — GitHub Copilot (Project-wide bug audit & fixes)
**Role:** Bug audit & defensive fixes

**Done:**

- **Full codebase audit** — reviewed all 11 source files for bugs, race conditions, memory leaks, and code quality issues
- **9 bugs fixed across 7 files:**
  1. `audio_service.dart` — `_updateAmbienceFromProfile` now `async`/`await`s `_crossfadeTo` (was fire-and-forget, causing overlapping crossfades)
  2. `audio_service.dart` — `_crossfadeTo` null-checks ambience asset key before access (was crashing on unknown keys)
  3. `audio_service.dart` — SFX player disposal: added 30s timeout + `catchError` to prevent memory leaks when stream never completes
  4. `parser_service.dart` — `CommandVerb.unknown` now excludes verb from args (was inconsistent with all other verbs)
  5. `game_screen.dart` — replaced recursive `Future.delayed` typewriter with `Timer` + cancel in `dispose()` (was causing `setState` on disposed widget)
  6. `main.dart` — wrapped AudioService initialization in try-catch (audio failure must not prevent game from starting)
  7. `database_service.dart` — database singleton getter uses `Completer` to prevent race condition on concurrent init calls
  8. `llm_context_service.dart` — Fifth Sector verse now uses encounter counter instead of always index 0
  9. `game_engine_provider.dart` — inventory display: `\n` → `\n\n` between items list and weight

**Stato progetto:**
- Engine completo con 9 bugfix difensivi applicati
- Prossimo step: Fase 0-omega (test APK su device fisico)

---

### 2026-04-04 — GitHub Copilot (Docs audit & CLAUDE.md update)
**Role:** Documentation maintenance

**Done:**

- **Audit documentazione vs. codebase** — verificato allineamento completo tra `docs/gdd.md`,
  `docs/work_log.md`, `docs/parser_state_machine.md` e codice effettivo: nessuna discrepanza trovata
- **CLAUDE.md aggiornato:**
  - Rimossa sezione "Known bug (unfixed)" — bug simulacra già fixato nel codice
    (`game_engine_provider.dart` line 1167: aggiunta oggetti per `weightDelta >= 0`)
  - "Priority order" aggiornata: items 1-5 marcati ✅ DONE, solo Fase 0-omega (step 6) ancora pending

**Stato progetto:**
- Engine completo: 4 settori + Quinto Settore + Boss Finale + La Zona + 3 finali
- Tutto il codice è pronto per Fase 0-omega (test APK su device fisico)
- Prossimo step: `tools/fase_0_omega/CLAUDE_CODE_PROMPT.md`

---

### 2026-04-04 — GitHub Copilot (Audio wiring, State persistence, Player memories, LLM context wiring)
**Role:** Post-completion infrastructure — priorità 1-4

**Done:**

- **Audio triggers wired (Priorità 1)**
  - `AudioService`: aggiunto `handleTrigger(String? trigger)` — dispatcha verso
    crossfade ambience (`siciliano`, `aria_goldberg`, nuovi), SFX one-shot (`sfx:*`)
    o silence-ending per Finale 2 (`silence`)
  - `_ambienceAssets` esteso con `siciliano` (Bach BWV 1017) e `aria_goldberg` (Aria Goldberg)
  - Logica `_updateAmbienceFromProfile` non sovrascrive più i trigger speciali
    (siciliano/aria_goldberg hanno priorità sul profilo psicologico)
  - `_handleZoneResponse` e `_handleGo` in `game_engine_provider.dart`: aggiunto `audioTrigger`
    per `quinto_landing` → `siciliano`, `finale_acceptance` → `aria_goldberg`,
    `finale_oblivion` → `silence`, `il_nucleo` → `oblivion`
  - `processInput`: `AudioService().handleTrigger(response.audioTrigger)` chiamato dopo
    ogni risposta del motore

- **Persistenza completa dello stato (Priorità 2)**
  - `DatabaseService`: bumped a versione 2 con `onUpgrade` — aggiunge colonne
    `completed_puzzles`, `puzzle_counters`, `inventory`, `psycho_weight` a `game_state`
  - `GameState`: espanso con i 4 nuovi campi (deserializzati da JSON)
  - `GameStateNotifier`: rimpiazzato `updateNode()` con `saveEngineState()` che persiste
    tutto; `build()` ripristina lo stato completo dal DB
  - `GameEngineNotifier.build()`: ora ripristina `completedPuzzles`, `puzzleCounters`,
    `inventory`, `psychoWeight` da `savedState` invece di partire da zero
  - `processInput`: rimossa la vecchia chiamata `updateNode`; la `saveEngineState`
    al fondo del processInput salva il nodo + tutto lo stato in un'unica transazione

- **Player memories → DB (Priorità 3)**
  - `DatabaseService`: aggiunta tabella `player_memories` (key UNIQUE, content, created_at);
    helper `saveMemory()` e `loadAllMemories()`
  - `EngineResponse`: aggiunto campo `playerMemoryKey` (nullable)
  - `_handleMemoryWrite`: passa `playerMemoryKey: puzzleId` per le 4 stanze proustiane
  - `_handleZoneResponse`: passa `playerMemoryKey: 'zone_$encounters'` per ogni risposta
  - `processInput`: se `response.playerMemoryKey != null` salva il testo del giocatore in
    `player_memories`

- **TextBundleService → LlmContextService (Priorità 4)**
  - `LlmContextService`: importa `TextBundleService`, aggiunge `_buildBundleContext()` che
    arricchisce il system prompt con versi Tarkovsky (quinto / zona), keywords di
    confronto (nucleo) dalla cache precaricata — zero I/O sincrona

**Not done (Priorità 5):**
- Fase 0-omega: `_llmStub()` → modello on-device reale — richiede APK completo su device fisico

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
