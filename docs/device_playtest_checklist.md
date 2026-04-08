# Device Playtest Checklist

Target device: Android API 26+ on a mid-range device with about 3 GB RAM.

Purpose: verify full progression, persistence, audio, UI stability, and ending logic on a physical device after the Demiurge bundle pipeline and current UX changes.

## Preflight

- Launch the app from a clean install and confirm the title/home screen appears without crashes.
- Confirm background music starts gracefully or fails silently without blocking the app.
- Confirm a new run starts at `intro_void` and the background resolves to the soglia image.
- Confirm command input works both by typing and by tapping quick-command chips.
- Confirm `hint`, `hint more`, and `hint full` all return contextual help.

## Save And Resume

- Start a run, move to at least one new node, then fully close and reopen the app.
- Confirm current node, visible transcript, inventory, completed puzzles, counters, and psycho state are preserved.
- From the game menu, trigger `New game`, confirm the warning dialog appears, and verify the full reset path returns the run to `intro_void`.

## Garden Route

- Reach the Garden sector and confirm normal navigation between its nodes works.
- Solve the leaf-order gate and confirm the corresponding exit unlocks.
- Verify wrong answers do not soft-lock progression and still allow retry.
- Confirm any granted item appears in inventory and that transcript reset behavior only happens on meaningful success.

## Observatory Route

- Reach the Observatory and verify movement plus puzzle hinting.
- Test the lens-combination gate and the blindfold/calibration flows mentioned by the engine hints.
- Confirm the node transitions unlocked by Observatory puzzles persist after app restart.

## Gallery Route

- Reach the Gallery and verify reflection and mirror-related progression.
- Test `walk backward`, anomalous-tile interaction, and pentagon construction.
- Confirm the weight-sensitive mirror outcome behaves correctly:
  - with zero psycho weight, verify the clean mirror result and simulacrum acquisition
  - with non-zero psycho weight, verify the chaotic mirror failure path

## Laboratory Route

- Reach the Laboratory and verify decipher/collect interactions for substances.
- Test `calcinate`, the temperature-setting step, and the Bain-Marie wait/return condition.
- Confirm the Great Work gate only opens after all required laboratory conditions are met.

## La Zona

- During ordinary navigation outside boss and finale contexts, keep moving until La Zona triggers naturally.
- Confirm entering La Zona increments the encounter counter and presents verse, environment, and introspective question text.
- Answer the question with free text and confirm the response is accepted and saved.
- Repeat until multiple encounters have occurred and verify later activations still work.
- Confirm La Zona does not trigger from forbidden contexts such as `il_nucleo`, `finale_*`, or Quinto transitions.

## Fifth Sector

- Reach `quinto_landing` only after the four main sectors are properly completed.
- Enter all four memory-price rooms:
  - `quinto_childhood`
  - `quinto_youth`
  - `quinto_maturity`
  - `quinto_old_age`
- In each room, verify the intended free-text or command-driven offering works.
- Confirm the quick-command chips for `Say ...` and `Write ...` only prefill input and do not auto-submit incomplete commands.
- Verify descent from `quinto_landing` to `quinto_ritual_chamber` is blocked until all four memory prices are paid.

## Ritual And Finale

- In `quinto_ritual_chamber`, place each simulacrum in the cup, stir, and drink.
- Confirm ritual completion unlocks descent to `il_nucleo`.
- In `il_nucleo`, verify mundane items are stripped while simulacra are preserved.
- Exercise all three ending branches and confirm each reaches the correct destination:
  - `finale_acceptance`
  - `finale_oblivion`
  - `finale_eternal_zone`
- On `finale_acceptance`, verify the wake-up interaction works.

## UI And Audio Stability

- Confirm typewriter text can be skipped safely and does not throw setState/dispose issues.
- Verify background image changes correctly by sector and remains subtle after transition flashes.
- Confirm special audio routing behaves correctly:
  - Quinto landing triggers the memory cue
  - finale acceptance uses the Goldberg cue
  - finale oblivion uses silence
  - boss context uses the oblivion cue without profile override corruption
- Check that ordinary psycho-profile ambience still modulates correctly outside special-track contexts.

## Regression Watchlist

- Inventory must still add weightless simulacra correctly.
- Exit gates must not unlock early after load/resume.
- Hints must match the current node and not leak unrelated puzzle answers.
- Quick-command chips must not send incomplete verbs.
- No duplicate Demiurge narration should appear back-to-back in normal play.

## Pass Criteria

- No crashes during a full run from `intro_void` to any ending.
- No irreversible soft-locks in sector progression, Quinto access, ritual sequence, or finale selection.
- Save/load remains stable across at least one restart in early game, mid game, and late game.
- Audio and background transitions remain non-blocking even if assets fail to load.