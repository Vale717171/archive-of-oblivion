# Parser State Machine — L'Archivio dell'Oblio
*Autore: GitHub Copilot — sessione 2026-04-02*
*Implementazione Dart: `lib/features/parser/` + `lib/features/game/`*

---

## Overview

Il micro-loop di interazione risponde al gap identificato da ChatGPT o3 nel work log:
> *"manca un loop di interazione concreto — cosa fa l'utente per 10 minuti?"*

Ogni turno è un ciclo finito di 6 fasi. L'utente non vede mai la macchina a stati — vede solo testo.

---

## Diagramma degli Stati

```
                    ┌─────────────────────────────────────┐
                    │                                     │
                    ▼                                     │
              ┌──────────┐                                │
    start ───►│   IDLE   │◄── display complete            │
              └────┬─────┘                                │
                   │ user submits input                   │
                   ▼                                      │
              ┌──────────┐                                │
              │ PARSING  │── unrecognized ──► IDLE (show "?")
              └────┬─────┘                                │
                   │ ParsedCommand                        │
                   ▼                                      │
              ┌────────────┐                              │
              │ EVALUATING │── pure logic ──────────────► │
              └─────┬──────┘                              │
                    │                                     │
              LLM needed?                                 │
                    │                                     │
            ┌───────┴────────┐                            │
            │                │                            │
            ▼                ▼                            │
     ┌────────────┐   ┌────────────────┐                  │
     │LLM_PENDING │   │EVENT_RESOLVED  │                  │
     └─────┬──────┘   └───────┬────────┘                  │
           │                  │                            │
           └────────┬─────────┘                            │
                    ▼                                      │
              ┌────────────┐                               │
              │ DISPLAYING │── typewriter output ──────────┘
              └────────────┘
```

---

## Descrizione degli Stati

| Stato | Durata | Cosa accade |
|---|---|---|
| `idle` | Attesa utente | Input field attivo, cursore lampeggiante |
| `parsing` | ~1ms | Testo grezzo → `ParsedCommand` (sincrono, puro) |
| `evaluating` | ~5ms | Engine controlla nodo corrente, inventario, peso psicologico |
| `llmPending` | 5–20s | Invio System Prompt all'LLM on-device; UI mostra "..." |
| `eventResolved` | ~10ms | Aggiornamento DB (weight, node, dialogue_history), trigger audio |
| `displaying` | 0.5–3s | Typewriter su testo finale; al termine → `idle` |

---

## Verbi Riconosciuti

```
go [north/south/east/west]    — navigazione
examine [oggetto] / look      — ispezione
take [oggetto]                — raccolta (aumenta peso se oggetto materiale)
drop [oggetto]                — abbandono
use [oggetto]                 — interazione
wait / z                      — attesa (rilevante per alcuni enigmi)
deposit everything            — azione chiave del Settore Giardino
smell [oggetto]               — trigger proustiano
taste [oggetto]               — trigger proustiano (Laboratorio)
arrange [argomento]           — enigma foglie (Cypress Avenue)
walk [through/blindfolded]    — movimento speciale
combine [oggetti]             — combinazione (Osservatorio)
offer [concetto]              — offerta (Laboratorio)
press [oggetto]               — pressione (Galleria)
inventory / i                 — mostra inventario
help / ?                      — comandi disponibili
```

---

## Integrazione con PsychoProfile

Il testo visualizzato cambia stile in base allo stato psicologico:

| Condizione | Effetto testo |
|---|---|
| Normale (lucidity ≥ 50, anxiety < 50) | Bianco puro, prosa fluida |
| Alta ansia (anxiety > 70) | Testo leggermente rossastro, risposte frammentate |
| Bassa lucidità (lucidity < 30) | Testo grigiastro, risposte oniriche |
| Alto oblio (oblivionLevel > 60) | Testo azzurro-grigio, risposte smorzate |

Il cambio di stile è puramente visivo (colore testo Flutter). Il cambio di **contenuto** è gestito dall'LLM tramite `LlmContextService` (già implementato da Gemini).

---

## Peso Psicologico — Regola di Raccolta

```
Oggetto materiale (es. moneta, libro, attrezzo): +1 peso
Simulacro (Ataraxia, The Constant, Proportion, Catalyst): +0 peso
Azione "deposit everything": azzera inventario, peso → 0
```

La UI **non mostra mai il valore numerico del peso** al giocatore. Il feedback è indiretto: cambio di tono narrativo, effetti audio, comportamento dell'LLM.

---

## Esempio di Micro-Loop (Cypress Avenue)

```
[IDLE]
  Player: "examine leaves"

[PARSING]
  ParsedCommand { verb: examine, args: ['leaves'] }

[EVALUATING]
  currentNode = garden_cypress
  'leaves' in node.examines → found
  needsLlm = false

[EVENT_RESOLVED]
  dialogue_history ← { role: 'user', content: 'examine leaves' }
  dialogue_history ← { role: 'llm', content: '...' }

[DISPLAYING]
  typewriter: "You crouch and read the words: pleasure, friendship,
  prudence, tranquillity, memory, simplicity, absence.
  They belong to an order. You sense it, but cannot yet name it."

[IDLE]
  Player: _
```

---

## Note per i Collaboratori

- Il parser è **puro e privo di stato** — `ParserService.parse()` è una funzione statica.
- Il game engine è un **Riverpod `AsyncNotifier`** — `GameEngineProvider`.
- Il contenuto dei nodi (testi narrativi) è definito staticamente in `game_engine_provider.dart`.
  Futura evoluzione: spostare i bundle in `assets/texts/*.json` (GDD sezione 18).
- La chiamata all'LLM è **stub** (restituisce il testo engine direttamente) fino alla Fase 0-omega.
  Quando il modello è validato, sostituire `_llmStub()` con la chiamata reale.
