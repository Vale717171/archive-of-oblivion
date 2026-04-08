# Work Log — L'Archivio dell'Oblio
*Registro cronologico delle sessioni di sviluppo. Non modificare le voci esistenti.*
*GDD completo: [`gdd.md`](gdd.md)*

---

### 2026-04-08 — GitHub Copilot (Linux Android SDK local path fix)
**Role:** Build-environment alignment

**Done:**

- **Corrected `android/local.properties`** from a stale macOS SDK path to the active Linux/Codespaces SDK path at `/home/codespace/Android/Sdk`.
- **Verified the local Android SDK layout exists** under the Linux home directory, including `cmdline-tools/latest`.
- **Separated shell-vs-file confusion** so the local properties content is now stored in the right place instead of being treated as bash commands.

**Validation note:** The next step is to rerun the Android build from the project root. If Gradle still reports missing components, the SDK path is now correct and the remaining work is only package installation via `sdkmanager`.

**Architecture snapshot:**
The repository no longer points Android builds at a machine-specific macOS path in this workspace, reducing one class of environment-specific build failure.

### 2026-04-08 — GitHub Copilot (Boss utterance classifier extraction)
**Role:** Finale regression hardening, pure-rule extraction

**Done:**

- **Extracted a pure boss-utterance classifier** from the Antagonist handler so surrender, remain, resolution, and fallback branches can be tested directly.
- **Rewired `_handleBossInput()` to use the shared classifier**, removing duplicated keyword logic from the finale branch selection path.
- **Extended `game_engine_helpers_test.dart`** to cover representative utterances for Oblivion, Eternal Zone, Acceptance, and neutral fallback.

**Validation note:** Static diagnostics are the immediate check here; full execution still depends on the next green `flutter test` run.

**Architecture snapshot:**
The boss-resolution path is now less implicit. Finale branch selection depends on an explicit, reusable classifier rather than scattered keyword checks embedded only inside the handler.

### 2026-04-08 — GitHub Copilot (Gate/Zone helper extraction)
**Role:** Engine regression hardening, pure-helper extraction

**Done:**

- **Extracted public pure helpers from `game_engine_provider.dart`** for exit-gate lookup, gate-hint lookup, and Zone transit eligibility.
- **Rewired the engine to use the extracted helpers internally**, so tests and runtime now read the same source of truth for gate and transit classification.
- **Expanded `game_engine_helpers_test.dart`** to cover representative gate requirements, gate hint resolution, and conservative Zone eligibility rules around Memory, Finale, Nucleus, and Zone transitions.

**Validation note:** This is a behavior-preserving extraction aimed at testability and drift prevention; a fresh `flutter test` run remains the final execution check.

**Architecture snapshot:**
Critical progression metadata is now less buried inside the notifier implementation. The suite can directly assert gate and Zone-transition rules without depending on widget orchestration or device runtime.

### 2026-04-08 — GitHub Copilot (Parser/audio regression expansion)
**Role:** Low-risk QA hardening before device playtest

**Done:**

- **Expanded parser regression coverage** with alias-heavy commands (`pick`, `push`, `give`, `reverse`, `adjust`, `speak`) plus an explicit unknown-verb preservation check.
- **Expanded audio catalog regression coverage** with sector fallback checks, explicit asset resolution checks, and representative audio/background family alignment checks for garden, memory, and zone nodes.
- **Kept the work focused on pure deterministic surfaces** so the suite catches more drift without introducing widget/device complexity.

**Validation note:** The next useful verification step is a fresh `flutter test` run to execute the newly added cases.

**Architecture snapshot:**
The automated suite now guards more of the parser's synonym surface and more of the packaging/runtime assumptions around audio routing, which lowers the chance of subtle command or asset-regression bugs slipping into the first physical-device pass.

### 2026-04-08 — GitHub Copilot (Runtime/documentation alignment pass)
**Role:** Documentation drift cleanup, collaborator prompt alignment

