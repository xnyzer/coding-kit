---
id: F-098
title: Skript-Tests nach Gruppen auswählen und parallel ausführen
type: change
status: PLANNED
size: M
created: 2026-11-24
done:
depends-on:
superseded-by:
---

# F-098 — Skript-Tests nach Gruppen auswählen und parallel ausführen

## Erfassung

### Problem

Die Skript-Tests (knapp 3000 Checks, je unter dash und bash) laufen nacheinander und,
sobald eine Änderung sie betrifft, vollständig. Unter Windows kostet jeder Prozessstart
in Git Bash ein Vielfaches gegenüber Linux: Ein Commit mit einer Änderung am Installer
wartet rund eine Stunde im Pre-Commit-Hook, obwohl nur ein kleiner Teil der Checks den
Installer betrifft. In der CI unter Linux dauert derselbe Lauf wenige Minuten.

### Ziel

Die Skript-Tests laufen spürbar schneller: Eine Änderung startet nur die Testgruppen,
die sie betrifft, und die Gruppen laufen parallel auf den Kernen des Rechners — überall,
auch in der CI. Gleich bleiben muss: Jede Gruppe läuft weiter unter dash und bash (dazu
mawk und gawk, wo installiert); `just check-all` und die CI prüfen weiter alles; die
Zusammenfassung zählt Checks und Fehler wie heute, und jeder Fehler bleibt einer Shell
und einer Gruppe zuzuordnen.

### Lösungsskizze

- Eine Testgruppe ist eine Datei unter `tests/template-sync/` (render, sync, mise,
  install …) — sie wird zur Einheit für Auswahl und Parallelität.
- Auswahl: Die Zuordnung „geänderte Datei → Testgruppen“ steht an einer Stelle (heute
  die Pfadliste in `scripts/script-tests.sh`). Änderungen an gemeinsam genutzten Teilen
  (etwa `template-sync.sh` oder die Test-Harness) starten weiter alles.
- Parallel: Gruppe und Shell laufen als eigener Job mit eigenem Temp-Ordner und eigener
  Ergebnisdatei; die Zahl gleichzeitiger Jobs folgt zur Laufzeit der Kernzahl des
  Rechners und lässt sich überschreiben. Die Ausgabe wird je Job gesammelt und am Ende
  geordnet gezeigt.
- Standard auf allen Plattformen und in der CI, kein Sonderweg für Windows.
- Im Gespräch verworfen: Ausnahmen im Virenscanner (Sicherheitsabwägung) und unter
  Windows nur eine Shell im Hook (mit Parallelität unnötig, und Fehler einer Shell fielen
  erst in der CI auf).

### Abhängigkeiten

Keine — baut auf F-064 (Tests nur bei passenden Änderungen) und F-095 (Tests unter
Windows) auf, beide `DONE`.

### Noch zu analysieren

- Welche Gruppen voneinander abhängen (gemeinsame Helfer, etwa die Attrappen aus
  `mise.sh` in den Installer-Fällen).
- Wie fein die Zuordnung sein darf, ohne dass eine Änderung lokal durchrutscht — die CI
  fängt sie, aber erst nach dem Push.
- Den Gewinn messen: vorher und nachher, unter Windows und in der CI.

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben eine Änderung nur an Dateien, die die Zuordnung in
  `scripts/script-tests.sh` bestimmten Gruppen zuweist (etwa `install.sh` → install,
  `tests/template-sync/mise.sh` → mise), wenn `just check` oder der Pre-Commit-Hook die
  Skript-Tests startet, dann laufen nur diese Gruppen, und die Meldung nennt sie; eine
  Änderung, die keine Gruppe betrifft (etwa nur Doku), überspringt die Tests wie heute.
- [ ] AC-2 — Gegeben eine Änderung an einer gemeinsam genutzten Datei
  (`template-sync.sh`, `tests/template-sync/run.sh`, `justfile`,
  `scripts/script-tests.sh`) oder an einem Pfad, der die Tests betrifft, aber keiner
  Gruppe eindeutig zugeordnet ist, wenn die Tests starten, dann laufen alle Gruppen.
- [ ] AC-3 — Gegeben ein Rechner mit N Kernen, wenn die Tests laufen, dann laufen
  höchstens N−1 Jobs gleichzeitig (mindestens einer); ein Job ist eine Gruppe unter einer
  Shell bzw. einem zusätzlichen awk. `TEST_JOBS` setzt die Zahl anders; ein Wert, der
  keine positive ganze Zahl ist, bricht mit einer Meldung ab, bevor ein Test läuft.
- [ ] AC-4 — Gegeben derselbe Stand, wenn die Tests parallel laufen, dann stimmen die
  Zahlen der Checks, Fehler und übersprungenen Checks mit einem Lauf mit `TEST_JOBS=1`
  überein, der Exit-Code ist bei einem Fehler nicht 0, und jede Fehlerzeile nennt Shell
  (ggf. awk) und Gruppe.
