---
id: F-080
title: Stop-Hook und add-feature für reine Erfassungen abstimmen
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-080 — Stop-Hook und add-feature für reine Erfassungen abstimmen

## Erfassung

**Problem:** Der Stop-Hook verlangt `/step-done`, sobald der Arbeitsbaum ungesicherte
Änderungen hat. Das passiert auch direkt nach `/add-feature`, das ausdrücklich „nicht
committen“ sagt, und mitten in update-conventions, bevor dessen Commit-Frage kommt. In vier
von fünf Migrationen musste Claude den Hinweis zurückstellen.

**Ziel:**
- **Ist:** Der Hook prüft nur, ob es ungesicherte Änderungen gibt. Eine neue
  BACKLOG-Datei bleibt bis zum nächsten step-done liegen und landet dann im Commit eines
  fremden Features.
- **Soll:** In diesen Fällen gibt der Hook einen passenden Hinweis oder schweigt, und eine
  Erfassung kann einen eigenen Doku-Commit bekommen.
- **Reproduzieren:** `/add-feature` ausführen, dann die Sitzung anhalten.

**Lösungsskizze:**
- Ist nur `features/` geändert und kein Feature `IN-PROGRESS`, schweigt der Hook oder
  sagt „Erfassung committen oder liegen lassen“.
- Läuft ein Abgleich (`.claude/template-version` oder `.claude/template-base/` im Diff),
  weist der Hook darauf hin, dass die Commit-Frage am Ende von update-conventions kommt.
- add-feature bietet einen eigenen Doku-Commit an (`docs: add F-NNN … to the backlog`),
  nur nach Rückfrage. Das Kit macht es in seiner eigenen Historie schon so.

**Abhängigkeiten:** keine. F-027 betrifft denselben Hook, aber den Interpreter unter
Windows, nicht diese Logik.
