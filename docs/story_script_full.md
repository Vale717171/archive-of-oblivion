# Story Script (Full Pass) — The Archive of Oblivion

This document is a revision-friendly script of the current playable narrative flow.
Gameplay text is kept in English (as in-game), while structure notes are in Italian for editing convenience.

## 0. Conventions
- `[PLAYER]` = comando o scelta giocatore.
- `[ARCHIVE]` = testo fisso del motore.
- `[NARRATOR: ALL THAT IS]` = risposta variabile Echo/Demiurge (citazione + apertura/chiusura), da considerare slot poetico.
- `[GATE]` = testo di blocco diegetico.
- `[VARIANT]` = ramificazione o stato alternativo.

---

## ACT I — Awakening / Threshold

### Scene 1 — `intro_void`
[ARCHIVE]
"Silence. Then — awareness. You exist... In your pocket: a small empty Notebook. A path forms ahead."

[PLAYER] `go north` (or `forward` / `ahead`)

[NARRATOR: ALL THAT IS]
- Variable response (sector: threshold / universal), often with citation.

### Scene 2 — `la_soglia` (The Threshold)
[ARCHIVE]
"A circular rotunda... Four doors at cardinal points... pentagonal pedestal with five recesses..."

Core objective setup:
- collect 4 simulacra from 4 sectors;
- return and ascend to Memory (Fifth Sector).

[PLAYER] `go north | east | south | west`

---

## ACT II — Four Sectors (required)

## 1) NORTH — Garden of Epicurus

### 1.1 `garden_portico`
[ARCHIVE] Portico, Epicurean words on columns.

### 1.2 `garden_cypress` — Leaves order gate
[ARCHIVE] Seven leaves with words.

[PLAYER] `arrange leaves prudence friendship pleasure simplicity absence tranquillity memory`

[ARCHIVE]
"You arrange the leaves... The avenue opens north."
[NARRATOR: ALL THAT IS] variable overlay.

[GATE if unsolved]
"The fallen leaves bar your way... Hint: arrange leaves [seven words in Epicurean order]."

### 1.3 `garden_fountain` — Waiting gate
[PLAYER] `wait` x3

[ARCHIVE, step 1-2] "You wait..."
[ARCHIVE, step 3]
"A third time... a single drop... The path north opens."
[NARRATOR: ALL THAT IS] variable overlay.

[GATE if early]
"The passage north is not yet open... Hint: wait — and again, and again."

### 1.4 `garden_stelae` — Inscription gate
[PLAYER] `write` / `inscribe` (missing maxim text)

[ARCHIVE]
"The stylus moves... The words appear..."
[NARRATOR: ALL THAT IS] variable overlay.

[GATE if unsolved]
"The grove will not receive you... Hint: inscribe [the missing maxim]..."

### 1.5 `garden_grove` + alcoves (final Garden logic)
Required progression:
- walk through both alcoves without taking items;
- then `deposit everything` at statue.

[ARCHIVE]
"You place everything at the statue's feet..."
[NARRATOR: ALL THAT IS] variable overlay.

Reward:
- **Simulacrum: Ataraxia**

---

## 2) EAST — Blind Observatory

### 2.1 `obs_antechamber` — Lens combination
[PLAYER] `combine moon mercury sun`

[ARCHIVE]
"The mount accepts the sequence..."
[NARRATOR: ALL THAT IS] variable overlay.

[GATE]
"The corridor is dark... Hint: combine lens [Moon] [Mercury] [Sun]."

### 2.2 `obs_corridor` — Heisenberg move
[PLAYER] `walk blindfolded`

[ARCHIVE]
"You walk through without touching anything..."
[NARRATOR: ALL THAT IS] variable overlay.

### 2.3 `obs_void` — Silence and fluctuation
[PLAYER] `wait` x7 then `measure fluctuation`

[ARCHIVE]
"The seventh turning..."
[NARRATOR: ALL THAT IS] variable overlay.

### 2.4 `obs_archive` — Constant input
[PLAYER] `enter 1`

[ARCHIVE]
"The panel accepts it... In natural units... The passage south opens."
[NARRATOR: ALL THAT IS] variable overlay.

### 2.5 `obs_calibration`
[PLAYER] `calibrate 0 0 0`

[ARCHIVE]
"The calibration is set. The dome is open."

### 2.6 `obs_dome` — Finale sequence
[PLAYER] `invert mirror`
[PLAYER] `confirm` x3
[PLAYER] `observe`

