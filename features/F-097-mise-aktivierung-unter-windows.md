---
id: F-097
title: mise-Aktivierung unter Windows erkennen und anbieten
type: fix
status: BACKLOG
size:
created: 2026-11-23
done:
depends-on:
superseded-by:
---

# F-097 — mise-Aktivierung unter Windows erkennen und anbieten

## Erfassung

**Problem:** `template-sync.sh mise-check` prüft, ob die Shims von mise in jeder Shell
vorn stehen, und bietet sonst eine Zeile für die Startdatei der Shell an. Unter Windows
erkennt er die Shell nicht (`SHELL` ist in Git Bash `/bin/bash.exe`), nimmt den
Shims-Ordner unter `~/.local/share/mise/shims` an (mise nutzt dort
`%LOCALAPPDATA%\mise\shims`) und schlägt nichts vor. Eine Startdatei hilft dort auch
nicht: VS Code, PowerShell und Claude Code übernehmen den PATH aus der
Windows-Umgebung. Betroffen sind `install.sh` (Schritt 6) und
`/coding-kit:update-conventions global`.

**Ziel:**
- Ist: unter Windows meldet `mise-check` den Shims-Ordner als nicht im PATH, auch wenn
  er drin ist, und der Installer sagt nur „Für diese Shell trägt der Installer nichts
  ein“.
- Soll: unter Windows erkennt der Check den echten Shims-Ordner und ob er im
  Benutzer-PATH steht, und bietet sonst an, ihn dort einzutragen.
- Reproduzieren: Windows mit Git for Windows und mise, in Git Bash
  `sh plugins/coding-kit/scripts/template-sync.sh mise-check`.

**Lösungsskizze:**
- Den Shell-Namen ohne `.exe` vergleichen.
- Den Shims-Ordner bei mise erfragen statt annehmen.
- Auf Windows den Benutzer-PATH prüfen und das Eintragen dort anbieten (etwa über
  PowerShell); keine Zeile in einer Startdatei.
- Auf macOS und Linux bleibt alles, wie es ist.

**Abhängigkeiten:** keine. F-067 nutzt den Check in Schritt 6.
