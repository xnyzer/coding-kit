---
id: F-060
title: mise-Tools in jeder Shell erreichbar machen
type: fix
status: PLANNED
size: M
created: 2026-11-13
done:
depends-on:
superseded-by:
---

# F-060 — mise-Tools in jeder Shell erreichbar machen

## Erfassung

**Problem:** Das Kit sagt nur `mise install`, nie, wie mise aktiviert wird. Auf einem
Rechner ohne Aktivierung stehen die von mise installierten Tools nicht im `PATH`:
Werkzeuge, die nur über mise kommen (im Go-Modul golangci-lint und seit F-057
go-licenses), fehlen, und wo Homebrew dasselbe Werkzeug liefert, läuft dessen Version
statt der im Projekt festgelegten. `just check` scheitert dann im Terminal wie in der
Shell von Claude, oder es prüft mit falschen Versionen. In der CI fällt das nicht auf,
weil sie mise selbst aufruft.

**Ziel:**
- Ist: `mise doctor` meldet `activated: no` und `shims_on_path: no`; in einem
  Go-Projekt aus dem Template findet `just check` golangci-lint nur über `mise exec`.
- Soll: Nach der Einrichtung laut Kit stehen die mise-Tools in jeder Shell vorn im
  `PATH` — interaktiv, in Skripten und in der Shell von Claude —, und `just check`
  läuft ohne `mise exec`.
- Reproduzieren: Rechner ohne mise-Aktivierung, Go-Projekt aus dem Template,
  `just check`.

**Lösungsskizze:**
- Der Installer prüft, ob mise aktiviert ist, zeigt die Zeile für die Startdatei der
  Login-Shell und trägt sie nach Ja ein — wie heute das Angebot für `brew install`.
- `/coding-kit:update-conventions global`, der Weg für jeden weiteren Rechner, prüft
  dasselbe und trägt nur nach Freigabe ein.
- Lädt ein Node-Manager wie nvm nach der Aktivierung und steht damit vor den Shims,
  erkennen Installer und Skill das und schlagen eine Lösung vor.
- Kit-README und Template-Doku nennen die Aktivierung.
- Verworfen: alle `just`-Aufrufe in den Skills auf `mise exec -- just …` umstellen —
  wirkt nur in Skills, nicht im Terminal und nicht in Git-Hooks.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Reicht `mise activate zsh` in der `.zshrc` für die Shell von Claude, oder braucht es
  die Shims? (Spike)
- Wie verhalten sich Git-Hooks (lefthook), die `just` aufrufen?
- Was gilt unter bash und auf Linux/WSL (Bezug F-027)?

## Spezifikation

Grundlage ist der Stand vom 2026-11-13: Auf dem Entwicklungsrechner meldete
`mise doctor` `activated: no` und `shims_on_path: no`; Tools, die nur über mise kommen,
fehlten, und Homebrew-Versionen liefen statt der festgelegten. Mit
`eval "$(mise activate zsh --shims)"` in der `.zprofile` findet eine neue Login-Shell
im Projekt die festgelegten Versionen und außerhalb die des Systems. nvm, in der
`.zshrc` danach geladen, steht in interaktiven Shells weiter vor dem node-Shim.

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Rechner mit installiertem, aber nicht aktiviertem mise, wenn
  `install.sh` läuft, dann meldet er das, zeigt die Zeile und trägt sie nach Ja in die
  Startdatei der Login-Shell ein (zsh: `~/.zprofile`, bash: `~/.bash_profile`); ein
  zweiter Lauf erkennt die Aktivierung und fragt nicht erneut. Negativ: Bei Nein oder
  schon aktiviertem mise ändert er keine Datei.
- [ ] AC-2 — Gegeben derselbe Rechner, wenn `/coding-kit:update-conventions global`
  läuft, dann meldet der Skill die fehlende Aktivierung mit der Zeile und trägt sie nur
  nach Freigabe ein. Negativ: Ist mise aktiviert, meldet er nichts.
- [ ] AC-3 — Gegeben ein Rechner, auf dem nvm nach der Aktivierung lädt, wenn Installer
  oder Skill die Aktivierung prüfen, dann erkennen sie, dass nvm vor dem node-Shim
  steht, und schlagen eine Lösung vor (Reihenfolge korrigieren oder node über mise
  statt nvm); geändert wird nur nach Freigabe. Negativ: Ohne nvm oder ohne node-Shim
  keine Meldung.
