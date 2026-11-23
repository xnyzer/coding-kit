---
id: F-027
title: Hooks unter Windows verifizieren und Git-Bash-Pflicht dokumentieren
type: feature
status: DONE
size: S
created: 2026-08-12
done: 2026-11-23
depends-on:
superseded-by:
---

# F-027 — Hooks unter Windows verifizieren und Git-Bash-Pflicht dokumentieren

## Erfassung

**Problem:** `hooks.json` startet den Stop-Hook als
`bash "${CLAUDE_PLUGIN_ROOT}/hooks/stop-reminder.sh"`. Unter Windows wurde beobachtet,
dass der Hook nicht funktioniert; wahrscheinliche Ursache ist das `bash.exe` in
`System32`, das den WSL-Start auslöst — der Hook landet damit in einer Umgebung, in der
der übergebene Windows-Pfad nicht auflösbar ist. Auf Windows fällt damit die einzige
Erinnerung an `/step-done` aus, und ein fehlschlagender Hook erzeugt womöglich bei jedem
Stopp Lärm, statt still zu bleiben.

**Idee:** Der Einstiegspunkt darf sich nicht auf ein nacktes `bash` aus dem PATH
verlassen. Auf Windows wird die Bash der Git-Installation gezielt aufgelöst — git ist für
den Hook ohnehin Voraussetzung. Schlägt die Auflösung fehl, bleibt der Hook stumm statt
zu scheitern.

**Lösungsskizze:**
- Claude Code startet Hooks unter Windows selbst über die Git Bash, ohne sie über
  PowerShell (Doku: Hooks-Referenz, Setup). Ein eigener Interpreter-Wechsel im Einstieg
  entfällt; `hooks.json` und die Skripte bleiben, wie sie sind.
- Beide Hooks auf einem Windows-Rechner verifizieren.
- Die Windows-Notiz der README sagt, warum die Hooks scheitern können (keine Git Bash
  gefunden → PowerShell → `bash` unbekannt oder das `bash.exe` von WSL) und was hilft.
- Die Prüfung, ob Claude Code die Git Bash findet, gehört in den Installer (F-067).

**Noch zu analysieren:**
- Seit F-040d startet auch der Session-Hinweis (`hooks/session-start.sh`) über `bash`; die
  Lösung muss beide Hooks abdecken. Für Befehle in Skill-Texten gibt es das
  Frontmatter-Feld `shell` (`bash` oder `powershell`, siehe F-048) — prüfen, ob ein Skill
  es braucht.

**Abhängigkeiten:** keine. Thematische Nähe zu F-025 (Plattform-Abdeckung), aber anderer
Gegenstand: Plugin-Inhalt statt Installer.

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben Windows mit Git for Windows und ein Kit-Projekt mit nicht
  committeter Änderung, wenn eine Antwort von Claude endet, dann blockiert der
  Stop-Hook einmal mit der `[coding-kit]`-Meldung; bei sauberem Arbeitsbaum bleibt er
  still. — belegt: unter Windows blockierte der Hook bei einer unversionierten
  Testdatei und bei offenen Änderungen einmal mit der `[coding-kit]`-Meldung; bei
  sauberem Baum still (Debug-Log: `Stop … finished with status 0`, kein Hinweis).
- [x] AC-2 — Gegeben Windows mit Git for Windows, wenn Claude Code frisch startet
  (Matcher `startup`), dann läuft der SessionStart-Hook mit Exit 0 und ohne
  Hook-Fehler. — belegt: frischer Start mit `claude -p --debug=hooks` —
  `SessionStart:startup [bash "…/session-start.sh"] … finished with status 0`.
- [x] AC-3 — Gegeben die README, wenn ein Windows-Nutzer die Windows-Notiz liest, dann
  erfährt er: Claude Code startet die Hooks über die Git Bash; findet es keine, laufen
  sie in PowerShell und scheitern; Abhilfe ist Git for Windows bzw.
  `CLAUDE_CODE_GIT_BASH_PATH` im `env` der `settings.json`. Sie behauptet nicht mehr,
  das Kit wähle die Shell selbst. — belegt: Windows-Notiz der README neu gefasst;
  `just check` grün.

### Randfälle

- EC-1 — Windows ohne Git for Windows → der Hook läuft in PowerShell und scheitert laut
  („bash“ unbekannt, nachgestellt am 2026-11-23); das Kit läuft dort ohnehin nicht
  (Skills, Skripte, Installer brauchen Bash) → nur die README-Abhilfe, Erkennung in
  F-067.
