---
id: F-063
title: Neues Projekt als Fork eines GitHub-Repos anlegen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on: F-032
superseded-by:
---

# F-063 — Neues Projekt als Fork eines GitHub-Repos anlegen

## Erfassung

**Problem:** `/coding-kit:new-project` legt ein Projekt immer leer aus dem Template an.
Wer auf dem Code eines fremden Repos aufbauen will, forkt von Hand und baut die
Kit-Dateien per `/coding-kit:update-conventions` ein. Dann landen `CLAUDE.md`,
`features/`, justfile, CI und Renovate in jedem Pull Request an das Original, und das
Kit mergt in Dateien, die dem Original gehören.

**Ziel:** Als Nutzer möchte ich ein Projekt als Fork eines GitHub-Repos anlegen und mit
dem Kit-Zyklus führen, damit ich beides kann: (a) den Fork zu einem eigenen Projekt
weiterentwickeln und Neuerungen des Originals nachziehen, (b) Änderungen als Pull
Request an das Original zurückgeben, ohne Kit-Dateien darin.

**Lösungsskizze:**
- Fork-Modus in new-project: Eingabe ist das Original-Repo; `gh repo fork --clone`
  legt Fork und die Quelle `upstream` an.
- Nur eine Kit-Schicht darüber; Dateien, die das Original schon hat (CI, Linter,
  README, LICENSE, ggf. eigene CLAUDE.md oder justfile), verwaltet das Kit nicht.
- Lizenz vom Original übernehmen, kein `choose-license`; Stack erkennen wie
  choose-stack im Modus Bestandsprojekt.
- Beiträge über Branches, die vom Stand des Originals abzweigen und so keine
  Kit-Dateien tragen; Original nachziehen über `upstream` in den eigenen Hauptbranch.
- Option verworfen: Kit-Dateien nur lokal ausblenden (`.git/info/exclude`) — sie lägen
  dann nur auf einem Rechner.

**Abhängigkeiten:** F-032 (Git-Host je Projekt).

**Noch zu analysieren:**
- Welche Kit-Dateien sind im Fork Pflicht, welche optional (CI, Renovate, lefthook,
  Lizenzprüfung neben den Werkzeugen des Originals)?
- Wie hält update-conventions die Dateien des Originals dauerhaft heraus — eigene
  Antwort im Antworten-File, Abweichungs-Registry, oder beides?
- Wie unterstützt der Zyklus den Beitrag: eigener Schritt in step-done, ein Hinweis,
  oder ein eigener Skill?
- Umgang mit Regeln des Originals (CONTRIBUTING, DCO-Sign-off, CLA, Commit-Stil).
- Abgrenzung zum Begriff „Upstream“ in check-upstreams (Watchliste fürs Kit).
- GitLab und Forgejo erst mit F-053 und F-054.
