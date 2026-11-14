---
id: F-060
title: mise-Tools in jeder Shell erreichbar machen
type: fix
status: DONE
size: M
created: 2026-11-13
done: 2026-11-14
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
- Der Installer prüft, ob mise aktiviert ist, zeigt die Zeile für das Ende der
  Startdatei interaktiver Shells (zsh: `~/.zshrc`) und trägt sie nach Ja ein — wie
  heute das Angebot für `brew install`.
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

- [x] AC-1 — Gegeben ein Rechner mit installiertem, aber nicht aktiviertem mise, wenn
  `install.sh` läuft, dann meldet er das, zeigt die Zeile und trägt sie nach Ja ans
  Ende der Startdatei interaktiver Shells ein (zsh: `~/.zshrc`; bash siehe offene
  Fragen); ein zweiter Lauf findet die Zeile, fragt nicht erneut und nennt den Neustart,
  solange sie noch nicht wirkt. Negativ: Bei Nein oder schon aktiviertem mise ändert er
  keine Datei. — belegt: `install.sh` mit Test-Home in vier Läufen — Ja trägt die Zeile
  ein, ein zweiter Lauf fragt nicht und nennt den Neustart, nach dem Neustart `ok` ohne
  Änderung, Nein ändert keine Datei; dazu die Szenarien aus F-060b.
- [x] AC-2 — Gegeben derselbe Rechner, wenn `/coding-kit:update-conventions global`
  läuft, dann meldet der Skill die fehlende Aktivierung mit der Zeile und trägt sie nur
  nach Freigabe ein. Negativ: Ist mise aktiviert, meldet er nichts. — belegt:
  `/coding-kit:update-conventions global` mit dem Arbeitsstand des Plugins aus einem
  neuen Terminal ohne Aktivierung — G8 hängte die Zeile nach Freigabe genau einmal ans
  Ende der `.zshrc`; danach `mise doctor`: `shims_on_path: yes`, und `mise-check` in
  einer frischen Login-Shell ergibt `ok`, bei dem G8 nichts meldet.
- [x] AC-3 — Gegeben ein Rechner, auf dem nvm nach der Aktivierung lädt, wenn Installer
  oder Skill die Aktivierung prüfen, dann erkennen sie, dass nvm vor dem node-Shim
  steht, und schlagen eine Lösung vor (Reihenfolge korrigieren oder node über mise
  statt nvm); geändert wird nur nach Freigabe. Negativ: Ohne nvm oder ohne node-Shim
  keine Meldung. — belegt: Tests von `mise-check` (Überdeckung ergibt `hook` bzw.
  `offer`, ohne Überdeckung `ok`, ein Shim ohne Ordner davor bleibt ohne Meldung); auf
  diesem Rechner meldet `mise-check` nach `nvm use` node aus dem Ordner von nvm mit
  `hook`; Szenarien des Installers aus F-060b.
- [x] AC-4 — Gegeben ein Rechner nach der Einrichtung laut Kit, wenn eine neue Session
  von Claude Code in einem Go-Projekt aus dem Template `just check` ausführt, dann
  findet sie golangci-lint und go-licenses ohne `mise exec`, in den Versionen aus
  `mise.lock`. Negativ: Außerhalb eines Projekts gelten die Versionen des Systems. —
  belegt: `claude -p` aus einer Login-Shell in einem Go-Projekt aus dem Template —
  `just check` grün ohne `mise exec`, golangci-lint und go-licenses über die Shims; in
  einer frischen Login-Shell im Projekt dieselben Versionen wie in `mise.lock`,
  außerhalb go aus dem System.
- [x] AC-5 — Gegeben das Kit-README (Abschnitt Toolchain) und die Template-Doku
  (`README`, `CONTRIBUTING`, `HOW-TO-CODE-WITH-CLAUDE`), wenn man sie liest, dann nennen
  sie die Aktivierung mit Verweis auf `mise doctor` und den Neustart von Terminal bzw.
  Editor danach. Negativ: `just check` ist grün, der CHANGELOG-Eintrag hat einen
  Abschnitt `### Template`. — belegt: grep in Kit-README und Template-Doku
  (Aktivierung, `mise doctor`, Neustart in jeder Datei), CHANGELOG 3.5.0 mit
  `### Template`, `just check` grün.