- [ ] AC-5 — Gegeben ein laufender Testlauf, wenn ein Job fertig ist, dann erscheint
  eine Zeile mit Gruppe, Shell und Stand („k von n“); Fehlerzeilen erscheinen erst am
  Ende, geordnet nach Gruppe und Shell, danach die Zusammenfassung wie heute.
- [ ] AC-6 — Gegeben `just check-all` bzw. die CI, wenn sie laufen, dann laufen alle
  Gruppen, ebenfalls parallel.
- [ ] AC-7 — Gegeben der Windows-Rechner und eine Änderung nur an `install.sh`, wenn
  der Pre-Commit-Hook die Tests startet, dann dauert er höchstens ein Viertel eines
  Laufs aller Gruppen; gegeben ein Mac, wenn alle Gruppen parallel laufen, dann dauert
  der Lauf höchstens die Hälfte eines Laufs mit `TEST_JOBS=1`. Die gemessenen Zeiten —
  auch die eines parallelen Laufs unter Windows — stehen im Verlauf.

### Randfälle

- EC-1 — Ein Kern, oder die Kernzahl lässt sich nicht ermitteln → ein Job, der Lauf
  geht seriell durch.
- EC-2 — Ein Job endet ohne Ergebnis (Absturz, Abbruch der Shell) → er zählt als Fehler
  mit Gruppe und Shell; der Lauf scheitert, statt still grün zu sein.
- EC-3 — Mehrere Gruppen schreiben gleichnamige Dateien unter `$TMP` → jeder Job hat
  seinen eigenen Temp-Ordner, nichts überschneidet sich.
- EC-4 — Abbruch mit Strg+C → laufende Jobs enden, der Temp-Ordner wird aufgeräumt wie
  heute.
- EC-5 — Eine Änderung trifft mehrere Gruppen (etwa `install.sh` und eine Hook-Datei) →
  die Vereinigung der Gruppen läuft, jede einmal.

### Nicht-Ziele

- Ausnahmen im Virenscanner oder Windows-Einstellungen.
- Unter Windows nur eine Shell im Hook.
- Eine feinere Auswahl nach Befehlen von `template-sync.sh`.
- Die einzelnen Checks schneller machen (weniger Prozesse je Check) — wäre eine eigene
  Nummer.
- Die `just check` der Projekte aus dem Template.

### Tests

- AC-1, AC-2, EC-5: Fälle in einer neuen Testgruppe für `scripts/script-tests.sh` — ein
  Temp-Repo mit Änderungen, die Auswahl per Option ausgeben lassen und vergleichen.
- AC-3: Fälle für die Job-Zahl (Kernzahl als Attrappe, `TEST_JOBS` gültig und
  ungültig).
- AC-4, EC-2: ein absichtlich scheiternder bzw. abbrechender Test-Job in einem
  Probelauf; Vergleich der Zusammenfassung mit `TEST_JOBS=1` (manuell und in der CI).
- AC-5: Ausgabe eines Probelaufs prüfen.
- AC-6: CI-Lauf grün, Laufzeit im Log.
- AC-7: manuell — auf dem Windows-Rechner ein Commit mit Änderung nur an `install.sh`
  gegen einen Lauf aller Gruppen, auf dem Mac `just test` gegen `TEST_JOBS=1 just test`;
  alle Zeiten im Verlauf.

### Einbettung

- Berührt: `tests/template-sync/run.sh` (Jobs, Ergebnisdateien, Fortschritt,
  Zusammenfassung, Auswahl der Gruppen per Argument), `scripts/script-tests.sh`
  (Zuordnung Datei → Gruppen, Übergabe an `run.sh`), Kommentare im `justfile`, die
  Abschnitte zu den Tests in CLAUDE.md und README.
- Kein Plugin-Inhalt: keine neue Version, kein CHANGELOG-Eintrag.
- Die CI ändert sich nicht: `just check-all` bleibt, läuft nur parallel.
- F-064 bleibt gültig: Die Entscheidung über die Tests fällt weiter an einer Stelle,
  jetzt mit Gruppen statt alles oder nichts.

### Entscheidungen

- 2026-11-24 — Die Zuordnung steht zentral in `scripts/script-tests.sh`, nicht als
  Kopfzeile je Testdatei: eine Stelle wie in F-064. Vom Nutzer gewählt.
- 2026-11-24 — Höchstens Kerne minus eins gleichzeitig, damit der Rechner während des
  Laufs bedienbar bleibt. Empfehlung war alle Kerne; entschieden Kerne minus eins, weil
  der Hook oft läuft, während am Rechner weitergearbeitet wird.
- 2026-11-24 — Während des Laufs eine Fortschrittszeile je Job, Fehler gesammelt am
  Ende. Vom Nutzer gewählt.
- 2026-11-24 — Eine Änderung an `template-sync.sh` startet alle Gruppen; die feinere
  Auswahl nach Befehlen wäre fehleranfällig. Vom Nutzer gewählt.
- 2026-11-24 — Keine Ausnahmen im Virenscanner und kein Verzicht auf eine Shell unter
  Windows (im Gespräch verworfen, siehe Erfassung).
