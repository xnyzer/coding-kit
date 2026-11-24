---
id: F-067
title: Installer unter Windows in Git Bash lauffähig machen
type: feature
status: IN-PROGRESS
size: M
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
  `claude`, Schritt 6 über den Benutzer-PATH (F-097).
- Abbruchmeldungen sichtbar halten, wenn der Installer per Doppelklick startet (etwa vor
  dem Ende auf Enter warten).
- Bei WSL auf Git Bash verweisen; `.\install.sh` aus PowerShell öffnet die Git Bash
  ohnehin.
- Prüfen, ob Claude Code die Git Bash findet, und sonst `CLAUDE_CODE_GIT_BASH_PATH` im
  `env` der `settings.json` melden — ohne sie laufen die Hooks in PowerShell und
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

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben Windows ohne mise, aber mit winget, wenn der Nutzer in Schritt 5
  zustimmt, dann läuft `winget install jdx.mise`, der Installer findet mise im selben
  Lauf im Paketordner von winget und macht mit `mise use -g` und Schritt 6 weiter;
  lehnt der Nutzer ab, nennt er den Weg von Hand, und mise bleibt offen. — belegt:
  Installer-Fälle win-winget (winget install, mise im Paketordner gefunden, mise use -g
  im selben Lauf, nichts offen, Schritt 6 läuft) und win-winget-no (abgelehnt: kein
  Aufruf, Weg von Hand, mise offen)
- [x] AC-2 — Gegeben Windows ohne mise und ohne winget, aber mit scoop, wenn der Nutzer
  zustimmt, dann läuft `scoop install mise`; ohne beide nennt der Installer beide Wege
  von Hand und installiert nichts. — belegt: Installer-Fälle win-scoop (scoop install
  mise) und windows (weder winget noch scoop: beide Wege von Hand, nichts installiert)
- [ ] AC-3 — Gegeben Windows und keine Personal-Config, wenn der Installer sie anlegt,
  dann steht der Projekte-Ordner in der Form `C:/Users/…`, und die Meldung behauptet
  kein `chmod 600`, sondern nennt den Schutz über das Benutzerprofil; auf macOS und
  Linux bleiben Pfad und Meldung, wie sie sind.
- [ ] AC-4 — Gegeben Windows, wenn die `bash.exe` des Laufs nicht unter
  `C:\Program Files\Git` liegt und `CLAUDE_CODE_GIT_BASH_PATH` weder in der Umgebung noch
  in der `settings.json` steht, dann nennt der Installer ihren Pfad und den Eintrag für
  `env` in der `settings.json`; sonst sagt er dazu nichts. Er schreibt die `settings.json`
  nicht.
- [ ] AC-5 — Gegeben Windows, ein Terminal als Eingabe und der Installer als erste Shell
  seines Fensters (`SHLVL` 1), wenn der Lauf endet — fertig oder abgebrochen —, dann
  wartet er auf Enter, bevor sich das Fenster schließt; in jedem anderen Fall wartet er
  nicht.
- [ ] AC-6 — Gegeben eine Eingabe, die kein Terminal ist (Pipe, Datei), wenn der
  Installer fragt, dann endet jede Frage mit einem Zeilenumbruch — auf allen Systemen.
- [ ] AC-7 — Gegeben WSL, wenn der Installer startet, dann sagt die Warnung zusätzlich,
  dass für Claude Code unter Windows der Installer in Git Bash laufen muss.
- [ ] AC-8 — Gegeben der Windows-Rechner und ein frisches Test-Home
  (`HOME`, `CLAUDE_CONFIG_DIR`), wenn der Installer in Git Bash ganz durchläuft, dann
  endet er ohne Fehler, mit Personal-Config, Plugin und Toolchain.

### Randfälle

- EC-1 — winget installiert, aber mise liegt nicht im erwarteten Paketordner → melden:
  Git Bash neu starten und den Installer erneut ausführen; mise bleibt offen.
- EC-2 — `winget install` bzw. `scoop install` scheitert → benennen, mise bleibt offen.
- EC-3 — `LOCALAPPDATA` nicht gesetzt → `$HOME/AppData/Local` als Rückfall (wie
  `mise-check`).
- EC-4 — Eine bestehende Personal-Config mit `/c/…`-Pfaden → bleibt unberührt.
- EC-5 — `SHLVL` nicht gesetzt → kein Warten.

### Nicht-Ziele

