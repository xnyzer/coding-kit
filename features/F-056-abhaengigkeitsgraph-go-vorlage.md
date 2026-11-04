---
id: F-056
title: Fehlschlag des GitHub-Abhängigkeitsgraphen an der Go-Vorlage beheben
type: fix
status: IN-PROGRESS
size: S
created: 2026-11-04
done:
depends-on:
superseded-by:
---

# F-056 — Fehlschlag des GitHub-Abhängigkeitsgraphen an der Go-Vorlage beheben

## Erfassung

**Problem:** GitHub liest für seinen Abhängigkeitsgraphen jede `go.mod` im Repo. Die
Go-Vorlage des Templates (`modules/go/files/go.mod`) enthält Platzhalter
(`{{GO_MODULE}}`) und ist deshalb keine gültige `go.mod`. Jede Änderung an ihr lässt den
Lauf „Graph Update: go_modules“ fehlschlagen (2026-10-23 und 2026-11-04) — ein roter
Lauf in den Actions und eine mögliche Benachrichtigung, ohne Folgen für die CI oder die
Projekte. Die Python-Vorlage ist nicht betroffen.

**Ziel:**
- Ist: Nach einer Änderung an der Go-Vorlage schlägt „Graph Update: go_modules“ fehl.
- Soll: Kein Fehlschlag mehr; eine Vorlage zählt nicht als echte Abhängigkeitsdatei.
  Was Projekte aus der Vorlage bekommen, bleibt gleich.
- Reproduzieren: eine Änderung an `modules/go/files/go.mod` pushen und die Actions
  ansehen.

**Lösungsskizze:**
- Die Vorlage heißt `go.mod.tmpl`; der Renderer streicht die Endung `.tmpl` bei
  `files/**` und schreibt wie bisher `go.mod` ins Projekt.
- Geprüft und verworfen (2026-11-04): ein Ausschluss je Pfad — `exclude-paths` in
  `.github/dependabot.yml` gilt laut Doku nur für Versions-Updates, nicht für die
  Graph-Läufe; die Graph-Läufe für Go und Python haben keinen eigenen Schalter, sie
  laufen, solange der Abhängigkeitsgraph an ist. Den Graphen abschalten nähme dem Repo
  die Dependabot-Alerts.

**Abhängigkeiten:** keine.

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben eine Datei unter `files/` eines Moduls, deren Name auf `.tmpl`
  endet, wenn der Renderer sie ausgibt, dann landet sie ohne diese Endung im Projekt
  (`files/go.mod.tmpl` → `go.mod`); Dateien ohne die Endung behalten ihren Pfad, und
  keine Ausgabe trägt die Endung `.tmpl` — belegt: Test „host github: no target keeps
  the .tmpl suffix“; ohne die Renderer-Zeile schlagen 15 Checks fehl; `just check` grün.
- [x] AC-2 — Gegeben die Go-Vorlage, dann gibt es im Kit-Repo keine Datei `go.mod` mehr,
  und der Render des Go-Moduls ergibt dieselbe `go.mod` wie vorher — Pfad und Inhalt,
  für Host `github` und `git` — belegt: `git ls-files` ohne `go.mod`; der ganze
  Go-Render vor und nach der Änderung ist für beide Hosts Byte für Byte gleich; Tests
  „Go module path“ und „bare Go module“.
- [ ] AC-3 — Gegeben der Push mit der Umbenennung auf `main`, dann folgt kein
  fehlgeschlagener Lauf „Graph Update: go_modules“ mehr; die übrigen Einträge des
  Abhängigkeitsgraphen (Actions, Python- und TS-Vorlage) bleiben.

### Randfälle

- EC-1 — Unter `files/` liegen `x` und `x.tmpl` → der Render bricht mit „two sources
  render to x“ ab (die Prüfung gibt es schon im Renderer, ein Test belegt sie).
- EC-2 — GitHub startet beim Push noch einen Graph-Lauf für den alten Ordner, um den
  Eintrag abzuräumen → in Ordnung, solange er nicht fehlschlägt; schlägt er einmalig
  fehl, gilt AC-3 erst mit dem nächsten Push, der keinen Lauf mehr auslöst.

### Nicht-Ziele

- `pyproject.toml` und `package.json` der Vorlagen bleiben lesbar: Sie lassen sich
  parsen, ihr Graph-Lauf ist grün, und ihre Einträge im Graphen melden verwundbare
  Versionsbereiche der Vorlage.
- Keine `.github/dependabot.yml` im Kit — sie hilft hier nicht (siehe Skizze) und würde
  Dependabot-PRs neben Renovate einschalten.
- Für Projekte ändert sich nichts: gleiche Dateien, gleiche Platzhalter.

### Tests

