---
id: F-030
title: Graphiti-Episodenverlust erkennen und wiederherstellbar halten
type: feature
status: BACKLOG
size:
created: 2026-10-09
done:
depends-on: F-033
superseded-by:
---

# F-030 — Graphiti-Episodenverlust erkennen und wiederherstellbar halten

## Erfassung

**Problem:** `add_memory` meldet nur „queued" — ob eine Episode wirklich im Graph
ankommt, sieht der Skill nicht. Episoden, die der Graphiti-Server verliert, werden nie
erneut verarbeitet; wiederherstellen lassen sie sich nur aus den lokalen
Claude-Code-Transkripten. Die löscht Claude Code standardmäßig nach 30 Tagen — danach
ist ein Verlust endgültig.

**Idee:** Ein Skill prüft an passender Stelle, ob die zuletzt geschriebenen eigenen
Episoden angekommen sind. Die Aufbewahrung der Transkripte (365 Tage) setzt F-033.

**Lösungsskizze:**
- Erfolgskontrolle: z. B. zu Sessionbeginn oder in `step-done` die letzten Episoden der
  Gruppe abrufen und mit den zuletzt geschriebenen abgleichen; Fehlendes melden (nicht
  automatisch nachschreiben). Leseaufrufe kosten keine Extraktion.
- `cleanupPeriodDays` → F-033 (AC-8).

**Abhängigkeiten:** F-033 (setzt die Aufbewahrung der Transkripte). Thematische Nähe zu
F-029 (Graphiti).