[ARCHIVE]
"You look into the inverted telescope... In your hands: The Constant."
[NARRATOR: ALL THAT IS] variable overlay.

Reward:
- **Simulacrum: The Constant**

---

## 3) SOUTH — Gallery of Mirrors

### 3.1 `gallery_hall`
[PLAYER] `walk backward`

[ARCHIVE]
"You walk backward..."
[NARRATOR: ALL THAT IS] variable overlay.

### 3.2 `gallery_corridor`
[PLAYER] `press anomalous tile`

[ARCHIVE]
"You press the anomalous tile..."
[NARRATOR: ALL THAT IS] variable overlay.

### 3.3 `gallery_proportions`
[PLAYER] `construct pentagon`

[ARCHIVE]
"You construct the pentagon..."
[NARRATOR: ALL THAT IS] variable overlay.

### 3.4 `gallery_copies`
[PLAYER] describe/write/paint missing element x3

[ARCHIVE]
"The third description..."
[NARRATOR: ALL THAT IS] variable overlay.

### 3.5 `gallery_originals`
[PLAYER] `paint ...` (long-form creative text)

[ARCHIVE]
"You paint..."
[NARRATOR: ALL THAT IS] variable overlay.

### 3.6 `gallery_dark` <-> `gallery_light`
Tunnel requires abandonment.

[PLAYER] `drop [item]`

[ARCHIVE]
"You set down the [item]..."

### 3.7 `gallery_central` — Mirror resolution
[PLAYER] `break mirror`

[ARCHIVE]
- if low burden/correct state: gets simulacrum progression text;
- if wrong state: chaotic variant / rejection.

Reward path:
- **Simulacrum: The Proportion**

---

## 4) WEST — Alchemical Laboratory

### 4.1 `lab_vestibule`
[PLAYER] `offer [concept]` x3 (distinct)

[ARCHIVE]
"You offer..."
[NARRATOR: ALL THAT IS] variable overlay.

### 4.2 `lab_substances`
[PLAYER] `decipher symbols`
[PLAYER] `collect mercury`
[PLAYER] `collect sulphur`
[PLAYER] `collect salt`

[ARCHIVE]
"All three substances of the Tria Prima are gathered..."
[NARRATOR: ALL THAT IS] variable overlay.

### 4.3 `lab_furnace`
[PLAYER] `calcinate` then `wait` loop until completion

[ARCHIVE]
"The fifth turning... The furnace path south is clear."
[NARRATOR: ALL THAT IS] variable overlay.

### 4.4 `lab_alembic`
[PLAYER] `set temperature gentle`

[ARCHIVE]
"You set the temperature to Gentle..."

### 4.5 `lab_bain_marie`
Requires leaving and returning after other paths/visits.

[ARCHIVE return]
"The outer water has changed... The path south to the Great Work opens."

### 4.6 `lab_great_work`
Planetary order placement loop (7 steps).

[ARCHIVE]
"The seventh circle accepts the final placement..."
[NARRATOR: ALL THAT IS] variable overlay.

### 4.7 `lab_sealed`
[PLAYER] `blow`

[ARCHIVE]
"You breathe into the alembic..."
[NARRATOR: ALL THAT IS] variable overlay.

Reward:
- **Simulacrum: The Catalyst**

---

## Intermezzo — La Zona (procedural anomaly)
Can trigger during transits.

[ARCHIVE]
"The Zone does not release you yet... It is still waiting for your answer."

Flow:
- Zone asks an introspective question.
- Player gives free-text answer.
- If accepted, return gate clears.

[VARIANT]
- repeated evasive responses keep player longer in Zone loop.

---

## ACT III — Fifth Sector (Memory)

### Entrance gate from Threshold
[PLAYER] `go up` from `la_soglia`

Required:
- all 4 simulacra in inventory;
- sector depth thresholds met (garden/observatory/gallery/laboratory).

[GATE if depth missing]
"The fifth stair forms, then folds back into stone..."

### 5.1 `quinto_landing`
[ARCHIVE]
"A spiral staircase brought you here..."

Branches:
- Childhood
- Youth
- Maturity
- Old Age

### 5.2 `quinto_childhood`
[PLAYER] `write [first true word]`

[ARCHIVE]
"You write... The price has been paid."
[NARRATOR: ALL THAT IS] variable overlay.

