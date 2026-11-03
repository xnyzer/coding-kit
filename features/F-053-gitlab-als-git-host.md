---
id: F-053
title: GitLab als Git-Host
type: feature
status: BACKLOG
size:
created: 2026-11-03
done:
depends-on: F-032
superseded-by:
---

# F-053 — GitLab als Git-Host

## Erfassung

**Problem:** Nach F-032 läuft ein Projekt auf GitLab nur als „nur Git“: Repo anlegen, Topics,
Issues, CI und Renovate fehlen.

**Ziel:** Als Nutzer mit Projekten auf GitLab möchte ich den ganzen Zyklus dort führen, damit
die Host-Schritte wie auf GitHub laufen.

**Lösungsskizze:**
- CLI `glab` (offiziell, MIT). Topics nur beim Anlegen oder über die API, nicht über
  `repo update`.
- CI über `.gitlab-ci.yml`, Vorlagen unter `.gitlab/` (z. B. `issue_templates`);
  Renovate-Plattform `gitlab`, Preset-Präfix `gitlab>`.
- Noreply-Adresse im Format `<id>-<user>@users.noreply.gitlab.com`.
- Test auf gitlab.com.

**Abhängigkeiten:** F-032 (Host je Projekt, Fähigkeiten an einer Stelle, Commit-Adresse
je Host).
