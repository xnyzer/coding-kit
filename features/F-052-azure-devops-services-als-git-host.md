---
id: F-052
title: Azure DevOps Services als Git-Host
type: feature
status: BACKLOG
size:
created: 2026-11-03
done:
depends-on: F-032
superseded-by:
---

# F-052 — Azure DevOps Services als Git-Host

## Erfassung

**Problem:** Nach F-032 läuft ein Projekt auf Azure DevOps nur als „nur Git“: Repo anlegen,
Work Items, Pipeline und Renovate fehlen. In der Firma wird Azure DevOps Services (Cloud)
gebraucht.

**Ziel:** Als Nutzer in der Firma möchte ich Projekte auf Azure DevOps Services mit dem
ganzen Zyklus führen, damit die Host-Schritte dort genauso laufen wie auf GitHub.

**Lösungsskizze:**
- CLI `az` mit der Erweiterung `azure-devops` (nur Services); Repos über `az repos`,
  Anmeldung und Identität über die REST-Verbindungsdaten, weil es keinen
  whoami-Befehl gibt.
- Unterschiede zu GitHub: Repos haben weder Beschreibung noch Topics; die Sichtbarkeit
  gilt je Azure-Projekt, nicht je Repo; Work Items statt Issues, der Typ hängt vom
  Prozess ab.
- CI über `azure-pipelines.yml`, die Pipeline muss einmal registriert werden;
  PR-Vorlage unter `.azuredevops/`; Renovate-Plattform `azure`.
- Es gibt keine Noreply-Adresse: die Commit-Adresse kommt aus der Personal-Config
  (Firmenadresse), nie aus einer Annahme.
- Test mit einer kostenlosen eigenen Organisation, ohne Firmendaten.

**Abhängigkeiten:** F-032 (Host je Projekt, Fähigkeiten an einer Stelle, Commit-Adresse
je Host).
