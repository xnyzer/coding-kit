---
id: F-096
title: Projekte-Ordner außerhalb synchronisierter Ordner vorschlagen
type: feature
status: IN-PROGRESS
size: M
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

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben ein Rechner ohne Personal-Config, wenn der Installer nach dem
  Projekte-Ordner fragt, dann schlägt er auf jeder Plattform `~/Coding-Projects` vor
  (unter Windows in der Form `C:/…`) — auch wenn es `~/Documents` oder einen
  xdg-Dokumente-Ordner gibt.
  — belegt: Testgruppe install, Fälle `ready` (`~/Coding-Projects` trotz `Documents`)
  und `win-config` (`X:/test-home/Coding-Projects`)
- [x] AC-2 — Gegeben ein Pfad unter einem Sync-Ordner — OneDrive laut einer der
  Umgebungsvariablen `OneDrive`, `OneDriveConsumer`, `OneDriveCommercial`, oder
  `~/Dropbox` —, wenn `template-sync.sh synced-folder PFAD` ihn prüft, dann meldet es den
  Dienst und den Sync-Ordner; ein Pfad außerhalb, auch der Home-Ordner über dem
  Sync-Ordner, ergibt „nicht synchronisiert“. Pfade in den Formen `C:/…`, `C:\…` und
  `/c/…` gelten als gleich, Laufwerkspfade ohne Rücksicht auf Groß- und Kleinschreibung.
  — belegt: Testgruppe `synced`, 27 Fälle je Shell (drei Pfadformen, beliebige
  Schreibweise, drei OneDrive-Variablen, Dropbox, Nachbarordner, Home-Ordner darüber)
- [x] AC-3 — Gegeben eine Antwort des Installers, die in einem Sync-Ordner liegt, wenn er
  sie prüft, dann warnt er mit dem Dienst und fragt „Trotzdem verwenden?“ mit Vorgabe
  Nein; bei Nein fragt er den Ordner neu, bei Ja gilt er. Ein Ordner außerhalb geht ohne
  Rückfrage durch.
  — belegt: Testgruppe install, Fälle `synced-no`, `synced-yes` und `ready` (lokaler
  Ordner ohne Rückfrage)
- [x] AC-4 — Gegeben eine bestehende Personal-Config, deren `CODING_KIT_PROJECTS_DIR` in
  einem Sync-Ordner liegt, wenn der Installer läuft oder `/coding-kit:update-conventions
  global` (auch im Modus `status`), dann erscheint ein Hinweis mit Dienst und Ordner und
  dem Satz, dass nichts verschoben wird; die Config bleibt unverändert. Liegt der Ordner
  außerhalb oder fehlt der Schlüssel, erscheint kein Hinweis.
  — belegt: Testgruppe install, Fälle `exists-synced` und `exists`; update-conventions
  G1; `synced-folder --config` auf dem Windows-Rechner (`synced` im echten OneDrive,
  `local` für die eigene Config, `none` für eine leere)
- [ ] AC-5 — Gegeben ein Mac, wenn ein Pfad unter iCloud Drive
  (`~/Library/Mobile Documents`), unter `~/Library/CloudStorage/…` oder — bei
  eingeschaltetem „Schreibtisch & Dokumente“ — unter `~/Documents` bzw. `~/Desktop`
  geprüft wird, dann meldet `synced-folder` ihn als synchronisiert; mit ausgeschalteter
  Einstellung ist `~/Documents` nicht synchronisiert. Belegt auf dem Mac mit der echten
  Einstellung.

### Randfälle

- EC-1 — Die OneDrive-Variablen fehlen oder sind leer → keine OneDrive-Erkennung, kein
  Fehler.
- EC-2 — Der Pfad ist der Sync-Ordner selbst oder endet mit `/` → synchronisiert.
- EC-3 — Ein Nachbar mit gleichem Anfang (`…/OneDrive-Backup`, `…/Dropbox2`) → nicht
  synchronisiert.
- EC-4 — Sync-Ordner mit Leerzeichen und Strich, etwa `OneDrive - Firma` → richtig
  erkannt, nichts im Pfad wird von der Shell ausgewertet.
- EC-5 — Installer ohne Terminal (Vorgaben) → der Vorschlag liegt außerhalb, keine
  Rückfrage; wird nach einem Nein neu gefragt, ist die Vorgabe wieder
  `~/Coding-Projects`.

### Nicht-Ziele

- Bestehende Projekte verschieben oder die Personal-Config umschreiben — nur Hinweise.
- Das Google-Drive-Laufwerk unter Windows (`G:`), Netzlaufwerke, symbolische Links
  auflösen.
- Weitere Sync-Clients unter Linux außer `~/Dropbox`.
- Eine Prüfung je Projekt in `/coding-kit:new-project`; die Config-Prüfung deckt den
  Ordner ab.

### Tests

- AC-1, AC-3, EC-5: Fälle in der Testgruppe install — Vorschlag ohne Config (auch mit
  `~/Documents`), Antwort in einem Test-OneDrive mit Nein, dann Ja.