- `CLAUDE_CODE_GIT_BASH_PATH` selbst in die `settings.json` schreiben (nur melden).
- Bestehende Personal-Configs auf die neue Pfadform umstellen.
- Wo der Projekte-Ordner liegt (außerhalb eines Sync-Ordners) → F-096.
- Git for Windows oder Claude Code installieren; einen Installer für PowerShell.

### Tests

- AC-1, AC-2: Installer-Fälle mit Attrappen für winget (legt die mise-Attrappe in einen
  Paketordner unter `LOCALAPPDATA`) und scoop: Zustimmung, Ablehnung, keiner von beiden,
  Fehlschlag (EC-2), kein Paketordner (EC-1).
- AC-3: Installer-Fälle unter Windows (Attrappe `cygpath -m`) und macOS für Pfad und
  Meldung.
- AC-4: Installer-Fälle mit und ohne `CLAUDE_CODE_GIT_BASH_PATH` in Umgebung bzw.
  `settings.json`.
- AC-5: automatisch der Negativfall (Eingabe aus einer Datei: kein Warten); manuell auf
  dem Windows-Rechner per Doppelklick: das Fenster wartet auf Enter.
- AC-6: Installer-Fall: in der Ausgabe folgt jeder Frage ein Zeilenumbruch.
- AC-7: der bestehende WSL-Fall prüft den Hinweis.
- AC-8: manuell auf dem Windows-Rechner mit frischem Test-Home.

### Einbettung

- Berührt: `install.sh` (Schritte 1, 3, 5 und das Ende), `tests/template-sync/install.sh`,
  die Attrappe `cygpath` in `tests/template-sync/mise.sh` (`-m`), README (Abschnitt
  Windows: der Installer installiert mise jetzt selbst), CHANGELOG mit neuer Version.
- Schritt 6 unter Windows kommt aus F-097; F-096 berührt danach dieselbe Stelle in
  Schritt 3.
- Die Leser von `CODING_KIT_PROJECTS_DIR` (new-project, update-conventions,
  check-upstreams) nutzen ihn in Shell-Befehlen; die Form `C:/…` gilt in Git Bash und
  PowerShell.

### Offene Fragen

keine

### Entscheidungen

- 2026-11-24 — mise unter Windows über winget, sonst scoop, sonst von Hand; nach winget
  sucht der Installer mise im Paketordner, weil winget den PATH erst für neue Shells
  setzt. Vom Nutzer gewählt.
- 2026-11-24 — Findet Claude Code die Git Bash womöglich nicht, nur melden; `set-settings`
  kann kein verschachteltes `env` schreiben, und der Aufwand stünde in keinem
  Verhältnis. Vom Nutzer gewählt.
- 2026-11-24 — Im eigenen Fenster am Ende auf Enter warten, bei Erfolg und Abbruch;
  erkannt an Windows, Terminal und `SHLVL` 1. Vom Nutzer gewählt.
- 2026-11-24 — Der Projekte-Ordner kommt unter Windows in der Form `C:/Users/…` in die
  Personal-Config. Vom Nutzer gewählt.
- 2026-11-24 — Einen Start aus PowerShell oder cmd nicht eigens erkennen: `.\install.sh`
  öffnet über die Dateizuordnung die Git Bash (Fall Doppelklick), `bash install.sh`
  trifft WSL, für das schon eine Warnung kommt; sie bekommt den Hinweis auf Git Bash
  (AC-7). Die Lösungsskizze nannte das Erkennen.

## Plan

**Größe:** M — etwa 5 Dateien und 350 Zeilen, fast alles in `install.sh` und seinen
Tests; viele kleine Teile mit einzelnen offenen Fragen, die das Interview geklärt hat.

**Ansatz:** Alles bleibt in `install.sh`; macOS und Linux behalten ihr Verhalten.

- Die Erkennung der Plattform (`PLATFORM`) rückt an den Anfang, damit die Schritte 1, 3
  und 5 und das Ende sie nutzen.
- **mise:** `offer_mise` bietet unter Windows `winget install jdx.mise` an, ohne winget
  `scoop install mise`, sonst beide Wege von Hand. Nach winget sucht eine kleine Funktion
  mise im Paketordner `…/Microsoft/WinGet/Packages/jdx.mise_*/mise/bin` unter
  `LOCALAPPDATA` (per `cygpath -u`, Rückfall `$HOME/AppData/Local`) und stellt ihn für
  den Rest des Laufs vorn in den PATH; scoop legt seinen Shim-Ordner selbst in den PATH.
- **Personal-Config:** Unter Windows wandelt `cygpath -m` den Vorschlag und die Antwort
  für den Projekte-Ordner in die Form `C:/…`; die Meldung nach dem Anlegen nennt dort
  den Schutz über das Benutzerprofil statt `chmod 600`.
