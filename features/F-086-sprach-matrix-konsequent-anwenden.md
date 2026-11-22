---
id: F-086
title: Sprach-Matrix in Template-Texten und Doku-Struktur anwenden
type: change
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-086 — Sprach-Matrix in Template-Texten und Doku-Struktur anwenden

## Erfassung

**Problem:** Teile des Templates beachten den Languages-Block nicht:
- CODING-STANDARDS § 5 schreibt Kommentare auf Englisch vor, § 12 und CONTRIBUTING
  Commits auf Englisch, auch wenn der Languages-Block etwas anderes festlegt.
- INDEX.md und `F-000-template.md` bleiben englisch, während migrate und die Skills die
  Abschnittsnamen jeweils selbst übersetzen.

Projekte müssen deshalb Abweichungen eintragen, und die Überschriften der Feature-Dateien
laufen auseinander.

**Ziel:** Template-Texte und die Struktur der lebenden Doku folgen dem Languages-Block.
Gleich bleibt: Identifier, Feldnamen, Status-Tokens und Conventional-Commit-Tokens sind
immer englisch.

**Lösungsskizze:**
- § 5 nennt `{{LANG_COMMENTS}}` für Kommentare und Doc-Comments, § 12 und CONTRIBUTING
  nennen `{{LANG_COMMITS}}` für die Prosa. Die CHANGELOG-Notiz sagt, dass eine dafür
  eingetragene Abweichung danach entfällt.
- Eine kleine Übersetzungstabelle für die Struktur-Wörter, die render nach
  `LANG_LIVING_DOCS` anwendet: die Abschnitte von F-000 sowie Überschriften und
  Tabellenkopf von INDEX.md.
- Die vier Abschnittsnamen kommen in die Template-Antworten (etwa `FEATURE_SECTIONS`):
  - F-000 wird damit gerendert.
  - `migrate --sections` nimmt sie als Standard.
  - Die Skills lesen ihr Gerüst schon heute aus der F-000 des Projekts.
- MANIFEST § Answers legt für die `LANG_*`-Werte englische Sprachnamen fest, denn sie
  stehen wörtlich in englischem Zonentext.
- Verworfen:
  - Die Struktur immer englisch zu halten. Das Kit übersetzt seine eigenen Abschnitte.
  - Einen Platz für die Spezifikation in `--sections`. Das alte Format hat keine, und
    prep-step schreibt sie später.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Welche Sprachen die Tabelle anfangs kennt und was für die übrigen gilt.
- Wie bestehende Projekte mit englischer F-000 umgestellt werden.
