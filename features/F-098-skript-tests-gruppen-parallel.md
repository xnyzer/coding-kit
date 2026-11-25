---
id: F-098
title: Skript-Tests nach Gruppen auswählen und parallel ausführen
type: change
status: IN-PROGRESS
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

- [x] AC-1 — Gegeben eine Änderung nur an Dateien, die die Zuordnung in
  `scripts/script-tests.sh` bestimmten Gruppen zuweist (etwa `install.sh` → install,
  `tests/template-sync/mise.sh` → mise), wenn `just check` oder der Pre-Commit-Hook die
  Skript-Tests startet, dann laufen nur diese Gruppen, und die Meldung nennt sie; eine
  Änderung, die keine Gruppe betrifft (etwa nur Doku), überspringt die Tests wie heute.
  — belegt: Testgruppe `selection` (Fälle doc, inst, test, stand-ins, zones, notes,
  lock, new, staged); der Pre-Commit-Hook ruft `scripts/script-tests.sh --staged` auf
- [x] AC-2 — Gegeben eine Änderung an einer gemeinsam genutzten Datei
  (`template-sync.sh`, `tests/template-sync/run.sh`, `justfile`,
  `scripts/script-tests.sh`) oder an einem Pfad, der die Tests betrifft, aber keiner
  Gruppe eindeutig zugeordnet ist, wenn die Tests starten, dann laufen alle Gruppen.
  — belegt: Testgruppe `selection` (Fälle core, fixtures, runner, self, empty);
  `--list` im Arbeitsstand ergibt `all`
- [x] AC-3 — Gegeben ein Rechner mit N Kernen, wenn die Tests laufen, dann laufen
  höchstens N−1 Jobs gleichzeitig (mindestens einer); ein Job ist eine Gruppe unter einer
  Shell bzw. einem zusätzlichen awk. `TEST_JOBS` setzt die Zahl anders; ein Wert, der
  keine positive ganze Zahl ist, bricht mit einer Meldung ab, bevor ein Test läuft.
  — belegt: Testgruppe `runner` (Kernzahl als Attrappe: 8 → 7, 1 → 1, nproc-Fallback,
  ohne Kernzahl → 1; `TEST_JOBS` 5, 1, mehr als Jobs; abgelehnt 0, 07, abc, -2, 10000,
  „3 4“ mit Exit 2 vor dem ersten Job)
- [x] AC-4 — Gegeben derselbe Stand, wenn die Tests parallel laufen, dann stimmen die
  Zahlen der Checks, Fehler und übersprungenen Checks mit einem Lauf mit `TEST_JOBS=1`
  überein, der Exit-Code ist bei einem Fehler nicht 0, und jede Fehlerzeile nennt Shell
  (ggf. awk) und Gruppe.
  — belegt: global, lock und license mit `TEST_JOBS=1` und parallel, je 508 Checks,
  0 Fehler, 2 übersprungen; Probelauf mit scheiterndem Check und abbrechendem Job: Exit 1,
  Fehlerzeilen `FAIL [license/dash] …`, `FAIL [release-notes/bash] the job ended without
  a result`
- [x] AC-5 — Gegeben ein laufender Testlauf, wenn ein Job fertig ist, dann erscheint
  eine Zeile mit Gruppe, Shell und Stand („k von n“); Fehlerzeilen erscheinen erst am
  Ende, geordnet nach Gruppe und Shell, danach die Zusammenfassung wie heute.
  — belegt: Gesamtlauf unter Windows („install/bash ok — 38 of 38“, Fehlerzeilen danach,
  dann die Zusammenfassung)
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

## Verlauf

### F-098a — fertig 2026-11-25

- **Umgesetzt:** `tests/template-sync/run.sh` führt die Gruppen aus einer Liste
  (`ALL_GROUPS`) und nimmt Gruppen als Argumente; ein Argument, das keine Gruppe nennt,
  bricht vor dem ersten Test mit Exit 2 ab, und die Zusammenfassung nennt bei einer
  Auswahl die Gruppen. `scripts/script-tests.sh` ordnet in `groups_for` jede geänderte
  Datei Gruppen oder „alle“ zu und übergibt die Vereinigung, jede Gruppe einmal;
  `--list` gibt die Auswahl aus, ohne zu testen. Neue Testgruppe `selection` mit
  kleinen Temp-Repos je Fall. Doku in CLAUDE.md und README, Kommentare in `justfile` und
  `lefthook.yml`.
- **Entscheidungen:** `run.sh` lädt weiter alle Gruppendateien und führt nur die
  gewählten aus, weil die Gruppen Helfer teilen. Eine Testdatei, deren Helfer andere
  Gruppen aufrufen, startet diese mit: `sync.sh` alle, `zones.sh` zones und global,
  `global.sh` global und hook, `mise.sh` mise und install. Ebenso startet
  `release-notes.sh` publish-release mit (das ruft es auf), und `mise.lock` startet
  privacy (ein Fall prüft sie).