- AC-2, EC-1–EC-4: neue Testgruppe `synced` für `synced-folder` mit gesetzten und leeren
  Umgebungsvariablen und den drei Pfadformen.
- AC-4: Fälle für `synced-folder --config` (Schlüssel im Sync-Ordner, außerhalb,
  fehlend) und ein Installer-Fall mit bestehender Config; manuell
  `/coding-kit:update-conventions global status` mit einer Config im Test-OneDrive.
- AC-5: Fälle mit nachgebauten Ordnern; manuell auf dem Mac mit „Schreibtisch &
  Dokumente“ an und aus.

### Einbettung

- Berührt: `install.sh` (Vorschlag, Rückfrage, Hinweis bei bestehender Config),
  `plugins/coding-kit/scripts/template-sync.sh` (neuer Befehl `synced-folder`),
  `/coding-kit:update-conventions` Teil G (Hinweis), README (Beispiele mit
  `$HOME/Documents/Coding-Projects`, Hinweis zu Sync-Ordnern), Tests.
- Plugin-Inhalt (Skript und Skill): neue Version und CHANGELOG-Eintrag; kein
  Template-Inhalt.
- Eine Änderung an `template-sync.sh` startet im Hook alle Testgruppen; der Beleg für
  F-098 AC-7 (Commit nur an `install.sh`) kommt deshalb nicht aus F-096a.
- Kein Widerspruch zu Zielen oder Nicht-Zielen; der Installer bleibt der einzige, der
  die Personal-Config anlegt.

### Entscheidungen

- 2026-11-25 — Vorschlag `~/Coding-Projects` auf allen Plattformen statt des
  Dokumente-Ordners: liegt praktisch nie in einem Sync-Ordner und braucht keine
  Erkennung. Vom Nutzer gewählt.
- 2026-11-25 — Erkannt werden die üblichen Dienste: OneDrive unter Windows, iCloud Drive
  samt „Schreibtisch & Dokumente“ und `~/Library/CloudStorage` auf dem Mac, `~/Dropbox`
  überall. Vom Nutzer gewählt.
- 2026-11-25 — Im Installer warnen und nachfragen statt nur warnen oder ablehnen: Wer
  bewusst so arbeitet, kann es. Vom Nutzer gewählt.
- 2026-11-25 — Die Erkennung steht als Befehl in `template-sync.sh`, den Installer und
  update-conventions teilen — eine Stelle mit Tests statt zweier Kopien.
- 2026-11-25 — Die Mac-Erkennung ist ein eigener Substep auf dem Mac; F-096 bleibt bis
  dahin `IN-PROGRESS`. Vom Nutzer gewählt.
- Alternative verworfen: Dokumente-Ordner behalten und nur bei Sync ausweichen — der
  Vorschlag hinge an einer Erkennung, die auf dem Mac unsicher ist.

### Offene Fragen

- [ ] [CLARIFY] Woran sich „Schreibtisch & Dokumente“ auf dem Mac zuverlässig erkennen
  lässt — klärt der Mac-Substep; blockiert die Windows-Substeps nicht.

## Plan

**Größe:** M — sechs bis acht Dateien (`install.sh`, `template-sync.sh`,
update-conventions, README, CHANGELOG und `plugin.json`, Tests der Gruppe install und
eine neue Gruppe `synced`), eine offene Frage (Mac-Erkennung), keine Migration.