### Randfälle

- EC-1 — Die Startdatei fehlt → der Installer legt sie mit der Zeile an, nach Ja.
- EC-2 — mise ist per `mise activate` ohne Shims aktiviert (`mise doctor`:
  `activated: yes`, `shims_on_path: no`) → zählt als aktiviert, keine zweite Zeile;
  ob die Prüfung auf Überdeckung dann greift, ist im Durchlauf F-060c zu prüfen.
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

- [x] [CLARIFY] Übernimmt die Shell von Claude Code die Shims aus der `.zprofile`, oder
  braucht es die `.zshenv` oder die `.zshrc`? — Claude übernimmt den `PATH` vom
  startenden Prozess; die Zeile gehört ans Ende der `.zshrc`, siehe Verlauf F-060a.
- [x] [CLARIFY] Wie stellt man die Reihenfolge gegenüber nvm sicher: Aktivierung am Ende
  der `.zshrc` wiederholen, oder node über mise statt nvm? — Aktivierung am Ende der
  `.zshrc`, nach nvm; ein Umstieg von nvm ist nicht nötig, siehe Verlauf F-060a.
- [x] [CLARIFY] Wo steht die gemeinsame Prüfung, die Installer und Skill nutzen? —
  `template-sync.sh mise-check` und `set-mise`, siehe Verlauf F-060b.
- [x] [CLARIFY] Welche Startdatei gilt für bash — auf macOS liest bash als Login-Shell
  `~/.bash_profile`, sonst `~/.bashrc`? — Das Kit trägt für bash nichts ein und nennt
  nur die Zeile (`manual`); die Doku empfiehlt das Ende der `~/.bashrc`, die auf macOS
  von der `~/.bash_profile` geladen werden muss. Siehe Verlauf F-060c.
- [x] [CLARIFY] Projekte mit `.nvmrc`: Stellt ein automatischer Wechsel von nvm beim
  Ordnerwechsel nvm wieder vor die Shims, und meldet die Prüfung das? — Ja, er stellt
  nvm wieder davor; `mise-check` meldet das als `hook`. Siehe Verlauf F-060c.

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
- 2026-11-13 — Für zsh gehört die Zeile `eval "$(mise activate zsh --shims)"` ans Ende
  der `~/.zshrc`, nicht in die `.zprofile`; AC-1 und die Lösungsskizze sind angepasst,
  AC-5 nennt zusätzlich den Neustart. Grund: Claude Code und VS Code übernehmen den
  `PATH` einer interaktiven Login-Shell, und nur am Ende der `.zshrc` stehen die Shims
  vor nvm. Für bash bleibt die Startdatei offen. Empfehlung aus dem Spike, vom Nutzer
  auf seinem Rechner übernommen.
- 2026-11-13 — Die Erkennung hat zwei Teile: Die Startdatei wird nach einer Zeile mit
  `mise activate` durchsucht (auch auskommentiert oder in anderer Form, EC-5) — sie
  entscheidet, ob eingetragen wird. Der `PATH` des laufenden Prozesses und
  `mise doctor` zeigen, ob die Aktivierung wirkt und welches Werkzeug mit Shim ein
  Ordner davor überdeckt; wirkt sie noch nicht, heißt die Meldung Neustart. Grund: Der
  `PATH` ändert sich erst nach einem Neustart, ein zweiter Lauf im selben Terminal
  würde die Zeile sonst doppelt eintragen.

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
- `install.sh`, Schritt 5: ruft die Prüfung, bietet die Zeile für das Ende der
  `.zshrc` an (bash nach dem Durchlauf F-060c), Standard: Nein; legt eine fehlende
  Startdatei an; nvm-Vorschlag nach Freigabe.
