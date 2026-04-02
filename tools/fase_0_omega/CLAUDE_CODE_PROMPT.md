# Claude Code — Fase 0-omega Session Prompt
*Questa sessione si esegue ALLA FINE, quando il gioco completo è installabile sul device.*

---

## Contesto

La validazione LLM avviene sul gioco reale, non su un'app di test isolata. Il motivo:
RAM, audio, SQLite e LLM girano tutti insieme — il test deve rispecchiare le condizioni reali.

A questo punto del progetto:
- Il gioco completo è buildabile e installabile come APK
- `_llmStub()` in `lib/features/game/game_engine_provider.dart` restituisce testi statici
- Tutti i settori, La Zona, il boss finale e il Quinto Settore sono implementati

---

## Prompt da incollare in Claude Code

```
Read CLAUDE.md and docs/work_log.md first.

Fase 0-omega: replace _llmStub() in lib/features/game/game_engine_provider.dart
with a real on-device LLM integration.

━━━ STRATEGY ━━━
Try in order until one works on the physical Android device:

TENTATIVO 1 — flutter_llama (Qwen 2.5 0.5B Q4_K_M, ~350 MB):
  - Add flutter_llama to pubspec.yaml
  - Implement LlmService wrapping flutter_llama
  - Wire up to game_engine_provider replacing _llmStub()
  - Android patches: minSdk 26, largeHeap=true, READ_EXTERNAL_STORAGE
  - Model loaded from /sdcard/Download/ via path_provider

TENTATIVO 2 — mediapipe_genai (Gemma 2B, ~1.3 GB):
  Only if Tentativo 1 fails on device.
  - Swap package, adapt prompt format: <start_of_turn>user / <end_of_turn> / <start_of_turn>model
  - All LLM prompt templates in docs/gdd.md §20 need format adaptation

TENTATIVO 3 — FFI Custom llama.cpp:
  Only if both above fail. High complexity, ~8h setup.

━━━ SUCCESS CRITERIA ━━━
- Load time < 60 seconds
- Generation time < 20 seconds (100 tokens)
- Sensible English output (not gibberish)
- 5 consecutive generations without crash
- RAM < 1.5 GB total (LLM + audio + SQLite)

━━━ YOUR JOB ━━━
1. Implement Tentativo 1 integration
2. Apply required Android patches
3. Build release APK: flutter build apk --release
4. Print the adb install command and what the human needs to test manually
5. Document the result in docs/work_log.md
```

---

## Cosa fa Claude Code / cosa fai tu

| Passo | Chi lo fa |
|---|---|
| Implementa LlmService + patch Android + build APK | **Claude Code** |
| Scarica `qwen2.5-0.5b-instruct-q4_k_m.gguf` da HuggingFace (~350 MB) | **Tu** |
| `adb push model.gguf /sdcard/Download/` | **Tu** |
| `adb install build/app/outputs/apk/release/app-release.apk` | **Tu** |
| Giocare e verificare che l'LLM risponda correttamente | **Tu** |
| Se fallisce, dire a Claude Code di passare al Tentativo 2 | **Tu** |

---

## Link modelli

**Tentativo 1 — Qwen 2.5 0.5B Q4_K_M (~350 MB):**
```
https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf
```

**Tentativo 2 — Gemma 2B IT GPU int8 (~1.3 GB):**
```
https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference#models
```
(richiede accettazione termini di licenza Google)
