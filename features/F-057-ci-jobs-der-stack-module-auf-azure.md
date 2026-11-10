---
id: F-057
title: CI-Jobs der Stack-Module auch in der Azure-Pipeline
type: feature
status: BACKLOG
size:
created: 2026-11-10
done:
depends-on: F-052
superseded-by:
---

# F-057 — CI-Jobs der Stack-Module auch in der Azure-Pipeline

## Erfassung

**Problem:** Stack-Module können der GitHub-CI eigene Jobs anhängen (`ci.part.yml` unter
`# module:ci-jobs`); für `azure-pipelines.yml` gibt es keinen solchen Modulteil. Das
Go-Modul prüft so die Lizenzen seiner Abhängigkeiten (`just license-check`), das nicht in
`just check` steckt — auf Azure-Go-Projekten fehlt diese Prüfung in der CI.

**Ziel:** Als Nutzer in der Firma möchte ich, dass ein Projekt auf Azure dieselben
CI-Prüfungen seines Stack-Moduls bekommt wie auf GitHub, damit eine verbotene Lizenz
nicht unbemerkt hineinkommt.

**Lösungsskizze:**
- Option: ein Modulteil für `azure-pipelines.yml` (Schritte unter einer Marke), analog
  zu `ci.part.yml` — MANIFEST § Module contract und Render ziehen nach.
- Option: `license-check` in das `just check` des Go-Moduls aufnehmen; dann prüfen alle
  Hosts gleich, aber `just check` braucht Netz und wird langsamer.
- Option: nur dokumentieren, bis ein Go-Projekt auf Azure entsteht.

**Abhängigkeiten:** F-052 (dort entsteht `azure-pipelines.yml`).

**Noch zu analysieren:** Brauchen weitere Module CI-Jobs außerhalb von `just check`?
Wie verhält sich ein Modulteil, wenn die Pipeline im Projekt angepasst wurde (Pool)?
