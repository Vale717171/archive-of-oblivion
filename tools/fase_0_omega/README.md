# Fase 0-omega — LLM Validation Suite
*L'Archivio dell'Oblio — GDD §17*

> **DA ESEGUIRE PRIMA DI QUALSIASI ALTRA COSA.**
> Il componente LLM è il più rischioso dell'intero progetto.

Questa cartella contiene due app Flutter minimali per validare l'inferenza LLM on-device
su Android fisico. L'obiettivo è scoprire quale soluzione funziona **prima** di costruire
il gioco attorno ad essa.

---

## Prerequisiti

- Flutter SDK installato localmente
- Un device Android fisico connesso via USB con USB debugging abilitato
- `adb` nel PATH (`flutter doctor` deve mostrare il device)
- ~1 GB libero sul device (Test 1) o ~3 GB (Test 2)

Verifica il device:
```bash
adb devices
# deve mostrare: <serial>  device
```

---

## TENTATIVO 1 — flutter_llama (~4 ore)

**Cartella:** `llm_test_1/`
**Modello:** Qwen 2.5 0.5B Instruct Q4_K_M (~350 MB)
**App finale se passa:** ~500 MB

### Step 1 — Scarica il modello

```bash
# Da HuggingFace (browser o wget):
# https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf

# Con wget:
wget "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"
```

### Step 2 — Crea il progetto Flutter e copia i file

```bash
flutter create llm_test_1 --org com.archivio.test
cd llm_test_1

# Copia i file da questo repo:
cp path/to/repo/tools/fase_0_omega/llm_test_1/pubspec.yaml .
cp path/to/repo/tools/fase_0_omega/llm_test_1/lib/main.dart lib/
```

### Step 3 — Applica le patch Android

Leggi `llm_test_1/android_patches.md` e applica le modifiche a:
- `android/app/build.gradle` (minSdk 26, largeHeap)
- `android/app/src/main/AndroidManifest.xml` (largeHeap, externalStorage)

### Step 4 — Dipendenze e build

```bash
flutter pub get
flutter run --release  # DEVICE FISICO — non emulatore
```

> ⚠️ **Usa sempre `--release`** — debug mode è 3-5x più lento e dà false negatives.

### Step 5 — Carica il modello sul device

L'app mostra il path atteso. Fai `adb push`:

```bash
# Il path lo vedi nell'app (schermata iniziale)
# Di solito è: /sdcard/Download/qwen2.5-0.5b-instruct-q4_k_m.gguf
adb push qwen2.5-0.5b-instruct-q4_k_m.gguf /sdcard/Download/
```

### Step 6 — Esegui il test

Nell'app:
1. Verifica che il file sia trovato (indicatore verde)
2. Premi **▶ START TESTS**
3. Attendi il completamento di tutti i 5 test prompts
4. Leggi il verdetto finale

### Criteri di successo (GDD §17)

| Criterio | Soglia |
|---|---|
| Caricamento modello | < 60 secondi |
| Generazione per prompt | < 20 secondi (100 token) |
| Output sensato in inglese | non gibberish |
| 5 run consecutive | senza crash |
| RAM occupata | < 1.5 GB (misura con Android Studio Profiler) |