- [ ] AC-4 — Gegeben ein Rechner nach der Einrichtung laut Kit, wenn eine neue Session
  von Claude Code in einem Go-Projekt aus dem Template `just check` ausführt, dann
  findet sie golangci-lint und go-licenses ohne `mise exec`, in den Versionen aus
  `mise.lock`. Negativ: Außerhalb eines Projekts gelten die Versionen des Systems.
- [ ] AC-5 — Gegeben das Kit-README (Abschnitt Toolchain) und die Template-Doku
  (`README`, `CONTRIBUTING`, `HOW-TO-CODE-WITH-CLAUDE`), wenn man sie liest, dann nennen
  sie die Aktivierung mit Verweis auf `mise doctor`. Negativ: `just check` ist grün, der
  CHANGELOG-Eintrag hat einen Abschnitt `### Template`.

### Randfälle

- EC-1 — Die Startdatei fehlt → der Installer legt sie mit der Zeile an, nach Ja.
- EC-2 — mise ist per `mise activate` ohne Shims in der `.zshrc` aktiviert
  (`activated: yes`, `shims_on_path: no`) → ob das für die Shell von Claude reicht,
  klärt der Spike; keine zweite Zeile eintragen, ohne das zu wissen.
- EC-3 — Eine andere Shell als zsh oder bash (etwa fish) → nur die Zeile nennen, nichts
  schreiben.
- EC-4 — Windows mit Git Bash → nur Hinweis, nichts schreiben (→ F-027).
- EC-5 — Die Zeile steht schon, nur auskommentiert oder in anderer Form → als
  vorhanden zählen, nichts doppelt eintragen; im Zweifel nur melden.

### Nicht-Ziele

- Keine Änderung an nvm selbst und keine Deinstallation von Tools aus Homebrew.
- Keine Besonderheiten für Windows oder WSL (→ F-027).
- Kein `mise exec` in den Skills.
- Keine Änderung an Startdateien ohne Freigabe.

### Tests

- AC-1: manuell — `install.sh` mit einem leeren Test-HOME: erster Lauf fragt und trägt
  ein, zweiter Lauf fragt nicht; Nein ändert nichts.
- AC-2: manuell — Lauf von `/coding-kit:update-conventions global` auf einem Rechner
  ohne Aktivierung (Test-HOME oder Zeile vorübergehend auskommentiert).
- AC-3: manuell — auf einem Rechner mit nvm (dieser Rechner): Meldung und Vorschlag;
  nach der Korrektur zeigt `command -v node` in einem Projekt mit node über mise auf
  den Shim.
- AC-4: manuell — neue Session von Claude Code (`claude -p`) in einem Go-Projekt aus
  dem Template: `just check` grün ohne `mise exec`.
- AC-5: Check — `just check`, grep in README und Template-Doku, CHANGELOG mit
  `### Template`.

### Einbettung

- Berührt: `install.sh`, `README.md` (Toolchain), der Skill
  `/coding-kit:update-conventions` (Teil global), im Template `core/README.md`,
  `core/CONTRIBUTING.md`, `core/HOW-TO-CODE-WITH-CLAUDE.md`; CHANGELOG und Version
  (3.5.0, unveröffentlicht).
- Eine gemeinsame Prüfung für Installer und Skill ist zu klären (etwa ein Befehl im
  Skript `template-sync.sh`), damit die Logik nicht doppelt steht.
- Folgen: Hilft F-057 lokal (go-licenses kommt nur über mise) und jedem Projekt mit
  Tools, die es nur über mise gibt.
- Kein Widerspruch zu Zielen oder Nicht-Zielen; „Die globalen Kit-Regeln und die
  Personal-Config auf jeden Rechner bringen“ wird um die Toolchain ergänzt.

### Offene Fragen

- [ ] [CLARIFY] Übernimmt die Shell von Claude Code die Shims aus der `.zprofile`, oder
  braucht es die `.zshenv` oder die `.zshrc`? (Spike, nicht blockierend)
- [ ] [CLARIFY] Wie stellt man die Reihenfolge gegenüber nvm sicher: Aktivierung am Ende
  der `.zshrc` wiederholen, oder node über mise statt nvm? (Spike, nicht blockierend)
- [ ] [CLARIFY] Wo steht die gemeinsame Prüfung, die Installer und Skill nutzen?
  (Plan, nicht blockierend)