- EC-2 — Windows mit WSL und ohne gefundene Git Bash → PowerShell trifft
  `System32\bash.exe`, WSL kann den Pfad `C:/…` nicht auflösen → wie EC-1; hier nicht
  nachstellbar (kein WSL auf dem Prüfrechner), nur dokumentiert.

### Nicht-Ziele

- Kein PowerShell-Einstieg und keine zweite Fassung der Hooks — ein still endender Hook
  verdeckte nur, dass das ganze Kit ohne Bash nicht läuft.
- Kein Feld `shell` in `hooks.json` — mit Git Bash ändert es nichts, ohne sie macht es
  den Hook nicht still.
- Die Erkennung, ob Claude Code die Git Bash findet → F-067.
- Kit-Entwicklung unter Windows (`python3` im justfile, Test-Attrappen mit `ln -s` und
  `chmod`) → eigene Nummer.

### Tests

- AC-1 → manuell auf Windows: unversionierte Datei anlegen, Antwort beenden → Meldung;
  sauberer Baum → still.
- AC-2 → manuell auf Windows: frischer Start mit `claude --debug`, im Debug-Log der
  SessionStart-Hook mit Exit 0.
- AC-3 → Durchsicht der README; `just check` (Privacy-Lint) grün.
- Nicht-Regression: `just check` auf macOS; die Hook-Tests (`tests/template-sync/hook.sh`)
  liefen auf Windows unter dash und bash schon grün.

### Einbettung

- Nur `README.md` (Windows-Notiz) ändert sich — kein Plugin-Inhalt, also keine neue
  Version und kein CHANGELOG-Eintrag.
- F-067 bekommt in der Lösungsskizze einen Punkt für die Git-Bash-Erkennung.
- Graph: der alte Fakt „Stop-Hook geht unter Windows ins WSL“ wird mit dem Wegweiser bei
  step-done eingeordnet.
- Folge-Nummer für die Kit-Entwicklung unter Windows (per `/coding-kit:add-feature`).

### Offene Fragen

- keine

### Entscheidungen

- 2026-11-23 — Kein eigener Interpreter-Wechsel im Hook-Einstieg statt der
  ursprünglichen Skizze, weil Claude Code die Git Bash laut Doku selbst nutzt und der
  Stop-Hook auf Windows unverändert lief. Das Ziel „im Fehlerfall still bleiben“ entfällt
  bewusst: Ohne Bash läuft das Kit insgesamt nicht, ein lauter Hook-Fehler ist dort der
  ehrliche Hinweis.

## Plan

**Größe:** S — eine Doku-Stelle und eine Verifikation, die Lösung liegt nach der
Doku-Klärung auf der Hand.

**Ansatz:**
- AC-1 belegen: Stop-Hook-Test vom 2026-11-23 (blockierte einmal, Meldung wie erwartet)
  plus ein stiller Stopp bei sauberem Baum.
- AC-2: frischer Start im Kit-Repo mit `claude --debug`, Debug-Log prüfen.
- AC-3: Windows-Notiz der README umschreiben.
- `just check` (der Teil `validate` auf Windows per `python` statt `python3`, bis die
  Folge-Nummer das behebt).

## Verlauf

### F-027 — fertig 2026-11-23

**Umgesetzt:** Die Windows-Notiz der README sagt, dass Claude Code die Hooks über die
Git Bash startet, dass sie ohne Git Bash in PowerShell scheitern (`bash` unbekannt bzw.
das `bash.exe` von WSL) und hilft mit Git for Windows oder `CLAUDE_CODE_GIT_BASH_PATH`.
`hooks.json` und die Hook-Skripte bleiben unverändert; beide Hooks liefen auf Windows
mit Git Bash ohne Änderung.

**Entscheidungen:** Das Skill-Feld `shell` bleibt ungenutzt: Es gilt nur für
`!`-Befehle im Skill-Text, und die hat kein Skill des Kits (`docs/skill-authoring.md`
entsprechend nachgezogen, Befund des unabhängigen Reviews).

**Abweichung vom Plan:** keine.

**Funde:**
- `${CLAUDE_PLUGIN_ROOT}` steht im Hook-Befehl unter Windows mit Backslashes
  (`C:\…\hooks/…`), anders als die Doku es für die Shell-Form beschreibt; in Git Bash
  läuft es trotzdem.
- Geprüft ist der stille Weg des SessionStart-Hooks; die Hinweiszeile mit eingerichteten
  Kit-Regeln prüfen die Hook-Tests auf macOS und Linux.
