---
id: F-061
title: Template-Versionen als Startwerte statt Renovate-Pflege im Kit
type: change
status: IN-PROGRESS
size: M
created: 2026-11-20
done:
depends-on:
superseded-by:
---

# F-061 — Template-Versionen als Startwerte statt Renovate-Pflege im Kit

## Erfassung

**Problem:** Renovate pflegt im Kit-Repo auch die Versionen unter
`plugins/coding-kit/template/`. Seit es am 2026-11-20 aus dem Silent-Modus kam, öffnet es
dafür PRs, die an der Versionsregel rot bleiben — rund ein Dutzend, darunter große
Sprünge. Grundsätzlicher: Ob ein Projekt eine neuere Tool- oder Sprachversion übernimmt,
entscheidet das Projekt mit seinem eigenen Renovate; das Kit kann das nicht für alle
Projekte entscheiden. Hebt das Kit eine Version in einer managed Datei an (CI-Workflows,
`azure-pipelines.yml`, Sprachversionen der Module), bietet `/update-conventions` sie
jedem Projekt an.

**Ziel:** Versionen im Template sind Startwerte für neue Projekte; danach entscheidet
das Projekt. Das Kit hebt sie nur bewusst an, etwa wenn ein Modul überarbeitet und mit
der neuen Version geprüft wird. Gleich bleiben: die Versionsregel, das Preset
(`default.json`) für alle Projekte, die Lock File Maintenance aus F-059 und Renovate für
die Kit-eigenen Dateien.

**Lösungsskizze:**
- In der `renovate.json` des Kit-Repos (nicht im Preset) für den Ordner
  `plugins/coding-kit/template/` Updates nur nach Freigabe im Dashboard, mit eigenem
  Branch-Präfix.
- `docs/renovate-preset.md` (Abschnitt Dogfooding) und wo nötig das MANIFEST anpassen;
  beschreiben, wann und wie das Kit Startwerte bewusst auffrischt.
- Die offenen Template-PRs schließen; Kit-eigene Updates laufen als eigene PRs weiter.
- Verworfen: Template-Updates gebündelt laufend übernehmen (das Kit entschiede für alle
  Projekte); die Versionsregel für Renovate lockern.

**Abhängigkeiten:** keine

**Noch zu analysieren:**
- Reicht der Ausschluss, oder sollen Versionszeilen in managed Dateien nach dem Anlegen
  ganz dem Projekt gehören (Policy seed), damit auch ein bewusstes Auffrischen im Kit
  nicht allen Projekten angeboten wird?
- Den heutigen Stand einmal bewusst auffrischen, oder die Startwerte so lassen? Sind
  go 1.26 und python 3.13 bewusst gewählt?
- Nebenbefund: Renovate meldet „Unexpected downgrade detected“ bei den Selektoren in
  `mise.toml` — harmlos, die Lock File Maintenance hebt trotzdem an.

## Spezifikation

Grundlage ist der Code-Stand vom 2026-11-20 (nach `8186e81`). Renovate pflegt im
Kit-Repo alle Versionen, auch die unter `plugins/coding-kit/template/`. Dort sind sie
Startwerte für neue Projekte: Seed-Dateien (`package.json`, `[project]` in
`pyproject.toml`) gehören nach dem Anlegen dem Projekt; managed Dateien (Workflows,
`azure-pipelines.yml`, `mise.toml` der Module) gleicht `/update-conventions` drei-wegig
ab — eine Version, die das Kit nicht ändert, löst dort nichts aus. Renovates Freigabe
über das Dashboard (`dependencyDashboardApproval`) verhindert nur neue Branches;
bestehende pflegt es weiter, deshalb bekommen die Template-Updates eigene Branch-Namen.

### Abnahmekriterien

- [ ] AC-1 — Gegeben die `renovate.json` des Kit-Repos, wenn Renovate läuft, dann
  öffnet es für Versionen unter `plugins/coding-kit/template/` keine PRs, sondern führt
  sie im Dependency Dashboard unter „Pending Approval“; ein Häkchen dort erzeugt den PR.
  Negativ: Updates der Kit-eigenen Dateien (Workflows im Root, `mise.lock`) kommen
  weiter als eigene PRs; `default.json` bleibt unverändert.
