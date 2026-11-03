---
id: F-030
title: Graphiti-Episodenverlust erkennen und wiederherstellbar halten
type: feature
status: DROPPED
size:
created: 2026-10-09
done: 2026-11-03
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

**Entscheidung (2026-11-03) — nicht umsetzen, `DROPPED`:** Erkennen und Wiederherstellen
leistet der Graphiti-Server selbst besser als das Kit: Ein serverseitiges Eingangsbuch
hält seit 2026-10-15 jeden schreibenden Aufruf mit Originaltext und Status fest
(gespeichert, verworfen, unklar), meldet Verluste und hebt den Text auf, bis er
nachgereicht ist — für jeden Client, nicht nur für Claude Code auf einem Rechner. Dass
der Server gescheiterte Episoden nicht wiederholt, ist ebenfalls Server-Sache (wie bei
F-029). Für einen Server ohne ein solches Protokoll bleiben die Transkripte der
Rückweg, die Claude Code seit F-033 ein Jahr aufhebt. Die Ankunftsprüfung in
update-conventions behebt F-051.

Befunde aus der Planung, falls die Idee wiederkommt:
- Die Skizze trägt nicht: `get_episodes` sortiert nach der Episoden-ID, nicht nach
  Datum, und liefert immer den vollen Text — ein Abgleich müsste die ganze Gruppe laden.
- Eine eigene ID je Episode geht nicht: Der Parameter `uuid` von `add_memory` lädt eine
  bestehende Episode zur Neuverarbeitung; mit einer neuen ID scheitert die Verarbeitung
  und die Episode geht verloren.
- Erwogen und verworfen: ein Hook, der jedes `add_memory` mit Text in einem lokalen
  Postausgang festhält; ohne eigene ID ließe sich die Ankunft nur über die ganze Gruppe
  prüfen.