**Done:**

- **Aligned active comments and helper docs with the current Demiurge architecture** across parser/storage/bundle services so future maintenance is no longer pointed at a removed on-device LLM runtime.
- **Updated collaborator prompts in `docs/prompts/`** to reflect the actual project state: deterministic narrator, subtle background imagery already present, and current release priorities instead of obsolete Fase 0-omega instructions.
- **Corrected the README release-gap wording** so audio placeholders are recognized as already present and usable for device-side runtime verification.

**Validation note:** Editor diagnostics report no errors in the touched Dart files. This pass changed wording and guidance only; no gameplay logic changed.

**Architecture snapshot:**
The repository is now more self-consistent for future sessions: the live runtime is described as deterministic and Demiurge-driven across code comments, collaboration prompts, and release-facing docs, reducing the risk of future contributors following stale LLM-era instructions.

### 2026-04-08 — GitHub Copilot (Manifest/helper consistency tests)
**Role:** Regression coverage, runtime/catalog alignment

**Done:**

- **Expanded `game_engine_helpers_test.dart`** to cover more sector-label edge cases and untitled-node fallbacks.
- **Added `test/audio_manifest_consistency_test.dart`** to verify that the declared audio manifest stays aligned with the runtime audio catalog and does not drift into duplicate-key mistakes.
- **Updated implementation-status notes** to reflect the broader automated consistency coverage now present in the repository.

**Validation note:** A fresh terminal-side `flutter test` run is still needed to execute the newly added tests.

**Architecture snapshot:**
The repository now guards not only logic helpers but also a key integration seam: the declared audio asset manifest must stay consistent with the runtime track catalog, reducing one class of pre-release packaging errors.

### 2026-04-08 — GitHub Copilot (Placeholder audio verified)
**Role:** Audio validation, pre-device checkpoint

**Done:**

- **Confirmed the placeholder audio pipeline is operational** after local asset generation.
- **Confirmed repository-side verification completes successfully** with `tools/audit_audio_assets.py` in the user terminal.
- **Confirmed `flutter analyze` and `flutter test` still pass** with placeholder audio present in the repository.
- **Confirmed the automated suite is now green at 18 passing tests** in the current workspace state.

**Validation note:** Dependency update notices remain informational only and did not block audio verification, analysis, or tests.

**Architecture snapshot:**
The project now has a fully testable audio path for phone playtesting: declared manifest, generated placeholder assets, runtime routing, persisted music/SFX controls, repository audit tooling, analyzer-clean code, and a green test suite.

### 2026-04-08 — GitHub Copilot (Placeholder audio generation path)
**Role:** Audio integration, legal-risk reduction, device-test enablement

**Done:**

- **Added `tools/generate_placeholder_audio.py`** to synthesize temporary `.ogg` assets locally with `ffmpeg`, matching the planned audio catalog without downloading third-party recordings.
- **Updated the audio pipeline docs** so the safest immediate path for phone testing is now explicit: generate placeholders, audit them, then run analyze/test.
- **Updated README and implementation-status docs** so this route is visible as part of the current release-readiness workflow.

**Architecture snapshot:**
The project now has two valid audio onboarding paths: final licensed masters later, or immediately generated placeholder audio now. That means device-side audio testing no longer has to wait on music sourcing decisions.

### 2026-04-08 — GitHub Copilot (Audio import pipeline prep)
**Role:** Release-readiness tooling, audio integration support

**Done:**

- **Added `tools/audit_audio_assets.py`** to compare the declared audio catalog in `assets/audio/manifest.json` against the actual repository files.
- **Added `docs/audio_asset_pipeline.md`** to define a safe workflow for importing real audio masters with license awareness and repository verification.
- **Updated `README.md` and `docs/implementation_status.md`** so the new audio import tooling is part of the documented pre-release process.

