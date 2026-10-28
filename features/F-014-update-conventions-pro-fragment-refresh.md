---
id: F-014
title: Pro-Fragment-Refresh in update-conventions
type: feature
status: DONE
size:
created: 2026-07-17
done: 2026-07-19
depends-on:
superseded-by:
---

# F-014 — Pro-Fragment-Refresh in update-conventions

## Verlauf

### F-014 — update-conventions: Pro-Fragment-Refresh (2026-07-19)

**Aufgabe:** update-conventions aktualisierte CODING-STANDARDS als einen Modul-Part.
Mit Append-Slot und Pro-Fragment-Markern (F-013) musste der Abwärts-Abgleich
fragment-granular werden — ohne projektlokal ergänzte Fragmente zu überschreiben.

**Was entstanden ist (Plugin 0.9.0):**

- **Zwei Diff-Ebenen abwärts:** A2.3 Sonderfall `CODING-STANDARDS.md` — die
  Soll-Fassung wird mit dem **Ist-Slot des Projekts** befüllt, der Datei-Diff zeigt
  damit nur Core-Änderungen (§1–12). Neuer A2-Schritt 6 „Fragment-Abgleich": die
  `fragment:NAME`-Blöcke im Slot einzeln gegen ihr Template-Pendant diffen
  (Sprachfragment ↔ `CODING-STANDARDS.part.md` des Moduls, Katalog-Fragmente ↔
  `modules/standards/<name>.md`) mit denselben Entscheidungen wie je Datei
  (übernehmen / lassen / Override / promoten). Ohne Template-Pendant → projektlokal:
  nie anfassen, nur auflisten; Inline-`<!-- override: … -->` im Block schützt genau
  dieses Fragment.
- **Neu deklarierte Fragmente:** fehlt im Projekt ein inzwischen vom `MODULE.md`
  deklariertes Katalog-Fragment → Anhängen anbieten (Mechanik wie `/choose-stack`,
  idempotent). Reihenfolge-Regel: Bestehendes in-place ersetzen, Neues ans
  Slot-Ende — nie umsortieren (kosmetische Diffs vermeiden).
- **AUFWÄRTS:** projektlokales Fragment kann generalisiert in den Katalog promotet
  werden (`modules/standards/<name>.md` + Katalog-Zeile mit Trigger-Mapping im
  dortigen README); Frontmatter-`description` erweitert.
- **Entscheidung:** keine `manifest-format`-Erhöhung — das Template hat den
  Fragment-Vertrag innerhalb von Format 1 ergänzt, das bestehende Gate in §0 genügt;
  §0 liest zusätzlich MANIFEST § Standards fragments + `modules/standards/README.md`.
  Der A3-Heuristik-Pfad erbt die Fragment-Logik über die gemeinsame Soll-Erzeugung.
- **Begleitanpassungen:** plugin.json 0.9.0, CHANGELOG-Eintrag, README-Tabellenzeile
  update-conventions.
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
