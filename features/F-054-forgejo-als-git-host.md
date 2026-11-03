---
id: F-054
title: Forgejo als Git-Host
type: feature
status: BACKLOG
size:
created: 2026-11-03
done:
depends-on: F-032
superseded-by:
---

# F-054 — Forgejo als Git-Host

## Erfassung

**Problem:** Nach F-032 läuft ein Projekt auf Forgejo (etwa Codeberg) nur als „nur Git“: Repo
anlegen, Topics, Issues, CI und Renovate fehlen.

**Ziel:** Als Nutzer mit Projekten auf Forgejo möchte ich den ganzen Zyklus dort führen,
damit die Host-Schritte wie auf GitHub laufen.

**Lösungsskizze:**
- CLI `fj` (forgejo-cli, Apache-2.0 oder MIT); `tea` und `berg` sind archiviert, der
  Nachfolger von `tea` braucht einen neueren Gitea — Pflegestand zur Planungszeit
  prüfen.
- CI über `.forgejo/workflows`; `.github/workflows` liest Forgejo nur, wenn
  `.forgejo/workflows` fehlt, und GitHub Actions sind nur teilweise kompatibel.
  Vorlagen unter `.forgejo/`.
- Noreply-Adresse im Format `<user>@noreply.<domain>`; Renovate-Plattform `forgejo`,
  Preset-Präfix `forgejo>`.
- Basis-URLs selbst gehosteter Server sind privat: nur in der Personal-Config.
- Test auf Codeberg.

**Abhängigkeiten:** F-032 (Host je Projekt, Fähigkeiten an einer Stelle, Commit-Adresse
je Host).