**Architecture snapshot:**
Audio is still content-incomplete, but the project now has a clearer operational path from planned catalog to shipped assets: declared manifest, runtime routing, persistent settings, and a repository-side audit tool.

### 2026-04-08 — GitHub Copilot (Browser trial vertical slice)
**Role:** Web-facing prototype, pre-release presentation support

**Done:**

- **Added `docs/web_trial_demo.html`** as a standalone browser-playable teaser for the project.
- **Kept the slice intentionally self-contained** so it does not depend on Flutter web, `sqflite`, or the mobile runtime stack.
- **Included parser-style interaction, local save via browser storage, a small Garden gate, and a generated ambient drone** to approximate atmosphere without shipping external audio files.
- **Updated repository docs** so the HTML trial is now discoverable from the README and implementation-status matrix.

**Architecture snapshot:**
The project now has two presentational surfaces: the main Flutter application for the full game, and a lightweight HTML vertical slice for quick browser sharing and tone validation while a full web port remains out of scope for now.

### 2026-04-08 — GitHub Copilot (Parser/background regression pass)
**Role:** Automated coverage, coherence cleanup

**Done:**

- **Expanded parser regression coverage** with additional tests for shortcuts, stop-word stripping, movement normalization, and creative/ritual verb routing.
- **Added `test/background_service_test.dart`** to cover sector/node background mapping and startup fallback behavior.
- **Cleaned a remaining legacy parser-state comment** so `needsLlm` now reflects the actual Demiurge-driven runtime behavior.

**Validation note:** VS Code error inspection reports no issues in the newly edited files. A fresh terminal-side test run would pick up the newly added parser/background coverage.

**Architecture snapshot:**
Low-level confidence is now broader across the core non-UI helpers that shape runtime feel: parser normalization, background routing, Demiurge formatting/mapping, audio routing, and settings persistence all have direct automated coverage.

### 2026-04-08 — GitHub Copilot (Expanded test suite re-verified)
**Role:** Validation, regression checkpoint

**Done:**

- **Confirmed `flutter test` still passes after the added README/docs/audio-settings/test work.**
- **Verified the suite now runs 13 passing tests**, including the newly added coverage around app settings, Demiurge helpers, and audio-track routing helpers.

**Validation note:** Dependency-update notices remain informational only and did not block test execution.

**Architecture snapshot:**
The repository now has broader automated confidence than earlier in the session: parser coverage, engine helper coverage, Demiurge helper coverage, audio catalog coverage, and app-settings model coverage are all green in the current test run.

### 2026-04-08 — GitHub Copilot (Audio settings wiring pass)
**Role:** Audio UX, persistence, pre-release polish

**Done:**

- **Extended app settings persistence** with separate music and SFX toggles/volumes in `database_service.dart` and `app_settings_provider.dart`.
- **Wired `AudioService` to live app settings** so background music and SFX now respect user preferences instead of only psycho-profile modulation.
- **Added new controls to the settings panel** in `archive_panels.dart` for music enable/disable, music volume, SFX enable/disable, and SFX volume.
- **Added unit coverage for the expanded settings model** in `test/app_settings_test.dart`.

**Validation note:** VS Code error inspection reports no issues in the updated files. A fresh `flutter test` run is recommended to include the new settings test.

**Architecture snapshot:**
The audio stack is still waiting on real masters, but it is no longer only a planned shell. User-facing control over music and SFX is now part of the persisted app configuration and already integrated with runtime audio behavior.

### 2026-04-08 — GitHub Copilot (Pre-release documentation and test coverage pass)
**Role:** Release-readiness support, documentation, automated coverage

**Done:**

- **Added a real top-level `README.md`** describing the project, current state, verification commands, Demiurge pipeline, and known release gaps.
- **Added `docs/implementation_status.md`** to separate implemented, partial, and still-missing improvement areas before device playtesting.
- **Expanded automated coverage** with new unit tests for `DemiurgeEntry` formatting and `DemiurgeService.sectorForNode(...)` plus `AudioTrackCatalog` mapping behavior.
- **Kept the additions aligned with the actual current repo state** instead of repeating now-obsolete assumptions from earlier planning notes.

