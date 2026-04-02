# L'Archivio dell'Oblio — Game Design Document
*Ultimo aggiornamento: aprile 2026*

> **Collaborazione multi-LLM attiva.**
> Ogni sessione di lavoro viene registrata in [`docs/work_log.md`](docs/work_log.md).
> Prima di lavorare: leggi questo documento + il work log. Alla fine: aggiungi la tua voce al log.

---

## 1. IDENTITÀ DEL PROGETTO

**Titolo di lavoro:** L'Archivio dell'Oblio (alt: L'Archivio dei Concetti Perduti)
**Genere:** Avventura Testuale / Interactive Fiction Psico-Filosofica
**Piattaforma:** Android
**Lingua del gioco:** Inglese (tutti i testi narrativi, dialoghi, descrizioni, prompt LLM — traduzione dall'italiano richiede cura per preservare il tono etereo)
**Motore:** Ibrido — Parser logico tradizionale + LLM 0.5B in locale
**Tematica centrale:** La lotta tra la preservazione della memoria (che porta dolore ma identità) e l'oblio totale (che porta pace ma annullamento)
**Presentazione:** Solo testo e musica — niente immagini. Coraggioso, coerente con l'estetica anni '80, più leggero da sviluppare.

**NOTA CRITICA:** L'LLM non è opzionale. Senza di esso il gioco perde la Zona procedurale, i trigger proustiani, il boss finale personalizzato, l'aroma dell'infuso. Diventa un parser anni '80 con audio. Tutta la sua essenza dipende dall'LLM.

---

## 2. VISIONE GENERALE

Un'avventura testuale per Android ispirata ai giochi degli anni '80, ma radicalmente diversa nello spirito. Il viaggio del protagonista non è alla ricerca di armi o tesori, ma alla scoperta della saggezza e della profondità del pensiero umano. Un atto culturale oltre che un gioco.

**Il giocatore è il protagonista** — nessuna identità predefinita, nessun nome.

---

## 3. PREMESSA NARRATIVA

Il giocatore si sveglia in un non-luogo chiamato L'Archivio. Non ricorda chi sia né come ci sia arrivato. Scoprirà che l'Archivio è la sua stessa mente — un costrutto difensivo creato dall'Inconscio per isolarlo da un trauma indicibile.

Il Sistema (L'Antagonista) vuole spegnere gli ultimi ricordi per raggiungere la "Pace del Vuoto". Il giocatore deve esplorare quattro settori concettuali, recuperare quattro Simulacri e compiere il rituale della memoria per risvegliarsi.

---

## 4. TONO NARRATIVO

Etereo, sospeso, impersonale ma non freddo. Frasi brevi seguite da silenzi. Tra una didascalia di Tarkovskij e una voce che legge da un libro antico.

Il narratore non giudica, non incoraggia, non deride. **Constata.** Niente esclamazioni, niente ironia.

Esempi di tono:
> *"Apri la porta. Dall'altra parte non c'è buio — c'è assenza."*
> *"Provi a prendere il frammento. Le dita lo sfiorano. Ti chiedi se sei tu a toccarlo o lui a toccare te."*

Il tono varia dinamicamente in base al Peso Psicologico del giocatore.

---

## 5. RUOLO DELL'LLM

Il modello 0.5B on-device **non gestisce la logica degli enigmi** ma agisce come **interprete emotivo e narrativo**. Tramite System Prompt nascosti, attinge ai bundle JSON per generare:

- Descrizioni ambientali dinamiche (colorate dal Peso Psicologico)
- Monologhi interiori e risposte contestuali
- La Zona (ambiente procedurale + domande introspettive)
- Trigger proustiani trasversali
- Dialogo adattivo dell'Antagonista finale
- Aroma personalizzato dell'infuso (Quinto Settore)

L'LLM riceve solo lo snapshot della scena attuale — non ricorda la storia. Ci pensa il parser.

---

## 6. IL PESO PSICOLOGICO — MECCANICA CENTRALE

Variabile intera nascosta (`psychological_weight = 0`). Sovverte la regola d'oro delle avventure testuali: *raccogli tutto ciò che trovi*.

**Accumulo:**
- Oggetti materiali (monete, libri, attrezzi falsi): +1
- Simulacri (Ataraxia, Constant, Proportion, Catalyst): +0

**Soglie:**
| Livello | Valore | Effetto LLM |
|---|---|---|
| Light | 0 | Prosa lucida, ariosa, minimale |
| Burdened | 1–2 | Frasi tortuose, senso di affaticamento |
| Oppressed | 3+ | Claustrofobico, ansiogeno, mente annebbiata |

**Effetti sul gameplay:**
- Settore 1 (Epicuro): Stele illeggibile se peso > 0
- La Zona: probabilità scala col peso (5% → 40%)
- Settore 3 (Specchi): specchio si frantuma caoticamente se peso > 0
- Boss finale: l'Entità usa gli oggetti portati nelle argomentazioni

**Karmic Debt:** Se nel Giardino il giocatore deposita tutto tranne l'acqua della Fontana Secca, accumula un debito che introduce varianti nel Quinto Settore.

---

## 7. HUB CENTRALE: LA SOGLIA

Rotonda circolare di marmo nero venato d'argento. Quattro porte sui punti cardinali: ambrata (Nord), blu cobalto (Est), dorata (Sud), violacea (Ovest). Piedistallo pentagonale con cinque incavi al centro. Orologio senza lancette con numeri in senso antiorario.

**Inventario iniziale:** Solo un Taccuino vuoto.

---

## 8. I QUATTRO SETTORI

---

### SETTORE NORD — Il Giardino di Epicuro (Filosofia)

**Mappa:**
```
[Entrance from Portico] → [Cypress Avenue] → [Dry Fountain]
                                    ↓
                         [Circle of Stelae]
                                    ↓
                    [Central Grove - Epicurus Statue]
                           ↙            ↘
              [Alcove of Pleasures]    [Alcove of Pains]
```

**Bundle:** `epicuro_bundle.json`

**Enigmi:**
1. **Cypress Avenue** — foglie con parole in ordine epicureo. Comando: `arrange leaves [order]`
2. **Dry Fountain** — `wait` per tre turni, la rugiada arriva da sola
3. **Circle of Stelae** — incidere la Massima XI mancante
4. **Twin Alcoves** — attraversare senza interagire con nulla. Comando: `walk through`
5. **Finale** — `deposit everything` ai piedi della statua

**Trigger proustiano:** `smell` sul tiglio nell'alcova nascosta

**Simulacro:** Ataraxia — sfera di vetro perfettamente vuota

---

### SETTORE EST — L'Osservatorio Cieco (Fisica)

**Mappa:**
```
[Antechamber of Lenses]
         ↓
[Corridor of Hypotheses]
     ↙          ↘
[Hall of Void]  [Archive of Constants]
     ↘          ↙
[Calibration Chamber]
         ↓
[Telescope Dome]
```

**Bundle:** `newton_bundle.json`, `fisica_bundle.json`

**Enigmi:**
1. **Antechamber** — combinare lenti in ordine inverso. Comando: `combine lens Moon, lens Mercury, lens Sun`
2. **Corridor** — Heisenberg: camminare bendati. Comando: `walk blindfolded`
3. **Hall of Void** — nessun input per 7 turni, poi `measure fluctuation`
4. **Archive** — la costante è "1". Comando: `enter 1`
5. **Calibration** — coordinate nulle. Comando: `calibrate 0,0,0`
6. **Finale** — `invert primary mirror` → `confirm` × 3 → `observe`

**Trigger proustiano:** bagliore automatico dopo `measure fluctuation`

**Simulacro:** The Constant — prisma di luce tangibile

---

### SETTORE SUD — La Galleria degli Specchi (Arte)

**Mappa:**
```
[Hall of First Impression]
         ↓
[Corridor of Symmetry]
         ↓
[Room of Proportions]
     ↙          ↘
[Wing of Copies]  [Wing of Originals]
     ↓                ↓
[Dark Chamber] ←→ [Light Chamber]
         ↘    ↙
[Central Gallery - The Perfect Mirror]
```

**Bundle:** `arte_bundle.json`

**Cameo:** Andrei Tarkovskij cammina di spalle a nord — irraggiungibile, distanza costante.

**Enigmi:**
1. **Hall** — porta visibile solo nel riflesso. Comando: `walk backward toward door`
2. **Corridor** — tessera anomala nel mosaico. Comando: `press anomalous tile`
3. **Proportions** — costruzione euclidea del pentagono
4. **Wing of Copies** — descrivere l'elemento mancante × 3
5. **Wing of Originals** — dipingere opera immaginaria (min 50 parole)
6. **Twin Chambers** — tunnel richiede di abbandonare un oggetto
7. **Finale** — `break mirror` (se peso > 0: frantumazione caotica, nessun simulacro)

**Trigger proustiano:** `observe reflection` alla seconda visita

**Simulacro:** The Proportion — compasso d'oro privo di cardini

---

### SETTORE OVEST — Il Laboratorio Alchemico (Chimica)

**Mappa:**
```
[Vestibule of Principles]
         ↓
   [Hall of Substances]
    ↙    ↓    ↘
[Furnace] [Alembic] [Bain-Marie]
    ↘    ↓    ↙
   [Table of the Great Work]
         ↓
   [Sealed Chamber]
```

**Bundle:** `alchimia_bundle.json`

**Nota Seth:** Seth Speaks è in copyright. Non citare direttamente. Usare solo il tono — allegorico, mistico, oracolare — riscritto con parole proprie.

**Enigmi:**
1. **Vestibule** — offrire sostanze concettuali alle tre statue. Comando: `offer [concept]` × 3
2. **Substances** — decodificare simboli alchemici. Comando: `decipher symbols` → `collect [substances]`
3. **Furnace** — calcinazione, 5 turni. Comando: `calcinate` → `wait` × 5
4. **Alembic** — temperature su scala alchemica
5. **Bain-Marie** — lasciare la stanza e tornare dopo 3 settori
6. **Great Work** — sette cerchi Saturno→Sole. Comando: `place [product] in [planet] circle` × 7
7. **Finale** — `blow into the alembic` (il catalizzatore è il respiro umano)

**Trigger proustiano:** `taste crystal` sul residuo del crogiolo

**Simulacro:** The Catalyst — fiala di liquido luminescente che batte al ritmo del cuore

---

## 9. I TRIGGER PROUSTIANI TRASVERSALI

| Settore | Trigger | Comando | Citazione Proust |
|---|---|---|---|
| Giardino | Profumo tiglio | `smell` | "l'odore e il sapore restano ancora a lungo, come anime" |
| Osservatorio | Bagliore | automatico | I campanili di Martinville |
| Galleria | Riflesso anticipato | `observe reflection` (2ª) | "più fragili ma più vivaci... più fedeli" |
| Laboratorio | Sapore cristallo | `taste crystal` | La madeleine di Combray |

Le risposte del giocatore vengono salvate e usate per generare l'aroma personalizzato dell'infuso finale.

---

## 10. L'ANOMALIA: LA ZONA

**Ispirazione:** Stalker di Andrei Tarkovskij.

**Attivazione:**
| Condizione | Probabilità | Modificatore |
|---|---|---|
| Transito Soglia ↔ Settore | 15% | +5% per Simulacro |
| Dopo completamento settore | 25% | +10% con karmic debt |
| Terzo transito consecutivo | 40% | — |
| Dopo il terzo Simulacro | 50% | fisso |
| Pre-Quinto Settore | 75% | inevitabile prima volta |

**Dinamica:** L'LLM prende il controllo. Una domanda profonda basata sull'ultima azione. Risposta evasiva → loop d'angoscia. Risposta introspettiva → sentenza criptica, ritorno alla Soglia.

**Nota tecnica:** Set predefinito di domande in `zona_templates.json`. Le risposte vengono salvate in `zone_responses` e influenzano il boss finale.

**Elementi fissi:** Geometrie impossibili. Un verso di Arseny Tarkovsky sempre presente, variante per ogni istanza.

---

## 11. IL QUINTO SETTORE: LA MEMORIA (Proust)

**Accesso:** Dopo tutti e 4 i Simulacri. Scala a chiocciola con candele.

**Atmosfera:** Camera da letto inizio Novecento. Luce color seppia. Odore di Earl Grey, polvere, libri vecchi. Siciliano di Bach lontano.

**Citazione all'ingresso:**
> *"The real life, the life finally discovered and illuminated, the only life therefore really lived, is literature."*

**Le quattro stanze** — ogni stanza richiede un ricordo personale come prezzo d'ingresso:
- **Childhood** — disporre la prima parola imparata. Oggetto: madeleine di legno
- **Youth** — scrivere una promessa non mantenuta. Oggetto: biglietto per Balbec
- **Maturity** — rispondere al telefono e dire ciò che non si è mai detto. Oggetto: occhiali appannati
- **Old Age** — descrivere ciò che si vuole ricordare alla fine. Oggetto: orologio fermo alle 17:00

**Il Rituale:**
```
place Ataraxia in cup    → acqua limpida
place Constant in cup    → acqua si illumina
place Proportion in cup  → spirale aurea
place Catalyst in cup    → oro antico
stir                     → aroma unico (LLM combina i 4 trigger sensoriali)
drink                    → TRANSIZIONE AL NUCLEO
```

---

## 12. IL CONFRONTO FINALE: IL NUCLEO

**L'Antagonista:** Entità senza volto, tratti mutevoli. Voce calma, ragionevole. Argomenta per il nichilismo con logica Schopenhauer. Legge l'inventario e personalizza le argomentazioni.

**Parole chiave risolutive:** "human warmth", "imperfection", "observer", "acceptance", "I want to remember", "I exist", "irrepeatable", "breath"

### La Regola del Tre

Se la frase risolutiva viene digitata con peso > 0:

**Tentativo 1:** blocco interiore — mente annebbiata

**Tentativo 2:** l'Entità nomina gli oggetti specifici nell'inventario

**Tentativo 3:** rottura della quarta parete — `[INVENTORY]` visibile nel testo

**La Catarsi:** `drop gold coin`, `drop ancient book`. Ogni oggetto lasciato premiato. Quando peso = 0, frase risolutiva accettata.

### I Tre Finali

**FINALE 1 — Acceptance (Vittoria):** L'Aria delle Goldberg riprende dalla nota sospesa, completa la frase, fade 20s. Porte aperte, luce oltre.

**FINALE 2 — Oblivion (Sconfitta):** Silenzio 30s → fruscio bianco → nulla. Verso di Tarkovsky: *"Lived. Died. No one will remember."*

**FINALE 3 — Eternal Zone (Neutro):** Zona permanente, variazioni procedurali infinite.

**Epilogo (Finale 1):**
> *"The Archive is empty. Time has started flowing again. Outside it is cold, but you are no longer alone."*

Ultimo comando: `WAKE UP`

---

## 13. I CAMEI

| Presenza | Dove | Come |
|---|---|---|
| **Arseny Tarkovsky** | Stele + La Zona + Finale 2 | Versi incisi |
| **Andrei Tarkovskij** | Galleria degli Specchi | Figura irraggiungibile di spalle |
| **Seth (Jane Roberts)** | Laboratorio Alchemico | Tono oracolare — no citazioni dirette (copyright) |

---

## 14. CONNESSIONI TEMATICHE TRASVERSALI

| Tema | Giardino | Osservatorio | Galleria | Laboratorio | Memoria |
|---|---|---|---|---|---|
| Rilascio | Deposita tutto | Elimina osservazione | Rompi specchio | Soffia respiro | Bevi infuso |
| Attesa | Fontana (rugiada) | Vuoto (7 turni) | Tarkovskij (mai arriva) | Bain-Marie | Stagioni |
| Inversione | Cercare smettendo | Guardare dentro | Camminare indietro | Aggiungere vita | Ricordare futuro |
| Imperfezione | Abbandono volontario | Indeterminazione | Crepa necessaria | Processo incompleto | Nostalgia dolente |

---

## 15. COLONNA SONORA — BACH

Solo testo e musica. Bach è l'architettura sonora dell'Archivio — non accompagnamento ma fondamento.

### Corrispondenze

| Settore | Opera | Strumento | Perché |
|---|---|---|---|
| **Soglia** | Preludio Do maggiore BWV 846 (WTC I) | Clavicembalo | Ciclico, neutro, tabula rasa |
| **Giardino** | Aria Variazioni Goldberg BWV 988 | Clavicembalo | Contemplativo, atarassia |
| **Osservatorio** | Contrapunctus I Arte della Fuga BWV 1080 | Ensemble | Rigore matematico |
| **Galleria** | Preludio Do maggiore BWV 846 | Pianoforte | Stesso DNA — riflesso musicale |
| **Laboratorio** | Preludio Suite Violoncello n.2 BWV 1008 | Violoncello solo | Oscuro, primordiale |
| **Memoria** | Siciliano Sonata Violino n.4 BWV 1017 | Violino + clavicembalo | Dialogo passato/presente |
| **Zona** | Fuga n.14 Fa# min BWV 883 (WTC II) | Clavicembalo processato | Decostruita, glitch |
| **Nucleo** | Aria Goldberg (reprise) + silenzio | Clavicembalo | La scelta pesa acusticamente |

### Comportamenti Audio Speciali

- **Giardino** — `deposit everything`: Aria dissolve in silenzio totale (10s)
- **Osservatorio** — `invert primary mirror`: Contrapunctus suona al contrario
- **Galleria** — inizia clavicembalo, morphs verso pianoforte (20s). `break mirror`: si frantuma in arpeggi
- **Laboratorio** — `blow into the alembic`: nota armonica di violoncello si sovrappone
- **Memoria** — progressione violino per stagioni; `drink`: silenzio → riparte con bordone continuo
- **Zona** — variazione procedurale ogni ingresso (speed 0.7–1.3x, pitch ±0.5). Silenzio totale durante domande
- **Finale Accettazione** — Aria riprende dalla nota sospesa, completa, fade 20s
- **Finale Oblio** — silenzio 30s → fruscio bianco → nulla
- **Finale Zona Eterna** — Aria manipolata, loop infinito mutante

### Fonti Audio

- **Musopen.org** — CC0 (Kimiko Ishizaka per Goldberg/WTC)
- **IMSLP** — registrazioni storiche pubblico dominio
- **Archive.org** — collezioni barocche CC

**Formato:** OGG Vorbis Q6, 44.1 kHz stereo (~28 MB totali)

---

## 16. ARCHITETTURA TECNICA

### Stack

- **Flutter** — UI, logica di gioco, SQLite, navigazione
- **just_audio + audio_session** — crossfade, effetti dinamici
- **LLM on-device 0.5B** — offline (soluzione da validare, vedi sezione 17)
- **sqflite** — stato, ricordi, risposte Zona
- **Riverpod** — state management

### Budget Dimensioni

```
LLM (Qwen 0.5B Q4):        ~500 MB  (o ~2.5 GB se MediaPipe+Gemma)
Audio Bach (OGG):           ~28 MB
Testi JSON bundle:           ~30 KB
Codice app:                  ~15 MB
──────────────────────────────────
TOTALE:                     ~543 MB
```

### Flusso interazione

```
Input giocatore
      ↓
ParserService.parse()  [lib/features/parser/parser_service.dart]
      ↓
GameEngineNotifier._evaluate()  [lib/features/game/game_engine_provider.dart]
      ↓
_llmStub() → [POST Fase 0-omega: LLM on-device via flutter_llama/MediaPipe/FFI]
      ↓
GameScreen (typewriter + palette PsychoProfile)  [lib/features/ui/game_screen.dart]
```

### Struttura file implementata

```
lib/
├── main.dart                              ← entry point, AudioService init
├── core/
│   └── storage/
│       ├── database_service.dart          ← SQLite singleton (Gemini)
│       └── dialogue_history_service.dart  ← persistenza dialoghi (Copilot)
└── features/
    ├── audio/
    │   └── audio_service.dart             ← crossfade reattivo a PsychoProfile (Grok)
    ├── game/
    │   └── game_engine_provider.dart      ← Riverpod engine + nodi narrativi (Copilot)
    ├── llm/
    │   └── llm_context_service.dart       ← System Prompt dinamico (Gemini)
    ├── parser/
    │   ├── parser_service.dart            ← parser puro stateless (Copilot)
    │   └── parser_state.dart              ← modelli dati (Copilot)
    ├── state/
    │   ├── game_state_provider.dart       ← nodo corrente + SQLite (Gemini/Grok)
    │   └── psycho_provider.dart           ← PsychoProfile + SQLite (Gemini)
    └── ui/
        └── game_screen.dart               ← UI testuale + typewriter (Copilot)
```

---

## 17. STRATEGIA VALIDAZIONE LLM — FASE 0-OMEGA

**DA ESEGUIRE PRIMA DI QUALSIASI ALTRA COSA.**

Il componente LLM è il più rischioso dell'intero progetto. Validarlo in anticipo evita di scoprire problemi dopo 20 ore di sviluppo.

### Gerarchia di Fallback

```
TENTATIVO 1: flutter_llama (4 ore)
    ↓ SUCCESSO → Usa questo
    ↓ FALLIMENTO ↓

TENTATIVO 2: MediaPipe LLM Task (4 ore)
    ↓ SUCCESSO → Usa questo (app ~2.5 GB, Gemma invece di Qwen)
    ↓ FALLIMENTO ↓

TENTATIVO 3: FFI Custom llama.cpp (8 ore)
    ↓ SUCCESSO → Usa questo
    ↓ FALLIMENTO → STOP, riprogetta

TOTALE worst case: 16 ore
TOTALE best case: 4 ore
```

### Tentativo 1: flutter_llama

```bash
flutter create llm_test_1
cd llm_test_1
flutter pub add flutter_llama path_provider
mkdir -p assets/llm
# Download Qwen 2.5 0.5B Instruct Q4_K_M (~350 MB) da HuggingFace
flutter run --release  # DEVICE FISICO, non emulatore
```

**Criteri di successo:**
- Load time < 60 secondi
- Generation time < 20 secondi (100 token)
- Output inglese/italiano sensato (non gibberish)
- 5 generazioni consecutive senza crash
- RAM < 1.5 GB

### Tentativo 2: MediaPipe LLM Task

```bash
flutter create llm_test_2
cd llm_test_2
flutter pub add mediapipe_text path_provider
# Download Gemma 2B int8 (~2.5 GB) o Gemma 2 2B compresso (~1.3 GB) da Google
flutter run --release
```

**Nota:** Gemma usa prompt format diverso da Qwen (`<start_of_turn>user` invece di `<|user|>`). Tutti i template prompt del gioco vanno adattati.

**Criteri di successo:**
- Load time < 60 secondi
- Generation time < 15 secondi (MediaPipe ottimizza meglio l'hardware)
- Output sensato
- RAM < 2 GB

### Tentativo 3: FFI Custom llama.cpp

Solo se Tentativo 1 e 2 falliscono. Compila llama.cpp come libreria condivisa per Android ARM64 via NDK, crea binding Dart con dart:ffi.

**Costo:** 8 ore setup + complessità manutenzione elevata. Ma massimo controllo e performance.

### Decision Tree

```
flutter_llama OK?
  SÌ → Usa flutter_llama, Qwen 0.5B, app ~500 MB
  NO → MediaPipe OK?
         SÌ → Usa MediaPipe, Gemma 2B, app ~2.5 GB
              Adatta tutti i prompt template
         NO → FFI Custom OK?
                SÌ → Usa FFI, Qwen 0.5B, app ~500 MB
                     Aggiungi 8 ore al progetto
                NO → STOP
                     Opzioni: desktop app / server-based / riprogetta
```

### Tabella Comparativa

| Soluzione | Setup | Complessità | Dimensione | Performance | Affidabilità |
|---|---|---|---|---|---|
| flutter_llama | 4h | Bassa | ~500 MB | Media | Da testare |
| MediaPipe | 4h | Media | ~2.5 GB | Alta | Google ufficiale |
| FFI Custom | 8h | Alta | ~500 MB | Molto alta | Massima |

---

## 18. ARCHITETTURA OFFLINE-FIRST — BUNDLE STATICI

Nessun download runtime. Tutti i testi pre-estratti e bundlati nell'APK.

### Struttura assets

```
app/assets/
├── texts/
│   ├── manifest.json
│   ├── epicuro_bundle.json       # 3 KB
│   ├── proust_bundle.json        # 8 KB
│   ├── tarkovsky_bundle.json     # 2 KB
│   ├── newton_bundle.json        # 2 KB
│   ├── alchimia_bundle.json      # 3 KB
│   └── arte_bundle.json          # 2 KB
├── prompts/
│   ├── zona_templates.json
│   ├── antagonist_templates.json
│   └── proust_triggers.json
├── audio/
│   ├── preludio_c_major_wtc1.ogg
│   ├── goldberg_aria.ogg
│   ├── contrapunctus_1.ogg
│   ├── contrapunctus_1_reversed.ogg
│   ├── preludio_c_major_piano.ogg
│   ├── cello_suite_2_prelude.ogg
│   ├── cello_harmonic_overlay.ogg
│   ├── siciliano_bwv1017.ogg
│   ├── fuga_14_processed.ogg
│   └── white_noise.ogg
├── llm/
│   └── [modello scelto nella fase 0-omega].gguf
└── config/
    ├── llm_config.json
    └── game_config.json
```

### Fonti testi

| Bundle | Fonte | ID | Licenza |
|---|---|---|---|
| epicuro | Massime Capitali, Lettera a Meneceo | Gutenberg 67707 | Public Domain |
| proust | Du côté de chez Swann | Gutenberg 7178 | Public Domain (FR) |
| tarkovsky | Poesie scelte | — | Public Domain (verifica) |
| newton | Opticks | Gutenberg 33504 | Public Domain |
| alchimia | Tabula Smaragdina, Corpus Hermeticum | — | Public Domain |
| arte | De Divina Proportione, Notebooks Leonardo | Gutenberg 25326, 5000 | Public Domain |

**Seth Material:** NON bundlare — in copyright. Solo tono.

---

## 19. SCHEMA DATABASE SQLITE

```sql
CREATE TABLE citations (
    id TEXT PRIMARY KEY,
    author TEXT NOT NULL,
    work TEXT,
    text_english TEXT NOT NULL,
    text_original TEXT,
    themes TEXT,
    sector TEXT,
    use_type TEXT
);

CREATE TABLE player_memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    sector TEXT,
    trigger_type TEXT,
    player_response TEXT,
    emotional_tone TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE game_state (
    session_id TEXT PRIMARY KEY,
    current_sector TEXT,
    simulacri_collected TEXT,
    psychological_weight INTEGER DEFAULT 0,
    zone_encounters INTEGER DEFAULT 0,
    proust_triggers_activated TEXT,
    karmic_debt BOOLEAN DEFAULT FALSE,
    boss_fight_attempts INTEGER DEFAULT 0,
    updated_at TIMESTAMP
);

CREATE TABLE zone_responses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    question_asked TEXT,
    player_response TEXT,
    theme TEXT,
    created_at TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES game_state(session_id)
);
```

---

## 20. TEMPLATE PROMPT LLM (in inglese)

```
[ZONE - Environment]
<|system|>
You are the narrator of an oneiric text adventure. Max 60 words,
poetic, impossible geometries, one unexpected sensory detail. Only describe.
<|user|>
Simulacra collected: {n}/4. Tarkovsky verse to vary: "{verse}". Mood: {mood}.
<|assistant|>

[ZONE - Introspective Question]
<|system|>
Ask ONE personal question. Max 15 words. Direct, deep, non-invasive.
<|user|>
Previous sector: {sector}. Previous response: "{response}". Theme: {theme}.
<|assistant|>

[PROUST - Involuntary Memory]
<|system|>
Generate a Proustian reminiscence. Max 50 words. Triggered by {trigger}.
Precise sensory detail, sensation preceding the memory. Then ONE question.
<|user|>
Proust reference: "{citation}". Sector: {sector}.
<|assistant|>

[ANTAGONIST - Argument]
<|system|>
You are the Antagonist. Argue calmly that oblivion is mercy. Logical, never hostile.
Max 80 words. If player makes a valid point, concede elegantly.
<|user|>
Phase: {phase}. Simulacrum: {simulacrum}. Player input: "{input}".
Memories: {memories}. Inventory: {inventory}.
<|assistant|>

[NARRATOR - Weight 0]
<|system|> Describe with lucid, minimal, airy style. The player is at peace. <|assistant|>

[NARRATOR - Weight 1-2]
<|system|> Describe with slight fatigue. Slightly longer, tortuous sentences. <|assistant|>

[NARRATOR - Weight 3+]
<|system|> Describe as oppressive, claustrophobic, anxious. Mind clouded. <|assistant|>
```

**Nota MediaPipe/Gemma:** Se si usa MediaPipe, sostituire i tag `<|system|>` con il formato Gemma: `<start_of_turn>user` / `<end_of_turn>` / `<start_of_turn>model`.

---

## 21. ROADMAP DI SVILUPPO

**FASE 0-OMEGA (Prima di tutto):** Validazione LLM con strategia a cascata (4-16 ore)

**Versione 1 — scheletro funzionante**
- Solo Il Giardino di Epicuro
- Parser base + Peso Psicologico
- LLM on-device (soluzione scelta in 0-omega)
- `epicuro_bundle.json` + `tarkovsky_bundle.json`
- Audio: Aria Goldberg + dissolvenza su `deposit everything`

**Versione 2 — atmosfera**
- Salvataggio partita
- La Zona attiva con LLM procedurale
- Tutti i bundle testi
- Crossfade audio tra settori

**Versione 3 — completamento**
- Tutti i settori
- Trigger proustiani trasversali
- Boss finale con Regola del Tre e tre finali
- Quinto Settore con aroma personalizzato
- Tutti gli effetti audio speciali

---
## 22. NOTE APERTE / DA DECIDERE

**Completato:**
- ~~GDD Tecnico — state machine del parser~~ ✅ (docs/parser_state_machine.md + lib/features/parser/)
- ~~UI testuale base reattiva a PsychoProfile~~ ✅ (lib/features/ui/game_screen.dart)
- ~~Game engine con nodi narrativi stub~~ ✅ (lib/features/game/game_engine_provider.dart)
- ~~Database SQLite: schema + providers Riverpod~~ ✅ (Gemini)
- ~~AudioService reattivo a PsychoProfile~~ ✅ (Grok)

**Ancora aperto / priorità:**
- **PRIORITÀ 1:** Fase 0-omega — validazione LLM su device fisico (GDD sezione 17)
  - Dopo la validazione: sostituire `_llmStub()` in `game_engine_provider.dart`
- **PRIORITÀ 2:** Bundle testi JSON (`assets/texts/epicuro_bundle.json`, etc.) — GDD sezione 18
  - I nodi del Giardino sono già nel codice; migrare in asset quando il formato è stabile
- Fase 0-omega: modello specifico dipende dall'esito (flutter_llama vs MediaPipe vs FFI)
- Verso esatto di Arseny Tarkovsky per la Stele (Settore Giardino, garden_stelae)
- Traduzione inglese definitiva dei testi narrativi (i nodi del Giardino sono già in inglese)
- Test crossfade audio su device reali (rischio click nel workaround player swap)
- Implementazione Settori Est (Osservatorio), Sud (Galleria), Ovest (Laboratorio) — stub presenti
- La Zona procedurale (GDD sezione 10) — richiede LLM validato
- Boss finale / Il Nucleo (GDD sezione 12) — richiede LLM validato
- Il Quinto Settore (GDD sezione 11) — richiede trigger proustiani collezionati

---

*Questo documento va aggiornato a ogni sessione di lavoro.*
*Sviluppo da iniziare dopo il completamento dell'altra app Android in Flutter.*
*Prima azione quando si inizia: Fase 0-omega (validazione LLM su device fisico).*

---

## 23. CONTRIBUTI LLM

### 2026-04-02 — GitHub Copilot (Parser & UI Specialist)
**Sessione:** Implementazione parser state machine + UI testuale + game engine stub
**Fatto:**
- `docs/parser_state_machine.md` — specifica completa del micro-loop a 6 fasi
- `lib/features/parser/parser_state.dart` — modelli: `ParserPhase`, `CommandVerb`, `ParsedCommand`, `EngineResponse`, `GameMessage`
- `lib/features/parser/parser_service.dart` — parser puro e stateless
- `lib/core/storage/dialogue_history_service.dart` — persistenza dialoghi SQLite
- `lib/features/game/game_engine_provider.dart` — engine Riverpod con 12 nodi (intro_void, la_soglia, Giardino completo, 3 stub)
- `lib/features/ui/game_screen.dart` — UI testuale, typewriter, palette reattiva a PsychoProfile
- `lib/main.dart` — aggiornato a GameScreen

**Architettura risultante:**
```
Input giocatore
      ↓
ParserService.parse() [puro, sincrono]
      ↓
GameEngineNotifier._evaluate() [Riverpod AsyncNotifier]
      ↓
_llmStub() → [POST Fase 0-omega: LLM on-device]
      ↓
GameScreen [typewriter + palette PsychoProfile]
```

**Prossimo passo suggerito:**
Fase 0-omega (validazione LLM). Poi sostituire `_llmStub()` in `game_engine_provider.dart`.
Vedi dettagli in `docs/work_log.md`.

---

### 2026-04-02 — Copilot (prima sessione — Design)
- Proposto diagramma di state machine per il parser (poi implementato nella sessione successiva).
- Suggerita checklist operativa per i primi passi post-validazione LLM.
- Ribadito: tutti i contributi vanno tracciati sia nel GDD che in docs/work_log.md.

---