- `/coding-kit:update-conventions`, Teil G: dieselbe Prüfung, Eintrag nur nach
  Freigabe — Änderung über `/add-skill`.
- Version 3.5.0 (unveröffentlicht), CHANGELOG.
- Erfüllt AC-1 und AC-2 bis auf die Durchläufe, AC-3 teilweise.

### F-060c — Doku und Durchläufe

- Installer, Schritt 5: Ein Shim ohne Version außerhalb eines Projekts zählt nicht als
  vorhandenes Werkzeug; die Doku nennt, dass ein Shim außerhalb eines Projekts nur mit
  einer Version des Systems oder einer globalen Version von mise läuft (Fund F-060b).
- Kit-README (Toolchain) und Template-Doku (`README`, `CONTRIBUTING`,
  `HOW-TO-CODE-WITH-CLAUDE`): Aktivierung mit Verweis auf `mise doctor`; CHANGELOG mit
  `### Template`.
- Durchläufe: Installer mit Test-HOME (fragt, trägt ein, zweiter Lauf fragt nicht);
  `/coding-kit:update-conventions global` ohne Aktivierung; nvm auf diesem Rechner;
  neue Session von Claude Code in einem Go-Projekt (`just check` ohne `mise exec`).
- Erfüllt AC-1 bis AC-5.

**Erkennung (Schritt 2a):** entfällt; keine neuen Frameworks, Dependencies oder
Sprachen. Neue Config oder Endpunkte gibt es nicht.

## Verlauf

### F-060a — fertig 2026-11-13

**Umgesetzt:** Spike mit neuen Sessions von Claude Code (`claude -p`), Login-Shells und
einem Hook-Skript, in einem kleinen Projekt mit golangci-lint und node über mise:

- Claude Code übernimmt den `PATH` vom Prozess, der es startet (Terminal oder VS Code);
  aus der `.zshrc` übernimmt es nur Funktionen wie `nvm`, keine Änderungen am `PATH`.
  Terminal und VS Code laden `.zprofile` und `.zshrc`, deshalb kommt eine Aktivierung
  dort auch bei Claude an.
- Mit der Zeile am Ende der `.zshrc`: im Projekt node und golangci-lint aus mise,
  außerhalb die Versionen des Systems (node aus nvm, go aus Homebrew); ebenso in einer
  neuen Claude-Session, die aus dem Terminal startet. Mit der Zeile nur in der
  `.zprofile` lädt nvm danach und überdeckt node.
- Ein einfaches pre-commit-Skript, ausgelöst durch `git commit` aus dem Terminal, sieht
  die Shims und node aus mise.
- Entwurf der Prüfung auf Überdeckung: Steht der Shim-Ordner im `PATH` des Prozesses,
  und welches Werkzeug mit Shim findet `command -v` in einem Ordner davor? Ohne die
  Zeile meldet er node, npm, pnpm und weitere im Ordner von nvm, mit der Zeile keines.
- Nach einer Änderung muss das Terminal bzw. VS Code neu starten; eine neue
  Claude-Session allein übernimmt den alten `PATH`.

**Entscheidungen:** siehe Spezifikation (Ort der Zeile für zsh, Erkennung in zwei
Teilen).

**Abweichung vom Plan:**

- Varianten über `ZDOTDIR` blieben wirkungslos, weil Claude die `.zshrc` aus dem
  Home-Ordner liest. Getestet wurde deshalb mit der echten `.zshrc` des Nutzers,
  testweise und auf seinen Wunsch; danach war sie wieder wie vorher.
- Starts von Claude mit fast leerer Umgebung sind künstlich; sie zeigten nur, dass
  Claude den `PATH` nicht aus der `.zshrc` aufbaut.
- Nicht geprüft und offen für den Durchlauf F-060c: bash, mise per `mise activate` ohne
  Shims (EC-2), Projekte mit `.nvmrc`, Git-Hooks über lefthook und ein Commit aus einer
  Claude-Session — dass Hooks den `PATH` der aufrufenden Shell übernehmen, ist für
  Claude nur abgeleitet.

