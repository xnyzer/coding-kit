---
id: F-066
title: Releases per GitHub-Workflow beim Tag-Push anlegen
type: feature
status: PLANNED
size: M
created: 2026-11-22
done:
depends-on: F-065
superseded-by:
---

# F-066 — Releases per GitHub-Workflow beim Tag-Push anlegen

## Erfassung

**Problem:** Seit F-065 bekommt jede Version ab 1.0.0 einen Tag `vX.Y.Z` und ein
GitHub-Release. Das Release legt ein eigener Schritt nach dem Push des Tags von Hand an;
wird er vergessen oder bricht er ab, fehlt das Release, und niemand merkt es.

**Ziel:** Als Pfleger des Kits möchte ich, dass ein gepushter Tag `vX.Y.Z` sein
GitHub-Release selbst bekommt, damit kein Release fehlt und sein Text immer aus dem
CHANGELOG des getaggten Stands stammt.

**Lösungsskizze:**
- Ein Workflow, ausgelöst vom Push eines Tags `v*` und auch von Hand startbar
  (`workflow_dispatch`): Er ruft `scripts/publish-release.sh` auf, das den Abschnitt der
  Version mit `scripts/release-notes.sh` aus dem CHANGELOG des getaggten Commits liest und
  das Release mit `gh release create` anlegt, ohne eigenen Titel.
- Gibt es das Release schon, überspringt er es; ist die Version nicht datiert oder fehlt
  sie, schlägt er fehl.
- Schreibrecht (`contents: write`) nur für diesen Job; die CI behält `contents: read`.
  Die Action ist per SHA gepinnt, Renovate hält sie aktuell.
- Der Release-Ablauf in der Kit-CLAUDE.md verkürzt sich entsprechend.
- Alternative: nur eine Prüfung in der CI, die eine datierte Version ohne Tag oder
  Release meldet — ohne Schreibrecht, aber nur als Erinnerung.

**Abhängigkeiten:** F-065.

**Noch zu analysieren:** Geklärt in der Spezifikation (Entscheidungen vom 2026-11-22).

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Tag `vX.Y.Z`, dessen Commit die Version im CHANGELOG datiert
  hat, und noch kein Release dafür, wenn `just publish-release vX.Y.Z` läuft, dann legt
  es mit `gh release create vX.Y.Z --verify-tag` ein Release ohne eigenen Titel an; der
  Text ist die Ausgabe von `scripts/release-notes.sh` für den CHANGELOG **im getaggten
  Commit**, nicht im Arbeitsbaum.
- [ ] AC-2 — Gegeben der Tag ist die höchste Version unter allen Tags `v*`, dann
  übergibt das Skript `--latest=true`; sonst `--latest=false` (z. B. ein Patch `v3.6.1`,
  während `v3.7.0` existiert).
- [ ] AC-3 — Gegeben es gibt das Release für den Tag schon, dann ruft das Skript
  `gh release create` nicht auf, meldet „übersprungen“ und endet mit Exit 0.
- [ ] AC-4 — Gegeben ein Tag, den es nicht gibt, ein Name, der nicht `vX.Y.Z` ist, oder
  eine Version, die im CHANGELOG des getaggten Commits fehlt oder nicht datiert ist, wenn
  das Skript läuft, dann bricht es mit einer Meldung auf stderr und einem Exit-Code
  ungleich 0 ab, ohne `gh release create` aufzurufen.
- [ ] AC-5 — Gegeben der Push eines Tags `v*` oder ein manueller Start des Workflows mit
  einem Tag, dann ruft der Workflow das Skript für diesen Tag auf. Schreibrecht
  (`contents: write`) hat nur dieser Job, die Workflow-Ebene hat keine Rechte; die
  Action ist per SHA gepinnt; der Tag aus dem manuellen Start kommt als
  Umgebungsvariable ins Skript, nie als Text in den Befehl. actionlint findet nichts.
- [ ] AC-6 — Gegeben das Release `v3.7.0` existiert, wenn der Workflow manuell für
  `v3.7.0` startet, dann überspringt er es; nach dem Löschen des Releases `v3.7.0` legt
  ein zweiter Start es neu an — Titel der Tag-Name, Text gleich der Skriptausgabe,
  „Latest“.
- [ ] AC-7 — Gegeben ein anstehendes Release, wenn man in der Kit-CLAUDE.md nachliest,
  dann steht dort: Schritt 4 übernimmt der Workflow nach dem Push des Tags; scheitert er,
  startet man ihn manuell (`gh workflow run`) oder ruft `just publish-release vX.Y.Z` von
  Hand auf. Die README nennt Workflow und Skript.

### Randfälle

