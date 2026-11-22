---
id: F-075
title: Seed-Zonen bei der Migration zurückstellen, platzieren und teilen
type: change
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-075 — Seed-Zonen bei der Migration zurückstellen, platzieren und teilen

## Erfassung

**Problem:** Bei der Migration von Bestandsprojekten verhalten sich die Zonen in CLAUDE.md
und README anders als erwartet:
- Was nur zurückgestellt werden sollte, ist danach dauerhaft abgewählt.
- Eingesetzte Zonen landen an unpassenden Stellen.
- `claude-conventions` bündelt fünf Themen. Wird die Zone wegen einer Zeile
  zurückgestellt, bleibt auch alles andere darin alt.

**Ziel:** Zonen lassen sich bei der Migration zurückstellen, sie landen an einer
sinnvollen Stelle, und jede Zone behandelt genau ein Thema. Gleich bleibt: Zonen setzt
und verschiebt nur das Skript, nie Claude.

**Lösungsskizze:**
- Für `unmarked` und `unconfirmed` gibt es ein echtes „diesmal nicht“: `snapshot` lässt
  diese Zone aus der Seed-Basis weg. Heute macht Schritt 9 daraus `opted-out`.
- Zonen ohne Vorgänger in der Projektdatei setzt das Skript hinter eine Überschrift aus
  dem Render statt an den Anfang der Datei, oder es verschiebt sie nach Bestätigung.
- `claude-conventions` wird nach Themen geteilt, mindestens Lizenz und Toolchain bekommen
  eigene Zonen. Beide hängen vom Projekt ab (eigene Lizenzpolitik, zurückgestellte
  Toolchain), und die Zone ist die Einheit für Opt-out, Override und Rückstellung.
  Umbenennen und Teilen kann der Abgleich schon (`removed` und `new` als Umzug).
- A3 kennt Abhängigkeiten: Wird die Toolchain zurückgestellt, bietet der Skill ihre Zonen
  mit einem Hinweis an oder stellt sie ebenfalls zurück.
- Der Skill beschreibt den Ablauf für `unmarked`-Dateien, der sich bewährt hat:
  1. Marker als reine Wrapper setzen.
  2. `zones` erneut laufen lassen, jetzt meldet es `differs`.
  3. Den Template-Inhalt übernehmen.
  4. Projektzeilen als Projekttext hinter die Zone setzen.
- Ein gleichwertiger Languages-Block in einer anderen Sprache wird erkannt. Beim
  Einsetzen der Zone bietet der Skill an, ihn zu entfernen, heute würde er verdoppelt.
- Verworfen:
  - Die Toolchain-Zeilen neutral zu formulieren. Die Toolchain ist der Vertrag.
  - Eine Rückstellung je Zeile innerhalb einer Zone. Getrennte Zonen lösen das
    einfacher.

**Abhängigkeiten:** keine. Die Lizenz-Zone wird in F-077 genutzt.