- [ ] AC-2 — Gegeben die offenen Renovate-PRs und -Branches vom 2026-11-20, wenn nach
  dem Push der erste Lauf mit der neuen Regel war, dann enthält kein offener PR mehr
  Dateien unter `plugins/coding-kit/template/`; reine Template-PRs und -Branches sind
  geschlossen (von Renovate oder von Hand). Negativ: Das Update von actions/checkout
  für die Kit-CI bleibt als grüner PR.
- [x] AC-3 — Gegeben `docs/renovate-preset.md` (Abschnitt Dogfooding) und die
  `CLAUDE.md` des Kits, wenn man sie liest, dann sagen sie: Versionen im Template sind
  Startwerte, das Kit hebt sie bewusst an (Häkchen im Dashboard, PR, Version und
  CHANGELOG mit `### Template`), `/update-conventions` bietet eine solche Anhebung je
  Datei zur Bestätigung an. Negativ: keine Versionsstände im Text; `just check` grün.
  — belegt: `docs/renovate-preset.md` (Dogfooding) und `CLAUDE.md` nennen Startwerte,
  den Weg zum Anheben und das Angebot je Datei in `/update-conventions`, ohne
  Versionsstände; `just check` grün.

### Randfälle

- EC-1 — Ein freigegebener Template-PR ist rot, bis Version und CHANGELOG nachgezogen
  sind → gewollt, die Versionsregel bleibt.
- EC-2 — Dieselbe Abhängigkeit im Root und im Template (actions/checkout) → zwei
  getrennte Updates: ein PR für die Kit-CI, ein Eintrag im Dashboard fürs Template.
- EC-3 — Ein Projekt hat eine Version selbst angehoben, das Kit hebt später bewusst an
  → gleiche Version: kein Konflikt; andere Version: Konflikt, das Projekt entscheidet.
- EC-4 — Sicherheitsupdate für eine Version im Template → Projekte bekommen es über ihr
  eigenes Renovate; im Kit steht es im Dashboard und wird bewusst übernommen.
- EC-5 — Renovate räumt einen alten Template-Branch nicht selbst ab → von Hand
  schließen; ein geschlossener PR blockiert den neuen nicht, weil der Branch-Name neu ist.
  Muss #1 von Hand geschlossen werden, kommt das Update für die Kit-CI über das Häkchen
  unter „PR Closed (Blocked)“ im Dashboard neu.

### Nicht-Ziele

- Keine Änderung am Preset `default.json`; Projekte sind nicht betroffen.
- Keine Änderung der Policies im MANIFEST; managed Dateien bleiben managed.
- Kein Auffrischen der Startwerte in F-061; das geschieht, wenn ein Modul überarbeitet
  wird (etwa python und ts-node in F-058).
- Die Warnung „Unexpected downgrade detected“ wird nicht weiter verfolgt.

### Tests

- AC-1: Check — `renovate-config-validator` auf `renovate.json` (per npx, nichts ins
  Repo); manuell nach dem Push: Dashboard zeigt die Template-Updates unter „Pending
  Approval“ mit Präfix `template-`.
- AC-2: manuell nach dem Push — `gh pr list` und `git ls-remote`: kein offener PR mit
  Template-Dateien, #1 nur mit der Kit-CI und grün.
- AC-3: manuell — Doku lesen; `just check` (Privacy- und Versions-Lint).

### Einbettung

- Berührt: `renovate.json` (Root), `docs/renovate-preset.md`, `CLAUDE.md` (Regel zu
  Versionsständen). Kein Plugin-Inhalt, also keine neue Version.
- Der Graph-Fakt „die Versionsregel hält Renovate-PRs rot, bis die Version steigt“ gilt
  danach nur noch für freigegebene Template-PRs; der Wegweiser beim Abschluss sagt das.
- Folge: F-058 kann die Startwerte von python und ts-node mit auffrischen.
- Kein Widerspruch zu Zielen oder Nicht-Zielen.

### Offene Fragen

keine

### Entscheidungen

- 2026-11-20 — Versionen im Template sind Startwerte; ob ein Projekt eine neuere
  Version übernimmt, entscheidet das Projekt. Empfehlung war zuerst, die
  Template-Updates gebündelt zu übernehmen; entschieden so, weil das Kit nicht für alle
  Projekte über Tool-Versionen entscheiden soll. Entscheidung des Nutzers.