- **Git Bash für Claude Code:** In Schritt 1 unter Windows: liegt `$BASH` nicht unter
  `C:\Program Files\Git` und steht `CLAUDE_CODE_GIT_BASH_PATH` weder in der Umgebung
  noch in der `settings.json` (Textsuche nach dem Schlüssel), eine Warnung mit dem Pfad
  in Windows-Form und dem Eintrag für `env`.
- **Fragen ohne Terminal:** `ask_yes_no` und `ask_value` schließen die Frage mit einem
  Zeilenumbruch ab, wenn die Eingabe kein Terminal ist (`[ -t 0 ]`).
- **WSL:** Die Warnung bekommt den Hinweis auf Git Bash.
- **Fenster offen halten:** Ein gemeinsamer Handler für `EXIT` räumt den Arbeitsordner
  von Schritt 3 auf (heute ein eigener `trap`) und wartet unter Windows mit Terminal und
  `SHLVL` 1 auf Enter — so auch nach `fail`.

Verworfen: ein eigener Installer für PowerShell — doppelte Pflege, und Hooks und
Snippets brauchen die Git Bash ohnehin.

**Erkennung (Standards und Module):** entfällt — keine neue Sprache, kein Framework,
keine Dependency. Keine neue Config, keine Endpunkte.

### F-067a — mise unter Windows installieren

- `install.sh`: `PLATFORM` an den Anfang, `offer_mise` für winget und scoop, mise nach
  winget im Paketordner finden.
- Tests: Attrappen für winget und scoop; Fälle für Zustimmung, Ablehnung, keinen von
  beiden, Fehlschlag, fehlenden Paketordner.
- README: Abschnitt Windows — der Installer bietet mise über winget oder scoop an.
- CHANGELOG mit neuer Version.
- Erfüllt AC-1, AC-2.

### F-067b — Personal-Config und Hinweise unter Windows

- `install.sh`: Pfadform `C:/…`, Meldung nach dem Anlegen, Hinweis auf
  `CLAUDE_CODE_GIT_BASH_PATH`, Zeilenumbruch nach Fragen ohne Terminal, WSL-Hinweis.
- Tests: Attrappe `cygpath -m`; Fälle je Kriterium.
- CHANGELOG ergänzen.
- Erfüllt AC-3, AC-4, AC-6, AC-7.

### F-067c — Fenster offen halten und Echtlauf

- `install.sh`: gemeinsamer Handler für `EXIT`, Warten auf Enter im eigenen Fenster.
- Tests: kein Warten bei Eingabe aus einer Datei.
- Manuell auf dem Windows-Rechner: Doppelklick (wartet auf Enter); ganzer Lauf mit
  frischem Test-Home (`HOME`, `CLAUDE_CONFIG_DIR`) in Git Bash.
- CHANGELOG ergänzen.
- Erfüllt AC-5, AC-8.

## Verlauf

### F-067a — fertig 2026-11-24

**Umgesetzt:** `install.sh` erkennt die Plattform jetzt am Anfang (`PLATFORM`).
`offer_mise` bietet unter Windows `winget install jdx.mise` an, ohne winget
`scoop install mise`, sonst beide Wege von Hand. `find_winget_mise` sucht mise im
Paketordner von winget unter `LOCALAPPDATA` und stellt ihn für den Rest des Laufs vorn
in den PATH — vor dem Angebot (von einem früheren Lauf installiert, Shell nicht neu
gestartet) und nach der Installation. Die Installer-Tests haben Attrappen für winget
und scoop; die README nennt beide Wege.

**Entscheidungen:**
- `offer_install` meldet jetzt, ob die Installation lief; die Aufrufe mit brew und
  pacman nehmen das mit `|| true` hin (das Skript läuft mit `set -e`).
- mise wird vor dem Angebot im Paketordner gesucht, damit ein früherer winget-Lauf nicht
  zu einer zweiten Installation führt.
- Keine neue Version und kein CHANGELOG-Eintrag: Die Versionsregel zählt nur
  `plugins/coding-kit/{skills,hooks,scripts,template,global}` zum Plugin, der
  Installer im Repo-Root gehört nicht dazu (wie bei F-025b). Das unabhängige Review
  verlangte beides mit Verweis auf den Plan — verworfen aus diesem Grund.

**Abweichung vom Plan:** Der Plan sah „CHANGELOG mit neuer Version“ vor; entfällt, siehe
Entscheidungen.

**Funde:** keine.
