---
id: F-095
title: Skript-Tests unter Windows in Git Bash lauffähig machen
type: fix
status: IN-PROGRESS
size: M
created: 2026-11-23
done:
depends-on:
superseded-by:
---

# F-095 — Skript-Tests unter Windows in Git Bash lauffähig machen

## Erfassung

**Problem:** Unter Windows scheitern die Skript-Tests (`tests/template-sync`) in Git
Bash mit 202 Fehlern, alle in `install` und `set-global`. Weil die Skript-Pfade, das
`justfile` und `install.sh` in der Pfadliste von `scripts/script-tests.sh` stehen,
scheitert dort jeder Commit an diesen Dateien im Pre-Commit-Hook — er geht nur mit
`--no-verify`.

**Ziel:**
- Ist: `just test` meldet unter Windows 202 Fehler, die mit dem geprüften Code nichts zu
  tun haben; unter Linux (CI) laufen alle Checks grün.
- Soll: die Tests laufen unter Windows so grün wie unter Linux und macOS, oder ein Fall,
  der auf Windows nicht prüfbar ist, wird dort ausdrücklich übersprungen und gemeldet.
- Reproduzieren: Windows mit Git for Windows und mise, im Kit-Repo `just test`.

**Lösungsskizze:**
- Statt `ln -s` kleine Wrapper-Skripte, die das echte Tool aufrufen — in den
  Installer-Tests und im Zusatzlauf je awk von `run.sh`. Git Bash legt bei `ln -s`
  Kopien an, die unter `env -i` ihre MSYS-Bibliotheken nicht finden.
- Prüfungen auf Dateirechte (`-rw-------`) überspringen, wenn eine Probe zeigt, dass
  `chmod 600` auf dem Dateisystem nicht wirkt (Git Bash bindet mit `noacl` ein); die
  Zusammenfassung nennt Zahl und Grund.
- `set-global` erkennt CRLF-Dateien unter Windows nicht, weil gawk aus Git for Windows
  das `\r` beim Lesen entfernt — an der Erkennung gawk mit `BINMODE=1` lesen lassen.
- `run.sh` isoliert die Test-Repos von der System-Git-Config (`GIT_CONFIG_NOSYSTEM=1`);
  die Systemvorgabe `core.autocrlf=true` von Git for Windows erzeugt sonst Warnungen.

**Abhängigkeiten:** keine. Herkunft: F-094 (Noch zu analysieren).

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben Windows mit Git Bash, wenn `just test` läuft, dann laufen die
  Installer-Fälle unter dash und bash durch wie unter Linux; gegeben Linux oder macOS,
  dann bleiben sie grün und die Zahl der Checks ändert sich nicht.
- [ ] AC-2 — Gegeben ein Dateisystem, auf dem `chmod 600` nicht wirkt, wenn die Tests
  laufen, dann werden die Prüfungen auf Eigentümer-Rechte übersprungen, und die
  Zusammenfassung nennt die Zahl der übersprungenen Checks und den Grund; gegeben ein
  Dateisystem mit echten Rechten, dann laufen sie wie bisher und nichts wird
  übersprungen.
- [ ] AC-3 — Gegeben eine Personal-Config mit CRLF-Zeilenenden, wenn `set-global` unter
  Windows einen Wert setzt, dann endet jede Zeile der Datei weiter mit CRLF; auf macOS
  und Linux ändert sich nichts.
- [ ] AC-4 — Gegeben eine System-Git-Config mit `core.autocrlf=true`, wenn die Tests
  laufen, dann erscheint keine Warnung „LF will be replaced by CRLF“, und kein Ergebnis
  hängt von der System-Config ab.
- [ ] AC-5 — Gegeben Windows mit Git Bash, wenn `just test` läuft, dann meldet die
  Zusammenfassung 0 Fehler, und ein Commit an Skript-Pfaden geht dort ohne
  `--no-verify` durch den Pre-Commit-Hook.

### Randfälle

- EC-1 — mawk fehlt (unter Git Bash immer) → wie bisher „not installed: mawk“, kein
  Fehler.
- EC-2 — ein Tool der Attrappen-Liste fehlt auf dem Rechner → wie bisher kein Eintrag im
  Attrappen-Ordner.
- EC-3 — der Pfad eines Tools enthält Leerzeichen → der Wrapper ruft ihn zitiert auf.
- EC-4 — awk ohne `BINMODE` (macOS-awk, mawk) → die Variable bleibt ohne Wirkung, das
  Verhalten ist unverändert.

### Nicht-Ziele

- mawk unter Windows beschaffen.
- Die Rechte unter Windows über die ACL prüfen (`icacls`) — das Kit setzt sie nicht
  selbst.
- Die Laufzeit der Tests unter Windows verkürzen (etwa zehn Minuten).
- Der Fall „memory-dir“ mit dem Ordnernamen `C:\Users\demo` meldet unter Windows ein
  `fatal` von git auf stderr, besteht aber — er bildet auf POSIX einen Windows-Pfad nach.
- Die Meldung „angelegt (chmod 600)“ des Installers → F-067.

### Tests

- AC-1 → `just test` unter Windows (Installer-Fälle ohne Fehler) und CI unter Linux
  (gleiche Zahl der Checks wie vorher).
- AC-2 → `just test` unter Windows: Zusammenfassung mit übersprungenen Checks und Grund;
  CI unter Linux: nichts übersprungen.