**Se passa → usa flutter_llama per il gioco. Procedi a [Risultati](#risultati).**
**Se fallisce → procedi a Tentativo 2.**

---

## TENTATIVO 2 — mediapipe_genai (~4 ore)

**Cartella:** `llm_test_2/`
**Modello:** Gemma 2 2B IT GPU int8 (~1.3 GB, compresso)
**App finale se passa:** ~1.5–2.5 GB
**Nota:** Cambia il formato dei prompt — Gemma usa `<start_of_turn>user` invece di `<|user|>`.

### Step 1 — Scarica il modello Gemma

```bash
# Gemma 2 2B IT (versione GPU, int8, più leggera):
# https://www.kaggle.com/models/google/gemma-2/tfLite/gemma2-2b-it-gpu-int8

# OPPURE scarica direttamente da AI Edge:
# https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference#gemma

# File atteso: gemma-2b-it-gpu-int8.bin  (~1.3 GB)
# OPPURE: gemma2-2b-it-gpu-int8.bin
```

> Per scaricare Gemma devi accettare i termini di licenza Google su Kaggle/HuggingFace.

### Step 2 — Crea il progetto Flutter e copia i file

```bash
flutter create llm_test_2 --org com.archivio.test
cd llm_test_2

cp path/to/repo/tools/fase_0_omega/llm_test_2/pubspec.yaml .
cp path/to/repo/tools/fase_0_omega/llm_test_2/lib/main.dart lib/
```

### Step 3 — Applica le patch Android

Leggi `llm_test_2/android_patches.md` e applica le modifiche.

### Step 4 — Dipendenze e build

```bash
flutter pub get
flutter run --release
```

### Step 5 — Carica il modello sul device

Il modello è troppo grande per gli assets — va su storage esterno:

```bash
# Crea la cartella di destinazione
adb shell mkdir -p /sdcard/Download/

# Push del modello (1.3 GB — può richiedere 5-10 minuti)
adb push gemma-2b-it-gpu-int8.bin /sdcard/Download/

# Verifica
adb shell ls -lh /sdcard/Download/gemma-2b-it-gpu-int8.bin
```

### Step 6 — Esegui il test

Nell'app:
1. Il path del modello è precompilato (`/sdcard/Download/gemma-2b-it-gpu-int8.bin`)
2. Modificalo se hai usato un nome file diverso
3. Premi **▶ START TESTS**

### Criteri di successo (GDD §17)

| Criterio | Soglia |
|---|---|
| Caricamento modello | < 60 secondi |
| Generazione per prompt | < 15 secondi (MediaPipe ottimizza meglio) |
| Output sensato in inglese | non gibberish |
| 5 run consecutive | senza crash |
| RAM occupata | < 2 GB |

> **Differenza chiave:** se questo passa, tutti i template prompt del gioco
> (GDD §20) vanno adattati dal formato Qwen (`<|system|>`) al formato Gemma
> (`<start_of_turn>user ... <end_of_turn>`). L'app di test già usa Gemma format.

**Se passa → usa mediapipe_genai per il gioco.**

---

## TENTATIVO 3 — FFI Custom llama.cpp (~8 ore)

Solo se Tentativo 1 e 2 falliscono entrambi.

Richiede:
1. Android NDK r25c+ installato
2. Compilare llama.cpp come libreria condivisa ARM64:
   ```bash
   git clone https://github.com/ggerganov/llama.cpp
   cd llama.cpp
   mkdir build-android && cd build-android
   cmake .. -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
            -DANDROID_ABI=arm64-v8a \
            -DANDROID_PLATFORM=android-26 \
            -DLLAMA_BUILD_TESTS=OFF \
            -DLLAMA_BUILD_EXAMPLES=OFF
   make -j4
   # Produce: libllama.so
   ```
3. Creare binding Dart con `dart:ffi`
4. Copiare `libllama.so` in `android/app/src/main/jniLibs/arm64-v8a/`

Se anche questo fallisce → **STOP**. Il gioco va riprogettato (versione desktop
o LLM remoto). Aggiorna GDD §22.

---

## Risultati

Dopo aver completato i test, compila `results_template.md` e committalo nel repo.

---

## Decision Tree

```
flutter_llama OK?
  ✅ SÌ → Usa flutter_llama, Qwen 0.5B, app ~500 MB
           Aggiungi flutter_llama ^1.0.0 a pubspec.yaml principale
           Sostituisci _llmStub() in game_engine_provider.dart
  ❌ NO →
         mediapipe_genai OK?
           ✅ SÌ → Usa mediapipe_genai, Gemma 2B, app ~1.5-2.5 GB
                   Adatta tutti i prompt template da Qwen format a Gemma format (GDD §20)
                   Sostituisci _llmStub() in game_engine_provider.dart
           ❌ NO →
                   FFI Custom OK?
                     ✅ SÌ → Aggiungi 8 ore al progetto, usa Qwen 0.5B
                     ❌ NO → STOP — riprogetta o passa a versione desktop/server
```
