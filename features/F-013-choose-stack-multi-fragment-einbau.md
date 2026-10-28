---
id: F-013
title: Multi-Fragment-Einbau in choose-stack
type: feature
status: DONE
size:
created: 2026-07-17
done: 2026-07-19
depends-on:
superseded-by:
---

# F-013 — Multi-Fragment-Einbau in choose-stack

## Verlauf

### F-013 — choose-stack: Multi-Fragment-Einbau (2026-07-19)

**Aufgabe:** choose-stack installierte den EINEN `CODING-STANDARDS.part.md` eines
Stack-Moduls in den §13-Slot. Das project-template komponiert CODING-STANDARDS
inzwischen aus framework-granularen Fragmenten (Vertrag: MANIFEST § Standards
fragments; umgesetzt dort seit Template-VERSION 0.7.0, verifiziert gegen 0.8.0) —
ein Modul deklariert MEHRERE Fragmente, der Ein-Part-Einbau griff nicht mehr.

**Was entstanden ist (Plugin 0.8.0):**

- **choose-stack §0:** liest zusätzlich MANIFEST § Standards fragments und
  `modules/standards/README.md` (Fragment-Katalog).
- **choose-stack Modus B — Append-Prozedur:** Standards-Fragmente werden im Slot
  `<!-- module:coding-standards -->` **angehängt**, nie ersetzt. Fragmentliste in
  Reihenfolge: eigenes Sprachfragment (`CODING-STANDARDS.part.md`) + Katalog-Fragmente
  laut `Standards fragments:`-Zeile des `MODULE.md`, tolerant gelesen (fett/plain;
  `(none)`/leer/fehlend = keine). Die Quell-Dateien tragen ihre
  `<!-- fragment:NAME -->`-Marker bereits — nichts wird gewrappt. **Idempotent** je
  Marker: Vorhandenes nie doppelt einbauen, nie erneuern (Erneuern =
  `/update-conventions`); der docs-only-Platzhalter im Slot fällt beim Erst-Einbau weg.
- **Modulwechsel:** Sprachfragment wird gegen das neue getauscht; Katalog-Fragmente
  bleiben stehen und werden nur aufgelistet („noch aktuell?"). **Entscheidung
  (Nutzer):** kein automatisches Entfernen — Katalog-Fragmente sind cross-cutting und
  können den Sprachwechsel überleben; Entfernen ist Projektentscheidung.
- **new-project:** Referenz des Modul-Einbaus nachgezogen — „Standards-Fragmente
  anhängen" statt „CODING-STANDARDS-Slot füllen".
- **Begleitanpassungen:** plugin.json 0.8.0, CHANGELOG-Eintrag, README-Tabellenzeile
  choose-stack.
- **Geänderte Dateien:** `plugins/coding-kit/skills/choose-stack/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Abgrenzung:** Fragment-Refresh downstream bleibt F-014 (update-conventions);
  Erkennungs-/Backstop-Logik bleibt F-015/F-016; Eigenschafts-Trigger bleibt F-017.
