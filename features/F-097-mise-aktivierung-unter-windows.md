---
id: F-097
title: mise-Aktivierung unter Windows erkennen und anbieten
type: fix
status: PLANNED
size: M
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
- Den Shims-Ordner nach der Regel von mise bestimmen (unter Windows mit `%LOCALAPPDATA%`
  als Rückfall).
- Auf Windows den Benutzer-PATH prüfen und das Eintragen dort anbieten (etwa über
  PowerShell); keine Zeile in einer Startdatei.
- Auf macOS und Linux bleibt alles, wie es ist.

**Abhängigkeiten:** keine. F-067 nutzt den Check in Schritt 6.

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben Windows (`uname -s` beginnt mit MINGW, MSYS oder CYGWIN), wenn
  `mise-check` läuft, dann meldet er den Shell-Namen ohne `.exe`, den Shims-Ordner nach
  der Regel von mise — `MISE_DATA_DIR`, sonst `XDG_DATA_HOME/mise`, sonst
  `%LOCALAPPDATA%\mise`, auch aus Werten in Windows-Schreibweise — in POSIX-Form, eine
  Zeile `userpath` mit `present`, `absent` oder `unknown` und nie eine Zeile für eine
  Startdatei (`rc - -`, `line -`, `add -`).
- [ ] AC-2 — Gegeben Windows, wenn `mise-check` urteilt, dann: Shims im aktuellen PATH
  und nichts überdeckt → `ok`; Shims nicht im Benutzer-PATH → `offer-path`; im
  Benutzer-PATH, aber nicht im aktuellen PATH → `restart`; überdeckt von einem Ordner,
  der im Benutzer-PATH vor den Shims steht → `offer-path`; überdeckt nur von Ordnern
  außerhalb des Benutzer-PATH (System-PATH, Git Bash) → `manual`.
- [ ] AC-3 — Gegeben Windows, wenn `tool-check` läuft, dann zählt ein Shim im
  Shims-Ordner aus AC-1 nicht als vorhanden.
- [ ] AC-4 — Gegeben Windows, wenn `set-mise-path` läuft, dann steht der Shims-Ordner
  danach genau einmal und vorn im Benutzer-PATH, alle anderen Einträge bleiben in
  Reihenfolge und Schreibweise, der Werttyp bleibt (REG_EXPAND_SZ bzw. REG_SZ), und
  Windows wird über die Änderung benachrichtigt. Nicht unter Windows oder ohne
  PowerShell lehnt er ab und schreibt nichts.
- [ ] AC-5 — Gegeben Windows, wenn der Installer (Schritt 6) bzw.
  `/coding-kit:update-conventions global` (G8) `offer-path` bekommt, dann bieten sie das
  Eintragen an und rufen `set-mise-path` erst nach Zustimmung auf; bei `manual` nennen
  sie die überdeckten Werkzeuge mit Ordner und dass der System-PATH vor dem
  Benutzer-PATH steht — nie eine Zeile für eine Startdatei.
- [ ] AC-6 — Gegeben macOS oder Linux, wenn `mise-check`, `set-mise` und `tool-check`
  laufen, dann ist ihre Ausgabe dieselbe wie vorher (keine Zeile `userpath`).

### Randfälle

- EC-1 — Kein Benutzer-PATH vorhanden → `userpath absent`; `set-mise-path` legt ihn als
  REG_EXPAND_SZ mit nur dem Shims-Ordner an.
- EC-2 — Der Shims-Ordner steht im Benutzer-PATH in anderer Schreibweise
  (`%LOCALAPPDATA%\mise\shims`, andere Groß- und Kleinschreibung, Backslash am Ende) →
  zählt als derselbe Eintrag; `set-mise-path` verschiebt ihn nach vorn statt einen
  zweiten anzulegen.
- EC-3 — PowerShell fehlt oder das Lesen scheitert → `userpath unknown`; aktiv und nichts
  überdeckt bleibt `ok`, sonst `manual` mit dem Weg von Hand.
- EC-4 — Pfade mit Leerzeichen (`C:\Program Files\…`) im PATH → Vergleich und Schreiben
  bleiben korrekt.

### Nicht-Ziele

