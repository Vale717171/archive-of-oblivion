# Android Patches — llm_test_2 (mediapipe_genai)

Dopo `flutter create llm_test_2`, applica queste modifiche prima di `flutter run`.

---

## 1. `android/app/build.gradle`

```gradle
android {
    defaultConfig {
        minSdk 26  // GDD requisito
        targetSdk 34
    }
    // mediapipe richiede aaptOptions per escludere i file di compressione
    aaptOptions {
        noCompress "tflite", "bin"
    }
}
```

---

## 2. `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permessi per leggere il modello da storage esterno -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

    <application
        android:largeHeap="true"
        android:label="llm_test_2"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
    </application>

</manifest>
```

---

## 3. `android/build.gradle` (top-level)

Aggiungi il repository Maven di Google se non presente:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

---

## 4. `android/gradle.properties`

```properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4096m
```

---

## 5. Verifica build

```bash
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

---

## Note su GPU vs CPU

MediaPipe supporta GPU via OpenCL/OpenGL. Il test prova prima GPU, poi CPU come
fallback. Annota nei risultati quale modalità è stata usata (il log dell'app
lo riporta nel campo status).

**Modelli compatibili con mediapipe_genai:**
- `gemma-2b-it-gpu-int8.bin` — GPU accelerated, ~1.3 GB (raccomandato)
- `gemma2-2b-it-gpu-int8.bin` — Gemma 2 variant
- `gemma-2b-it-cpu-int8.bin` — CPU only, ~1.3 GB

Scarica da: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference#models

---

## Note importanti se questo Test PASSA

Se mediapipe_genai supera i criteri, **tutti i prompt template del gioco devono
essere convertiti** dal formato Qwen a formato Gemma:

| Qwen (Test 1 / GDD §20) | Gemma (Test 2) |
|---|---|
| `<\|system\|>\n{system}\n<\|user\|>\n{user}\n<\|assistant\|>` | `<start_of_turn>user\n{system}\n\n{user}\n<end_of_turn>\n<start_of_turn>model\n` |

Aggiorna `lib/features/llm/llm_context_service.dart` e tutti i template in
`assets/prompts/` (GDD §18).
