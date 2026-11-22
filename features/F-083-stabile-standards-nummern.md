---
id: F-083
title: CODING-STANDARDS mit stabilen Nummern und Platz für Projektregeln
type: change
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-083 — CODING-STANDARDS mit stabilen Nummern und Platz für Projektregeln

## Erfassung

**Problem:** Beim Umstieg auf die aktuelle `CODING-STANDARDS.md` haben sich die
Abschnittsnummern verschoben, aus 11 Abschnitten wurden 13. In einem Projekt zeigten
danach 16 ausdrückliche Verweise und etwa 45 nackte `§N` in Kommentaren auf die falschen
Abschnitte, ohne dass es auffiel. Für eigene Regeln eines Projekts gibt es keinen
vorgesehenen Platz.

**Ziel:** Abschnittsnummern bleiben über Versionen hinweg stabil, ein Umstieg zeigt seine
Tragweite vorher, und Projektregeln haben einen festen Platz. Gleich bleiben die Nummern
selbst, auf die Skills und Projekte verweisen.

**Lösungsskizze:**
- Eine Kit-Regel im MANIFEST: Neue Abschnitte kommen ans Ende oder als Unterabschnitt
  hinzu, bestehende Nummern verschieben sich nie.
- Bevor der Abgleich eine Fassung mit anderer Nummerierung anbietet, sucht der Skill nach
  Verweisen auf ihre Abschnitte. Er nennt die Tragweite und schlägt eine Zuordnung
  alt → neu vor.
- Ein Projektfragment im Slot, das der Abgleich als erlaubt kennt und nicht in jedem Lauf
  als `local` nachfragt.
- Verworfen: Anker statt Nummern. Die Nummern sind überall in Gebrauch, und stabile
  Nummern lösen dasselbe ohne Umbau.

**Abhängigkeiten:** keine.
