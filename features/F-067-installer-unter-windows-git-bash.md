---
id: F-067
title: Installer unter Windows in Git Bash lauffähig machen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on: F-025, F-097
superseded-by:
---

# F-067 — Installer unter Windows in Git Bash lauffähig machen

## Erfassung

**Problem:** Nach F-025 erkennt der Installer Windows nur und nennt den Weg von Hand: Er
bietet mise nicht über winget oder scoop an, ob er in Git Bash ganz durchläuft, ist nicht
geprüft, und beim Start per Doppelklick verschwindet eine Abbruchmeldung mit dem Fenster.
Auf Windows bleibt die Einrichtung damit zum großen Teil Handarbeit.

**Ziel:** Als Nutzer eines Windows-Rechners möchte ich den Installer in Git Bash starten
und dieselbe Einrichtung bekommen wie auf macOS und Linux, damit ich nichts von Hand
nachziehen muss.

**Lösungsskizze:**
- mise auf Windows über winget (`winget install jdx.mise`) oder scoop anbieten, danach wie
  überall `mise use -g` für just, lefthook und gitleaks. Laut mise-Doku legt scoop den
  Shim-Ordner nicht auf den PATH, und winget bekommt neue Releases verzögert — prüfen, was
  `mise-check` dann meldet und anbietet.
- Den ganzen Lauf in Git Bash prüfen: `$HOME`, Pfad der Personal-Config, die Aufrufe von
  `claude`, Schritt 6 mit der Startdatei der Git Bash.
- Abbruchmeldungen sichtbar halten, wenn der Installer per Doppelklick startet (etwa vor
  dem Ende auf Enter warten).
- Einen Start aus PowerShell oder cmd erkennen und auf Git Bash verweisen.
- Prüfen, ob Claude Code die Git Bash findet, und sonst `CLAUDE_CODE_GIT_BASH_PATH` im
  `env` der `settings.json` anbieten — ohne sie laufen die Hooks in PowerShell und
  scheitern (aus F-027).
- Verifikation auf einem echten Windows-Rechner; auf macOS und Linux nur die Tests mit
  Attrappen aus F-025.
- Die Meldung „angelegt (chmod 600)“ stimmt auf Windows nicht — `chmod` wirkt auf NTFS
  nicht; prüfen, ob die geerbten Rechte genügen, und die Meldung ehrlich fassen.
- Pfade landen in MSYS-Form (`/c/Users/…`) in der Personal-Config — prüfen, ob alle
  Leser damit umgehen.
- winget legt den Paketordner von mise auf den PATH, nicht die Shims, und das erst nach
  einem Neustart der Shell — der Installer muss mise im selben Lauf finden oder zum
  Neustart auffordern; die Aktivierung der Shims regelt F-097.
- Ohne Terminal (Eingaben per Pipe) stehen die Fragen ohne Zeilenumbruch hintereinander
  (alle Plattformen).

**Abhängigkeiten:** F-025; F-097 für Schritt 6. Thematisch nah an F-027 (derselbe
Windows-Rechner zur Verifikation), aber anderer Gegenstand: Installer statt
Plugin-Hooks. Den Vorschlag des Projekte-Ordners behandelt F-096.
