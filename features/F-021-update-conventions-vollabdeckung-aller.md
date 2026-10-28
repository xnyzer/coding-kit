---
id: F-021
title: update-conventions deckt alle Template-Dokumente ab, auch Seeds
type: feature
status: DONE
size:
created: 2026-07-19
done: 2026-07-20
depends-on:
superseded-by:
---

# F-021 — update-conventions deckt alle Template-Dokumente ab, auch Seeds

## Verlauf

### F-021 — update-conventions: Vollabdeckung aller Template-Dokumente (inkl. seed) (2026-07-20)

**Aufgabe:** update-conventions prüfte nur managed Dateien und Modul-Parts —
seed-Dateien samt ihrer Template-Struktur-Anteile (CLAUDE.md-Blöcke,
PROGRESS-Skelett, REQUIREMENTS-Kopfnotiz, README-Struktur) blieben ungeprüft, und
im Template gelöschte/umbenannte Dateien behandelte der Lauf nicht.
Template-Gegenstück: project-template TPL-011 (`section:NAME`-Zonen-Vertrag in
MANIFEST § Seed sections, Marker in sechs seed-Skeletten, VERSION 0.11.0) — war
bei Planungsbeginn bereits fertig; F-021 ist die rein kit-seitige Auswertung.

**Was entstanden ist (Plugin 0.15.0 + 0.16.0; 2 Substeps, 2 Commits):**

- **F-021a — seed-Abgleich abschnittsweise (0.15.0):** update-conventions liest in
  § 0 das Zonen-Inventar aus MANIFEST § Seed sections mit Feature-Detection
  (fehlt der Abschnitt — älterer Template-Stand —, entfallen seed-Abgleich und
  Marker-Migration still; `manifest-format` bleibt 1). Neuer A2-Schritt 7: die
  markierten Zonen der Template-Fassung werden instanziiert (rückaufgelöste
  Projektwerte aus A2.2) und einzeln gegen die Ist-Zone gedifft — je Zone
  übernehmen / lassen / Override, nie die ganze Datei ersetzen oder anlegen;
  gelöschtes Markerpaar = dauerhafter Opt-out (nur melden, nie ungefragt
  wiederherstellen); `claude-graphiti` fehlt legitim bei Projekten ohne
  Graphiti-Block. Neuer A3-Schritt 7: Marker-Migration für Alt-Projekte (reine
  Wrapper aus dem Inventar um wiedererkennbare Zonen, je Datei bestätigt; nicht
  Wiederauffindbares = Opt-out). Grundsatz präzisiert: seed nie als Ganzes,
  markierte Zonen abschnittsweise. new-project § 4b stellt klar, dass
  `section:NAME`-Markerpaare bei der Instanziierung erhalten bleiben.
- **F-021b — entfernte/umbenannte Template-Dateien (0.16.0):** neuer A2-Schritt 8:
  Core-Tabelle des Stempel-Stands (Stempel-Commit über die `VERSION`-Dateihistorie
  des Template-Checkouts auflösen, dann `git show <commit>:MANIFEST.md`) gegen die
  aktuelle diffen; Umbenennung → Umzug anbieten, Entfernung → Rückbau anbieten —
  je Datei bestätigt, Overrides gelten. Fallback ohne auflösbaren Stempel-Commit
  (shallow clone, zu alter Stempel): nur im CHANGELOG des Update-Fensters
  dokumentierte Fälle, nichts erraten. seed-Dateien werden nie gelöscht oder
  verschoben, nur gemeldet.
- **Entscheidungen:** Zwei Commits mit je eigenem Version-Bump (0.15.0/0.16.0),
  Historie deckungsgleich mit dem CHANGELOG (Nutzer-Wahl). Keine Heuristik für
  markerlose seed-Dateien im deterministischen Pfad — Alt-Projekte laufen über die
  bestätigte A3-Migration. LICENSE bleibt bewusst ohne Zonen (verwaltet
  `/choose-license`).
- **Begleitanpassungen:** plugin.json 0.15.0→0.16.0, CHANGELOG-Einträge,
  README-Zeile + Skill-Description um seed-Zonen und Rückbau/Umzug erweitert;
  project-template 0.11.1 (HOW-TO-Zeile zu `/update-conventions` nachgezogen,
  dortige Sync-Invariante: VERSION-Bump + CHANGELOG).
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`;
  im project-template: `core/HOW-TO-CODE-WITH-CLAUDE.md`, `VERSION`,
  `CHANGELOG.md`.