**Ansatz:** `template-sync.sh synced-folder PFAD` vergleicht einen Pfad mit einer Liste
von Sync-Ordnern: die Werte von `OneDrive`, `OneDriveConsumer`, `OneDriveCommercial`
und `$HOME/Dropbox` (F-096a), dazu die Mac-Orte (F-096c). Beide Seiten werden vorher
vereinheitlicht — `\` → `/`, `/c/…` → `C:/…`, ohne `/` am Ende, Laufwerkspfade ohne
Rücksicht auf Groß- und Kleinschreibung. Ein Treffer ist Gleichheit oder der Sync-Ordner
plus `/` als Anfang. Ausgabe eine Zeile `synced<TAB>DIENST<TAB>ORDNER` oder `local`,
Exit 0. `synced-folder --config DATEI` liest `CODING_KIT_PROJECTS_DIR` mit dem
vorhandenen Parser (`load_env`), ohne die Datei auszuführen, und gibt ohne Schlüssel
`none` aus. Installer und Skill werten nur diese Zeile aus.

Verworfen: die Erkennung im Installer und als Anweisung im Skill — zwei Kopien, die
Fassung im Skill nicht testbar.

### F-096a — Erkennung und Installer

- `template-sync.sh`: Befehl `synced-folder` (OneDrive, Dropbox), Hilfe und
  Kopfkommentar.
- `install.sh`: `default_projects_dir` liefert `$HOME/Coding-Projects`, die Logik mit
  `~/Documents` und `xdg-user-dir` entfällt. Nach der Antwort `synced-folder`; bei
  `synced` Warnung und „Trotzdem verwenden?“ mit Vorgabe Nein, bei Nein neu fragen. Bei
  bestehender Config ein Hinweis aus `synced-folder --config`.
- Tests: neue Gruppe `synced`; in install Vorschlag, Rückfrage Nein/Ja und bestehende
  Config, die xdg-Fälle angepasst.
- README: Beispiele mit `$HOME/Coding-Projects`, ein Satz zu Sync-Ordnern.
- Version 3.8.4 mit CHANGELOG-Eintrag (3.8.3 ist gepusht).
- Erfüllt AC-1, AC-2, AC-3, den Installer-Teil von AC-4, EC-1–EC-5.

### F-096b — Hinweis in update-conventions global

- Teil G, G1: `synced-folder --config <config>/coding-kit.env`; bei `synced` ein
  Hinweis im Bericht, auch im Modus `status`; nichts schreiben.
- CHANGELOG-Eintrag für den Skill unter 3.8.4, solange sie nicht gepusht ist.
- Manuell: `global status` mit einer Test-Config im Test-OneDrive.
- Erfüllt AC-4.

### F-096c — Mac-Erkennung (auf dem Mac)

- Klären, woran „Schreibtisch & Dokumente“ zu erkennen ist (offene Frage).
- `synced-folder` um iCloud Drive, `~/Library/CloudStorage/*` und — bei eingeschalteter
  Einstellung — `~/Documents` und `~/Desktop` erweitern.
- Tests mit nachgebauten Ordnern; Nachweis mit der echten Einstellung an und aus.
- Erfüllt AC-5.

**Erkennung (Standards und Module):** entfällt — keine neue Sprache, kein Framework,
keine Dependency. Keine neue Config; die OneDrive-Variablen werden nur gelesen.

## Verlauf

### F-096a — fertig 2026-11-25

- **Umgesetzt:** `template-sync.sh synced-folder PFAD` bzw. `--config DATEI` vergleicht
  einen Pfad mit den Sync-Ordnern aus `OneDrive`, `OneDriveConsumer`,
  `OneDriveCommercial` und `~/Dropbox` (nur wenn es ihn gibt), beide Seiten
  vereinheitlicht (`sync_form`); Ausgabe `synced`, `local` oder `none`. `--config` liest
  `CODING_KIT_PROJECTS_DIR` mit `load_env`, ohne die Datei auszuführen. `install.sh`
  schlägt `~/Coding-Projects` vor (die Logik mit `~/Documents` und `xdg-user-dir`
  entfällt), fragt vor einem Ordner in einem Sync-Ordner „Trotzdem verwenden?“ und
  weist bei bestehender Config auf einen solchen Ordner hin. Neue Testgruppe `synced`,
  neue Fälle in install, README, Version 3.8.4.
- **Entscheidungen:** keine über die Spezifikation hinaus.
- **Abweichung vom Plan:**
  - Liegt schon die Vorgabe in einem Sync-Ordner (der Home-Ordner selbst in OneDrive)
    und ist die Eingabe zu Ende, bricht der Installer ab, statt endlos neu zu fragen;
    dafür meldet `ask_value` das Ende der Eingabe (`ANSWER_AT_END`).
  - `--config` liest `~`, `$HOME` und `${HOME}` am Anfang als Home-Ordner, weil die
    README die Config von Hand mit `$HOME` zeigt.
  - Die Testpfade heißen `C:/Profiles/u/…`: Die Privacy-Prüfung meldet `/Users/<name>`
    als lokalen Pfad.
- **Messung:** install 376 Checks in 975 s (zwei Jobs parallel), synced 54 Checks.
- **Funde:** keine; das unabhängige Review fand nichts.

### F-096b — fertig 2026-11-25

- **Umgesetzt:** `/coding-kit:update-conventions` Teil G, G1 ruft `template-sync.sh
  synced-folder --config <config>/coding-kit.env` auf; bei `synced` steht ein Hinweis
  mit Dienst und Ordner im Bericht (auch im Modus `status`), samt dem Satz, dass das Kit
  nichts verschiebt. CHANGELOG unter 3.8.4, README-Zeile des Skills.
- **Entscheidungen:**
  - Die Skill-Übersicht in `HOW-TO-CODE-WITH-CLAUDE.md` bleibt unverändert: Sie ist
    Template-Inhalt und ginge in alle Projekte, für einen Hinweis ohne eigene Aktion.
  - Der Hinweis erscheint in jedem Lauf von Teil G, nicht nur mit `global`, weil G1
    dort immer läuft.
- **Abweichung vom Plan:** Einen ganzen Lauf des Skills gab es nicht (die Session läuft
  mit dem installierten Plugin); belegt ist der Befehl, den G1 aufruft, auf dem
  Windows-Rechner mit dem echten OneDrive.
- **Funde:** Das unabhängige Review fand, dass der Satz „nichts wird verschoben“ als
  Anweisung an den Skill statt als Teil des Hinweises stand; behoben.
