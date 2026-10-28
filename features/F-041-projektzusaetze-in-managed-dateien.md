---
id: F-041
title: Projektzusätze in managed Dateien erhalten, Abweichungen früh erkennen
type: feature
status: DONE
size:
created: 2026-10-24
done: 2026-10-24
depends-on:
superseded-by:
---

# F-041 — Projektzusätze in managed Dateien erhalten, Abweichungen früh erkennen

## Verlauf

### F-041a — Renderer (2026-10-24)

Teil von F-041 (Projektzusätze in managed Dateien erhalten und Abweichungen früh
erkennen; F-041b–e folgen).

**Problem:** Der Drei-Wege-Merge braucht eine Soll-Fassung, die bei gleichem Template und
gleichen Projektwerten byte-gleich herauskommt. Bisher instanziierte das Sprachmodell
das Template und erschloss die Projektwerte bei jedem Lauf neu.

**Was entstanden ist (1.1.0, unveröffentlicht):**

- **Renderer (`plugins/coding-kit/scripts/template-sync.sh render`, POSIX sh):** liest
  Core-Tabelle und Modul-Kontrakt aus dem MANIFEST und schreibt die reine
  Instanziierung in einen leeren Ordner, dazu eine Liste „Ziel, managed/seed,
  core/module". Er setzt die Modul-Teile ein (justfile ersetzt, Modul-Tools ans Ende von
  `[tools]`, gitignore- und CI-Teil direkt unter ihren Marker, `files/**` laut Policy
  samt Pfad-Platzhaltern), ersetzt Platzhalter literal (auch `&`, `/`, `\`), löst
  `optional`-Blöcke auf und setzt den Fragment-Slot zusammen. Ohne `--seeds` schreibt er
  nur managed Ziele, mit `--seeds` auch die seed-Dateien. Mehrdeutige Antworten
  (doppelte Schlüssel, Tab oder `{{` im Wert, unbekanntes Modul oder Fragment) und
  unaufgelöste Platzhalter weist er ab; unbekannte Schlüssel ergeben eine Warnung. Ein
  voller Render dauert etwa 0,25 s.
- **Antworten-Datei:** MANIFEST § Answers legt `.claude/template-answers` fest
  (`KEY=value`; Platzhalterwerte plus `MODULE`, `VISIBILITY`, `OPTIONAL`, `FRAGMENTS`).
  Abgeleitet und nie gespeichert: `PROJECT_NAME_SNAKE`, `CODEQL_LANGUAGES` (aus dem
  `MODULE.md`; ohne Wert entfällt jedes Ziel, das ihn braucht, sodass docs-only keinen
  CodeQL-Workflow bekommt), `TEMPLATE_VERSION` und die Lizenzblöcke.
- **MANIFEST § Module contract:** exakte Einsetzregeln (Reihenfolge, Leerzeilen,
  Marker). Die Policy-Tabelle im `MODULE.md` nennt jede Datei mit vollem Pfad; ihr
  erstes Wort (`managed`/`seed`) ist maschinenlesbar. Im Python-Modul steht jetzt
  `src/{{PROJECT_NAME_SNAKE}}/py.typed`. Ältere Templates mit kurzem Dateinamen rendert
  der Renderer weiter, solange der Name eindeutig ist.
- **TBD-Lizenz** (Fund aus der Gegenprobe, mit Freigabe mitgenommen):
  `core/CONTRIBUTING.md` verwies bei Lizenz TBD auf eine `LICENSE`-Datei, die es dann
  nicht gibt; ein Projekt hatte den Satz beim Anlegen deshalb von Hand umformuliert.
  Jetzt gibt es zwei optionale Blöcke `license` und `license-tbd`; der Renderer wählt aus
  `LICENSE_SPDX`. Projekte mit Lizenz rendern byte-gleich wie unter 1.0.0.
- **Kit:** Die Versionsregel zählt `plugins/coding-kit/scripts/` zum Plugin-Inhalt; die
  Formulierung in `CLAUDE.md`, README, `docs/skill-authoring.md` und im CHANGELOG-Kopf
  ist nachgezogen. Der Validator prüft Plugin-Skripte (ausführbar, `sh -n`), die
  Datei-Policies der Module (jede Datei genau einmal, voller Pfad, `managed`/`seed`) und
  ob der Renderer jeden Modul-Teil des MANIFEST kennt. `just check` führt
  `tests/template-sync/run.sh` aus: 164 Prüfungen, je 82 unter dash und bash.
- **Version:** `plugin.json` 1.1.0, CHANGELOG-Eintrag mit `### Template`.

**Verifikation:** Ein Render des Templates 0.13.2 aus der Kit-Historie (`c55460e`) mit
den Werten zweier Bestandsprojekte: Beim docs-only-Projekt sind alle 16 managed Dateien
byte-gleich mit dem Bootstrap-Commit, beim ts-node-Projekt 26 von 28. Die zwei
Abweichungen sind Handkonkretisierungen beim Anlegen (`adapt`-Stelle in `SECURITY.md`,
TBD-Satz in `CONTRIBUTING.md`), keine Renderfehler; geprüft im Scratchpad, ohne
Projektdaten im Repo. Fehlerinjektion: drei eingebaute Fehler im Renderer
(Tool-Einfügung, Fragment-Trenner, public-only) und fünf im Validator (fehlende
Policy-Zeile, falsches Policy-Wort, Kurzname, unbekannter Modul-Teil, Skript nicht
ausführbar) werden erkannt. `just check`, Versionsregel und gitleaks grün.

**Notable decisions:**
- Renderer statt Sprachmodell: gleiche Antworten ergeben byte-gleiche Dateien —
  Voraussetzung für Snapshot und Merge (F-041b).
- Lizenzblock aus `LICENSE_SPDX` abgeleitet statt einer Formulierung für beide Fälle:
  Kein Satz ist mit und ohne `LICENSE`-Datei richtig, und eine Ableitung kann kein Skill
  vergessen.
- Tests in `just check` (rund 5 s) statt nur in der CI, damit der Pre-Commit
  Renderfehler abfängt.
- Nur POSIX-awk, kein shellcheck (GPL). Ubuntu nutzt mawk; das prüft erst die CI.
- `.github/workflows/ci.yml` blieb unverändert, obwohl im Plan genannt: Die CI ruft
  bereits `just check` auf.

**Im selben Commit:** Plan F-041c/F-041d ergänzt (Antworten und Registry bei
Fragment-Einbau und Lizenzwahl; render → merge auch bei aktuellem Stempel), F-042 ins
Backlog.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh` (neu),
`tests/template-sync/run.sh` (neu), `plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/CONTRIBUTING.md`,
`plugins/coding-kit/template/modules/python/MODULE.md`, `scripts/validate.py`,
`scripts/version-rule.py`, `justfile`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`plugins/coding-kit/CHANGELOG.md`, `CLAUDE.md`, `README.md`, `docs/skill-authoring.md`,
`PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-041b — Merge und Erkennung (2026-10-24)

Teil von F-041 (Projektzusätze in managed Dateien erhalten und Abweichungen früh
erkennen; F-041a erledigt, F-041c–e folgen).

**Problem:** Der Renderer liefert die Soll-Fassung, aber noch nichts vergleicht oder
mergt sie mit dem Projekt. Es fehlten der Merge je Datei, die Erkennung von Abweichungen,
das Setzen des Basis-Snapshots und eine Basis für die Erst-Migration.

**Was entstanden ist (1.1.0, unveröffentlicht):**

- **`merge PROJECT SOLL OUT`:** je Ziel `git merge-file -p --diff3` aus Basis-Snapshot
  (`.claude/template-base/<Ziel>.base`), Projekt und gerenderter Soll-Fassung. Die
  Ergebnisse landen in einem leeren Ordner, dazu je Datei eine Zeile mit Klasse,
  Konfliktzahl und Registry-Art. Klassen: `identical`, `template-only`, `project-only`,
  `merged`, `caught-up`, `conflict`, `kept`, `two-way`, `new`, `missing`, `removed`,
  `skipped`. `keep`-Zeilen lösen Konflikte mit `--ours`, `skip`-Zeilen bleiben unberührt.
- **Normalisierung:** Vergleich und Merge laufen auf LF-Kopien mit Endzeilenumbruch. Der
  Inhalt des Fragment-Slots wird ausgeblendet und nach dem Merge mit der Projektfassung
  wieder eingesetzt; ein Slot ohne Ende bleibt unmaskiert. `--diff-algorithm=histogram`
  nur, wenn git es kann (ab 2.44).
- **`status` und `changed`:** vergleichen Projekt und Snapshot (`unchanged`, `deviates`,
  `missing`, mit Registry-Art und Diffstat). `changed` beschränkt sich auf die Dateien,
  die der Arbeitsbaum gegenüber HEAD berührt, plus neue, und meldet Handänderungen am
  Snapshot als `snapshot-edited`. Ohne Snapshot endet beides mit Exit 3.
- **`snapshot`:** setzt die Basis bestätigter Ziele auf die Soll-Fassung oder entfernt
  sie, wenn das Template das Ziel nicht mehr rendert.
- **`base-from-history`:** exportiert das Template einer Version aus der Historie eines
  coding-kit-Checkouts, und zwar den Stand des neuesten Template-Commits mit dieser
  Version (`plugin.json` ab 1.0.0, davor `template/VERSION`).
- **Registry-Parser:** liest die Files-Tabelle (`## Files`) in
  `convention-overrides.md`: Pfade oder Globs (Komma-Listen, Backticks, `*` passt auch
  auf `/`), Art `skip`, `keep`, `adapt` oder leer; unbekannte Arten werden abgewiesen.
  Im MANIFEST legt F-041c das Format fest.
- **Kit:** `just check` ruft `validate` und `test` auf. Der Pre-Commit-Hook führt die
  Skript-Tests nur aus, wenn Skript, Template oder Tests gestaged sind (lefthook-`glob`).
  Die Tests sind aufgeteilt in `run.sh` (Gerüst), `render.sh` und `sync.sh`.
  `CONTRIBUTING.md`, README und CHANGELOG sind nachgezogen.

**Verifikation:** 282 Prüfungen, je 141 unter dash und bash. Abgedeckt sind fehlende
Endzeile, CRLF, beidseitiges Anhängen (Konflikt), leere und fehlende Basis, gleiche
Änderung, `keep`, `skip`, Glob-Zeilen, Fragment-Slot, `changed` an einem echten
Git-Repo und `base-from-history` für 0.11.2, 0.13.2 und 1.0.0. Fehlerinjektion: Vier
eingebaute Fehler im Skript (CR-Normalisierung, Registry, Slot-Maskierung, vertauschte
Klassen) werden erkannt. Abnahme an einer Scratch-Kopie des docs-only-Projekts (Basis =
Render von 0.13.2 aus der Historie, Soll = Arbeitsstand): `mise.toml` ist `merged` ohne
Konflikt (Python bleibt, `lockfile_platforms` kommt dazu), `justfile` und `.gitignore`
sind `project-only`, drei Dateien `caught-up`; die Skip-Zeilen greifen, es entstehen
keine Konfliktmarker. Für alle Versionen vor 1.0.0 geprüft: Template-Inhalt änderte sich
nie ohne Versionssprung, die Suchregel von `base-from-history` hält. Der lefthook-Glob
ist geprüft: Skript- und verschachtelte Template-Dateien lösen die Tests aus, eine
README-Änderung nicht.

**Notable decisions:**
- Eine leere Basis zählt als Basis (beidseitig hinzugefügt → Konflikt), nur eine fehlende
  Basis bedeutet zweiwegig — allein die fehlende Datei sagt „keine gemeinsame Herkunft".
- Gegenüber der Planskizze kamen die Klassen `project-only`, `two-way`, `kept` und
  `removed` dazu; der Skill stellt für jede eine andere Frage.
- Ergebnisse immer mit LF und Endzeilenumbruch: Die `.gitattributes` des Templates setzt
  `eol=lf`.
- Kein eigener `apply`-Befehl: Ergebnisse übernimmt der Skill nach Bestätigung per Kopie.
- Skript-Tests im Pre-Commit nur bei passenden Dateien statt immer (rund 13 s); die CI
  und `just check` testen weiter vollständig.

**Im selben Commit:** F-041c um die Wahl der Migrationsbasis ergänzt (standardmäßig die
Stempel-Version, auf Wunsch eine ältere, damit früher abgelehnte Änderungen erneut
angeboten werden). Anlass: Der F-039e-Sync hatte drei Dateien des docs-only-Projekts
nicht angefasst, sein Stempel steht trotzdem auf 1.0.0.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`tests/template-sync/run.sh`, `tests/template-sync/render.sh` (neu, aus `run.sh`),
`tests/template-sync/sync.sh` (neu), `justfile`, `lefthook.yml`,
`plugins/coding-kit/CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.

### F-041c — Vertrag und update-conventions (2026-10-24)

Teil von F-041 (Projektzusätze in managed Dateien erhalten und Abweichungen früh
erkennen; F-041a–b erledigt, F-041d–e folgen).

**Problem:** Renderer und Merge gab es, aber weder Vertrag noch Skill nutzten sie. Das
MANIFEST kannte keinen Snapshot und keine Registry-Arten; `update-conventions` verglich
zweiwegig, durchsuchte ohne Argument alle Projektordner und brach bei aktuellem Stempel
ab.

**Was entstanden ist (1.1.0, unveröffentlicht):**

- **MANIFEST `manifest-format: 2`:** Abschnitt Base snapshot (Ablage `<Ziel>.base` samt
  Begründung der Endung, Inhalt, Merge, berechnete Abweichung, generiert) und Abschnitt
  Deviation registry (Tabellen Files und Rules, Arten `skip`, `keep`, `adapt` oder leer,
  Revision). `managed` heißt jetzt Drei-Wege-Merge; der `override`-Marker gilt nur noch
  für seed-Zonen und Fragmente; § Version stamp beschreibt Render und Merge auch bei
  aktuellem Stempel sowie die Migration.
- **Template-Inhalt:** Registry-Vorlage mit erklärendem Kopf (Zone `overrides-head`) und
  den Tabellen Files und Rules; `.gitattributes` mit
  `.claude/template-base/** linguist-generated=true`; `.claude/README.md` (Registry,
  `template-answers`, `template-base/` mit dem `git diff --no-index`-Tipp); HOW-TO (Zeile
  `/update-conventions`, drei Dateien in der Tabelle der wichtigen Dateien); Fragmente
  `nextjs` und `astro`: Abweichungen an managed Dateien als `keep` registrieren, die
  Import-Ausnahme in die Rules-Tabelle.
- **`update-conventions` neu:**
  - Argumente: ohne Angabe nur das aktuelle Projekt (sonst fragen statt suchen), Pfad
    oder Name, `alle`, `status`, `revise`, Sichtbarkeits-Prämisse eines Aufrufers.
  - A2: Update-Fenster ohne Abbruch bei aktuellem Stempel, Antworten gegen das Projekt
    prüfen, render → merge, Entscheidung je Klasse (übernehmen / diesmal nicht /
    dauerhaft ablehnen; Konflikt mit Lösungsvorschlag oder `keep`), Fragmente wie bisher,
    seed-Zonen aus `render --seeds`, entfernte Ziele, Snapshot setzen, Registry-Revision,
    Abschluss mit Lock-Abgleich und Stempel. Der Modus `status` schreibt nichts.
  - A3 Migration: Antworten aus dem Projekt zurückgewinnen; Basis aus der
    Template-Historie (Stempel-Version oder älter; Checkout aus `--plugin-dir`, per Pfad
    oder als Klon nach OK) oder einmal zweiwegig; Registry in die zwei Tabellen
    überführen; Altprojekt-Migrationen.
- **Skript:** `status` und `merge` nehmen mit `--base DIR` eine gerenderte Basis statt des
  Snapshots, damit der Status-Modus und die Migrationsvorschau nichts ins Projekt
  schreiben; Tests dazu.
- **`new-project`:** Formatprüfung auf 2.
- **Validator:** prüft die MANIFEST-Abschnitte, die Registry-Tabellen (Kopfzeilen) und die
  `.gitattributes`-Zeile.
- **Begleitend (add-skill):** README-Zeile von `update-conventions` und die
  Discovery-Hinweise (`alle`); CHANGELOG 1.1.0 mit `### Template`.

**Verifikation:** `just check` grün (296 Prüfungen). Fehlerinjektion im Validator: ein
fehlender Abschnitt Base snapshot, eine umbenannte Rules-Tabelle und eine fehlende
`.gitattributes`-Zeile werden gemeldet. Nicht-interaktiver Test mit
`claude -p --plugin-dir plugins/coding-kit` an einer Kopie des docs-only-Projekts
(`/coding-kit:update-conventions status` ohne Projektangabe; Bash erlaubt, Write/Edit
gesperrt): Migrationsvorschau mit zurückgewonnenen Antworten und Basis 1.0.0 aus der
Kit-Historie; `.gitignore`, `justfile` und `mise.toml` als `project-only`, nicht
registriert; nur dieses Projekt bearbeitet; `git status` der Kopie danach leer. Der
Agent empfahl von sich aus die Basis 0.13.2, damit die beim F-039e-Sync übersprungene
`lockfile_platforms`-Änderung wieder angeboten wird.

**Notable decisions:**
- „Diesmal nicht" setzt keinen Snapshot, der nächste Lauf bietet die Änderung wieder an.
  „Dauerhaft ablehnen" setzt ihn und verlangt eine Registry-Zeile mit Grund — so bleibt
  eine Ablehnung sichtbar.
- `--base` statt eines vorläufigen Snapshots im Projekt: Status-Modus und
  Migrationsvorschau bleiben schreibfrei.
- seed-Zonen aus `render --seeds` statt von Hand instanziiert: dieselbe Quelle wie für
  die managed Dateien.
- Die HOW-TO-Zeile für `step-done` folgt in F-041d mit dem Backstop. `choose-stack` prüft
  das Manifest-Format nicht; umgestellt wurden nur `update-conventions` und `new-project`.
- Der Plan-Modus taugt nicht für den Abnahmetest, weil Render und Merge ins
  Temp-Verzeichnis schreiben; geprüft wurde deshalb mit erlaubtem Bash und gesperrten
  Schreib-Werkzeugen. Die Plan-Datei aus dem ersten Versuch ist entfernt.

**Geänderte Dateien:** `plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/.claude/{convention-overrides.md,README.md}`,
`plugins/coding-kit/template/core/.gitattributes`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`,
`plugins/coding-kit/template/modules/standards/{nextjs,astro}.md`,
`plugins/coding-kit/skills/{update-conventions,new-project}/SKILL.md`,
`plugins/coding-kit/scripts/template-sync.sh`, `tests/template-sync/sync.sh`,
`scripts/validate.py`, `plugins/coding-kit/CHANGELOG.md`, `README.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.

### F-041d — Übrige Skills (2026-10-24)

Teil von F-041 (Projektzusätze in managed Dateien erhalten und Abweichungen früh
erkennen; F-041a–c erledigt, F-041e folgt).

**Problem:** Nach F-041c arbeitete nur `update-conventions` mit Snapshot, Antworten und
Registry. `new-project` legte Projekte noch ohne beides an, `choose-stack` setzte
Modul-Teile von Hand ein, `step-done` bemerkte geänderte managed Dateien nicht, und
Fragment-Einbau, Lizenz- und Sichtbarkeitswechsel hielten die Antworten nicht aktuell.

**Was entstanden ist (1.1.0, unveröffentlicht):**

- **`new-project` § 4b:** Antworten-Datei schreiben und `render --seeds` ins Projekt
  kopieren. Von Hand bleiben die `template:adapt`-Stellen (je konkretisierter managed
  Datei eine `adapt`-Zeile), der Lizenztext (bei TBD die gerenderte LICENSE löschen) und
  die Begleithandlungen. Danach den Snapshot aus dem managed Render setzen; `status`
  prüft, dass nur die `adapt`-Dateien abweichen. Antworten und Snapshot gehören in den
  Erst-Commit. Der Trockenlauf zeigt die Zielliste aus `render --seeds`.
- **`choose-stack` Modus B:** Modulwechsel über eine Kopie der Antworten (`MODULE=<neu>`),
  Render und Merge gegen den Snapshot; seed-Dateien des Moduls nur anlegen, wenn sie
  fehlen; danach `MODULE` in den Antworten und den Snapshot nachziehen. Ohne Antworten
  oder Snapshot zuerst die Migration über `update-conventions`. § Begleithandlungen:
  Fragmente, die das Modul nicht deklariert, kommen in `FRAGMENTS`; ändert eine
  Begleithandlung managed Dateien, gehören `keep`-Zeilen in die Registry.
- **`step-done` § 1b:** `changed` nach dem Review; je unregistrierter Abweichung den Diff
  gegen den Snapshot zeigen und registrieren, zurücknehmen oder dem Template vorschlagen
  anbieten. Handänderungen am Snapshot sind ein Fehler, außer der Schritt war ein Lauf
  eines Skills, der ihn setzt. Nie blockierend. § 1a weist beim Fragment-Vorschlag
  `FRAGMENTS` und `keep`-Zeilen mit aus, ebenso `prep-step` § 2a.
- **`choose-license`:** setzt im Bestandsprojekt `LICENSE_SPDX` in den Antworten. Die
  lizenzabhängigen managed Dateien findet ein Render mit alter und neuer Antwort; nur sie
  werden über den Merge übernommen und im Snapshot gesetzt.
- **`go-public`:** `VISIBILITY=public` in den Antworten im Nachzug-Commit; der
  Abschluss-Check prüft es.
- **Doku:** Baustein „Hilfsskripte" in `docs/skill-authoring.md`; README (Repo-Baum mit
  `scripts/` und `tests/`, Zeilen für new-project, step-done, choose-stack,
  choose-license); HOW-TO-Zeilen für `/step-done`, `/choose-stack` und
  `/choose-license`; CHANGELOG.

**Verifikation:** `just check` grün (296 Prüfungen).

- § 4b per Skript nachgestellt (ts-node, public): Der Snapshot entspricht allen 30
  gerenderten managed Zielen; `status` zeigt danach nur `SECURITY.md` und
  `CODE_OF_CONDUCT.md`, beide als `adapt`.
- `nextjs`-Einbau nach der neuen Mechanik nachgestellt: Ohne Zeilen gibt es vier
  unregistrierte Abweichungen (`tsconfig.json`, `biome.json`, justfile, `.gitignore`),
  der Slot zählt nicht; mit `keep`-Zeilen keine mehr; `FRAGMENTS=nextjs` rendert das
  Fragment in den Slot.
- `step-done` mit `claude -p --plugin-dir plugins/coding-kit` an einem Scratch-Projekt mit
  geänderter `mise.toml`: `changed` meldet `mise.toml deviates none`; der Skill zeigt den
  Diff gegen den Snapshot, bietet die drei Wege an und läuft ohne Blockade bis zur
  Commit-Frage.
- `choose-license` TBD → Apache-2.0 auf dieselbe Weise: Antworten, `LICENSE`,
  `CONTRIBUTING.md` und dessen Basis sind nachgezogen. Der Agent renderte alt und neu,
  mergte und übernahm nur `CONTRIBUTING.md`.

**Notable decisions:**
- Die lizenzabhängigen Dateien ergeben sich aus dem Vergleich zweier Renders statt aus
  einer Liste im Skill — kommt eine neue Datei mit `LICENSE_SPDX` dazu, braucht der Skill
  keine Änderung.
- `choose-stack` verlangt Antworten und Snapshot und verweist sonst auf die Migration,
  statt ohne Basis zu mergen.
- `snapshot-edited` ist erwartet, wenn der Schritt ein Lauf von update-conventions,
  new-project, choose-stack oder choose-license war.
- HOW-TO: neben `/step-done` auch `/choose-stack` und `/choose-license` nachgezogen, weil
  sich ihr Verhalten in Projekten sichtbar ändert.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{new-project,choose-stack,step-done,prep-step,choose-license,go-public}/SKILL.md`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`, `docs/skill-authoring.md`,
`README.md`, `plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-041e — Test, Release, Gegenprobe (2026-10-24)

Schließt F-041 ab (Projektzusätze in managed Dateien erhalten und Abweichungen früh
erkennen; F-041a–d siehe darunter).

**Problem:** Snapshot, Merge und Skills waren gebaut und einzeln getestet, aber noch nicht
an echten Projekten durchgespielt, nicht veröffentlicht und beim Nutzer nicht
installiert.

**Was entstanden ist (Release 1.1.0):**

- **Migrationstests an Kopien** (`claude -p --plugin-dir`, nicht-interaktiv, die
  Entscheidungen standen im Prompt):
  - docs-only-Projekt (Stempel 1.0.0, angelegt mit 0.13.2): Basis 0.13.2 aus der
    Kit-Historie; `mise.toml` ist `merged` (Python-Pin bleibt, `lockfile_platforms` kommt
    dazu), `justfile` und `.gitignore` sind mit Grund registriert, die nicht
    instanziierten Dateien als `skip`; Snapshot mit 16 Basen, `just check` grün.
  - ts-node-Projekt (Stempel 0.13.2): `mise.toml` zusammengeführt (der projekteigene
    `[env]`-Block bleibt); `justfile`, `.gitignore` und `privacy-lint.sh` unangetastet;
    Alt-Registry in 9 Files- und 2 Rules-Zeilen überführt; Snapshot mit 27 Basen. Alle
    Docker-freien Prüfungen sind grün, `biome ci` läuft mit Snapshot ohne Fehler (die
    `.base`-Endung wirkt). `stack-check` war schon vorher nur wegen fehlendem Docker rot.
- **Funde aus den Tests, in `update-conventions` nachgezogen:** eine Mischbasis für die
  Migration (Dateien des letzten Syncs aus der Stempel-Version, die übrigen aus der
  älteren); Fragmente, die es in der Basis-Version noch nicht gab, fallen beim
  Basis-Render weg; Schreibzugriffe unter `.claude/` fragt Claude Code einzeln ab — ohne
  Freigabe bereitet der Skill die Dateien vor und nennt den Kopierbefehl, nie umgehen
  (ein Testagent hatte die Sperre per Shell umgangen).
- **Release:** CHANGELOG datiert (`8a67f22`), Push von sechs Commits nach Personendaten-,
  gitleaks- und Versionsregel-Prüfung. Die CI ist grün; die Skript-Tests liefen dort zum
  ersten Mal unter Ubuntu (296 Prüfungen, dash und bash). Plugin beim Nutzer auf 1.1.0
  aktualisiert; der Cache enthält `scripts/template-sync.sh` (ausführbar) und ist mit dem
  Repo dateigleich.
- **Gegenprobe:** `/coding-kit:update-conventions` am echten docs-only-Projekt mit
  Mischbasis: Stempel 1.1.0, Snapshot mit 16 Basen, Plattformliste in `mise.toml`
  angekommen, die drei Projektdateien als `keep` registriert, Alt-Registry überführt
  (vier Dateien `skip`, eine Regel). `status` zeigt keine unregistrierte Abweichung. Der
  erste Aufruf lief noch mit dem Skill aus 1.0.0 (Session vor dem Plugin-Update
  gestartet) und durchsuchte deshalb alle Projekte; nach `/reload-plugins` lief 1.1.0 ohne
  jede Suche über andere Projekte.

**Notable decisions:**
- Der Plan-Modus taugt nicht für Migrationstests; geprüft wurde mit nicht-interaktiven
  Läufen in Wegwerf-Kopien.
- Release vor dem Abschluss-Eintrag: Die Gegenprobe braucht das installierte 1.1.0, also
  erst Release-Commit und Push, dann Gegenprobe und Verbuchung.
- Die drei übrigen Downstream-Projekte (Stempel 0.13.2) folgen jetzt; ihre Migration ist
  keine Aufgabe im Kit.

**Geänderte Dateien:** `plugins/coding-kit/CHANGELOG.md` und
`plugins/coding-kit/skills/update-conventions/SKILL.md` (im Release-Commit),
`PROGRESS.md`, `PROGRESS-ARCHIVE.md`.