- AC-3 → der vorhandene Fall „set-global: CRLF file gets CRLF lines“ unter Windows grün,
  in der CI weiter grün.
- AC-4 → Ausgabe von `just test` unter Windows ohne „LF will be replaced“.
- AC-5 → `just test` unter Windows mit 0 Fehlern; der Commit dieses Features an
  `tests/` und `plugins/coding-kit/scripts/` läuft regulär durch den Hook.

### Einbettung

- Test-Gerüst: `tests/template-sync/run.sh` (Probe und Zähler fürs Überspringen,
  `GIT_CONFIG_NOSYSTEM`, Wrapper im awk-Zusatzlauf), `tests/template-sync/install.sh`
  (Wrapper), `tests/template-sync/global.sh` (Rechte-Prüfung über den neuen Helfer).
- Plugin-Skript: `plugins/coding-kit/scripts/template-sync.sh` (`set-global`) — Plugin-
  Inhalt, also eine neue Version über 3.8.0 und ein CHANGELOG-Eintrag; kein Template-
  Inhalt, kein Abschnitt `### Template`.
- Doku: prüfen, ob `docs/skill-authoring.md` (Tests) das Überspringen erwähnen sollte.
- Folge: F-067 profitiert direkt — seine Commits an `install.sh` brauchen danach unter
  Windows kein `--no-verify`.

### Offene Fragen

- keine

### Entscheidungen

- 2026-11-23 — Rechte-Prüfungen auf einem Dateisystem ohne echte Rechte überspringen und
  melden statt die Windows-ACL zu prüfen: das gilt für jedes solche Dateisystem, und das
  Kit setzt die ACL nicht selbst.
- 2026-11-23 — Der CRLF-Fehler in `set-global` wird in F-095 behoben (eigener Substep),
  nicht unter einer eigenen Nummer: der Test deckt ihn auf und wird mit dem Fix grün.
- 2026-11-23 — Wrapper-Skripte statt erzwungener Symlinks (`MSYS=winsymlinks`): laufen
  überall gleich, ohne Entwicklermodus oder Adminrechte.
- 2026-11-23 — Die Test-Repos laufen ohne System-Git-Config (`GIT_CONFIG_NOSYSTEM=1`):
  keine Warnungen, Ergebnisse unabhängig vom Rechner.

## Plan

**Größe:** M — sechs Dateien in Test-Gerüst und Plugin-Skript, die Ursachen sind
nachgestellt (Wrapper-Versuch lief durch), offen war nur die Behandlung der Rechte-
Prüfungen; berührt Plugin-Inhalt.

**Ansatz:** Ursachen einzeln beheben, wo sie liegen — den echten Fehler im Skript, die
Annahmen des Test-Gerüsts über Links, Dateirechte und die System-Git-Config. Verworfen:
die Fälle unter Windows pauschal überspringen (verdeckt den CRLF-Fehler im Skript und
lässt die Installer-Tests auf Windows ungeprüft).

### F-095a — CRLF in set-global unter Windows

- `plugins/coding-kit/scripts/template-sync.sh`: das awk-Programm von `set-global`
  liest mit `BINMODE=1`, damit gawk unter Windows das `\r` sieht; Kommentar mit dem
  Grund.
- Version 3.8.1 in `plugin.json`, CHANGELOG-Eintrag „3.8.1 — unveröffentlicht“.
- Erfüllt AC-3. Commit unter Windows noch mit `--no-verify` (nur die bekannten Fehler
  des Test-Gerüsts, vor und nach identisch), CI prüft.

### F-095b — Test-Gerüst unter Windows

- `tests/template-sync/install.sh` und der awk-Zusatzlauf in `run.sh`: Wrapper-Skripte
  statt `ln -s`.
- `run.sh`: einmalige Probe, ob `chmod 600` wirkt; Helfer für Rechte-Prüfungen, der sonst
  überspringt und zählt; die Zusammenfassung nennt „N skipped (no file modes)“.
  `install.sh` und `global.sh` nutzen den Helfer.
- `run.sh`: `GIT_CONFIG_NOSYSTEM=1` für alle Fälle.
- Erfüllt AC-1, AC-2, AC-4, AC-5 — der Commit geht unter Windows regulär durch den Hook.

## Verlauf

### F-095a — fertig 2026-11-23

**Umgesetzt:** `set-global` (`plugins/coding-kit/scripts/template-sync.sh`) startet sein
awk mit `-v BINMODE=1`: gawk unter Windows liest das `\r` jetzt mit, erkennt die
CRLF-Datei und reicht die übrigen Zeilen unverändert durch. Die Ausgabe schreibt gawk
dort ohnehin binär, ein zweites `\r` kommt nicht dazu (vorab nachgestellt). Version 3.8.1
mit CHANGELOG-Eintrag.

**Entscheidungen:** keine über die Spezifikation hinaus.

**Abweichung vom Plan:** keine.

**Funde:**
- `just test` unter Windows: 200 statt 202 Fehler, die übrige Liste ist identisch. Der Fall
  „set-global: the file is private“ ist eine Rechte-Prüfung und gehört zu F-095b.
- AC-3 ist unter Windows belegt („set-global: CRLF file gets CRLF lines“ unter dash und
  bash grün, vorher rot); der Teil „macOS und Linux unverändert“ steht bis zur CI aus.
