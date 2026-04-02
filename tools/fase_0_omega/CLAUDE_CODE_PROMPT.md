# Claude Code — Fase 0-omega Session Prompt
*Copia e incolla questo prompt nella prima sessione Claude Code per la validazione LLM.*

---

## PROMPT DA COPIARE (incolla direttamente nella chat Claude Code)

```
Read CLAUDE.md and docs/work_log.md first — they contain the project conventions
and what has been done so far.

Your task for this session is Fase 0-omega (GDD §17):
build and wire up the two LLM validation test apps that are already scaffolded
in tools/fase_0_omega/.

━━━ CONTEXT ━━━
The game depends entirely on an on-device 0.5B LLM. We need to validate that
it works on a physical Android device before building anything else.
Two Flutter standalone test apps are already scaffolded:
  - tools/fase_0_omega/llm_test_1/ (flutter_llama + Qwen 2.5 0.5B Q4_K_M)
  - tools/fase_0_omega/llm_test_2/ (mediapipe_genai + Gemma 2B)

The pubspec.yaml and lib/main.dart files are already in place.
The android_patches.md files document exactly what needs to be changed.

━━━ YOUR JOB ━━━
Create the full Flutter projects for both test apps and apply all required patches,
so they are ready to build and deploy. I will handle downloading the models and
running them on the physical device.

Specifically:

1. TENTATIVO 1 — flutter_llama:
   a. Run: flutter create tools/fase_0_omega/llm_test_1_project --org com.archivio.test
      (use a _project suffix so git doesn't confuse it with the scaffolded folder)
   b. Copy tools/fase_0_omega/llm_test_1/pubspec.yaml into the new project
   c. Copy tools/fase_0_omega/llm_test_1/lib/main.dart into the new project
   d. Apply ALL patches from tools/fase_0_omega/llm_test_1/android_patches.md:
      - android/app/build.gradle: minSdk 26, targetSdk 34
      - android/app/src/main/AndroidManifest.xml: largeHeap="true",
        READ_EXTERNAL_STORAGE permission, MANAGE_EXTERNAL_STORAGE permission
      - android/gradle.properties: org.gradle.jvmargs=-Xmx4096m
   e. Run: flutter pub get (inside the project folder)
   f. Verify: flutter analyze — fix any issues

2. TENTATIVO 2 — mediapipe_genai:
   Same steps as above but using:
   - tools/fase_0_omega/llm_test_2/ as source
   - Project folder: tools/fase_0_omega/llm_test_2_project
   - Additional patch: aaptOptions { noCompress "tflite", "bin" } in build.gradle
   - Run: flutter pub get && flutter analyze

3. After both projects are ready:
   - Print the exact adb commands the human needs to run for each test
   - Print the exact flutter run --release command for each
   - Confirm what the human needs to do manually (download models, push via adb,
     run on physical device, fill results_template.md)

━━━ IMPORTANT CONSTRAINTS ━━━
- Use --release flag always (debug mode gives false performance results)
- Physical device only — emulator results are useless (no ARM SIMD/NEON)
- Do not modify tools/fase_0_omega/llm_test_1/ or llm_test_2/ source folders —
  they are the scaffolded templates; the _project folders are the actual builds
- The model files (.gguf, .bin) are NOT in the repo — too large for git
  The human pushes them via adb

━━━ END OF SESSION ━━━
When done, provide:
1. Confirmation that both projects build (flutter pub get + analyze pass)
2. A checklist of what the human needs to do on the physical device
3. A work log entry ready to prepend to docs/work_log.md
```

---

## Cosa fa Claude Code / cosa fa l'umano

| Passo | Chi lo fa |
|---|---|
| `flutter create` + copia file + patch Android | **Claude Code** |
| `flutter pub get` + `flutter analyze` | **Claude Code** |
| Scarica `qwen2.5-0.5b-instruct-q4_k_m.gguf` da HuggingFace | **Tu** |
| Scarica `gemma-2b-it-gpu-int8.bin` da Google AI Edge | **Tu** (solo se T1 fallisce) |
| `adb push model.gguf /sdcard/Download/` | **Tu** |
| `flutter run --release` (device fisico connesso) | **Tu** |
| Leggere i risultati nell'app e compilare `results_template.md` | **Tu** |
| Committare `results_template.md` compilato nel repo | **Tu** |

---

## Sessione successiva (dopo i test sul device)

Una volta che `results_template.md` è compilato con il verdict (T1 passa / T1 fallisce
→ T2 passa / ecc.), apri una nuova sessione Claude Code con questo prompt:

```
Read CLAUDE.md and docs/work_log.md.

Fase 0-omega is complete. The results are in tools/fase_0_omega/results_template.md.
[incolla il contenuto del file o di' a Claude Code di leggerlo]

Your task: replace _llmStub() in lib/features/game/game_engine_provider.dart
with the real LLM integration using [PACKAGE SCELTO].

Also fix the known simulacra inventory bug (described in CLAUDE.md — Known bug section).
```

---

## Link modelli (scarica prima di iniziare i test)

**Tentativo 1 — Qwen 2.5 0.5B Q4_K_M (~350 MB):**
```
https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf
```

**Tentativo 2 — Gemma 2B IT GPU int8 (~1.3 GB):**
```
https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference#models
```
(richiede accettazione termini di licenza Google)

---

## Setup rapido (comandi da terminale prima di aprire Claude Code)

```bash
# Clona (se non già fatto) e spostati nel repo
cd /path/to/archive-of-oblivion

# Verifica che Flutter sia installato
flutter doctor

# Verifica device fisico connesso
adb devices
# deve mostrare: <serial>  device

# Apri Claude Code nella root del progetto
claude
# oppure con l'editor:
# code . && claude
```
