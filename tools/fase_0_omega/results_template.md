# Fase 0-omega — Results Template
*Compila questo file dopo aver eseguito i test e committalo nel repo.*
*GDD §17 — L'Archivio dell'Oblio*

**Data test:** _______________
**Device:** _______________ (es. Samsung Galaxy A52, Android 13, Snapdragon 778G, 6 GB RAM)
**Flutter version:** _______________

---

## TENTATIVO 1 — flutter_llama

**Eseguito:** ☐ Sì  ☐ No

**Modello:** Qwen 2.5 0.5B Instruct Q4_K_M
**File:** `qwen2.5-0.5b-instruct-q4_k_m.gguf`
**Dimensione file:** ~350 MB

### Metriche

| Criterio | Valore misurato | Pass/Fail |
|---|---|---|
| Load time | ___s | ☐ Pass (< 60s)  ☐ Fail |
| Test 1 — Zone Narrative | ___s / ___tok/s | ☐ Pass (< 20s)  ☐ Fail |
| Test 2 — Proustian Trigger | ___s / ___tok/s | ☐ Pass (< 20s)  ☐ Fail |
| Test 3 — Narrator Weight 0 | ___s / ___tok/s | ☐ Pass (< 20s)  ☐ Fail |
| Test 4 — Narrator Weight 3+ | ___s / ___tok/s | ☐ Pass (< 20s)  ☐ Fail |
| Test 5 — Antagonist | ___s / ___tok/s | ☐ Pass (< 20s)  ☐ Fail |
| 5 runs senza crash | — | ☐ Pass  ☐ Fail |
| RAM peak (Profiler) | ___ MB | ☐ Pass (< 1500 MB)  ☐ Fail |

### Qualità output (campione — incolla qui il testo generato dal Test 3)

```
[incolla qui l'output del Narrator Weight 0]
```

### Verdict Tentativo 1

☐ **PASSED** → Usa flutter_llama. Non eseguire Tentativo 2.
☐ **FAILED** → Motivo: _______________. Procedi a Tentativo 2.

### Errori o note

```
[stacktrace o note se fallisce]
```

---

## TENTATIVO 2 — mediapipe_genai

**Eseguito:** ☐ Sì  ☐ No  ☐ Non necessario (Tentativo 1 passato)

**Modello:** Gemma 2B IT GPU int8
**File:** `gemma-2b-it-gpu-int8.bin`
**Dimensione file:** ~1.3 GB

### Metriche

| Criterio | Valore misurato | Pass/Fail |
|---|---|---|
| Load time | ___s | ☐ Pass (< 60s)  ☐ Fail |
| Test 1 — Zone Narrative | ___s / ___tok/s | ☐ Pass (< 15s)  ☐ Fail |
| Test 2 — Proustian Trigger | ___s / ___tok/s | ☐ Pass (< 15s)  ☐ Fail |
| Test 3 — Narrator Weight 0 | ___s / ___tok/s | ☐ Pass (< 15s)  ☐ Fail |
| Test 4 — Narrator Weight 3+ | ___s / ___tok/s | ☐ Pass (< 15s)  ☐ Fail |
| Test 5 — Antagonist | ___s / ___tok/s | ☐ Pass (< 15s)  ☐ Fail |
| 5 runs senza crash | — | ☐ Pass  ☐ Fail |
| RAM peak (Profiler) | ___ MB | ☐ Pass (< 2000 MB)  ☐ Fail |
| GPU accelerated | — | ☐ Sì  ☐ No (CPU fallback) |

### Qualità output (campione — incolla qui il testo generato dal Test 3)

```
[incolla qui l'output del Narrator Weight 0]
```

### Verdict Tentativo 2

☐ **PASSED** → Usa mediapipe_genai. Adatta i prompt template (vedi `android_patches.md`).
☐ **FAILED** → Motivo: _______________. Procedi a Tentativo 3 (FFI custom, +8h).

### Errori o note

```
[stacktrace o note se fallisce]
```

---

## TENTATIVO 3 — FFI Custom llama.cpp

**Eseguito:** ☐ Sì  ☐ No  ☐ Non necessario

**Verdict Tentativo 3:**

☐ **PASSED** → Usa FFI custom.
☐ **FAILED** → **STOP** — riprogetta architettura (desktop / LLM remoto).

---

## DECISIONE FINALE

☐ **Soluzione scelta:** _______________
☐ **Prossimo passo:** Sostituire `_llmStub()` in `lib/features/game/game_engine_provider.dart`
☐ **Aggiornare `pubspec.yaml`** con il package scelto
☐ **Aggiornare GDD §17 e §22** con l'esito

---

## Confronto velocità (se hai testato più tentative)

| Soluzione | Load | Avg gen | RAM | App size |
|---|---|---|---|---|
| flutter_llama | ___s | ___s | ___ MB | ~500 MB |
| mediapipe_genai | ___s | ___s | ___ MB | ~1.5–2.5 GB |
| FFI custom | ___s | ___s | ___ MB | ~500 MB |