- **Messung (Windows, jede Gruppe allein):** alle 18 Gruppen grün, zusammen 3012 Checks
  wie im Gesamtlauf. install 1071 s, sync 789 s, zones 603 s, render 571 s, detect
  333 s, global 306 s, host 285 s, mise 159 s, features 143 s, privacy 141 s, hook
  108 s, settings 104 s, migrate 65 s, lock 51 s, selection 34 s, publish-release 30 s,
  license 25 s, release-notes 11 s; Summe 4829 s, der Gesamtlauf rund 72 min. Eine
  Änderung nur an `install.sh` braucht damit knapp ein Viertel des Gesamtlaufs
  (1071 s gegen rund 1080 s); der Beleg im Hook folgt mit dem ersten solchen Commit.
- **Abweichung vom Plan:** Die Zuordnung ist feiner als geplant. Das unabhängige Review
  fand Gruppen, die Helfer anderer Testdateien nutzen (siehe Entscheidungen); `mise.sh`
  startet settings nicht mehr mit, weil die Gruppe es nicht nutzt. Der Kommentar in
  `lefthook.yml` beschrieb noch „alles oder nichts“ und ist angepasst.
- **Funde:** Unter Windows schreibt der memory-dir-Fall in `settings.sh` „fatal: cannot
  change to …“ auf stderr, ohne zu scheitern (bekannt aus F-067c); keine neue Aufgabe.

### F-098b — fertig 2026-11-25

- **Umgesetzt:** `tests/template-sync/run.sh` schreibt je Gruppe und Shell (und je
  zusätzlichem awk) einen Job in eine Liste. Es startet so viele Bahnen, wie Jobs
  gleichzeitig laufen dürfen: Kerne minus eins aus `getconf`, sonst `nproc`, sonst 1,
  oder `TEST_JOBS`, höchstens so viele wie Jobs. Jede Bahn holt sich den nächsten freien
  Job per `mkdir`. Er läuft in einer Subshell mit eigenem `$TMP` und eigener
  Ausgabedatei und schreibt am Ende eine Ergebniszeile; fehlt sie, zählt der Job als
  Fehler (EC-2). Je fertigem Job erscheint eine Fortschrittszeile. Danach folgen die
  Ausgaben in fester Reihenfolge und die Summen. Ohne Kernzahl läuft ein Job zurzeit
  (EC-1). `--plan` nennt die Jobs, ohne zu testen. Bei Strg+C hält eine Stop-Datei die
  Bahnen an, und die laufenden Jobs enden nach ihrem aktuellen Befehl. Danach räumt der
  Lauf den Temp-Ordner auf (EC-4: Exit 130, kein Prozess übrig, Temp-Ordner leer). Neue
  Testgruppe `runner`; Doku in README und `justfile`.
- **Entscheidungen:**
  - Parallel bringt auch unter Windows viel: Ein Gesamtlauf braucht 1841 s statt rund
    4800 s, also 2,6-mal schneller. Die Annahme in der Spezifikation („parallele Forks
    laufen faktisch nacheinander“) gilt für einzelne Fork-Schleifen, nicht für die
    Testgruppen.
  - `TEST_JOBS` nimmt 1 bis 9999 ohne führende Null. Die Grenze hält die Rechnung fern
    von einem Überlauf, und die Meldung nennt sie.
- **Messung (Windows, 20 Kerne, 19 gleichzeitig):**
  - Gesamtlauf: 38 Jobs, 3054 Checks, 1841 s.
  - global, lock und license: 213 s parallel, 416 s mit `TEST_JOBS=1`.
  - Drei kleine Gruppen: 33,5 s statt 66 s.
  - install/bash endet als letzter Job; die längste Gruppe bestimmt die Dauer des
    Gesamtlaufs.
- **Abweichung vom Plan:**
  - Die Gruppen starten in der Reihenfolge ihrer gemessenen Dauer, die längste zuerst.
  - Die Fortschrittszeile ist englisch wie alle Ausgaben der Tests: „install/dash ok —
    12 of 38“ statt „fertig — 12 von 34“.
  - Der Abbruch lief zuerst über ein hartes Beenden. Danach liefen Befehle verwaister
    Jobs weiter und legten Ordner im gelöschten Temp-Ordner an. Jetzt gibt es die
    Stop-Datei, Jobs enden mit SIGTERM nach dem aktuellen Befehl, und der Lauf wartet
    auf sie.
- **Funde:**
  - Der host-Fall „stops at TF401019 without waiting“ maß 10 s gegen eine Verbindung,
    die 20 s offen bleibt. Unter der Last des parallelen Laufs scheiterte er. Jetzt bleibt
    die Verbindung 60 s offen, und die Grenze liegt bei 40 s; die Gruppe ist grün.
  - Das unabhängige Review fand zwei Dinge, beide behoben:
    - Eine Bahn ließ die pid ihres letzten Jobs stehen. Strg+C hätte so einen fremden
      Prozess treffen können.
    - Die Meldung zu `TEST_JOBS` nannte die Grenze nicht.
  - Zu AC-7: Am Viertel gemessen wurde in F-098a gegen den seriellen Gesamtlauf. Gegen
    den parallelen Gesamtlauf (1841 s) bleibt ein Lauf nur von install darüber, weil
    install den Gesamtlauf begrenzt. Den install-Lauf aufzuteilen, wäre eine eigene
    Nummer.
