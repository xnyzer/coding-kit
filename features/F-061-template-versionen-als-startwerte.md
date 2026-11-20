---
id: F-061
title: Template-Versionen als Startwerte statt Renovate-Pflege im Kit
type: change
status: BACKLOG
size:
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
- In der `renovate.json` des Kit-Repos (nicht im Preset) den Ordner
  `plugins/coding-kit/template/` ausschließen.
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
