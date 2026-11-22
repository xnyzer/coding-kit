---
id: F-082
title: Bedienung von update-conventions vereinfachen und klarstellen
type: change
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-082 — Bedienung von update-conventions vereinfachen und klarstellen

## Erfassung

**Problem:** Bei großen Migrationen fehlen dem Skill Werkzeuge und klare Aussagen. Claude
improvisiert und macht dabei vermeidbare Fehler.

**Ziel:** Wiederkehrende Handgriffe übernimmt das Skript, offene Fragen beantwortet der
Skill-Text. Gleich bleibt: Der Skill schreibt nichts ungefragt.

**Lösungsskizze:**
- `changelog-window <Stempel>` gibt genau die relevanten CHANGELOG-Abschnitte aus, auf
  Wunsch je Ziel gruppiert. Heute fasst Claude rund 25 Abschnitte von Hand zusammen.
- `snapshot` bekommt eine Option „alle gerenderten Ziele außer …“ und kann Ziele aus einer
  Datei oder von stdin lesen. In einem Lauf mussten 28 von 31 Zielen einzeln genannt
  werden.
- Für `docs/notes.md` bei Graphiti sagt der Skill klar, ob die Datei angelegt wird. Die
  Zone `claude-startup` importiert sie immer, deshalb werden Zone und Datei gekoppelt, oder
  der Skill warnt beim Ablehnen.
- Ein Shell-Hinweis: Die Bash-Aufrufe laufen unter macOS oft in zsh, und zsh teilt
  unquotierte Variablen nicht in Wörter. Dateilisten deshalb mit `while IFS= read -r` oder
  über `sh -c` verarbeiten, und keine Optionen verwenden, die macOS nicht kennt. Der
  Hinweis gehört in `docs/skill-authoring.md`, damit alle Skills ihn beachten.

**Abhängigkeiten:** keine.