### 5.3 `quinto_youth`
[PLAYER] `write [promise not kept]`

[ARCHIVE]
"You write..."
[NARRATOR: ALL THAT IS] variable overlay.

### 5.4 `quinto_maturity`
[PLAYER] `say [what was never said]` (or `write` variant)

[ARCHIVE]
"You speak into the telephone... The glasses on the desk clear. You may leave."
[NARRATOR: ALL THAT IS] variable overlay.

### 5.5 `quinto_old_age`
[PLAYER] `write [how to be remembered]`

[ARCHIVE]
"You write..."
[NARRATOR: ALL THAT IS] variable overlay.

### 5.6 `quinto_ritual_chamber`
[PLAYER] `place ataraxia in cup`
[PLAYER] `place the constant in cup`
[PLAYER] `place the proportion in cup`
[PLAYER] `place the catalyst in cup`
[PLAYER] `stir`
[PLAYER] `drink`

Extra hard gates before descent:
- memory depth threshold met;
- quote exposure threshold met.

[GATE if quote exposure missing]
"The descent darkens, then pauses... Too few voices have passed through you..."

On success:
[ARCHIVE]
"You drink... The passage below opens."
[NARRATOR: ALL THAT IS] variable overlay.

Transition:
- new node => `il_nucleo`

---

## ACT IV — The Nucleus (Final confrontation)

### `il_nucleo`
[ARCHIVE]
"A space with no walls..."

Boss interaction categories:
- surrender language -> Oblivion route;
- remain language -> Eternal Zone route;
- human/acceptance language -> Acceptance route;
- other -> escalating attempts, burden-sensitive pressure.

[VARIANT: burdened attempts]
The antagonist references carried mundane items and resists resolution until psychological burden is released.

Useful purgative commands during confrontation:
- `drop [item]`
- `deposit everything` (boss-context behavior keeps simulacra, clears mundane burden)

---

## ACT V — Endings

## Ending A — `finale_acceptance`
[ARCHIVE]
"The Archive grows transparent..."

Final epilogue command:
[PLAYER] `wake up`

[ARCHIVE]
"The Archive is empty. Time has started flowing again. Outside it is cold, but you are no longer alone. — FINE —"

## Ending B — `finale_oblivion`
[ARCHIVE]
Minimal/void output, silence-oriented closure.

## Ending C — `finale_eternal_zone`
[ARCHIVE]
"You remain. The variations begin. They do not end."

Loop back:
- can return to `la_zona` branch state.

---

## All key diegetic gate lines (current)

### Core puzzle gates
- leaves_arranged: "The fallen leaves bar your way..."
- fountain_waited: "The passage north is not yet open..."
- stele_inscribed: "The grove will not receive you..."
- lenses_combined: "The corridor is dark..."
- heisenberg_walked: "Sight is the obstacle..."
- void_fluctuation_measured: "The calibration chamber is sealed..."
- archive_constant_entered: "The panel awaits..."
- obs_calibrated: "The dome is locked..."
- hall_backward_walked: "The way forward is behind you..."
- corridor_tile_pressed: "One tile does not belong..."
- proportion_pentagon_drawn: "A geometric form must be constructed..."
- gallery_item_abandoned: "The tunnel ... requires abandonment."
- lab_offers_complete: "The three statues wait..."
- furnace_calcinated: "Calcination is unfinished..."
- alembic_temperature_set: "The temperature is wrong..."
- bain_marie_complete: "The transformation has not begun..."
- memory_childhood / youth / maturity / old_age: personal price gates
- ritual_complete: "The passage down is sealed. The cup is not ready..."

### New progression hardening gates
- Threshold->Quinto depth gate: "The fifth stair forms, then folds back into stone..."
- Memory->Nucleus depth gate: "The passage trembles but does not yield..."
- Quote exposure gate: "The descent darkens, then pauses..."

---

## Editorial checklist for rewrite pass
- Verify tonal continuity between fixed lines and variable Demiurge slots.
- Tighten repetition in gate lines while preserving diegetic ambiguity.
- Decide desired explicitness ladder for hints 1/2/3 per room.
- Check rhythm of Nucleus escalation vs burden release pacing.
- Review ending contrast (Acceptance warmth vs Oblivion austerity vs Eternal Zone recursion).

---

## Optional next step
If you want, I can generate **an exhaustive raw dump** (node descriptions + examine texts + all fixed command responses) in a second file for line-by-line editing.