**Validation note:** VS Code error inspection reports no issues in the newly added files. A fresh `flutter test` run is still recommended to include the added test files in the terminal-side verification.

**Architecture snapshot:**
The project now has a clearer release-readiness surface: public-facing repository framing in `README.md`, an internal implementation matrix in `docs/implementation_status.md`, and broader low-level regression coverage around narration and audio routing helpers.

### 2026-04-08 — GitHub Copilot (Static QA verification passed)
**Role:** Validation, release-readiness checkpoint

**Done:**

- **Confirmed `flutter analyze` passes cleanly** in the corrected workspace environment with no reported issues.
- **Confirmed `flutter test` passes** with all 5 tests green.
- **Verified the recent fixes did not introduce regressions** in the current automated coverage surface.

**Validation note:** The terminal output still reports 10 newer package versions outside the current dependency constraints, but these are informational only and did not block analysis or tests.

**Architecture snapshot:**
The project is now in a clean static-validation state: Demiurge bundles are regenerated and audited, analyzer findings are resolved, and the current automated test suite passes. The next milestone remains physical Android playtesting.

### 2026-04-08 — GitHub Copilot (Flutter analyze cleanup)
**Role:** Static analysis fix-up, settings API correction

**Done:**

- **Fixed the invalid Riverpod override in `app_settings_provider.dart`** by renaming the app-specific mutation method from `update(...)` to `saveSettings(...)`, avoiding a signature collision with `AsyncNotifierBase.update(...)`.
- **Updated all settings-panel call sites** in `archive_panels.dart` to use the renamed notifier API.
- **Cleaned the remaining analyzer findings** by removing the unnecessary cast in `game_screen.dart`, simplifying the ignored queue variable in `audio_service.dart`, and removing the missing `assets/config/` entry from `pubspec.yaml`.

**Validation note:** VS Code error inspection reports no remaining issues in the edited files after the cleanup. A fresh `flutter analyze` run in the user's terminal is still needed to confirm the workspace is now fully clean.

**Architecture snapshot:**
App settings persistence now uses an explicit app-domain mutation API rather than shadowing Riverpod's generic `update` helper, which removes a fragile naming collision and keeps the notifier surface clearer.

### 2026-04-08 — GitHub Copilot (Targeted engine playtest-risk review)
**Role:** Code review, progression-risk triage

**Done:**

- **Reviewed the highest-risk progression slices** in `game_engine_provider.dart`: La Zona activation/return flow, exit-gate enforcement, Quinto descent gating, ritual completion, and finale routing.
- **Did not find an obvious static blocker** in those paths during read-through: the reviewed logic remains internally coherent with the current playtest checklist.
- **Identified the remaining risk profile as behavioral rather than structural** — especially probabilistic La Zona timing, ritual chamber sequencing on device, and boss/finale state flow after real inventory manipulation.

**Validation note:** Workspace error inspection still reports no editor-detected problems.

**Architecture snapshot:**
At this stage the project's main uncertainty is no longer content generation or obvious compile-time breakage. The next meaningful verification step is runtime behavior on device across long-form progression and save/resume boundaries.

### 2026-04-08 — GitHub Copilot (Device playtest checklist)
**Role:** QA planning, release-readiness support

**Done:**

- **Added `docs/device_playtest_checklist.md`** as a concrete physical-device verification guide for the current game architecture.
- **Structured the checklist around real engine risks** rather than generic Flutter smoke tests: sector gates, La Zona activation, Quinto memory prices, ritual completion, three endings, persistence, and special audio routing.
- **Included regression checks for the recently touched areas** such as quick-command prefill behavior, weightless simulacra inventory, and Demiurge repetition quality.