- Kein Eingriff in den System-PATH (bräuchte Admin-Rechte); was dort die Shims
  überdeckt, wird nur gemeldet.
- Keine Aktivierung über Startdateien unter Windows (`$PROFILE` der PowerShell,
  `.bashrc` der Git Bash) — der Benutzer-PATH erreicht alle Programme.
- mise unter Windows installieren und den Installer sonst lauffähig machen → F-067.
  WSL zählt als Linux.

### Tests

- AC-1, AC-2, AC-3: Fälle in `tests/template-sync/mise.sh` mit Stellvertretern für
  `uname`, `cygpath` und `powershell.exe` — laufen auch unter Linux in der CI.
- AC-4: Fälle mit Stellvertreter-PowerShell (Aufruf, übergebener Ordner, Ablehnung);
  dazu manuell auf dem Windows-Rechner: Benutzer-PATH samt Typ nach `private/`
  sichern, `set-mise-path`, Ergebnis per `reg query` prüfen, Sicherung zurückschreiben.
- AC-5: Fälle in `tests/template-sync/install.sh` (Windows-Lauf mit `offer-path`:
  Frage, Aufruf nach Ja, keiner nach Nein; `manual` ohne Startdatei-Zeile); den Text
  von G8 durchsehen.
- AC-6: die bestehenden Fälle in `mise.sh` bleiben unverändert grün.

### Einbettung

- Berührt: `template-sync.sh` (mise-check, tool-check, neuer Befehl `set-mise-path`,
  Kopf-Doku), `install.sh` Schritt 6, `update-conventions` G8, README (Absatz zur
  Aktivierung, Windows-Hinweis), CHANGELOG 3.8.1 (unveröffentlicht, kein Abschnitt
  Template — das Template bleibt unberührt).
- `tool-check` nutzt denselben Shims-Ordner; Schritt 5 des Installers zählt unter
  Windows damit richtig.
- F-067 nennt für Schritt 6 noch „die Startdatei der Git Bash“ — das überholt dieses
  Feature; beim Planen von F-067 anpassen.

### Offene Fragen

keine

### Entscheidungen

- 2026-11-23 — Den Shims-Ordner berechnen statt bei mise erfragen (Abweichung von der
  Lösungsskizze): mise nutzt unter Windows dieselbe Regel wie auf Unix, nur mit
  `%LOCALAPPDATA%` als Rückfall (auf dem Windows-Rechner mit gesetzten Variablen
  geprüft); das geht auch ohne mise und ohne JSON aus `mise doctor` zu lesen.
- 2026-11-23 — Windows über `uname -s` erkennen, wie der Installer.
- 2026-11-23 — Der Shims-Ordner kommt **vorn** in den Benutzer-PATH, wie die Zeile am
  Ende der Startdatei auf Unix; die mise-Doku hängt ihn hinten an. Vom Nutzer gewählt.
- 2026-11-23 — Schreiben über die Registry mit erhaltenem Werttyp und anschließender
  Benachrichtigung, nicht über `[Environment]::SetEnvironmentVariable` (macht
  `%USERPROFILE%`-Einträge zu festen Pfaden). Vom Nutzer gewählt.
- 2026-11-23 — Ein Befehl `set-mise-path` im Skript schreibt, Installer und Skill rufen
  ihn nach Zustimmung auf. Vom Nutzer gewählt.
- 2026-11-23 — Der PowerShell-Code steht eingebettet in `template-sync.sh` und läuft nur
  unter Windows; keine eigene `.ps1`-Datei (Rahmenbedingung: Skripte in POSIX-Shell und
  awk). Die Registry erreicht nur PowerShell bzw. .NET.
- 2026-11-23 — Den Schreibweg einmal am echten Benutzer-PATH des Windows-Rechners prüfen,
  mit Sicherung und Rückschreiben, nach erneuter Rückfrage vor dem Lauf. Vom Nutzer
  gewählt.

## Plan

**Größe:** M — rund 8 Dateien und 250 Zeilen in Skript, Installer, Skill, Tests und
README; offen war nur der Schreibweg in den Benutzer-PATH, und das Feature ändert eine
echte Einstellung des Systems.