### Entscheidungen

- 2026-11-13 — Der Installer bietet an, die Zeile einzutragen (Standard: Nein), statt
  nur einen Hinweis zu zeigen. Grund: gleiche Bedienung wie beim Angebot für
  `brew install`. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-13 — `/coding-kit:update-conventions global` prüft die Aktivierung mit. Grund:
  Weitere Rechner werden über diesen Skill eingerichtet, nicht über den Installer.
  Entscheidung des Nutzers nach Empfehlung.
- 2026-11-13 — nvm wird mitgelöst: erkennen und eine Lösung vorschlagen. Empfehlung war,
  nvm nur als Hinweis in der Doku zu nennen; entschieden ist das Mitlösen, damit
  Node-Projekte die Version aus mise bekommen.

## Plan

**Größe:** M. Wenige Dateien (Skript, Installer, ein Skill, README, Template-Doku), die
offenen Fragen zum Laden der Shell klärt ein Spike zuerst. Formal reicht es über die
Template-Doku in alle Projekte, dort ändert sich aber nur Text.

**Ansatz:** Ein neuer Befehl in `template-sync.sh` prüft, ob mise aktiviert ist und ob
ein Node-Manager vor den Shims steht, und nennt die Zeile für die Startdatei; Installer
und `/coding-kit:update-conventions global` nutzen ihn und tragen nur nach Freigabe ein.
README und Template-Doku nennen die Aktivierung. Verworfen: die Prüfung je in Installer
und Skill getrennt schreiben — zwei Stellen, die auseinanderlaufen; und `mise exec` in
den Skills (siehe Lösungsskizze).

### F-060a — Spike: Shell von Claude, nvm und Erkennung

- Neue Session von Claude Code (`claude -p`) in einem Go-Projekt aus dem Template: Findet
  sie die Shims aus der `.zprofile`, oder braucht es `.zshenv` oder `.zshrc`?
- nvm: Was stellt die Shims in interaktiven Shells nach vorn — Aktivierung am Ende der
  `.zshrc` wiederholen, oder node über mise statt nvm? Was bedeutet das für Projekte mit
  `.nvmrc`?
- Erkennung: Welche Angaben aus `mise doctor` und aus einer Login-Shell reichen, um
  „nicht aktiviert“ und „nvm vor dem Shim“ sicher zu erkennen, ohne die Startdateien
  zu parsen?
- Git-Hooks (lefthook), aus dem Terminal und aus Claude gestartet.
- Ergebnis: Zeile, Startdatei und Erkennung als Entscheidung in der Feature-Datei.
- Ändert keine Kit-Dateien außer der Feature-Datei, also keine neue Version.
- Klärt die beiden offenen Fragen zum Spike.

### F-060b — Prüfung im Skript, Installer und Skill

- `template-sync.sh`: neuer Befehl für die Prüfung (Name im Plan nach dem Spike),
  Ausgabe in Zeilen wie die übrigen Befehle; Tests unter dash und bash, mit mawk.
- `install.sh`, Schritt 5: ruft die Prüfung, bietet die Zeile an (Standard: Nein),
  legt eine fehlende Startdatei an; nvm-Vorschlag nach Freigabe.
- `/coding-kit:update-conventions`, Teil G: dieselbe Prüfung, Eintrag nur nach
  Freigabe — Änderung über `/add-skill`.
- Version 3.5.0 (unveröffentlicht), CHANGELOG.
- Erfüllt AC-1 und AC-2 bis auf die Durchläufe, AC-3 teilweise.

### F-060c — Doku und Durchläufe

- Kit-README (Toolchain) und Template-Doku (`README`, `CONTRIBUTING`,
  `HOW-TO-CODE-WITH-CLAUDE`): Aktivierung mit Verweis auf `mise doctor`; CHANGELOG mit
  `### Template`.
- Durchläufe: Installer mit Test-HOME (fragt, trägt ein, zweiter Lauf fragt nicht);
  `/coding-kit:update-conventions global` ohne Aktivierung; nvm auf diesem Rechner;
  neue Session von Claude Code in einem Go-Projekt (`just check` ohne `mise exec`).
- Erfüllt AC-1 bis AC-5.

**Erkennung (Schritt 2a):** entfällt; keine neuen Frameworks, Dependencies oder
Sprachen. Neue Config oder Endpunkte gibt es nicht.