- AC-1, AC-2: `tests/template-sync/render.sh` — die vorhandenen Fälle für die Go-
  `go.mod` (Host `github` und `git`) laufen gegen die umbenannte Quelle; dazu ein Check,
  dass keine Ausgabe auf `.tmpl` endet. `just check` (der Validator vergleicht die
  Tabelle in `MODULE.md` mit den Dateien unter `files/`).
- EC-1: ein Fall in `render.sh` mit einer Template-Kopie, die `go.mod` und
  `go.mod.tmpl` hat → Render bricht ab.
- AC-3: manuell nach dem Push — `gh run list` zeigt keinen fehlgeschlagenen Lauf
  „Graph Update: go_modules“; `gh api …/dependency-graph/sbom` listet weiter
  Actions-, Python- und TS-Einträge.

### Einbettung

Berührt: Renderer (`template-sync.sh`, Ausgabe von `files/**`), MANIFEST § Module
contract (Regel zu `.tmpl`), Go-`MODULE.md` (Datei-Tabelle, Teile-Tabelle), die Datei
selbst, die Render-Tests. Skills lesen `files/` nur über den Renderer — new-project,
choose-stack und update-conventions bleiben unverändert. Das Ziel ändert sich nicht,
deshalb keine Zeile in `## Removed and renamed targets`. Für Projekte ändert sich
nichts, deshalb kein `### Template` im CHANGELOG (laut dessen Vorspann heißt ein
fehlender Abschnitt „betrifft Projekte nicht“); verlangt `just version-rule` ihn doch,
kommt ein Einzeiler dazu. 3.3.0 ist gepusht → 3.3.1. Kein ADR. Vorbild für die Endung:
die Basis-Kopien in `.claude/template-base/` tragen aus demselben Grund `.base`.

### Entscheidungen

- 2026-11-04 — Umbenennen statt Ausschluss: Die Skizze bevorzugte einen Ausschluss je
  Pfad oder das Abschalten der Go-Meldung und verwarf das Umbenennen. Den Ausschluss
  gibt es für Graph-Läufe nicht, ein Schalter je Ökosystem auch nicht; das Abschalten
  des ganzen Graphen kostet die Alerts. Das Umbenennen ist eine Zeile im Renderer und
  ein Satz im MANIFEST.

## Plan

**Größe:** S — eine Zeile im Renderer, ein Satz im MANIFEST, zwei Zeilen in
`MODULE.md`, eine Umbenennung, zwei Testfälle, dazu CHANGELOG und Version; die Lösung
liegt nach der Prüfung auf der Hand, und Projekte merken nichts.

- `git mv` von `modules/go/files/go.mod` nach `go.mod.tmpl`.
- `template-sync.sh`, Ausgabe von `files/**`: nach der Platzhalter-Ersetzung des
  Pfads die Endung `.tmpl` streichen.
- MANIFEST § Module contract, Zeile `files/**` und Composition rules: „a name ending in
  `.tmpl` loses the suffix — for files a tool in the kit repo would otherwise read as
  real (GitHub's dependency graph parses every `go.mod`)“.
- Go-`MODULE.md`: Datei-Tabelle `go.mod.tmpl`, Teile-Tabelle „go.mod (as
  `go.mod.tmpl`)“.
- `tests/template-sync/render.sh`: Check „keine Ausgabe auf `.tmpl`“ (AC-1) und der
  Fall mit `x` und `x.tmpl` (EC-1).
- CHANGELOG 3.3.1 mit einem Punkt zu F-056; `plugin.json` 3.3.1.
- Nach dem Push AC-3 prüfen und in step-done belegen.

Erkennung (2a): keine neuen Sprachen, Tools oder Dependencies. Keine neue Config, keine
Endpunkte.

## Verlauf

### F-056 — fertig 2026-11-04

- **Umgesetzt:** Die Go-Vorlage heißt `modules/go/files/go.mod.tmpl`. Der Renderer
  (`template-sync.sh`, Ausgabe von `files/**`) streicht nach der Platzhalter-Ersetzung
  die Endung `.tmpl`. MANIFEST § Module contract nennt die Regel in der Tabelle und unter
  den Composition rules; die Go-`MODULE.md` führt die Datei unter dem neuen Namen.
  `tests/template-sync/render.sh` prüft, dass keine Ausgabe auf `.tmpl` endet und dass
  ein Template mit `go.mod` neben `go.mod.tmpl` den Render abbricht (EC-1). Version
  3.3.1.
- **Entscheidungen:** kein `### Template` im CHANGELOG — der Render für Projekte bleibt
  Byte für Byte gleich, und die Versionsregel verlangt ihn nicht.
- **Abweichung vom Plan:** Der Test-Helfer `tmpl_left` steht in
  `tests/template-sync/run.sh` bei den übrigen Helfern statt in `render.sh`.
- **Funde:** keine; unabhängiges Review ohne Befunde. AC-3 wird nach dem Push belegt.