**Ansatz:** `template-sync.sh` bekommt einen Windows-Zweig, Unix bleibt Zeile für Zeile,
wie es ist. Windows erkennt eine kleine Funktion an `uname -s`. Unter Windows:

- `mise_shims_dir` nimmt `%LOCALAPPDATA%\mise` als Rückfall und wandelt das Ergebnis mit
  `cygpath -u` in die POSIX-Form — damit stimmen `mise-check` und `tool-check`.
- Den Benutzer-PATH liest `powershell.exe -NoProfile` über
  `[Environment]::GetEnvironmentVariable('Path', 'User')` (Variablen aufgelöst); `cygpath
  -u -p` wandelt die Liste in einem Aufruf. Verglichen wird ohne Groß- und
  Kleinschreibung und ohne Schrägstrich am Ende.
- Das Urteil entscheidet wie bisher das Skript; neu ist `offer-path`. Ein überdeckender
  Ordner, der im Benutzer-PATH vor den Shims steht, führt zu `offer-path`, jeder andere
  zu `manual`.
- `set-mise-path` gibt den Shims-Ordner in Windows-Form über eine Umgebungsvariable an
  PowerShell weiter (kein Zusammensetzen von Code aus Werten), liest den Benutzer-PATH
  roh aus der Registry (`DoNotExpandEnvironmentNames`), entfernt jede Schreibweise des
  Ordners, setzt ihn vorn ein, schreibt mit dem bisherigen Werttyp zurück und meldet die
  Änderung mit `WM_SETTINGCHANGE`. Die Pfadumwandlung der Git Bash für Argumente an
  Windows-Programme wird für diese Aufrufe abgeschaltet.
- Die Tests ersetzen `uname`, `cygpath` und `powershell.exe` durch Stellvertreter und
  laufen so auch unter Linux; den PowerShell-Code selbst prüft der manuelle Test auf
  dem Windows-Rechner.

Verworfen: eine Aktivierungszeile in der `.bashrc` der Git Bash oder im `$PROFILE` der
PowerShell — VS Code, Claude Code und andere Programme übernehmen den PATH aus der
Windows-Umgebung, nicht aus einer Shell; die Zeile wirkte nur in dieser einen Shell.

**Erkennung (Standards und Module):** entfällt — keine neue Sprache, kein Framework und
keine Dependency; PowerShell gehört unter Windows zum System. Keine neue Config, keine
Endpunkte.

### F-097a — Windows erkennen und melden

- `template-sync.sh`: Windows-Erkennung, Shims-Ordner, Shell-Name ohne `.exe`, Zeile
  `userpath`, Urteile `offer-path` und `manual` für Windows, Kopf-Doku von `mise-check`
  und `tool-check`.
- `install.sh` Schritt 6 und `update-conventions` G8: die Windows-Urteile formulieren —
  `offer-path` nennt vorerst den Weg von Hand (Ordner vorn in den Benutzer-PATH),
  `manual` die überdeckten Werkzeuge und den System-PATH; keine Startdatei-Zeile.
- Tests: Windows-Fälle in `tests/template-sync/mise.sh` (Stellvertreter), der
  Windows-Lauf in `tests/template-sync/install.sh` bekommt die Stellvertreter.
- CHANGELOG 3.8.1.
- Erfüllt AC-1, AC-2, AC-3, AC-6; AC-5 für `manual`.

### F-097b — Shims-Ordner in den Benutzer-PATH eintragen

- `template-sync.sh`: Befehl `set-mise-path` samt Kopf-Doku.
- `install.sh` Schritt 6 und `update-conventions` G8: bei `offer-path` fragen und nach
  Zustimmung `set-mise-path` aufrufen; danach VS Code und Terminals neu starten.
- README: Windows-Hinweis im Absatz zur Aktivierung.
- Tests: `set-mise-path` mit Stellvertreter-PowerShell (Aufruf, Ordner, Ablehnung
  außerhalb von Windows und ohne PowerShell); Installer-Fälle für Ja und Nein.
- Manueller Test auf dem Windows-Rechner mit Sicherung und Rückschreiben, nach
  Rückfrage.
- CHANGELOG 3.8.1 ergänzen.
- Erfüllt AC-4, AC-5.
