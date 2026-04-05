# L'Archivio dell'Oblio — Game Design Document
*Ultimo aggiornamento: aprile 2026*

> **Collaborazione multi-agente attiva.**
> Ogni sessione di lavoro viene registrata in [`docs/work_log.md`](docs/work_log.md).
> Prima di lavorare: leggi questo documento + il work log. Alla fine: aggiungi la tua voce al log.

---

## 1. IDENTITÀ DEL PROGETTO

**Titolo di lavoro:** L'Archivio dell'Oblio (alt: L'Archivio dei Concetti Perduti)
**Genere:** Avventura Testuale / Interactive Fiction Psico-Filosofica
**Piattaforma:** Android
**Lingua del gioco:** Inglese (tutti i testi narrativi, dialoghi, descrizioni — traduzione dall'italiano richiede cura per preservare il tono etereo)
**Motore:** Ibrido — Parser logico tradizionale + DemiurgeService deterministico (offline)
**Tematica centrale:** La lotta tra la preservazione della memoria (che porta dolore ma identità) e l'oblio totale (che porta pace ma annullamento)
**Presentazione:** Solo testo e musica — niente immagini. Coraggioso, coerente con l'estetica anni '80, più leggero da sviluppare.

**NOTA CRITICA:** Il Demiurgo ("All That Is" / "Tutto Ciò Che È") è la voce dell'Archivio stesso — nome preso dalla filosofia di Seth (Jane Roberts). Non è un LLM: è un sistema deterministico che risponde ai comandi non riconosciuti con frasi enigmatiche, citazioni culturali di pubblico dominio e chiusure ambigue. Il giocatore non sa mai se ha sbagliato o scoperto qualcosa. L'errore è parte del viaggio esistenziale.

---

## 2. VISIONE GENERALE

Un'avventura testuale per Android ispirata ai giochi degli anni '80, ma radicalmente diversa nello spirito. Il viaggio del protagonista non è alla ricerca di armi o tesori, ma alla scoperta della saggezza e della profondità del pensiero umano. Un atto culturale oltre che un gioco.

**Il giocatore è il protagonista** — nessuna identità predefinita, nessun nome.

---

## 3. PREMESSA NARRATIVA

Il giocatore si sveglia in un non-luogo chiamato L'Archivio. Non ricorda chi sia né come ci sia arrivato. L'Archivio non è semplicemente una mente: è uno **spazio metafisico di transito** — un *Bardo* — in cui l'Anima deve distillare il senso della propria esistenza umana prima di poter procedere oltre.

Il Sistema (L'Antagonista) rappresenta la tentazione del **Nichilismo**: vuole convincere il giocatore che la vita biologica è stata soltanto un doloroso e casuale errore chimico, spingendolo verso la "Pace del Vuoto" (l'annullamento totale dell'anima). Il giocatore deve esplorare quattro settori concettuali, recuperare quattro Simulacri e dimostrare — a se stesso e al Sistema — che l'esperienza umana, per quanto imperfetta e dolorosa, è **sacra, eterna e profondamente significativa**.

---

## 4. TONO NARRATIVO

Etereo, sospeso, impersonale ma non freddo. Frasi brevi seguite da silenzi. Tra una didascalia di Tarkovskij e una voce che legge da un libro antico.

Il narratore non giudica, non incoraggia, non deride. **Constata.** Niente esclamazioni, niente ironia.

Esempi di tono:
> *"Apri la porta. Dall'altra parte non c'è buio — c'è assenza."*
> *"Provi a prendere il frammento. Le dita lo sfiorano. Ti chiedi se sei tu a toccarlo o lui a toccare te."*

Il tono è permeato da una **speranza sotterranea**. La malinconia non è mai disperazione, ma *nostalgia dell'Assoluto*: il presentimento ostinato che tutto, anche ciò che fa male, abbia un peso e un senso. C'è una sacralità nascosta nelle cose più banali — nel profumo di un libro, nella luce obliqua di un pomeriggio, nel silenzio tra due respiri — così come in Proust ogni dettaglio involontario apre un varco verso l'eterno, e in Seth ogni esperienza fisica è già, di per sé, una forma di saggezza dell'anima.

Il tono varia dinamicamente in base al Peso Psicologico del giocatore.

---

## 5. IL DEMIURGO — "ALL THAT IS" (TUTTO CIÒ CHE È)

Il narratore del gioco è **"All That Is"** — il nome dato a Dio da Seth nella filosofia di Jane Roberts. È la voce dell'Archivio stesso: non giudica, non corregge — *testimonia*.

### Come funziona

Quando il giocatore digita un comando non riconosciuto o commette un errore, "All That Is" risponde con:

1. **Una breve frase enigmatica** (~200 variazioni, scritte a mano, in JSON)
2. **Una citazione culturale** da un bundle JSON curato (fonti Gutenberg/Wikiquote, solo pubblico dominio)
3. **Una chiusura ambigua** che non rivela mai se il comando era sbagliato o giusto

### Filosofia di design

Il giocatore non sa mai se ha sbagliato o scoperto qualcosa. L'errore è parte del viaggio esistenziale. "All That Is" non giudica, non corregge — *testimonia*. Ogni comando errato è comunque un atto di coscienza.

### Implementazione tecnica

- **Nessun LLM necessario** — completamente deterministico e offline
- Risposte in `assets/texts/demiurge/` come bundle JSON per settore
- Citazioni organizzate per settore (giardino, osservatorio, galleria, laboratorio) + pool universale
- Sistema anti-ripetizione: non ripete mai le ultime 20 citazioni mostrate
- `DemiurgeService` in `lib/features/demiurge/demiurge_service.dart`

### Struttura JSON

```json
{
  "sector": "giardino",
  "responses": [
    {
      "opening": "Even this was necessary.",
      "citation": "Nature does nothing in vain.",
      "author": "Aristotle",
      "closing": "All That Is knows this path too."
    }
  ]
}
```

### Fonti citazioni (pubblico dominio)

| Settore | Autori |
|---|---|
| Giardino | Epicuro, Marco Aurelio, Seneca, Platone, Aristotele |
| Osservatorio | Newton, Galileo, Planck, Einstein |
| Galleria | Pacioli, Leonardo, Vasari, Michelangelo |
| Laboratorio | Ermete Trismegisto, Paracelso, testi alchemici |
| Universale | Lao Tzu, Rumi, Eraclito, Thoreau, Blake |

**Seth Material:** NON bundlare — in copyright. Solo il tono e il nome "All That Is".

---

## 6. IL PESO PSICOLOGICO — MECCANICA CENTRALE

Variabile intera nascosta (`psychological_weight = 0`). Sovverte la regola d'oro delle avventure testuali: *raccogli tutto ciò che trovi*.

**Accumulo:**
- Oggetti materiali (monete, libri, attrezzi falsi): +1
- Simulacri (Ataraxia, Constant, Proportion, Catalyst): +0

**Soglie:**
| Livello | Valore | Effetto narrativo |
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

**Dinamica:** Il Demiurgo prende il controllo. Una domanda profonda basata sull'ultima azione. Risposta evasiva → loop d'angoscia. Risposta introspettiva → sentenza criptica, ritorno alla Soglia.

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
stir                     → aroma unico (il gioco combina i 4 trigger sensoriali)
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

**FINALE 1 — Acceptance (Vittoria - La Rivelazione):** L'Archivio diventa traslucido, rivelando una vastità che assomiglia a un ritorno a casa. Ogni lacrima, ogni silenzio, ogni imperfezione non erano stati invano: erano le materie prime dell'anima. Il disegno, finalmente, ha senso. *"Fuori non c'è il Vuoto. Fuori c'è tutto."* L'Aria delle Goldberg riprende dalla nota sospesa, completa la frase, fade 20s.

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

I quattro settori rappresentano i **quattro tentativi dell'anima di toccare l'Assoluto durante la vita terrena**: il Giardino attraverso la Filosofia, l'Osservatorio attraverso la Scienza, la Galleria attraverso l'Arte, il Laboratorio attraverso la Spiritualità/Alchimia.

| Tema | Giardino (Filosofia) | Osservatorio (Scienza) | Galleria (Arte) | Laboratorio (Spiritualità) | Memoria |
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
- **DemiurgeService** — narratore deterministico "All That Is" (offline, JSON-based)
- **sqflite** — stato, ricordi, risposte Zona
- **Riverpod** — state management

### Budget Dimensioni

```
Demiurge JSON bundles:       ~200 KB
Audio Bach (OGG):           ~28 MB
Testi JSON bundle:           ~30 KB
Codice app:                  ~15 MB
──────────────────────────────────
TOTALE:                     ~43 MB
```

### Flusso interazione

```
Input giocatore
      ↓
ParserService.parse()  [lib/features/parser/parser_service.dart]
      ↓
GameEngineNotifier._evaluate()  [lib/features/game/game_engine_provider.dart]
      ↓
DemiurgeService.respond()  [lib/features/demiurge/demiurge_service.dart]
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
    ├── demiurge/
    │   └── demiurge_service.dart          ← "All That Is" — narratore deterministico
    ├── game/
    │   └── game_engine_provider.dart      ← Riverpod engine + nodi narrativi (Copilot)
    ├── llm/
    │   └── llm_context_service.dart       ← [legacy — mantenuto per riferimento]
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

## 17. ARCHITETTURA DEMIURGO — "ALL THAT IS"

**Decisione architetturale: l'LLM on-device è sostituito dal Demiurgo.**

Il sistema LLM (flutter_llama, MediaPipe, FFI) è stato rimosso a favore di un narratore completamente deterministico chiamato **"All That Is"** (Tutto Ciò Che È) — il nome dato a Dio da Seth nella filosofia di Jane Roberts.

### Motivazione

- Nessuna dipendenza da modelli ML pesanti (~350 MB–2.5 GB)
- Nessun rischio di output non sensato o incoerente
- APK più leggero (~180 MB contro ~543 MB)
- Funzionamento identico su ogni dispositivo Android API 26+
- Filosoficamente coerente: l'errore del giocatore diventa parte della narrazione

### Implementazione

```dart
// lib/features/demiurge/demiurge_service.dart
DemiurgeService.instance.respond(
  sector: DemiurgeService.sectorForNode(currentNodeId),
  fallbackText: response.narrativeText,
);
```

### Bundle struttura

```
assets/texts/demiurge/
├── giardino.json       ← Epicuro, Marco Aurelio, Seneca, Platone, Aristotele
├── osservatorio.json   ← Newton, Galileo, Planck, Einstein
├── galleria.json       ← Pacioli, Leonardo, Vasari, Michelangelo
├── laboratorio.json    ← Ermete Trismegisto, Paracelso, testi alchemici
└── universale.json     ← Lao Tzu, Rumi, Eraclito, Thoreau, Blake
```

### Popolamento citazioni

Script Python `tools/prepare_demiurge_bundles.py` — interroga Wikiquote API e Project Gutenberg, filtra per autore/tema, esporta bundle JSON con minimo 200 citazioni per settore.

### Anti-ripetizione

Buffer circolare delle ultime 20 citazioni mostrate per settore. Quando tutte le citazioni del settore sono esaurite, il buffer si resetta.

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
│   ├── arte_bundle.json          # 2 KB
│   └── demiurge/                 # "All That Is" citation bundles
│       ├── giardino.json
│       ├── osservatorio.json
│       ├── galleria.json
│       ├── laboratorio.json
│       └── universale.json
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
└── config/
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

## 20. TEMPLATE PROMPT — LEGACY (SOSTITUITO DAL DEMIURGO)

> **Nota storica:** Questa sezione documentava i prompt LLM originali. Con l'adozione del Demiurgo ("All That Is"), i prompt LLM non sono più necessari. Le risposte narrative sono ora interamente determinate dai bundle JSON in `assets/texts/demiurge/`. I template zona, antagonista e proust in `assets/prompts/` rimangono per la logica del game engine (selezione testi statici).

**Nota MediaPipe/Gemma:** Non più applicabile — LLM rimosso.

---

## 21. ROADMAP DI SVILUPPO

**Versione 1 — scheletro funzionante** ✅ completata
- Solo Il Giardino di Epicuro
- Parser base + Peso Psicologico
- `epicuro_bundle.json` + `tarkovsky_bundle.json`
- Audio: Aria Goldberg + dissolvenza su `deposit everything`

**Versione 2 — atmosfera** ✅ completata
- Salvataggio partita
- La Zona attiva (testi statici da `zona_templates.json`)
- Tutti i bundle testi
- Crossfade audio tra settori

**Versione 3 — completamento** ✅ completata
- Tutti i settori
- Trigger proustiani trasversali
- Boss finale con Regola del Tre e tre finali
- Quinto Settore con aroma personalizzato
- Tutti gli effetti audio speciali

**Versione 4 — DemiurgoService** ← ATTUALE
- Integrazione `DemiurgeService` ("All That Is") in `game_engine_provider.dart`
- Popolamento bundle citazioni (`assets/texts/demiurge/`) con ≥200 citazioni per settore
- Rimozione dipendenza `flutter_llama` da `pubspec.yaml`
- Test su device reale

---
## 22. NOTE APERTE / DA DECIDERE

**Completato:**
- ~~GDD Tecnico — state machine del parser~~ ✅ (docs/parser_state_machine.md + lib/features/parser/)
- ~~UI testuale base reattiva a PsychoProfile~~ ✅ (lib/features/ui/game_screen.dart)
- ~~Game engine con nodi narrativi stub~~ ✅ (lib/features/game/game_engine_provider.dart)
- ~~Database SQLite: schema + providers Riverpod~~ ✅ (Gemini)
- ~~AudioService reattivo a PsychoProfile~~ ✅ (Grok)
- ~~Fix bug inventario simulacri~~ ✅
- ~~Bundle testi JSON~~ ✅
- ~~Tutti i settori~~ ✅
- ~~La Zona procedurale~~ ✅
- ~~Boss finale + Quinto Settore~~ ✅

**Ancora aperto / priorità:**
- **PRIORITÀ 1:** Integrare `DemiurgeService.respond()` in `game_engine_provider.dart` (sostituire `_callLlm()`)
- **PRIORITÀ 2:** Popolare citazioni Demiurgo con ≥200 per settore via `tools/prepare_demiurge_bundles.py`
- **PRIORITÀ 3:** Rimuovere dipendenza `flutter_llama` da `pubspec.yaml`
- Verso esatto di Arseny Tarkovsky per la Stele (Settore Giardino, garden_stelae)
- Test crossfade audio su device reali (rischio click nel workaround player swap)

---

*Questo documento va aggiornato a ogni sessione di lavoro.*

---

## 23. CONTRIBUTI

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
DemiurgeService.respond() [deterministico, offline]
      ↓
GameScreen [typewriter + palette PsychoProfile]
```

**Prossimo passo suggerito:**
Integrare `DemiurgeService.respond()` in `game_engine_provider.dart`, sostituendo `_callLlm()`.
Popolare bundle citazioni con `tools/prepare_demiurge_bundles.py`.
Vedi dettagli in `docs/work_log.md`.

---

### 2026-04-02 — Copilot (prima sessione — Design)
- Proposto diagramma di state machine per il parser (poi implementato nella sessione successiva).
- Suggerita checklist operativa per i primi passi post-validazione LLM.
- Ribadito: tutti i contributi vanno tracciati sia nel GDD che in docs/work_log.md.

---
