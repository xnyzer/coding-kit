---
id: F-067
title: Installer unter Windows in Git Bash lauffähig machen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on: F-025
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
- Verifikation auf einem echten Windows-Rechner; auf macOS und Linux nur die Tests mit
  Attrappen aus F-025.

**Abhängigkeiten:** F-025. Thematisch nah an F-027 (derselbe Windows-Rechner zur
Verifikation), aber anderer Gegenstand: Installer statt Plugin-Hooks.