**Architecture snapshot:**
Project readiness is now documented in two layers: implementation state in `CLAUDE.md`, and operational verification steps in `docs/device_playtest_checklist.md`. This makes the next milestone — physical Android playtest — explicit and repeatable.

### 2026-04-08 — GitHub Copilot (Demiurge bundle regeneration validated)
**Role:** Content pipeline verification, project-state update

**Done:**

- **Reviewed the terminal-side generation and audit output** after the latest `prepare_demiurge_bundles.py` reinforcement.
- **Confirmed all five Demiurge bundles now generate at exactly 200 entries each** for `giardino`, `osservatorio`, `galleria`, `laboratorio`, and `universale`.
- **Confirmed the strengthened pipeline now succeeds for sparse sectors** by supplementing online fetches with curated offline fallback quotes.
- **Confirmed `tools/audit_demiurge_bundles.py` now passes on every checked-in sector bundle** with no remaining count, schema, duplicate, or repeated-block failures in the reported output.
- **Updated `CLAUDE.md`** so project guidance now reflects that bundle regeneration is complete and the next priority is device playtesting.

**Validation note:** The successful generation and audit were executed in the user's workspace terminal after Flutter and the container environment were corrected. `flutter pub get` also completed successfully in the same environment.

**Architecture snapshot:**
The Demiurge content pipeline is now in a healthy steady state: online source collection, sector-local offline fallback supplementation, balanced per-author selection, low-repetition voice assignment, and post-generation auditing all work together to produce 200-entry bundles that pass validation.

### 2026-04-08 — GitHub Copilot (Sparse-source fallback pass)
**Role:** Content pipeline resilience, source-coverage repair

**Done:**

- **Analyzed the real generation output** supplied from the workspace terminal and confirmed that the new duplicate protections work, but `galleria` and especially `laboratorio` now fail for a different reason: insufficient source coverage.
- **Extended `tools/prepare_demiurge_bundles.py`** so sparse sectors can be supplemented with curated local fallback quotes already stored in `tools/generate_demiurge_offline.py`.
- **Raised Wikiquote extraction headroom** from 60 to 100 candidate lines per author to reduce premature truncation on richer pages.
- **Expanded author coverage** for the weakest sectors, adding more plausible public-domain authors to `galleria` and `laboratorio` before fallback supplementation.

**Validation note:** Static error checking passed for the updated generator. The change still needs a fresh terminal-side generation run to confirm whether fallback supplementation is enough to bring all sectors to the 200-entry target.

**Architecture snapshot:**
The generator now has a layered sourcing strategy: online fetch first, sector-local curated fallback second, then balanced selection and validation. This should make generation less brittle when specific Wikiquote or Gutenberg pages are missing, sparse, or unstable.

### 2026-04-08 — GitHub Copilot (Demiurge generator balancing pass)
**Role:** Content pipeline, generation quality, tooling cleanup

**Done:**

- **Analyzed the user-provided audit output** and confirmed the remaining failures are consistent with duplicate `citation + author` reuse inside the checked-in bundles rather than with Flutter setup issues.
- **Confirmed `flutter pub get` now succeeds in the workspace terminal**, so Flutter is present and dependency resolution is no longer the immediate blocker.
- **Strengthened `tools/prepare_demiurge_bundles.py`** by:
  - deduplicating quote candidates per author before bundle assembly
  - selecting quotes with a more balanced author interleave instead of flat sector-wide shuffling
  - assigning opening/closing variants with local repetition avoidance and pair reuse reduction
  - validating generated bundles against repeated contiguous blocks and duplicate voice-pair reuse
- **Removed a stray duplicate function signature** left in `tools/curate_demiurge_bundles.py` during the earlier curation-tool iteration.

**Validation note:** Static error checking passed for both `tools/prepare_demiurge_bundles.py` and `tools/curate_demiurge_bundles.py`. Direct script execution from this chat session is still blocked by the terminal/filesystem bridge used by the agent tools, even though the user's own terminal is now configured and working.

