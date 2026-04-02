# Android Patches — llm_test_1 (flutter_llama)

Dopo `flutter create llm_test_1`, applica queste modifiche prima di `flutter run`.

---

## 1. `android/app/build.gradle`

Trova il blocco `defaultConfig` e modifica `minSdk`:

```gradle
android {
    defaultConfig {
        // Cambia da 21 (default Flutter) a 26 (requisito GDD)
        minSdk 26
        targetSdk 34
        // ...
    }
}
```

---

## 2. `android/app/src/main/AndroidManifest.xml`

Modifica il tag `<application>` per abilitare large heap e lo storage access:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permesso per leggere il modello da /sdcard/Download/ -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <!-- Android 11+ richiede questo per accedere a storage esterno -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

    <application
        android:largeHeap="true"
        android:label="llm_test_1"
        android:icon="@mipmap/ic_launcher">
        <!-- ... resto invariato ... -->
    </application>

</manifest>
```

> `android:largeHeap="true"` è **critico** — senza di esso il modello può
> causare un OOM (Out of Memory) kill durante il caricamento.

---

## 3. `android/gradle.properties`

Aggiungi queste righe per aumentare la memoria Gradle e abilitare multidex:

```properties
android.useAndroidX=true
android.enableJetifier=true
# Aumenta la heap Gradle per la build (non runtime)
org.gradle.jvmargs=-Xmx4096m
```

---

## 4. Verifica build

```bash
flutter clean
flutter pub get
flutter build apk --release
# poi:
flutter install
# oppure direttamente:
flutter run --release
```

---

## Note su Vulkan GPU (opzionale)

Se vuoi testare l'accelerazione GPU (Vulkan), modifica in `lib/main.dart`:

```dart
final config = LlamaConfig(
  // ...
  nGpuLayers: -1,  // -1 = all layers on GPU
  useGpu: true,
);
```

E aggiungi al `AndroidManifest.xml`:

```xml
<uses-feature android:name="android.hardware.vulkan.level" android:required="false" />
```

I risultati con GPU potrebbero essere significativamente più veloci su device
con Adreno 600+ o Mali G-77+. Testa entrambe le configurazioni e annota i risultati
in `results_template.md`.