**Funde:**

- Auf dem Rechner des Nutzers steht die Aktivierung jetzt am Ende der `.zshrc`, die
  Zeile in der `.zprofile` ist entfernt (auf seinen Wunsch).

### F-060b — fertig 2026-11-14

**Umgesetzt:**

- `template-sync.sh mise-check` liest nur die Umgebung und meldet in Zeilen die Shell,
  ihre Startdatei (zsh: `.zshrc`), den Stand der Aktivierung darin (`last`, `present`,
  `commented`, `absent`), ob die Shims im `PATH` stehen, ob mise aktiv ist (Shims im
  `PATH` oder `MISE_SHELL`), je Werkzeug, das ein Ordner vor den Shims überdeckt, eine
  Zeile `shadowed`, die Zeile für diese Shell (zsh, bash, fish) und zuletzt `verdict`
  mit der Entscheidung: `ok`, `commented`, `manual`, `restart`, `hook` oder `offer`.
  `set-mise RC OUT` schreibt die Startdatei mit angehängter Zeile in einen
  Ausgabeordner. Beide nutzen dieselbe Zuordnung von Shell zu Startdatei und Zeile.
- Tests in `tests/template-sync/mise.sh` für beide Befehle und jedes `verdict` unter
  dash, bash und mawk; eine Gegenprobe mit vertauschter Logik ließ sie scheitern.
- `install.sh`, Schritt 6: formuliert je `verdict` eine Meldung, nennt überdeckte
  Werkzeuge mit ihrem Ordner und bietet bei `offer` die Zeile an (Standard: Nein),
  eingetragen über `set-mise`. In elf Szenarien mit Test-Home durchgespielt: Nein
  schreibt nichts, Ja legt die Datei an, ein zweiter Lauf fragt nicht, Überdeckung durch
  nvm wird erkannt (auch unter bash), ein fehlendes Zeilenende wird ergänzt, die
  Dateirechte bleiben, für bash und fish nennt er die Zeile, für andere Shells
  `mise activate --help`.
- `/coding-kit:update-conventions`, Teil G: neuer Schritt G8 mit derselben Prüfung je
  `verdict`; bei `ok` still, Eintrag nur nach Freigabe. Begleitend die Zeile des Skills
  in der README, die Skill-Übersicht in `HOW-TO-CODE-WITH-CLAUDE.md` und CHANGELOG 3.5.0
  mit `### Template`.

**Entscheidungen:**

- Die Entscheidung trifft `mise-check` (Zeile `verdict`); Installer und Skill wählen nur
  den Text. Grund: Die Regeln standen sonst zweimal und liefen schon auseinander —
  Befund aus dem unabhängigen Review.
- Das Anhängen macht ein eigener Befehl `set-mise`; Installer und Skill kopieren nur.
  Grund: Kit-Regel „auch das Einsetzen gehört ins Skript“ — Zeile und Kommentar stehen an
  einer Stelle.
- Steht die Zeile vor einem Tool-Manager, wird sie hinten neu angehängt; die ältere
  entfernt der Nutzer selbst.
- G8 bleibt bei `ok` still (AC-2) und berichtet im Testmodus `global <ordner>` nur, weil
  die Startdatei außerhalb des Stellvertreter-Ordners liegt.

**Abweichung vom Plan:**

- Zweiter Befehl `set-mise` und die Zeile `verdict` dazugekommen (siehe Entscheidungen).
- Den Schritt des Installers getestet, nicht den ganzen Installer (der braucht `gh` und
  `claude` mit Anmeldung); der ganze Lauf folgt in F-060c.
- shellcheck lief nicht (auf dem Rechner keine Version außerhalb eines Projekts); geprüft
  mit `bash -n` und `sh -n`.

**Funde:**

- Vorhandener Fehler behoben: Der Link in der README auf die Prüfung von `gh` im
  Installer zeigte auf falsche Zeilen.
