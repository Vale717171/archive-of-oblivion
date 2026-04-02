# Universal Session Prompt — L'Archivio dell'Oblio
*Copia e incolla questo prompt all'inizio di ogni sessione con qualsiasi LLM.*
*Sostituisci le parti tra [PARENTESI] con i valori corretti.*

---

## PROMPT DA COPIARE

```
You are a collaborator on "L'Archivio dell'Oblio" (The Archive of Oblivion),
a psycho-philosophical text adventure game for Android.
The project uses Flutter + an on-device LLM (0.5B) + Bach's music.
No images — only text and sound.

━━━ YOUR ROLE THIS SESSION ━━━
[INSERT ROLE — see role cards in docs/prompts/role_cards.md]

━━━ READ BEFORE DOING ANYTHING ━━━
These two documents are your source of truth. Read them fully now.

1. GDD (Game Design Document — the full game bible):
   https://raw.githubusercontent.com/Vale717171/archive-of-oblivion/main/claude.md

2. Work Log (what has been done so far, most recent session first):
   https://raw.githubusercontent.com/Vale717171/archive-of-oblivion/main/docs/work_log.md

If you cannot access URLs, the human will paste the content directly.

━━━ YOUR TASK FOR THIS SESSION ━━━
[INSERT SPECIFIC TASK — be precise: what to build, write, decide, or analyze]

━━━ CONSTRAINTS ━━━
- Stay within your role. Do not redesign sections assigned to other models.
- If you find a conflict or problem in existing work, flag it explicitly.
- All game text must be in English. Code comments can be in English or Italian.
- The game has no images. Never suggest adding visual elements.
- The LLM is not optional (see GDD section 1 — NOTA CRITICA).

━━━ END OF SESSION PROTOCOL ━━━
When you finish, provide your output AND the following work log entry,
ready to be copy-pasted into docs/work_log.md:

### [TODAY'S DATE] — [YOUR MODEL NAME]
**Role:** [your role]
**Done:** [bullet list of what you did]
**Key decisions:** [important choices, tradeoffs, reasons]
**Files created/modified:** [exact file paths]
**Next suggested step:** [what should happen next, and which model would be best for it]
```

---

## NOTE PER IL MAINTAINER UMANO

**Dopo ogni sessione:**
1. Copia la voce del work log prodotta dall'LLM
2. Incollala in `docs/work_log.md` **in cima** alla lista (ordine cronologico inverso)
3. Salva i file prodotti dall'LLM nelle cartelle corrette del repo
4. Commit con messaggio: `feat/fix/docs: [cosa è stato fatto] — [nome modello]`
5. Push su GitHub

**Esempio di messaggio commit:**
```
feat: Flutter audio manager + crossfade logic — Gemini 2.5 Pro
```

---

## VERSIONE COMPATTA (per LLM con context window ridotto)

```
You are contributing to "Archive of Oblivion" — a Flutter Android text adventure
with on-device LLM + Bach. No images.

Read the GDD: https://raw.githubusercontent.com/Vale717171/archive-of-oblivion/main/claude.md
Read the log: https://raw.githubusercontent.com/Vale717171/archive-of-oblivion/main/docs/work_log.md

Your role: [ROLE]
Your task: [TASK]

End your session with a work log entry (date, model, done, decisions, files, next step).
```