- EC-1 — Ein Tag auf einem Commit ohne Workflow-Datei (alle bis `v3.7.0`) → der
  Tag-Push startet nichts; der manuelle Start geht trotzdem, weil das Skript aus main
  kommt und nur den CHANGELOG aus dem Tag liest.
- EC-2 — Ein Tag der eingefrorenen Reihen oder `v0.*` → `release-notes.sh` lehnt die
  Version ab, das Skript bricht ab.
- EC-3 — Mehrere Tags in einem Push → je Tag ein Lauf; jeder rechnet „Latest“ gegen alle
  Tags, also wird nur der höchste „Latest“.
- EC-4 — Ein manueller Start mit einer Eingabe wie `v1.0.0; rm -rf x` → die
  Formatprüfung lehnt sie ab, bevor etwas anderes läuft.
- EC-5 — Ein Tag wird gelöscht und unter gleichem Namen neu gesetzt → das Release gibt es
  noch, das Skript überspringt; ein falsches Release korrigiert man von Hand.

### Nicht-Ziele

- Der Workflow setzt keine Tags — der Tag bleibt der freigegebene Schritt.
- Keine Prüfung, ob der Tag auf main liegt.
- Vorhandene Releases werden nie geändert oder ersetzt.
- Nichts davon gelangt ins Template oder in Projekte.
- actionlint kommt nicht in die Toolchain des Kits.

### Tests

- AC-1 bis AC-4, EC-2, EC-4 → automatisch: Fälle in `tests/template-sync/publish-release.sh`
  mit einem Wegwerf-Repo (Tags, CHANGELOG je Commit) und einem falschen `gh` auf dem
  PATH, das seine Aufrufe mitschreibt und ein vorhandenes Release vortäuschen kann;
  unter dash und bash, mit mawk.
- AC-5 → einmal `mise x actionlint@<aktuell> -- actionlint .github/workflows/release.yml`
  ohne Befund, dazu Durchsicht von Rechten, Pin und Eingabe.
- AC-6 → manuell nach dem Push: `gh workflow run release.yml -f tag=v3.7.0` (Lauf
  überspringt), `gh release delete v3.7.0`, zweiter Start, dann `gh release view v3.7.0`
  (Titel, Text, Latest) und `gh release list`.
- AC-7 → Durchsicht: CLAUDE.md und README nach dem Schreiben neu lesen.

### Einbettung

- Neu: `.github/workflows/release.yml`, `scripts/publish-release.sh` (POSIX-Shell),
  `tests/template-sync/publish-release.sh` (von `run.sh` geladen), Rezept
  `publish-release` im justfile.
- `scripts/script-tests.sh`: `scripts/publish-release.sh` in die Pfadliste.
- `scripts/release-notes.sh` bleibt, wie es ist — das neue Skript ruft es mit dem
  CHANGELOG aus dem Tag auf.
- Doku: Kit-CLAUDE.md (Release-Ablauf, Schritt 4), README (Repo-Struktur, Pflege).
- Renovate hält den neuen Action-Pin mit, wie in der CI.
- Versionsregel: nichts davon ist Plugin-Inhalt — keine neue Version.
- Sicherheit: Der Workflow ist der erste mit Schreibrecht. Einen Tag pushen oder den
  Workflow manuell starten kann nur, wer Schreibrecht am Repo hat; ein Release, das der
  Workflow mit seinem Token anlegt, startet keine weiteren Workflows.
- Keine Folge-F-Nummer nötig.

### Offene Fragen

keine

### Entscheidungen

- 2026-11-22 — Ein Skript `scripts/publish-release.sh` trägt die Logik, Workflow und
  Handbetrieb rufen dasselbe auf; verworfen: die Befehle direkt im Workflow (nicht
  testbar, und der Rückweg von Hand wäre eine zweite Fassung).
- 2026-11-22 — Der Workflow lässt sich zusätzlich manuell für einen vorhandenen Tag
  starten; damit wird er sofort an `v3.7.0` geprüft (überspringen, dann Release löschen
  und neu anlegen lassen) und dient als Rückweg.
- 2026-11-22 — „Latest“ nur für die höchste Version unter allen Tags `v*`, immer
  ausdrücklich übergeben; verworfen: GitHub entscheiden lassen (ein Patch auf einer
  alten Reihe könnte „Latest“ werden).
- 2026-11-22 — Tests mit einer `gh`-Attrappe im Test-Harness, dazu actionlint einmal von
  Hand.

## Plan

**Größe:** M — rund sechs Dateien und unter 300 Zeilen; die offenen Fragen sind geklärt.
Die Reichweite hebt es an: der erste Workflow mit Schreibrecht, und die Probe an
`v3.7.0` wirkt öffentlich.

**Ansatz:** `scripts/publish-release.sh vX.Y.Z` (POSIX-Shell), im Repo aufgerufen, in
dieser Reihenfolge:

1. Den Namen gegen `vX.Y.Z` prüfen (nur Ziffern und Punkte), sonst Abbruch mit Exit 2.
2. Den Tag mit `git rev-parse` suchen, sonst Abbruch.
3. `gh release view vX.Y.Z` — gibt es das Release, „übersprungen“ melden, Exit 0.
4. Den CHANGELOG des getaggten Commits per `git show vX.Y.Z:plugins/coding-kit/CHANGELOG.md`
   in eine temporäre Datei schreiben und `scripts/release-notes.sh X.Y.Z <datei>`
   aufrufen; dessen Abbruch (fehlende oder undatierte Version) beendet auch dieses
   Skript.
5. Die höchste Version unter allen Tags `vX.Y.Z` bestimmen (`git tag -l`, numerisch
   sortiert); ist es dieser Tag, `--latest=true`, sonst `--latest=false`.
6. `gh release create vX.Y.Z --verify-tag --notes-file <datei> --latest=…`, ohne Titel.

Die temporären Dateien räumt ein `trap` weg. Das Rezept `just publish-release vX.Y.Z`
reicht den Tag mit `[positional-arguments]` als Argument weiter, nicht als Text im
Befehl.

`.github/workflows/release.yml`:

- Auslöser: `push` von Tags `v*` und `workflow_dispatch` mit der Eingabe `tag`.
- `permissions: {}` auf Workflow-Ebene; der eine Job bekommt `contents: write`.
- `actions/checkout` per SHA gepinnt wie in der CI, `fetch-depth: 0` (alle Tags und der
  CHANGELOG des Tags), `persist-credentials: false`.
- Ein Schritt: `sh scripts/publish-release.sh "$TAG"`, mit `TAG` und `GH_TOKEN` als
  Umgebungsvariablen. `TAG` ist beim Tag-Push `github.ref_name`, beim manuellen Start
  `inputs.tag`.
- `concurrency` je Tag, ohne Abbruch laufender Läufe.

Beim Tag-Push stammen Skript und CHANGELOG aus dem getaggten Commit; beim manuellen Start
stammt das Skript aus main und der CHANGELOG aus dem Tag.

Verworfen: die Befehle direkt in den Workflow schreiben (nicht testbar, der Rückweg von
Hand wäre eine zweite Fassung); `gh release create --generate-notes` (GitHub erzeugt den
Text aus PRs, nicht aus dem CHANGELOG).

### F-066a — Skript, Tests, Workflow und Doku

- Neu `scripts/publish-release.sh`, `.github/workflows/release.yml`, Rezept
  `publish-release` im justfile.
- Neu `tests/template-sync/publish-release.sh` (in `run.sh` geladen und aufgerufen): ein
  Wegwerf-Repo mit Tags und je Commit eigenem CHANGELOG, dazu ein falsches `gh` auf dem
  PATH, das seine Aufrufe und den Release-Text mitschreibt und vorhandene Releases aus
  einer Liste vortäuscht.
- `scripts/script-tests.sh`: `scripts/publish-release.sh` in die Pfadliste.
- Kit-CLAUDE.md: Schritt 4 des Release-Ablaufs — „legt der Workflow nach dem Push des
  Tags an; scheitert er: `gh workflow run release.yml -f tag=vX.Y.Z` oder
  `just publish-release vX.Y.Z`“. README: Repo-Struktur (Workflow, Skript) und Pflege.
- actionlint einmal über `release.yml` (`mise x actionlint@<aktuell> -- actionlint`).
- Erfüllt AC-1 bis AC-5, AC-7, EC-2 bis EC-5. Keine neue Version (kein Plugin-Inhalt).
- Commit lokal; gepusht wird auf deine Bitte — F-066b braucht den Workflow auf GitHub.

### F-066b — Probe an v3.7.0

- Voraussetzung: F-066a ist gepusht und die CI grün.
- Nach Freigabe: `gh workflow run release.yml -f tag=v3.7.0` → der Lauf meldet
  „übersprungen“.
- Nach Freigabe: `gh release delete v3.7.0 --yes` — nur das Release, der Tag bleibt —, dann
  ein zweiter Start → das Release entsteht neu.
- Prüfen: `gh release view v3.7.0` (Titel leer, also Tag-Name; Text gleich
  `just release-notes 3.7.0`; Latest), `gh release list` (21 Releases, nur v3.7.0 Latest),
  Rechte und Log des Laufs.
- Erfüllt AC-6, EC-1. Danach Verbuchung und Abschluss-Commit.

**Erkennung:** keine neuen Frameworks, Dependencies oder Toolchains — `gh`, `git` und
awk sind auf den Runnern vorhanden; actionlint läuft nur einmal von Hand.
