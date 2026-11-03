---
id: F-051
title: Ankunftsprüfung aus der Auto-Memory-Übertragung entfernen
type: fix
status: PLANNED
size: S
created: 2026-11-03
done:
depends-on: F-033
superseded-by:
---

# F-051 — Ankunftsprüfung aus der Auto-Memory-Übertragung entfernen

## Erfassung

**Problem:** A5 in update-conventions löscht eine übertragene Auto-Memory-Datei erst,
wenn `get_episodes` der Gruppe eine Episode mit ihrem Namen listet. `get_episodes`
liefert aber nur die ersten Episoden nach ID, nicht nach Datum, und eine frische Episode
ist oft noch in Verarbeitung. In jeder Gruppe mit mehr als einer Handvoll Episoden meldet
A5 deshalb „nicht angekommen“, obwohl sie ankommt: Die Datei bleibt liegen, die Meldung
ist falsch. In den Tests fiel es nicht auf, weil die Testgruppen leer waren.

**Ziel:**
- Ist: Übertragung in eine Gruppe mit vielen Episoden (z. B. `main`) → „nicht
  angekommen“, die Datei bleibt.
- Soll: Meldet `add_memory` „queued“, gilt der Eintrag als übertragen und die Datei
  wird gelöscht. Scheitert der Aufruf oder ist der Graph nicht erreichbar, bleibt sie
  liegen und wird gemeldet, wie bisher.
- Reproduzieren: A5 an einem Projekt mit Auto-Memory, Ziel Graph-Gruppe `main`.

**Lösungsskizze:**
- Die Prüfung über `get_episodes` entfällt. Der Rückweg für eine verlorene Episode ist
  das Transkript der Session, in dem jeder `add_memory`-Aufruf mit vollem Text steht
  (Aufbewahrung ein Jahr, angeboten in Teil G); ein Server mit eigenem Schreibprotokoll
  ist ein zusätzlicher Rückweg, keine Voraussetzung.
- Der Bericht von A5 nennt diesen Rückweg in einem Satz.
- Verworfen: eine eigene ID je Episode (der Parameter `uuid` von `add_memory` lädt eine
  bestehende Episode zur Neuverarbeitung, eine neue ID lässt sie scheitern); die ganze
  Gruppe laden (zehntausende Tokens je Prüfung, die Gruppe `main` noch mehr).

**Abhängigkeiten:** F-033 (erledigt).

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben A5 überträgt einen Eintrag in den Graph, wenn `add_memory`
  „queued“ meldet, dann gilt er als übertragen und seine Datei wird gelöscht — ohne
  Abfrage per `get_episodes`.
- [ ] AC-2 — Gegeben `add_memory` scheitert oder der Graph ist nicht erreichbar, wenn A5
  überträgt, dann bleibt die Datei liegen und wird als gescheitert gemeldet.
- [ ] AC-3 — Gegeben mindestens ein Eintrag ging in den Graph, wenn A5 berichtet, dann
  nennt der Bericht in einem Satz den Rückweg: Der Text steht im Transkript der Session.

### Randfälle

- EC-1 — Einige Einträge sind „queued“, dann scheitert ein Aufruf → die bestätigten
  Dateien werden gelöscht, die übrigen bleiben und werden gemeldet.

### Tests

- AC-1, AC-2: Check — grep: `get_episodes` kommt in `plugins/coding-kit/skills/` nicht
  mehr vor; A5 Schritt 5 gelesen.
- AC-3: manuell — A5 Schritt 5 gelesen.
- Dazu `just check` und die Versionsregel.

### Einbettung

Nur A5 Schritt 5 in update-conventions; kein anderer Skill prüft die Ankunft. Kein
Template-Inhalt, deshalb kein Abschnitt `### Template` im CHANGELOG. F-033 bleibt als
Verlauf unverändert.

## Plan

**Größe:** S — ein Absatz in einem Skill plus Version und CHANGELOG, Lösung liegt fest.

- A5 Schritt 5, Punkt Graph: „queued“ zählt als übertragen; Fehler oder kein Graph →
  Datei bleibt, Meldung. Die Prüfung über `get_episodes` und ihre Begründung entfallen.
- A5 Schritt 5, Punkt Melden: bei Graph-Übertragungen der Satz zum Rückweg über das
  Transkript.
- `plugin.json` auf 3.2.1, CHANGELOG-Eintrag 3.2.1 (Fehlerbehebung, ohne Template).