- 2026-11-20 — Template-Updates auf Freigabe im Dashboard statt ganz ausgeblendet.
  Grund: Die Liste zeigt, welche Startwerte veraltet sind, ohne laufende PRs.
  Entscheidung des Nutzers nach Empfehlung.
- 2026-11-20 — Versionszeilen in managed Dateien bleiben managed. Grund: Eine Version,
  die das Kit nicht ändert, löst in Projekten nichts aus; eine bewusste Anhebung wird je
  Datei bestätigt; als Seed kämen auch andere Verbesserungen dieser Dateien nicht mehr
  an. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-20 — Kein Auffrischen der Startwerte in F-061. Entscheidung des Nutzers nach
  Empfehlung.

## Plan

**Größe:** M. Drei Dateien mit wenigen Zeilen, aber wie Renovate die bestehenden PRs
umbaut, zeigt erst ein Lauf nach dem Push.

**Ansatz:** Eine Regel (`packageRules`) in der `renovate.json` des Kit-Repos gilt für
alle Dateien unter `plugins/coding-kit/template/`: Freigabe über das Dashboard
(`dependencyDashboardApproval`), eigener Branch-Präfix (`additionalBranchPrefix:
"template-"`) und ein Zusatz im PR-Titel („in the template“), damit Root- und
Template-Updates getrennt laufen. Verworfen: die Template-Dateien ganz abschalten
(`enabled: false`) — keine Liste veralteter Startwerte; `ignorePaths` — ersetzt die
Vorgaben von `config:recommended` und zeigt ebenfalls nichts an.

### F-061a — Regel und Doku

- `renovate.json`: die Regel, dazu eine Zeile in `description`.
- `docs/renovate-preset.md`, Abschnitt Dogfooding: Template-Versionen sind Startwerte;
  bewusst anheben über Häkchen im Dashboard → PR → Version und CHANGELOG mit
  `### Template`; `/update-conventions` bietet die Anhebung je Datei zur Bestätigung an.
- `CLAUDE.md`, Regel zu Versionsständen: Renovate hält die Pins des Kits aktuell, die im
  Template sind Startwerte (Verweis auf die Doku).
- Prüfen: `renovate-config-validator` auf `renovate.json` (per npx), Gegenprobe mit
  Tippfehler im Schlüssel; `just check`.
- Kein Plugin-Inhalt, also keine neue Version.
- Erfüllt AC-3; AC-1 bis auf den echten Lauf.

### F-061b — Lauf nach dem Push

- Nach Commit und Push von F-061a (auf ausdrückliche Bitte) den nächsten Renovate-Lauf
  abwarten oder im Mend-Portal anstoßen.
- Prüfen: Dashboard führt die Template-Updates unter „Pending Approval“; #1 ändert nur
  die Kit-CI und ist grün; kein offener PR mit Template-Dateien.
- Was Renovate nicht selbst schließt, nach Rückfrage von Hand schließen (EC-5).
- Ändert keine Kit-Dateien außer der Feature-Datei.
- Erfüllt AC-1 und AC-2.

**Erkennung (Schritt 2a):** entfällt; kein neues Framework, keine neue Sprache, kein
neues Tool, keine Dependencies.

## Verlauf

### F-061a — fertig 2026-11-20

**Umgesetzt:**

- `renovate.json`: eine Regel für `plugins/coding-kit/template/**` — Updates nur nach
  Freigabe im Dependency Dashboard, Branch-Präfix `template-`, im PR-Titel der Zusatz
  „in the template“; dazu eine Zeile in `description`. `renovate-config-validator`
  meldet die Datei gültig; mit Tippfehler im Schlüssel meldet er „Invalid configuration
  option“.
- `docs/renovate-preset.md`, Abschnitt Dogfooding: Template-Versionen sind Startwerte;
  der Weg zum bewussten Anheben in drei Schritten; was `/update-conventions` danach mit
  managed und Seed-Dateien tut.
- `CLAUDE.md`, Regel zu Versionsständen: Renovate hält die Pins des Kits aktuell, die
  im Template sind Startwerte.

**Entscheidungen:** keine neuen.

**Abweichung vom Plan:** keine.

**Funde:** Unabhängiges Review: keine Befunde.