- Ein Shim ohne Version bricht außerhalb eines Projekts mit „No version is set“ ab,
  statt auf das System zurückzufallen; `command -v` in Schritt 5 des Installers hält
  das Werkzeug dann für vorhanden → in F-060c aufgenommen (Plan).

### F-060c — fertig 2026-11-14

**Umgesetzt:**

- `template-sync.sh tool-check TOOL…` (neu) meldet je Werkzeug, ob es außerhalb eines
  Projekts läuft: aus einem Ordner im `PATH`, der nicht zu mise gehört, oder mit einer
  globalen Version in mise (`mise which` aus dem Home-Ordner). Shims und
  Installationsordner von mise zählen nicht; die Regel für die Installationsordner
  teilt es sich mit `mise-check`. Schritt 5 des Installers liest nur noch das Ergebnis.
- `mise-check` übergeht beim Prüfen auf Überdeckung die Installationsordner von mise
  selbst.
- Tests in `tests/template-sync/mise.sh` für beide Änderungen, mit einem Ersatz für
  mise; eine Gegenprobe ohne die neue Regel ließ den Test scheitern.
- Doku: Kit-README (Toolchain) und Template-Doku (`README`, `CONTRIBUTING`,
  `HOW-TO-CODE-WITH-CLAUDE`) nennen die Zeile am Ende der `.zshrc`, den Neustart von
  Terminal und Editor und `mise doctor`; alle außer der Template-README auch bash. Kit-
  README und HOW-TO sagen zusätzlich, dass ein Shim außerhalb eines Projekts nur
  ausführt, was im System oder global in mise installiert ist.
- Durchläufe:
  - Installer mit Test-Home in vier Läufen (AC-1); `gh` bekam das Token nur in der
    Umgebung dieses Laufs, weil die Anmeldung am Schlüsselbund des echten Home-Ordners
    hängt.
  - `/coding-kit:update-conventions global` mit dem Arbeitsstand des Plugins aus einem
    neuen Terminal; die Zeile war vorher aus der `.zshrc` des Nutzers entfernt, auf
    seinen Wunsch und mit Sicherung (AC-2).
  - nvm auf diesem Rechner, auch ein automatisches `nvm use` aus einer `.nvmrc` (AC-3).
  - Neue Claude-Session (`claude -p` aus einer Login-Shell) in einem Go-Projekt aus dem
    Template, mit einem Commit über lefthook (AC-4); die Versionen im Projekt danach in
    einer frischen Login-Shell gegen `mise.lock` geprüft.
  - Schritt 5 des Installers mit den Installationsordnern von mise im `PATH`, mit und
    ohne Homebrew; EC-2 (Aktivierung ohne Shims) ergibt `ok`.

**Entscheidungen:**

- bash: Das Kit nennt nur die Zeile und trägt nichts ein. Grund: Welche Datei bash
  liest, hängt von System und Startart ab.
- Die Prüfung aus Schritt 5 steht im Skript (`tool-check`), nicht im Installer. Grund:
  Befund aus dem unabhängigen Review — die Lage der Ordner von mise stand sonst zweimal,
  und das Skript ist unter dash und bash getestet.

**Abweichung vom Plan:**

- Neuer Befehl `tool-check` statt einer Änderung nur im Installer (siehe
  Entscheidungen).
- shellcheck lief diesmal, über `mise x`, weil es auf diesem Rechner nur als Shim ohne
  Version vorliegt: keine neuen Warnungen.

**Funde:**

- Vorhandener Fehler behoben (aus F-060b): `mise-check` hielt bei einer Aktivierung
  ohne Shims, aber mit Shims im `PATH`, die Installationsordner von mise für Überdeckung
  und meldete `hook` statt `ok`; mit Test belegt.
- Aus dem Review: Bei einer Aktivierung ohne Shims hielt Schritt 5 die Werkzeuge aus der
  `mise.toml` des Kits für vorhanden, weil der Installer im Kit-Ordner startet; behoben
  mit `tool-check`.