**Architecture snapshot:**
The Demiurge pipeline now has stronger guarantees at generation time: quote uniqueness is enforced earlier, author distribution is less clumpy, and the voice wrapper is assigned with local anti-pattern constraints rather than a simple shuffled-cycle scheme.

### 2026-04-08 — GitHub Copilot (Demiurge tooling hardening pass)
**Role:** Content tooling, audit precision, offline cleanup quality

**Done:**

- **Extended `tools/audit_demiurge_bundles.py`** to detect repeated contiguous blocks, not just duplicate individual `citation + author` pairs.
- **Improved `tools/curate_demiurge_bundles.py`** with an optional `--refresh-voice` mode that reassigns canonical Demiurge openings and closings after deduplication.
- **Added deterministic seed support to the voice refresh path** so local cleanup remains reproducible.
- **Updated `CLAUDE.md` guidance** to point future sessions to the stronger audit signal and the recommended local cleanup invocation.

**Validation note:** Static error checking passed for both updated tooling files. Script execution is still blocked in this chat session by the unstable workspace terminal/filesystem provider.

**Architecture snapshot:**
The Demiurge maintenance workflow now distinguishes between three failure modes: schema/count issues, duplicate quote identity, and repeated contiguous content blocks. Offline cleanup can now repair both quote uniqueness and voice-pattern quality in one pass.

### 2026-04-08 — GitHub Copilot (Offline Demiurge bundle curation tool)
**Role:** Content tooling, repository repair path

**Done:**

- **Added `tools/curate_demiurge_bundles.py`** to clean the checked-in Demiurge JSON bundles locally, without relying on network fetches.
- **Implemented normalized `citation + author` deduplication** for existing bundle files while preserving the expected `{opening, citation, author, closing}` schema.
- **Added hard target trimming** so curated bundles can be reduced back to the intended per-sector size instead of keeping oversized generated output.
- **Hooked post-curation validation into the existing bundle validator** so local cleanup reports any remaining structural or count issues immediately.
- **Updated project guidance in `CLAUDE.md`** to treat local curation as an explicit recovery path alongside full regeneration.

**Validation note:** Static error checking for `tools/curate_demiurge_bundles.py` passed. I could not execute the tool in this session because the workspace terminal/file-system provider remains unstable for direct script runs.

**Architecture snapshot:**
The Demiurge content workflow now has three layers: generation (`prepare_demiurge_bundles.py`), auditing (`audit_demiurge_bundles.py`), and offline repair of checked-in data (`curate_demiurge_bundles.py`). This makes bundle integrity recoverable even when source fetches are unavailable or the repository already contains bad generated output.

### 2026-04-08 — GitHub Copilot (Demiurge bundle audit follow-up)
**Role:** Content audit, project-state verification

**Done:**

- **Audited the checked-in Demiurge bundles** in `assets/texts/demiurge/` and confirmed the current repository state is worse than the previous note implied.
- **Verified that each of the five sector bundles currently contains 370 responses**, not 200, so the repository guidance had become stale again after later content generation.
- **Confirmed widespread exact duplicate `citation + author` pairs** inside every sector bundle, with repeated contiguous content blocks at regular offsets.
- **Confirmed no obvious JSON schema breakage** in the audited bundles: the sector wrapper and `{opening, citation, author, closing}` entries remain structurally valid.

**Validation note:** The workspace terminal provider is still failing to attach to `/workspaces/archive-of-oblivion`, so the audit was completed through direct repository inspection rather than by executing the local Python audit script in-shell.

**Architecture snapshot:**
The open Demiurge issue is now clearly a repository-content integrity problem: the shipped bundles are oversized and internally cyclical, which reduces the practical effectiveness of the 20-entry anti-repetition buffer in `DemiurgeService`.

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
