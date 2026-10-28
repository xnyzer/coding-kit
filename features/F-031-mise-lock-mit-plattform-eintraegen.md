---
id: F-031
title: mise.lock mit Plattform-Einträgen erzeugen (CI im --locked-Modus)
type: feature
status: DONE
size:
created: 2026-10-19
done: 2026-10-23
depends-on:
superseded-by:
---

# F-031 — mise.lock mit Plattform-Einträgen erzeugen (CI im --locked-Modus)

## Verlauf

### F-031 — mise.lock mit Plattform-Einträgen erzeugen (CI im --locked-Modus) (2026-10-23)

**Problem:** Projekte aus `/new-project` bekamen eine `mise.lock` nur mit Versionen, ohne
`[tools.X."platforms.*"]`-Einträge — `mise install` schreibt sie so. Sobald eine
`mise.lock` existiert, installiert die CI (`jdx/mise-action`) mit `--locked` und
scheiterte für jedes Tool mit „No lockfile URL found for <tool>@<version> on platform
linux-x64 (--locked mode)". Beobachtet bei einem Projekt aus project-template 0.13.2:
jeder CI-Lauf rot seit dem Bootstrap-Commit.

**Was entstanden ist (Plugin 0.19.1):**

- **`choose-stack` § Lock-Datei erzeugen und prüfen** (neu, einzige Fundstelle der
  Regel, nach dem Muster von § Begleithandlungen): nach `mise install` schlicht
  `mise lock`, ohne `--platform`; fehlt `lockfile_platforms` in der `mise.toml`, auf
  `/update-conventions` verweisen statt Flags zu setzen. Prüfung: jedes Tool hat einen
  `platforms.<p>`-Eintrag je Plattform aus `lockfile_platforms`; Lücke auf der Plattform
  des CI-Runners (aus `runs-on`) blockiert den Commit, übrige Lücken werden gemeldet und
  gegen „Known limitation" im Template-CHANGELOG abgeglichen.
- **`choose-stack` § 4** und **`new-project` § 4d:** `mise install && mise lock && …`
  plus Prüfung.
- **`update-conventions`:** A2.1 macht auch bei aktuellem Stempel den Lock-Abgleich;
  A2.9 prüft am Projektabschluss und bietet bei geänderter `mise.toml`, Lücken oder
  fehlender Lock-Datei `mise install && mise lock` an; A3.5 erzeugt und prüft ebenso.
- **Begleit-Änderungen:** `plugin.json` 0.19.1, `CHANGELOG.md`, `README.md`
  (Tabellenzeilen choose-stack und update-conventions).

**Verifikation:** mit mise 2026.10.6 an `core/mise.toml` aus project-template 0.13.3
geprüft — `mise install` schrieb 0 Plattform-Einträge, `mise lock` alle sieben
Plattformen je Tool; ein aus der `mise.toml` gestrichenes Tool verschwand bei
`mise lock` aus der Lock-Datei. `just check` grün. Ein Lauf gegen ein echtes Projekt
steht noch aus.

**Notable decisions:**

- **Kein `--platform`, anders als die Erfassungs-Skizze:** project-template TPL-020 hat
  `lockfile_platforms` zur einzigen Quelle der Plattformliste gemacht; ein Flag daneben
  würde die Liste doppelt führen. Renovate führt `mise lock` ebenfalls ohne Flag aus.
- **Lock-Abgleich unabhängig vom Stempel:** die Skizze ging von Projekten aus Template
  ≤ 0.13.2 aus. Auch Projekte aus Template 0.13.3, die Kit ≤ 0.19.0 angelegt hat, haben
  die Einstellung, aber eine Lock-Datei ohne Plattform-Einträge — ihr Stempel ist
  aktuell, der bisherige Kurzschluss „aktuell, fertig" hätte sie übersprungen.
- **Eine Fundstelle, drei Verweise** statt dreifacher Regel in den Skills.
- **Kein Guard in `just check`:** das justfile ist Template-Sache (managed); bei Bedarf
  als eigenes Template-Feature erfassen.
- **Kit-eigene `mise.toml` unverändert:** ihr Lock ist bereits vollständig, ein
  `lockfile_platforms` dort behebt keinen Fehler (User chose: Empfehlung übernommen).
- **Template-HOW-TO nicht nachgezogen:** sie beschreibt die Skills nur grob; die
  Lock-Prüfung ist dort ein Detail und rechtfertigt keinen eigenen Template-Release.

**Pairing:** project-template TPL-020 (VERSION 0.13.3). Die Paarungsprüfung aus F-035
steht noch aus (dort vermerkt).
