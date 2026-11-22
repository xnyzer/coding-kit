---
id: F-072
title: Workspaces erkennen und das Lizenz-Gate dort absichern
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-072 — Workspaces erkennen und das Lizenz-Gate dort absichern

## Erfassung

**Problem:** Drei von fünf migrierten Projekten waren pnpm-Workspaces, aber das Kit kennt
keinen Workspace. `detect` meldet `module ts-node covered`, und das Lizenz-Rezept prüft im
Root eines Workspaces 0 Pakete und ist grün. In einem Projekt waren es mit `-r` 379
Pakete, zwei davon fielen durch.

**Ziel:**
- **Ist:**
  - `pnpm licenses list --prod --json` ohne `-r` liefert im Workspace-Root `{}`.
  - Kein Rezept bemerkt, dass nichts geprüft wurde.
  - Der Abgleich gerät ohne Hinweis in die Lücke des Moduls.
- **Soll:**
  - Das Lizenz-Gate prüft alle Pakete eines Workspaces.
  - Ein Gate, das 0 Pakete prüft, obwohl es Abhängigkeiten gibt, ist rot.
  - `detect` sagt, dass das Modul einen Workspace noch nicht abdeckt.
- **Reproduzieren:** pnpm-Workspace mit Abhängigkeiten nur in den Paketen →
  `just license-check`.

**Lösungsskizze:**
- `-r` im Lizenz-Rezept, in einem Einzelpaket gleichwertig.
- „0 geprüft bei vorhandenen Abhängigkeiten“ ist ein Fehler, in den Lizenz-Rezepten
  aller Module.
- `detect` erkennt Workspaces (`pnpm-workspace.yaml`, `workspaces` in `package.json`,
  `go.work`, uv-Workspace, Multi-Modul in Maven oder Gradle) und meldet sie. MODULE.md
  nennt die Grenze.
- Den Workspace-Vertrag selbst liefert F-076.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Wie die Lizenz-Rezepte der anderen Module „0 geprüft“ erkennen.
- Welche Ausgabezeile `detect` für einen Workspace bekommt.
