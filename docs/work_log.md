# Work Log — L'Archivio dell'Oblio
*Registro cronologico delle sessioni di sviluppo. Non modificare le voci esistenti.*
*GDD completo: [`claude.md`](../claude.md)*

---

### 2026-04-02 — Claude Sonnet 4.5
**Role:** Architettura generale, setup repository, coordinamento multi-LLM
**Done:**
- Creata cartella di progetto `~/Development/archive-of-oblivion/`
- Struttura cartelle Flutter (`lib/`, `assets/`, `docs/`, `tools/`)
- `claude.md` — GDD completo trascritto e versionato
- `.gitignore` — configurato per Flutter (file `.gguf` LLM esclusi da git)
- Repository GitHub creato e pushato: https://github.com/Vale717171/archive-of-oblivion
- Progettato protocollo di collaborazione multi-LLM
- Creati: `docs/work_log.md`, `docs/prompts/universal_session_prompt.md`, `docs/prompts/role_cards.md`

**Key decisions:**
- `assets/llm/*.gguf` escluso da git — i modelli LLM vanno scaricati separatamente
- `claude.md` = GDD puro (fonte di verità), `docs/work_log.md` = registro storico separato
- Ogni LLM aggiorna il log alla fine della sessione, il maintainer umano fa il commit

**Files created/modified:**
- `claude.md` (aggiunto header multi-LLM)
- `docs/work_log.md` (questo file)
- `docs/prompts/universal_session_prompt.md`
- `docs/prompts/role_cards.md`

**Next suggested step:**
Fase 0-omega — validazione LLM su device fisico Android.
Modello consigliato per questo task: **o3** (ragionamento su sistemi, valutazione tecnica).
In alternativa: eseguire tu stesso i test con `flutter_llama` seguendo la sezione 17 del GDD.

---