- 2026-11-24 — Messung auf dem Windows-Rechner: Ein Programm aus PowerShell zu starten
  kostet rund 10 ms, ein `fork` der Git Bash dagegen 60–110 ms (dash günstiger als
  bash), und parallele Forks laufen faktisch nacheinander — 8 Schleifen brauchen
  achtmal so lange wie eine. Der Defender arbeitet dabei sichtbar mit; eine lokale
  Benutzerdatenbank der Git Bash (`/etc/passwd`, `nsswitch.conf`) brachte nichts und ist
  zurückgenommen. Folge: Unter Windows trägt die Auswahl nach Gruppen den Gewinn, die
  Parallelität wirkt auf dem Mac und in der CI. AC-7 ist danach ausgerichtet; die
  Empfehlung „halbe Zeit unter Windows“ ist verworfen.

## Plan

**Größe:** M — vier bis sechs Dateien (`tests/template-sync/run.sh`,
`scripts/script-tests.sh`, zwei neue Testgruppen, Doku), einzelne offene Fragen (Job-Verteilung
ohne `wait -n`, Zuordnung), keine neue Technik, keine Migration.

**Ansatz:** Die Testgruppe ist die Einheit für beides. `run.sh` nimmt Gruppen als
Argumente (ohne Argument alle) und führt Gruppe × Shell (bzw. × zusätzliches awk) als
Jobs aus. Die Verteilung ist reines POSIX-sh: so viele Bahnen wie erlaubte Jobs, jede
Bahn läuft im Hintergrund und holt sich den nächsten freien Job, indem sie für ihn einen
Ordner anlegt (`mkdir` gelingt genau einmal); danach `wait`. Ein Job läuft in einer
Subshell mit eigenen Zählern, eigenem `$TMP` und eigener Ausgabedatei und schreibt am
Ende eine Ergebniszeile; fehlt sie, zählt der Job als gescheitert. Die schweren Gruppen
stehen vorn in der Liste, damit keine Bahn am Ende allein läuft. `script-tests.sh`
ordnet jede geänderte Datei Gruppen zu oder „alle“ und übergibt die Vereinigung.

Verworfen: `xargs -P` — einfacher, aber nicht POSIX (das Kit schreibt seine Skripte in
POSIX-sh); GNU parallel — eine zusätzliche Abhängigkeit unter GPL, nach der
Lizenzregel ausgeschlossen.

### F-098a — Tests nach Gruppen auswählen

- `run.sh`: Gruppenliste an einer Stelle, Gruppen als Argumente, unbekannte Gruppe →
  Meldung und Exit 2.
- `script-tests.sh`: Zuordnung — `install.sh` → install; `scripts/release-notes.sh`
  und `scripts/publish-release.sh` → ihre Gruppe; `plugins/coding-kit/hooks/*` → hook;
  eine Testdatei → ihre Gruppe (`mise.sh` zusätzlich install und settings, die seine
  Helfer nutzen); alles andere, was die Tests betrifft (Skripte, Template, globale
  Regeln, `run.sh`, `justfile`, `script-tests.sh`, gequotete Pfade) → alle. Option
  `--list` gibt die Auswahl aus, ohne zu testen; die Meldung nennt die Gruppen.
- Tests: neue Gruppe `selection` — ein Temp-Repo mit Änderungen, `--list` je Fall.
- Doku: Abschnitt zu den Skript-Tests in CLAUDE.md und README, Kommentar im `justfile`.
- Erfüllt AC-1, AC-2, EC-5; Messung unter Windows für AC-7.

### F-098b — Gruppen parallel ausführen

- `run.sh`: Jobs und Bahnen wie im Ansatz; Zahl der Bahnen aus `getconf
  _NPROCESSORS_ONLN`, sonst `nproc`, sonst 1, davon eins weniger (mindestens eins);
  `TEST_JOBS` überschreibt und wird geprüft. Je fertigem Job eine Fortschrittszeile
  („install/dash fertig — 12 von 34“; laufen zwei Jobs gleichzeitig aus, kann eine Zahl
  doppelt erscheinen). Am Ende die Ausgaben der Jobs in fester Reihenfolge, dann die
  Zusammenfassung wie heute. Option `--plan` nennt Job-Zahl und Jobs, ohne zu testen.
- Tests: neue Gruppe `runner` — `--plan` mit Attrappe für die Kernzahl, `TEST_JOBS`
  gültig und ungültig.
- Manuell: Zusammenfassung parallel gegen `TEST_JOBS=1`; ein absichtlich
  abbrechender Job (EC-2); Strg+C (EC-4); Messung auf dem Mac für AC-7.
- Erfüllt AC-3, AC-4, AC-5, AC-6, EC-1–EC-4, AC-7.

**Erkennung (Standards und Module):** entfällt — keine neue Sprache, kein Framework,
keine Dependency. Neue Config: die Umgebungsvariable `TEST_JOBS` (nur für die Tests).
Keine Version und kein CHANGELOG-Eintrag (kein Plugin-Inhalt).

**Hinweis:** AC-7 verlangt eine Messung auf dem Mac; ohne sie bleibt F-098 nach dem Bau
`IN-PROGRESS`.
