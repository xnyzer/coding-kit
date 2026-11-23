---
id: F-096
title: Projekte-Ordner außerhalb synchronisierter Ordner vorschlagen
type: feature
status: BACKLOG
size:
created: 2026-11-23
done:
depends-on:
superseded-by:
---

# F-096 — Projekte-Ordner außerhalb synchronisierter Ordner vorschlagen

## Erfassung

**Problem:** Der Installer schlägt als Projekte-Ordner `~/Documents/Coding-Projects`
vor. Unter Windows ist der Dokumente-Ordner oft auf OneDrive umgeleitet, und ein leeres
`~/Documents` daneben führt den Vorschlag zusätzlich in die Irre; unter macOS
synchronisiert iCloud mit „Schreibtisch & Dokumente“ denselben Ort. Git-Repos in einem
Sync-Ordner führen leicht zu Konflikten, Sperren und kaputten `.git`-Ordnern.

**Ziel:** Als Nutzer möchte ich, dass das Kit einen Projekte-Ordner außerhalb
synchronisierter Ordner vorschlägt und mich warnt, wenn mein gewählter Ordner in einem
liegt, damit meine Repos nicht vom Sync-Dienst beschädigt werden.

**Lösungsskizze:**
- Erkennen, ob ein Ordner unter einem Sync-Dienst liegt: OneDrive (Umgebungsvariablen
  `OneDrive`, umgeleiteter Dokumente-Ordner), iCloud Drive, ggf. Dropbox — wie das je
  Plattform zuverlässig geht, ist zu prüfen.
- Im Installer dann einen Ort außerhalb vorschlagen, etwa direkt im Home-Ordner.
- Eine bestehende Personal-Config mit einem Projekte-Ordner im Sync-Ordner melden
  (Installer, `update-conventions global`) — nur Hinweis, nichts verschieben.

**Abhängigkeiten:** keine; berührt dieselbe Stelle im Installer wie F-067
(`default_projects_dir`).
