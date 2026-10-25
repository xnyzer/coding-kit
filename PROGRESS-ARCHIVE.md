# coding-kit — Progress-Archiv

Abgeschlossene Aufgaben mit Detail und Begründung. Neueste oben.

Seit F-039 liegen Plugin und Template in einem Repo; dieses Archiv führt beide Reihen
zusammen:

- **`F-NNN`** — Aufgaben des Kits; die Nummern zählen weiter (FEATURE-INDEX in der
  `PROGRESS.md`).
- **`TPL-NNN`** — Aufgaben des früheren project-template-Repos bis 0.16.0, dort als
  `F-NNN` geführt und hier umbenannt, damit Suchen eindeutig bleiben. Die
  Commit-Messages der importierten Template-Historie tragen dieselben Nummern. Diese
  Einträge sind englisch wie das Template-Repo und stehen nicht im FEATURE-INDEX.
- Verweise zwischen beiden Reihen sind entsprechend umgeschrieben; „coding-kit F-NNN"
  in einem TPL-Eintrag meint eine Kit-Aufgabe.

---

## F-042b — `detect` im Skript (2026-10-25)

Teil von F-042 (Neue Sprachen und Frameworks erkennen und Vorlagen nachziehen; F-042a
siehe darunter, F-042c–d folgen).

**Problem:** Der Signal-Vertrag aus F-042a stand, aber nichts las die Signale eines
Projekts: prep-step und step-done glichen Dependencies von Hand mit dem Katalog ab,
update-conventions gar nicht.

**Was entstanden ist (1.2.0, unveröffentlicht):**

- **`template-sync.sh detect [--changed] TEMPLATE PROJECT [SIGNAL…]`:** eine Zeile je
  Treffer, `<module|fragment> <name> <covered|declined|missing> <Signal (erster
  Fundort[ +weitere])>, …`, Module zuerst. Die Deklarationen kommen aus den
  `Signals:`-Zeilen der `MODULE.md` und der Auslöser-Spalte des Katalogs; Typen werden
  geprüft, PyPI-Namen normalisiert.
- **Leser:** `package.json` mit einem kleinen Tokenizer (auch minifiziert, nur die vier
  Dependency-Tabellen der obersten Ebene); `pyproject.toml` (Dependencies von
  `[project]`, `[project.optional-dependencies]` und `[dependency-groups]` ohne Strings in
  Inline-Tabellen, Poetry-Tabellen ohne `python`, Kommentare in mehrzeiligen Arrays);
  `requirements*.txt` (ohne Optionen, URLs und Pfade); `go.mod` (`require` einzeln und
  als Block, ohne `// indirect`, ein Pfad mit `/vN` zählt auch ohne Suffix); `[tools]`
  und `[tools.NAME]` der `mise.toml` bzw. `.mise.toml`; Dateimuster als sh-Glob auf Name
  oder Pfad.
- **Dateiliste:** `git ls-files`, getrackt plus ungetrackt und nicht ignoriert, ohne
  gelöschte Dateien und ohne `.claude/template-base/`; Manifeste zählen in jeder Tiefe.
- **Zustände:** `covered` nach `MODULE` der Antworten bzw. nach dem `fragment:NAME`-Marker
  im Slot (Marker außerhalb zählen nicht), `declined` nach einer Rules-Zeile
  `module:NAME`/`fragment:NAME` (Backticks optional), sonst `missing`. Ohne Antworten-Datei
  entfällt die Modul-Prüfung, mit Hinweis auf stderr.
- **`--changed`** liest Arbeitsbaum und HEAD gleich und meldet nur Signale, die HEAD nicht
  hatte; eine neue Hauptversion eines bekannten Go-Moduls ist damit nicht neu, ohne
  Commit ist alles neu. **Übergebene Signale** prüfen geplante Dependencies ohne Baum und
  ohne git; ein `file:`-Signal nennt einen geplanten Pfad.
- **Validator:** Die Typliste `SIGNAL_TYPES` im Skript muss der Tabelle in MANIFEST
  § Detection entsprechen — nicht im Plan genannt, verhindert aber, dass ein neuer Typ im
  Vertrag still unerkannt bleibt.
- **Tests:** `tests/template-sync/detect.sh`, 64 Prüfungen je Shell: alle Leser mit
  Treffer und Nicht-Treffer, Snapshot- und Ignore-Ausschluss, ungetrackte Dateien,
  Slot-Grenze, Ablehnungen, `--changed` mit und ohne HEAD, übergebene Signale samt
  Fehlerfällen und je Modul ein frisch gerendertes Projekt, das nur sein eigenes Modul
  als `covered` meldet. Die Suite läuft jetzt in rund 21 statt 13 s.
- **CHANGELOG:** Eintrag 1.2.0 um `detect` und die Validator-Prüfung ergänzt.

**Verifikation:** `just check` grün (Validator, 424 Prüfungen unter dash und bash). An
einer Scratch-Kopie des docs-only-Projekts: `module python missing tool:python
(mise.toml)`, mit der Zeile `module:python` in Rules `declined`; die Kopie ist gelöscht.
Fehlerinjektion: acht eingebaute Fehler (`// indirect`, Snapshot-Ausschluss,
`--changed`-Abzug, Kleinschreibung, Dependency-Tabellen, Go-Suffix, Slot-Grenze,
Ablehnungen) werden alle von Tests gefangen; eine abweichende Typliste meldet der
Validator.

**Notable decisions:**
- Template-Pfad als Argument wie bei `render` statt `detect PROJECT`: Die Skills haben ihn
  aufgelöst, die Tests brauchen ihn.
- `--changed` vergleicht den ganzen Baum mit HEAD statt nur die berührten Dateien: Eine
  Dependency, die ein anderes Manifest schon hatte, gilt so nicht als neu.
- Fundort je Signal als erster Pfad plus Anzahl weiterer, damit Zeilen auch in Monorepos
  lesbar bleiben.
- Beim ersten Testlauf hing der pyproject-Leser: `emit()` überschrieb mit seinem eigenen
  `match()` die Position der Schleife. Behoben; der Fall aus den Fixtures läuft durch.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`tests/template-sync/detect.sh` (neu), `tests/template-sync/run.sh`,
`scripts/validate.py`, `plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.

---

## F-042a — Signal-Vertrag und Daten (2026-10-25)

Teil von F-042 (Neue Sprachen und Frameworks erkennen und Vorlagen nachziehen; F-042b–d
folgen).

**Problem:** Die Auslöser des Fragment-Katalogs mischten Paket- und Dateinamen ohne Typ
(`nginx` konnte Paket, Ordner oder Image meinen), und die Module nannten gar keine
Signale. Ein Skript kann so nicht deterministisch abgleichen, und eine Sprache ohne ihr
Modul fiel nie auf.

**Was entstanden ist (1.2.0, unveröffentlicht):**

- **MANIFEST § Detection (neu):** Signale als `type:value` — `npm:`, `pypi:` (normalisiert
  verglichen), `go:` (auch mit Hauptversions-Suffix `/vN`), `tool:` für `[tools]` der
  `mise.toml`, `file:` für Dateimuster (mit `/` gegen den Pfad ab Root). Quelle ist die
  Dateiliste aus git (getrackt plus ungetrackt und nicht ignoriert, ohne
  `.claude/template-base/`); Manifeste zählen in jeder Tiefe. Zustände `covered` (Modul
  = `MODULE` der Antworten, Fragment-Marker im Slot), `declined` (Rules-Zeile) und
  `missing`; ohne Antworten-Datei entfällt nur die Modul-Prüfung. Eine Sprache ohne ihr
  Modul ist Werkzeugsprache: Modul mit Grund ablehnen, Toolchain als `keep`.
- **MANIFEST § Deviation registry:** Rules-Zeilen `module:NAME`/`fragment:NAME` sind
  maschinenlesbar und lehnen einen Erkennungs-Vorschlag dauerhaft ab; die Kopfzone der
  Registry-Vorlage (`overrides-head`) erklärt das. § Module contract und § Standards
  fragments verweisen auf § Detection.
- **Fragment-Katalog:** alle Auslöser typisiert, `audit-logging` (Eigenschaft)
  unverändert. `docker`: `file:Dockerfile*`, `file:*.Dockerfile` und Compose-Varianten
  inklusive `compose.yaml`; `nginx`: `file:nginx*.conf` und `file:*nginx/*` statt des
  mehrdeutigen `nginx`; `api-design`: `npm:@nestjs/core` statt `nestjs` (kein npm-Paket,
  hätte nie getroffen).
- **`api-design` für Python und Go** (Fund beim Bauen, mit Freigabe mitgenommen): Das
  Fragment ist sprachunabhängig, wurde aber nur von npm-Frameworks ausgelöst. Neu sind
  `pypi:fastapi`, `pypi:flask`, `pypi:django`, `pypi:litestar` und die Go-Frameworks Gin,
  Echo, chi und Fiber — ohne Versions-Suffix, daher die `/vN`-Regel für `go:`.
- **Module:** `Signals:`-Zeile im `MODULE.md` — `ts-node`: `file:package.json`,
  `file:tsconfig.json`, `tool:node`; `python`: `file:pyproject.toml`,
  `file:requirements*.txt`, `tool:python`; `go`: `file:go.mod`, `tool:go`; `docs-only`:
  `(none)`. Stubs bleiben ohne. `modules/README.md` erklärt die Zeile (nicht im Plan
  genannt, gehört zum selben Vertrag).
- **Validator:** liest die Signal-Typen aus der Tabelle in § Detection; prüft die
  Katalog-Zeilen (nur typisierte Signale in Backticks oder genau ein
  Eigenschafts-Auslöser) und die Module (Status `full`/`stub` aus `modules/README.md`,
  volle Module mit Zeile, Stubs ohne, Signale in Backticks).
- **Version:** `plugin.json` 1.2.0, CHANGELOG-Eintrag mit `### Template`.

**Verifikation:** `just check` grün (Validator, 296 Skript-Tests unter dash und bash).
Fehlerinjektion an einer Scratch-Kopie: unbekannter Typ (`nmp:next`), untypisierte
nginx-Zeile, go ohne `Signals:`-Zeile, java-Stub mit Zeile und ein Signal ohne Backticks
— alle fünf gemeldet (sechs Funde, die nginx-Zeile hatte zwei Fehler).

**Notable decisions:**
- Die Signal-Typen stehen nur im MANIFEST; der Validator liest sie von dort, damit
  Vertrag und Prüfung nicht auseinanderlaufen. `detect` (F-042b) muss genau diese Typen
  kennen.
- `go:` trifft jede Hauptversion des Modulpfads, damit Katalog-Signale ein Major-Release
  überstehen.
- Der Modul-Status kommt aus `modules/README.md` (`full`/`stub`), keine zweite
  Markierung im `MODULE.md`.
- prep-step § 2a, step-done § 1a und die Template-HOW-TO sprechen noch von
  Dependency-Signalen; inhaltlich stimmt das weiter, umgestellt wird in F-042c.

**Geänderte Dateien:** `plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/modules/standards/README.md`,
`plugins/coding-kit/template/modules/README.md`,
`plugins/coding-kit/template/modules/{ts-node,python,go,docs-only}/MODULE.md`,
`plugins/coding-kit/template/core/.claude/convention-overrides.md`,
`scripts/validate.py`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

---

## F-041e — Test, Release, Gegenprobe (2026-10-24)

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

---

## F-041d — Übrige Skills (2026-10-24)

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

---

## F-041c — Vertrag und update-conventions (2026-10-24)

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

---

## F-041b — Merge und Erkennung (2026-10-24)

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

---

## F-041a — Renderer (2026-10-24)

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

---

## F-039e — Test, Release, Gegenprobe (2026-10-24)

Schließt F-039 ab (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039a–d siehe darunter).

**Problem:** Die Umstellung war gebaut, aber weder im echten Betrieb getestet noch
veröffentlicht; project-template lief parallel weiter.

**Was entstanden ist (Release 1.0.0):**

- **Lokaler Test:** `update-conventions` ohne Schreibrechte (`claude -p --plugin-dir …
  --permission-mode plan`) an der Kopie eines docs-only-Projekts mit Stempel 0.13.2:
  Template aus dem Plugin, Version 1.0.0, Update-Fenster 0.13.3–0.16.0 aus dem
  eingefrorenen Abschnitt plus 1.0.0 `### Template`, Schritt 8 leer, Ziel-Stempel 1.0.0;
  keine Freigabe-Abfrage blockierte das Lesen des Templates außerhalb des Projekts. Der
  `new-project`-Trockenlauf aus F-039c galt weiter.
- **Funde aus dem Test:** kein Zusammenführen von Projektzusätzen in managed Dateien, nie
  eingetragene Abweichungen — als F-041 aufgenommen und nach einem unabhängigen
  Design-Review auf einen Drei-Wege-Merge mit Basis-Snapshot umgeplant (nach 1.0.0, als
  1.1.0); dazu: `update-conventions` ohne Argument nur für das aktuelle Projekt.
- **Release:** CHANGELOG datiert (`b09549f`), Push von 45 Commits nach Personendaten-,
  gitleaks- und Versionsregel-Prüfung; CI grün (Validator und Versionsregel); Plugin beim
  Nutzer auf 1.0.0 aktualisiert, der Cache enthält alle 78 Template-Dateien identisch zum
  Repo.
- **Gegenprobe:** `/update-conventions` am echten docs-only-Projekt: CODING-STANDARDS,
  HOW-TO und `.claude/README.md` übernommen, drei Projektdateien einmalig gelassen (bis
  F-041), Stempel 1.0.0, `just check` grün. Im Projekt zusätzlich die Override-Zeile ohne
  `private/README.md` (die Datei ist identisch mit dem Template, die Ausnahme steht in der
  Projekt-CLAUDE.md).
- **project-template:** README-Hinweis auf coding-kit gepusht, Repo archiviert
  (Template-Einstellung bleibt, die „generated from"-Labels bestehender Projekte bleiben
  gültig), lokaler Checkout entfernt; im CHANGELOG vermerkt.

**F-039 im Ganzen (a–e):** Template-Historie importiert (`TPL-NNN`), Dokumente
zusammengeführt, Skills lesen das Template aus `${CLAUDE_PLUGIN_ROOT}/template`, der
Vertrag zwischen Skills und Template wird mechanisch geprüft, die Versionsregel läuft vor
jedem Commit und in der CI, eine Version für alles ab 1.0.0. Entscheidungen der Planung:
Repo bleibt `coding-kit` (Marketplace und Renovate-Preset hängen am Namen); kein Override
für die Template-Arbeit, sondern `claude --plugin-dir`; Stempel-Auflösung über die
MANIFEST-Tabelle statt Git-Historie; `template/VERSION` entfällt; CHANGELOG ab 1.0.0
deutsch mit `### Template`, darunter beide alten Reihen eingefroren.

**Verifikation:** CI-Lauf auf `b09549f` grün; Cache-Ordner 1.0.0 mit `template/`
(78 Dateien) identisch zum Repo; Gegenprobe-Projekt auf 1.0.0 mit grünem `just check`;
GitHub-API: project-template `archived: true`, `is_template: true`.

**Notable decisions:**
- 1.0.0 vor F-041 freigegeben — F-041 wurde groß (Merge-Skript, Renderer,
  `manifest-format: 2`, Migration) und hätte 45 ungepushte Commits tagelang lokal
  gehalten (Entscheidung des Nutzers).
- Kein echter `--template`-Versuch am archivierten Repo, weil er ein Repo angelegt hätte;
  betrifft nur Plugins unter 1.0.0.
- project-template nur archiviert, nicht gelöscht.

**Geänderte Dateien:** `plugins/coding-kit/CHANGELOG.md` (Release-Datum, Archiv-Vermerk),
`PROGRESS.md`, `PROGRESS-ARCHIVE.md`; außerhalb des Repos: README im project-template-Repo,
Override-Zeile im Gegenprobe-Projekt.

---

## F-039d — Repo-Doku und Regeln (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039e folgt).

**Problem:** Regeln und Doku des Kits beschrieben noch zwei Repos — das Template als
Schwester-Repo, die Sync-Invariante nur für Skills und Hooks, die Einfrier-Regel für
project-template, die README mit Template-Klon und `CODING_KIT_TEMPLATE_REPO`.

**Was entstanden ist (repo-lokal plus eine Template-Datei):**

- **`CLAUDE.md`:** Überblick und Strukturregel für das Template im Plugin (Zugriff nur
  über `${CLAUDE_PLUGIN_ROOT}/template`, MANIFEST als geprüfter Vertrag); Sprachgrenze
  nennt `template/**` und den CHANGELOG; Publishing-Hygiene um „Downstream-Projekte nie
  beim Namen nennen", registrierte Platzhalter und die Blocklist ergänzt; Versionsregel
  statt Sync-Invariante (Template, `### Template`, MANIFEST-Pflege, `just version-rule`);
  Nummern-Regel für `TPL-NNN`; Graphiti-Hinweis auf die alte group_id
  `project-template`; Test mit `--plugin-dir`; Einfrier-Regel entfernt.
- **`README.md`:** Einleitung (ein Scaffolding-System, Template im Plugin seit 1.0.0);
  „Ohne GitHub" ohne Template-Klon — statt `cp -r project-template` ein leerer Ordner
  mit `git init`; Skill-Tabelle (`new-project` befüllt ein leeres Repo,
  `update-conventions` mit Update-Fenster, `choose-stack` braucht kein GitHub mehr);
  Personal-Config ohne `CODING_KIT_TEMPLATE_REPO`; Repo-Baum mit `template/`, CHANGELOG,
  `scripts/version-rule.py` und PROGRESS; Pflege-Abschnitt mit Versionsregel und
  `--plugin-dir`.
- **`CONTRIBUTING.md`:** Versionsregel für Skills, Hooks und Template; „Where
  conventions originate" und „Rules for template content" aus der CONTRIBUTING des
  Templates übernommen; Template-Zugriff und Test für Skills.
- **`docs/skill-authoring.md`:** Muster „Template nur über
  `${CLAUDE_PLUGIN_ROOT}/template`, die Variable wird nur im Skill-Text ersetzt";
  Template-Inhalt englisch; Versionsregel; Test mit `--plugin-dir` und
  `/reload-plugins`.
- **`docs/renovate-preset.md`:** Dogfooding ohne Template-Repo; Renovate-PRs an
  Template-Pins brauchen Versions-Bump und `### Template`; CHANGELOG-Pfad.
- **`add-skill`:** Schritt 3 zieht die HOW-TO im selben Commit nach und nennt sie unter
  `### Template` (statt Vermerk in F-039); CHANGELOG-Pfad und Versionsregel; Schritt 4
  testet mit `--plugin-dir`.
- **`marketplace.json`:** Beschreibungen nennen Template, `/new-project` und
  `/update-conventions`.
- **Template `core/.claude/README.md`:** Der Abschnitt `template-version` nennt den
  Stempel jetzt coding-kit-Version (CHANGELOG 1.0.0 unter `### Template`).

**Verifikation:** `just check` grün; interne Links und Anker der geänderten Doku geprüft
(keine toten); grep: außer Historie, Archiv, eingefrorenem CHANGELOG und Plan-Einträgen
nennt nichts project-template als Quelle; gitleaks ohne Fund.

**Notable decisions:**
- Die Template-Datei `core/.claude/README.md` in diesem Schritt korrigiert — direkte
  Folge der Stempel-Änderung aus F-039c, deshalb kein eigener Eintrag.
- „Downstream-Projekte nie beim Namen nennen" aus der Template-CLAUDE.md ins Kit
  übernommen — genau das hatte der Blocklist-Fund in F-039a gezeigt.
- In F-039c liefen die Skill-Änderungen ohne `/add-skill`; die Checkliste wurde hier
  nachträglich geprüft, offen waren nur README-Zeilen und das Authoring-Muster —
  beides erledigt.

**Geänderte Dateien:** `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`,
`docs/skill-authoring.md`, `docs/renovate-preset.md`, `.claude/skills/add-skill/SKILL.md`,
`.claude-plugin/marketplace.json`, `plugins/coding-kit/template/core/.claude/README.md`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

---

## F-039c — Skills und Vertrag auf das gebündelte Template (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039d–e folgen).

**Problem:** Die Skills suchten das Template in einem lokalen Checkout oder klonten es von
GitHub, `new-project` legte Repos per `gh repo create --template` an, und
`update-conventions` löste alte Stempel über die Git-Historie eines Checkouts auf — alles
Annahmen aus der Zeit zweier Repos.

**Was entstanden ist (Plugin 1.0.0, unveröffentlicht):**

- **`choose-stack` § 0:** Template = `${CLAUDE_PLUGIN_ROOT}/template`, Version aus
  `plugin.json`; kein Klon, kein Checkout, kein Override. Hinweis, dass die Variable nur
  im Skill-Text ersetzt wird; Arbeit am Template per `claude --plugin-dir`.
  Known-limitation-Abgleich gegen das Plugin-CHANGELOG.
- **`new-project`:** leeres Repo per `gh repo create … --clone` (Branch-Prüfung auf
  `main`), Quellen relativ zu `${CLAUDE_PLUGIN_ROOT}/template`, „Aufräumen" ersetzt
  durch „nur Manifest-Ziele", Stempel und `TEMPLATE_VERSION` aus `plugin.json`,
  Erst-Commit `feat: bootstrap from coding-kit <Version> (<Modul> module)`. Den toten
  Verweis auf den Optional-Block `security-tool` gestrichen (im Template seit 0.2.0
  entfernt, TPL-Commit `380aaa1`).
- **`update-conventions`:** § 0 auf das gebündelte Template; Update-Fenster aus den
  `### Template`-Abschnitten, Stempel unter 1.0.0 zusätzlich aus dem eingefrorenen
  Template-Abschnitt, leeres Fenster → nur neu stempeln; A2.8 über MANIFEST § Removed
  and renamed targets statt Git-Historie; Übernahme-Vorschlag an eine
  coding-kit-Session bzw. als Issue an das Repo aus der `homepage` in `plugin.json`;
  Ausweichpfad für ein MANIFEST ohne § Seed sections entfernt.
- **Übrige Skills:** `define-requirements` (Katalog und REQUIREMENTS-Skelett aus dem
  Plugin), `choose-license` (mitgelieferte LICENSE), `go-public` (kein
  Template-Checkout mehr).
- **MANIFEST:** Einleitung (eine Version mit dem Plugin), `TEMPLATE_VERSION` aus
  `plugin.json`, Sync direction an das coding-kit-Repo, neue Tabelle
  `## Removed and renamed targets` (leer), § Version stamp auf Plugin-Version und
  CHANGELOG-Fenster.
- **HOW-TO (Template, managed):** Nachzug aus F-038a — `/step-done` verbucht nach
  Vorschau und einer Freigabe mit der Commit-Message, `/add-feature` startet auch
  Claude, eingetragen wird nach OK.
- **Validator:** Vertragsprüfungen als eigene kleine Funktionen — `manifest-format`
  gegen die Formatangaben der Skills, Core-Tabelle ↔ Dateien unter `template/core/`,
  Seed-Inventar ↔ Section-Marker, Plausibilität der Tabelle für entfernte/umbenannte
  Ziele, Optional-Blöcke (MANIFEST „used" ↔ Template ↔ Skills),
  `${CLAUDE_PLUGIN_ROOT}/…`-Pfade in Skills.
- **Versionsregel:** Verlässt ein Ziel die Core-Tabelle, verlangt sie eine Zeile für die
  aktuelle Version in `## Removed and renamed targets`.
- **CHANGELOG 1.0.0** mit Abschnitt `### Template` (HOW-TO); `plugin.json`-Description
  nennt das Template.

**Verifikation:** `just check` grün. Fehlerinjektion in Scratch-Kopien: 9
Vertragsfälle und 3 Optional-Block-Fälle werden gemeldet, die echte Fassung ist grün.
grep: kein Skill nennt mehr den lokalen project-template-Checkout, `gh repo clone` des
Templates oder `CODING_KIT_TEMPLATE_REPO`. Headless-Trockenlauf (`claude -p
--plugin-dir plugins/coding-kit --permission-mode plan`, `/coding-kit:new-project
dry-run`): Template `plugins/coding-kit/template`, Version 1.0.0, `manifest-format: 1`,
`gh repo create … --clone` ohne `--template`, 31 Core-Ziele (privat, ohne public-only)
plus python-Modul, Erst-Commit `bootstrap from coding-kit 1.0.0`; der Lauf fand dabei
den `security-tool`-Verweis. `claude plugin validate` grün (einzige Warnung: fehlendes
Icon, schon bei 0.20.0).

**Notable decisions:**
- `prep-step`, `step-done` und `check-upstreams` unverändert: Sie verweisen auf
  `/choose-stack` § 0 bzw. auf das Kit-Repo, das bleibt richtig.
- Issue-Ziel aus der `homepage` in `plugin.json` statt aus `gh api user` — deklarierte
  Quelle statt Ableitung aus dem eigenen Konto.
- Prüfung „entferntes Core-Ziel ohne Tabellenzeile" in der Versionsregel statt im
  Validator, weil sie einen Diff braucht.
- Den `security-tool`-Fund in diesem Schritt behoben, samt Prüfung, statt ins Backlog
  (Entscheidung des Nutzers) — eine Abweichung zwischen Skill und Template ist genau
  das, was F-039 abstellen soll.
- Ein leerer Klon übernimmt den Default-Branch des Remotes (lokal geprüft); die
  Anleitung prüft trotzdem auf `main`, weil die CI-Vorlage darauf triggert.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{choose-stack,new-project,update-conventions,define-requirements,choose-license,go-public}/SKILL.md`,
`plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`, `scripts/validate.py`,
`scripts/version-rule.py`, `plugins/coding-kit/CHANGELOG.md`,
`plugins/coding-kit/.claude-plugin/plugin.json`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

---

## F-039b — Dokumente zusammenführen (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039c–e folgen).

**Problem:** Nach dem Import standen zwei Aufgabenreihen nebeneinander — PROGRESS und
Archiv des Kits hier, die des Templates nur noch in der Historie —, und die offenen
Kit-Einträge planten noch mit Übergaben zwischen zwei Repos (F-035).

**Was entstanden ist (repo-lokal, nur lebende Doku):**

- **Archiv:** Kit- und Template-Archiv zu einem zusammengeführt — 55 Einträge (27 Kit,
  28 Template), neueste oben, bei gleichem Datum nach dem Commit, der den Eintrag
  angelegt hat. Template-Einträge heißen `TPL-NNN` (86 Verweise umbenannt, 5 Kit-Verweise
  blieben); in Kit-Einträgen 5 Template-Nummern umgestellt („project-template TPL-020",
  „(dortiges TPL-016)"). Neuer Kopf erklärt beide Reihen; zwischen allen Einträgen jetzt
  `---`.
- **Done-Tabelle:** Zeilen bis F-038b entfernt (alle im Archiv), F-039a bleibt als erste
  Zeile von 1.0.0; Hinweis auf das Archiv über der Tabelle.
- **Offene Einträge:** F-024, F-025, F-032, F-033, F-034, F-036 und F-037 auf das
  Ein-Repo-Modell umgeschrieben — Template-Gegenstücke „im selben Commit" statt
  Übergabe, Pfade als `template/core/…`, der Paarungs-Prüfer aus F-035 gestrichen;
  F-025 braucht keinen Template-Checkout mehr.
- **F-026:** in F-039 aufgegangen (Aktualität, Klontiefe und Herkunft des Templates);
  der Rest — Kit-Repo-Herkunft in `check-upstreams` — steht jetzt in F-032. Eintrag
  entfernt, Index-Zeile markiert, Reihenfolge angepasst.

**Verifikation:** Alle 27 Kit- und 28 Template-Done-Zeilen haben einen Archiv-Eintrag
(per Skript gegen die Archiv-Überschriften geprüft); in TPL-Einträgen stehen nur die
fünf Kit-Verweise auf `F-`, in Kit-Einträgen kein unumbenannter Template-Verweis;
`just check` grün. Die Entwürfe hat der Nutzer vorab gesehen und freigegeben.

**Notable decisions:**
- F-039a bleibt in der Done-Tabelle — sie gehört schon zu 1.0.0; der Neustart betrifft
  nur alte Zeilen (Entscheidung des Nutzers).
- In Kit-Einträgen nur die Nummer ersetzt („project-template TPL-020"), keine Sätze
  umformuliert.
- Reihenfolge im Archiv per Merge zweier bereits sortierter Listen — die Reihenfolge
  innerhalb jedes Archivs bleibt erhalten.

**Geänderte Dateien:** `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

---

## F-039a — Import und Grundgerüst (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039b–e folgen).

**Problem:** Bevor Skills und Doku auf ein Repo umgestellt werden können, müssen
Historie, Inhalt und Prüfwerkzeug des Templates im Kit liegen — mit grünen Checks.

**Was entstanden ist (1.0.0, unveröffentlicht):**

- **Historien-Import:** project-template (37 Commits, bis 0.16.0) auf einem Scratch-Klon
  per `git filter-repo --to-subdirectory-filter plugins/coding-kit/template`
  umgeschrieben und per `git merge --allow-unrelated-histories` übernommen
  (Merge-Commit `b7b9fcd`). In den Commit-Messages heißen die Template-Nummern
  `TPL-NNN`; die drei Verweise auf Kit-Nummern blieben (kein Umbenennen nach „kit ",
  „kit's ", „its ", „there as "). Vor dem Merge: gitleaks über die Historie, Blocklist
  über Patches und Messages, Adressen, Pfade, IPs — ohne Befund.
- **Bereinigung:** Repo-eigene Template-Dateien entfernt (Governance-Doku, Tooling,
  `.github/`, `.claude/`, `scripts/`, `private/`, README, CLAUDE.md, CHANGELOG, PROGRESS,
  Archiv, VERSION). Übrig: `MANIFEST.md`, `core/`, `modules/` (78 Dateien). PROGRESS und
  Archiv des Templates bleiben für F-039b über `b7b9fcd` lesbar.
- **CHANGELOG:** nach `plugins/coding-kit/CHANGELOG.md` (liegt damit im Plugin-Cache).
  Der Kopf erklärt die eine Version, den Abschnitt `### Template` und die eingefrorenen
  Abschnitte; Eintrag 1.0.0 (unveröffentlicht); darunter „Eingefroren:
  coding-kit-Plugin bis 0.20.0" (21 Einträge) und „Eingefroren: project-template bis
  0.16.0" (25 Einträge), Überschriften je eine Ebene tiefer; TPL-Regel auch hier.
- **Validator (`scripts/validate.py`):** Template-Checks übernommen und auf
  `plugins/coding-kit/template/` beschränkt (Marker-Paare, Fragment-Deklarationen,
  Katalog). Platzhalter-Registry aus MANIFEST § Placeholders statt fester Liste (behebt
  die `LIVING_DOC_LANGUAGE`/`LANG_*`-Drift); Registry-Platzhalter in Template-Inhalt und
  allen Markdown-Dateien erlaubt, sonst keine. Blocklist-Check repo-weit
  (`private/blocklist.txt`, gitignoriert, in der CI still übersprungen).
- **Versionsregel (`scripts/version-rule.py`, `just version-rule`):** Änderungen unter
  `plugins/coding-kit/{skills,hooks,template}/` verlangen eine Version über dem
  Vergleichsstand und einen `## <Version>`-Eintrag im CHANGELOG. Pre-Commit
  (`--staged`, Basis = Upstream, sonst HEAD) als lefthook-Job; CI (`--since` mit der
  Basis von PR bzw. Push, `fetch-depth: 0`).
- **Version:** `plugin.json` 1.0.0.
- **Nebenbei:** Der jetzt repo-weite Blocklist-Check fand im Archiv-Eintrag F-011 den
  Namen eines Downstream-Projekts (öffentlich seit Plugin 0.7.0) — neutral
  umformuliert; die Historie bleibt (Entscheidung des Nutzers).

**Verifikation:** `git log -- plugins/coding-kit/template/VERSION` zeigt 25 Stände,
`git show <ältester Commit>:plugins/coding-kit/template/MANIFEST.md` liest das erste
MANIFEST. `just check` grün; `claude plugin validate plugins/coding-kit` grün (einzige
Warnung: fehlendes Icon, schon bei 0.20.0). Fehlerinjektion in einer Scratch-Kopie:
unbekannter und verirrter Platzhalter, offener Section-Marker, fehlendes MANIFEST und
Katalogdatei ohne Tabellenzeile werden gemeldet, ein Registry-Token in einem Skill
nicht. Versionsregel in acht Szenarien: fehlender Bump, fehlender CHANGELOG-Eintrag und
unbekannte Basis werden gemeldet; ungepushte Folge-Commits auf derselben Version,
reine Doku-Änderungen und neue Branches gehen durch.

**Notable decisions:**
- Versionsregel als eigenes Skript statt in `validate.py`: arbeitet auf `git diff` statt
  auf Dateien, braucht kein PyYAML und läuft getrennt im Pre-Commit und in der CI.
- Vergleichsbasis ist der gepushte Stand, nicht der vorige Commit — ein Release darf aus
  mehreren Commits bestehen (F-039 selbst).
- Merge-Commit ohne zusätzliche Änderungen; er besteht `just check` allein nicht, der
  Folge-Commit macht den Stand grün, dazwischen wird nicht gepusht.
- Kit-Verweise beim Umbenennen über eine Ausschlussregel statt einer Liste — an
  Messages, Archiv und CHANGELOG geprüft: genau die zehn bekannten Kit-Verweise bleiben
  `F-`.

**Geänderte Dateien:** `plugins/coding-kit/template/**` (Import, Bereinigung),
`plugins/coding-kit/CHANGELOG.md` (aus `CHANGELOG.md`),
`plugins/coding-kit/.claude-plugin/plugin.json`, `scripts/validate.py`,
`scripts/version-rule.py` (neu), `justfile`, `lefthook.yml`, `.github/workflows/ci.yml`,
`PROGRESS-ARCHIVE.md` (F-011 neutral), `PROGRESS.md`.

---

## F-038b — Repo-lokal: CLAUDE.md und add-skill (2026-10-23)

Schließt F-038 (Freigabe-Regel für PROGRESS-Einträge kit-weit) ab; der Plugin-Teil ist
F-038a (Plugin 0.20.0).

**Was entstanden ist (repo-lokal, kein Release):**

- **`CLAUDE.md`:** neue Strukturregel „PROGRESS nur mit Freigabe" — Vorschau und
  ausdrückliches OK für jeden neuen oder geänderten Eintrag in PROGRESS, Archiv und
  Index, auch wenn ein Skill ihn anlegt; Claude darf add-feature und add-skill selbst
  starten. Der Absatz zu `/add-skill` nennt jetzt Plugin- und repo-lokale Skills.
  Zusätzlich die Regel „project-template ist bis F-039 eingefroren" — Nachzüge werden in
  F-039 vermerkt; sie entfällt mit F-039.
- **`.claude/skills/add-skill/SKILL.md`:** `disable-model-invocation: false` explizit,
  Beschreibung und Einleitung sagen, dass Claude den Skill selbst starten darf;
  Freigabe-Gate mit Standardsatz; Interview fragt „Plugin oder repo-lokal?"; Schritt 2
  und 3 mit getrennten Wegen (repo-lokal: kein Bump, kein CHANGELOG, keine
  README-Skill-Zeile); fehlende F-Nummer wird **vor** dem Bauen über add-feature angelegt
  statt „spätestens beim Abschluss vergeben"; Schritt 3 (HOW-TO im Template) vermerkt
  den Nachzug in F-039, solange project-template eingefroren ist; Kontext-Recovery
  ergänzt.
- **`PROGRESS.md`, F-039:** zwei Punkte in der Lösungsskizze — HOW-TO-Nachzug aus F-038a
  (step-done mit Vorschau und Freigabe, add-feature auch von Claude gestartet) und
  Rückbau der Einfrier-Regel samt add-skill Schritt 3.

**Verifikation:** `just check` grün; `add-skill` erscheint mit neuer Beschreibung in der
Skill-Liste der laufenden Session.

**Notable decisions:**
- Einfrier-Regel in die CLAUDE.md statt nur in add-skill: jede Session liest sie, auch
  eine, die das Template ohne add-skill anfassen würde (Nutzerentscheidung, über den
  Plan hinaus).
- Die Frage „Plugin oder repo-lokal?" betrifft nur Sessions im Kit-Repo — add-skill
  liegt nicht im Plugin, Nutzer des Plugins sehen ihn nie.

**Geänderte Dateien:** `CLAUDE.md`, `.claude/skills/add-skill/SKILL.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.

---

## F-038a — Plugin: Freigabe-Gate und add-feature-Aufruf (2026-10-23)

Teil von F-038 (Freigabe-Regel für PROGRESS-Einträge kit-weit; F-038b — Kit-CLAUDE.md
und add-skill — folgt).

**Problem:** step-done schrieb Done-Zeile, Archiv-Eintrag und `(DONE)`-Marker ohne
Vorschau („Direkt tun, ohne zu fragen"). Zugleich hielt Claude add-feature für nur vom
Nutzer startbar, obwohl der Skill seit jeher `disable-model-invocation: false` trägt —
build-step („via add-feature … vorschlagen") und add-feature („Der Nutzer hat eine
Idee …") legten das nahe.

**Was entstanden ist (Plugin 0.20.0):**

- **`step-done`:** § 4 bereitet nur noch vor (mit Standardsatz Freigabe-Gate); neuer § 5
  „Freigabe, Verbuchung und Commit" — eine Frage mit Vorschau und Commit-Message,
  Antworten verbuchen und committen / nur verbuchen / Text ändern; nach OK schreiben,
  re-lesen, `just check`, committen. Autonome Ausnahme deckt Verbuchung und Commits der
  geplanten Substeps, neue Einträge werden nur gesammelt. Graphiti jetzt § 6, erst nach
  der Verbuchung; Commit-E-Mail und Co-Authored-By jetzt § 5a/5b.
- **`build-step`:** Scope-Schutz — add-feature selbst starten, autonom nur sammeln;
  Leitplanke Freigabe-Gate; Abschluss listet gesammelte Ideen; Start-Freigabe heißt
  „verbuchen und committen" (Frage, Goal-Zeile ohne Freigabe, `claude -p`-Beispiel,
  Modus-Erkennung, Recovery, description).
- **`add-feature`:** description und Einleitung „Wer startet" (Nutzer oder Claude),
  Freigabe-Gate inkl. autonomem Fall.
- **`docs/skill-authoring.md`:** Hinweis, dass der Text eines modellaufrufbaren Skills
  dem nicht widersprechen darf; neuer Pflicht-Baustein „Freigabe-Gate" mit Standardsatz.
- **Begleit-Änderungen:** `plugin.json` 0.20.0, `CHANGELOG.md`, `README.md`
  (Tabellenzeilen add-feature und step-done, Absatz „Freigabe für die PROGRESS").

**Verifikation:** `just check` grün, `claude plugin validate` grün (einzige Warnung:
fehlendes Icon, ohne Belang). grep über alle PROGRESS-schreibenden Skills: add-feature,
step-done, build-step tragen den Standardsatz; prep-step, define-requirements,
refine-requirements waren bereits mit eigener Formulierung gegated; teach-step und
check-upstreams schreiben nur über diese. Das Laufzeitverhalten ist noch ungetestet,
installiert ist 0.19.1 — Test per `claude --plugin-dir plugins/coding-kit` möglich.

**Notable decisions:**
- Standardsatz in jedem schreibenden Skill statt einer zentral referenzierten Regel —
  `docs/` liegt nicht im Plugin-Cache, Skills können es zur Laufzeit nicht lesen.
- Verbuchung und Commit in einer Frage, damit der Abschluss nicht zweimal fragt.
- prep-step, define-requirements, refine-requirements unverändert gelassen (bereits
  gegated, „sinngemäß gleich" laut Authoring-Doku); update-conventions ohne Standardsatz,
  weil es die PROGRESS nur innerhalb einer einzeln bestätigten Migration berührt.
- Nur § 3 von step-done wird von außen referenziert (new-project) — die Umnummerierung
  ab § 4 bricht nichts.

**Geänderte Dateien:** `plugins/coding-kit/skills/{step-done,build-step,add-feature}/SKILL.md`,
`docs/skill-authoring.md`, `README.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

---

## TPL-023 — Validator: catalog fragment contract + catalog/file consistency (2026-10-23)

**Problem:** `scripts/validate.py` checked that fragment markers are balanced (in every
file) and that fragments a `MODULE.md` declares exist, but not that each
`modules/standards/<name>.md` wraps its whole body in `fragment:<name>`, nor that the
catalog table in `modules/standards/README.md` and the fragment files match. A misnamed
marker breaks `/update-conventions` (it refreshes by marker name); a missing catalog row
means no skill ever proposes the fragment — both passed the gate.

**Implemented (1 file — repo tooling, no VERSION bump, as TPL-002c):**

- `scripts/validate.py`: `check_catalog(catalog_dir, findings)`, called from `main()` for
  `modules/standards/`, with two parts:
  - `check_fragment_files` — the file content (stripped) starts with
    `<!-- fragment:<stem> -->` and ends with the matching close; findings for a missing
    wrapper, content outside it, a wrapper named differently from the file (opening or
    closing marker), and a nested `fragment:` marker inside.
  - `check_catalog_table` — backticked names in the first column of the table inside
    `## Catalog` (up to the next `##` heading) vs. the `*.md` files, both directions.
  - Helper `display_path` (repo-relative, absolute outside the repo) so the checks also run
    against directories outside the repo. Module docstring lists all checks.

**Verification:** `just check` green on the real catalog (all eight fragments already
complied). Negative cases run against scratch fixtures (copies of the catalog, not in the
repo), each yielding exactly one finding:

| Case | Finding |
|------|---------|
| opening marker misnamed | `wrapper is named 'reakt', expected 'react' (the file name)` |
| closing marker misnamed | same finding |
| text after the wrapper | `content outside the fragment wrapper` |
| nested marker | `nested fragment marker inside the wrapper` |
| catalog row without file | `catalog row 'nginx' has no file nginx.md` |
| file without catalog row | `fragment has no row in the catalog table` |

Diff scanned for secrets and private data (clean).

**Notable decisions:**

- **Strict contract** (nothing but surrounding whitespace outside the wrapper): skills
  append the file verbatim, so anything outside would reach projects unmarked and could
  never be refreshed. Matches `MANIFEST.md` ("self-contained file whose body is wrapped").
- **No test suite:** the check takes the catalog directory as a parameter and was proven
  against fixtures at build time; a pytest setup for two functions was not worth new
  infrastructure (TPL-002c precedent).
- **Extra fixture case** (closing marker misnamed, beyond the plan) exposed a misleading
  message — it named the correct opener instead of the wrong closer; fixed to report the
  offending name.
- Pre-existing, left as is: ruff's `EXE001` (shebang on a non-executable file) — ruff is
  not part of the gate.

---

## TPL-022 — nextjs fragment: register managed-file deviations as overrides (2026-10-23)

**Problem:** On the `ts-node` module, a Next.js project has to deviate from managed files,
but the `nextjs` fragment only mentioned overrides for `agentRules` and imports.
`/update-conventions` would revert the unregistered deviations — the gap TPL-019 closed for
`astro`.

**Implemented:**

- `modules/standards/nextjs.md`: a new opening paragraph *Adopting Next changes managed
  files — do it in the adoption step*, mirroring `astro`. Each deviation is registered in
  `.claude/convention-overrides.md` in the same step:
  - `tsconfig.json` shaped for Next (bundler resolution, DOM libs, `next-env.d.ts` and the
    `.next` types in `include`, `next` plugin, `rootDir`/`include` matching `src/app` or
    `app/`), with the reason: Next rewrites it in place on every `next dev` / `next build` /
    `next typegen` unless it uses `extends` or `references`, yet leaves the non-fitting
    `lib` and `nodenext` resolution alone. Pointer to the installed
    `writeConfigurationDefaults.js` (not public API).
  - `justfile`: `dev` → `next dev`, `build` → `next build`, `next typegen` before
    `tsc --noEmit` in the gate.
  - `tsconfig.build.json` removed; `.next/` and `next-env.d.ts` in `.gitignore`.
  - `biome.json` explicitly unchanged.
  The `AGENTS.md` rule (with its binding order) and the *Imports* section are unchanged.
- Sync invariant: `VERSION` 0.15.0 → 0.16.0 (minor — a new rule, like TPL-019/TPL-021) +
  `CHANGELOG.md` entry (Added + Migration note for projects that adopted `nextjs` earlier).
  No `MANIFEST.md` change.

**Verification:** claims checked at prep time against the Next TypeScript docs, the source
of the published `next` package (`dist/lib/typescript/writeConfigurationDefaults.js`, read
for the current release) and the Biome domains docs. Edited section re-read; `just check`
green; diff scanned for secrets and private data (clean).

**Notable decisions:**

- **`biome.json` dropped from the list** (the intake sketch named it as a candidate):
  Biome's `next` domain activates automatically from the dependency, and generated files
  stay out through `useIgnoreFile`.
- **Order not binding**, unlike `AGENTS.md`: if Next rewrites the file first, its edits land
  in the managed file but the fix is the same — the fragment says "ideally before the first
  `next dev`".
- **`next typegen` in the gate** (beyond the sketch): the route helper types (`PageProps`,
  …) only exist after `next dev` / `next build` / `next typegen`, so `tsc --noEmit` alone
  fails in a fresh checkout and in CI.
- **Minor instead of patch** (deviation from the sketch): the change adds a rule, it does
  not correct one.
- **Migration note added** to the CHANGELOG entry (not in the plan): projects that adopted
  `nextjs` before 0.16.0 learn what to register and what to add.

---

## TPL-019 — Standards fragment astro (2026-10-23)

**Problem:** The catalog had no fragment for Astro. A project that adopted Astro got no
guidance on the static-first/islands model, Astro's built-in CSP, its asset pipeline or how
`.astro` files enter the quality gate, and nothing recorded that Astro's bundler resolution
contradicts the `.js`-extension rule of the `ts-node` fragment.

**Implemented:**

- `modules/standards/astro.md` (new, wrapped in `fragment:astro`): an adoption-time
  requirement up front, then four sections — *Static first, islands only where needed*
  (`client:*` preference, `client:only` names its framework, state via a store library,
  React islands also under `react`, personal data never prerendered), *Strict Content
  Security Policy* (`security.csp`, no `'unsafe-inline'`/`'unsafe-eval'`, verify with
  `build` + `preview`, `<ClientRouter />` and Shiki not covered, `set:html` vs `set:text`,
  header-only directives from the proxy → `nginx`), *Build & quality gate* (client-side
  imports as the shipped set, sharp/libvips licensing, self-hosted fonts, conditional
  service-worker rule, `astro check`, Biome's documented `.astro` override) and *Imports*
  (extensionless, recorded as an override against `ts-node`).
- `modules/standards/README.md`: catalog row
  `| astro | Static-first sites: islands, strict CSP, build & quality gate, images | astro |`.
- Sync invariant: `VERSION` 0.14.1 → 0.15.0 (minor, new catalog content) + `CHANGELOG.md`
  entry (Added). No `MANIFEST.md` change — fragment files are not listed individually
  (TPL-013 precedent). No module declares the fragment; projects retrofit it via
  `/choose-stack` or `/prep-step`.

**Verification:** version-dependent claims checked at prep time against the current Astro
docs (configuration and directives reference, fonts guide), Biome's language-support page
and the npm registry, not from memory. Fragment markers and line widths checked by hand —
the validator only resolves catalog fragments a `MODULE.md` declares, and none declares
`astro`. `just check` green; diff scanned for secrets and private data (clean).

**Notable decisions:**

- **Companion action in the fragment** (beyond the intake sketch): on the `ts-node` module
  an Astro project deviates from three *managed* files — `tsconfig.json` (extends
  `astro/tsconfigs/strict`), `biome.json` (`.astro` override) and the `justfile` gate
  (`astro check`, devDependencies `@astrojs/check` + `typescript`). The fragment requires
  registering each in `.claude/convention-overrides.md` in the adoption step, otherwise
  `/update-conventions` reverts them and `.astro` files drop out of the gate; plus
  `.astro/` in `.gitignore`. No binding order (unlike `nextjs`' `AGENTS.md`). The HOW-TO
  needed no change — since TPL-017 its rows describe companion actions generically.
- **Draft corrections:** "dependencies are shipped to browsers" reworded (the scaffold lists
  `astro` itself under `dependencies`); "personal data always `client:only`" widened to
  client-side *or* on-demand rendering; project-specific notions (load budget, third-party
  notice list) made conditional; the intake's "Text" (i18n) section dropped as not
  Astro-specific.
- **No version numbers in the text:** CSP named by its config key `security.csp`, Biome's
  rule list marked "currently" with a pointer to its docs, no service-worker integration
  named (`@vite-pwa/astro` peers stop at Astro 5).
- **Follow-up candidate (not built):** the `nextjs` fragment has the same gap — its managed
  tsconfig/Biome/gate deviations are not registered as overrides; to be proposed via
  `/add-feature`.

---

## TPL-018 — HOW-TO: state where the workflow skills come from (2026-10-23)

**Problem:** The skill overview in `core/HOW-TO-CODE-WITH-CLAUDE.md` listed the workflow
skills without saying where they live. Only setup step 2 hinted at it in passing, so a
reader could look for them in the repository, did not learn the namespaced call form, and
did not see that the workflow also works without the plugin.

**Implemented:**

- `core/HOW-TO-CODE-WITH-CLAUDE.md`: one paragraph directly below `## Overview: skills` —
  the skills come from the coding-kit plugin (see *Contributor setup*); they can be called
  as `/coding-kit:<skill>`; the short form used throughout the file works as long as no
  other command or skill has the same name; without the plugin the workflow still works
  by hand (PROGRESS.md + `just` recipes, `just check` above all). Nothing else in the
  file changed.
- Sync invariant: `VERSION` 0.14.0 → 0.14.1 (patch) + `CHANGELOG.md` entry (Changed). No
  `MANIFEST.md` change.

**Verification:** edited sections re-read; `just check` green; diff scanned for secrets
and private data (clean).

**Notable decisions:**

- **Short form qualified** (deviation from the intake sketch, which presented both call
  forms as equal): the Claude Code docs name `/plugin-name:skill-name` as the plugin
  skill form and say the bare name works only "unless another command already uses that
  name" — relevant because downstream projects may add their own `.claude/skills/`.
- **Section reference instead of "setup step 2"** — survives renumbering of the setup
  steps.
- **Existing plugin mentions kept** (setup step 2, `.claude/skills/` row): both are short
  and sit where a reader needs them; no tightening.
- The HOW-TO has no copy in coding-kit, so no cross-repo counterpart was needed.

---

## TPL-021 — CODING-STANDARDS: readability over cleverness + secure coding beyond secrets (2026-10-23)

**Problem:** `core/CODING-STANDARDS.md` set no explicit bar for readability (simplest
viable solution, code written for the next maintainer), and §8 covered almost only
secrets — input validation, injection, authorization and least privilege were missing
from the core. coding-kit's F-034 makes the build skills apply the standard actively; the
content they apply has to come from this file (what applies lives here, when/how it is
checked lives in the skills).

**Idea:** Close both gaps by extending existing sections — no new section, so §1–§13 keep
their numbers (skills and fragments reference them, e.g. `api-design` → "core §8"). Terse
style: one bold rule plus one sentence, stack-neutral. Language-specific safe variants go
into the language fragments; `api-design` is de-duplicated against the new core rules.

**What was built (6 template files + sync):**

- `core/CODING-STANDARDS.md`
  - §1 (Mindset): *Simplest viable solution wins* (no abstraction or extension point on
    speculation — introduce it with the second real use case); *Write for the next
    maintainer* (yardstick: a teammate new to the code understands it without
    explanation).
  - §6 (Control flow): the nesting-depth rule covers conditionals **and loops**; new
    *Readable over clever* (no dense one-liners, long chains or nested loops that must be
    decoded before changing them — named intermediate steps or a helper instead).
  - §8 renamed "Secure coding & secrets"; five rules after the crypto rule: validate
    input at every trust boundary (allowlist), no injection paths (parameterised queries,
    argument-list process spawning, no `eval`, context-appropriate output encoding),
    authorize every access on the concrete resource, least privilege, secure by default
    (links §7 and §10 instead of restating them).
- `modules/standards/api-design.md`: validation and route authorization reference core §8;
  the "forbidden by default" list drops `eval`, shell strings and interpolated SQL and
  keeps the web-specific items (raw HTML, browser web storage, unstructured logging);
  "whitelist" → "allowlist".
- `modules/standards/nextjs.md`: "whitelist validation" → "allowlist validation".
- Language fragments, one *Safe calls (core §8)* line each — `python`: `subprocess` with an
  argument list, never `shell=True`; no `eval`/`exec`, `pickle` or `yaml.load` on untrusted
  data. `go`: `exec.Command` with separate args, never `sh -c` with foreign input;
  `database/sql` placeholders, never `fmt.Sprintf` into a query. `ts-node`:
  `execFile`/`spawn` over `exec`; no `eval`/`new Function`.
- Sync invariant: `VERSION` 0.13.3 → 0.14.0 (minor, new binding rules) + `CHANGELOG.md`
  entry (Added, Changed, Migration note). No `MANIFEST.md` change.

**Verification:** every edited section re-read; no stale "Security & secrets" heading or
"whitelist" left in template content; `just check` green; gitleaks clean.

**Notable decisions:**

- **No blanket ban on nested loops** (deviation from the intake sketch): a 2D grid walk is
  legitimate. The existing depth limit is extended to loops instead, and *Readable over
  clever* targets loops that have to be decoded.
- **§8 renamed** to "Secure coding & secrets" (user decision) — the section now covers
  far more than secrets; references go by number, so nothing breaks.
- **"No sensitive data in URLs" stays in `api-design`** (deviation from the sketch, which
  linked it to §7): §7 covers errors and internals, not URLs, and URLs are HTTP-specific.
- **Dynamic code execution moved into core §8** — it is language-neutral, so it left the
  `api-design` list together with shell strings and raw SQL.
- **`python` also forbids `pickle`/unsafe `yaml.load` on untrusted data** — unsafe
  deserialisation is Python's typical injection path; added beyond the sketch.
- `java`/`swift-ios` ship no language fragment yet, so they got no *Safe calls* line;
  `prisma` already covered parameterised SQL.
- Sequence agreed with the owner: TPL-021 → TPL-018 → TPL-019, one commit each.

---

## F-031 — mise.lock mit Plattform-Einträgen erzeugen (CI im --locked-Modus) (2026-10-23)

**Problem:** Projekte aus `/new-project` bekamen eine `mise.lock` nur mit Versionen, ohne
`[tools.X."platforms.*"]`-Einträge — `mise install` schreibt sie so. Sobald eine
`mise.lock` existiert, installiert die CI (`jdx/mise-action`) mit `--locked` und
scheiterte für jedes Tool mit „No lockfile URL found for <tool>@<version> on platform
linux-x64 (--locked mode)". Beobachtet bei einem Projekt aus project-template 0.13.2:
jeder CI-Lauf rot seit dem Bootstrap-Commit.

**Was entstanden ist (Plugin 0.19.1):**

- **`choose-stack` § Lock-Datei erzeugen und prüfen** (neu, einzige Fundstelle der
  Regel, nach dem Muster von § Begleithandlungen): nach `mise install` schlicht
  `mise lock`, ohne `--platform`; fehlt `lockfile_platforms` in der `mise.toml`, auf
  `/update-conventions` verweisen statt Flags zu setzen. Prüfung: jedes Tool hat einen
  `platforms.<p>`-Eintrag je Plattform aus `lockfile_platforms`; Lücke auf der Plattform
  des CI-Runners (aus `runs-on`) blockiert den Commit, übrige Lücken werden gemeldet und
  gegen „Known limitation" im Template-CHANGELOG abgeglichen.
- **`choose-stack` § 4** und **`new-project` § 4d:** `mise install && mise lock && …`
  plus Prüfung.
- **`update-conventions`:** A2.1 macht auch bei aktuellem Stempel den Lock-Abgleich;
  A2.9 prüft am Projektabschluss und bietet bei geänderter `mise.toml`, Lücken oder
  fehlender Lock-Datei `mise install && mise lock` an; A3.5 erzeugt und prüft ebenso.
- **Begleit-Änderungen:** `plugin.json` 0.19.1, `CHANGELOG.md`, `README.md`
  (Tabellenzeilen choose-stack und update-conventions).

**Verifikation:** mit mise 2026.10.6 an `core/mise.toml` aus project-template 0.13.3
geprüft — `mise install` schrieb 0 Plattform-Einträge, `mise lock` alle sieben
Plattformen je Tool; ein aus der `mise.toml` gestrichenes Tool verschwand bei
`mise lock` aus der Lock-Datei. `just check` grün. Ein Lauf gegen ein echtes Projekt
steht noch aus.

**Notable decisions:**

- **Kein `--platform`, anders als die Erfassungs-Skizze:** project-template TPL-020 hat
  `lockfile_platforms` zur einzigen Quelle der Plattformliste gemacht; ein Flag daneben
  würde die Liste doppelt führen. Renovate führt `mise lock` ebenfalls ohne Flag aus.
- **Lock-Abgleich unabhängig vom Stempel:** die Skizze ging von Projekten aus Template
  ≤ 0.13.2 aus. Auch Projekte aus Template 0.13.3, die Kit ≤ 0.19.0 angelegt hat, haben
  die Einstellung, aber eine Lock-Datei ohne Plattform-Einträge — ihr Stempel ist
  aktuell, der bisherige Kurzschluss „aktuell, fertig" hätte sie übersprungen.
- **Eine Fundstelle, drei Verweise** statt dreifacher Regel in den Skills.
- **Kein Guard in `just check`:** das justfile ist Template-Sache (managed); bei Bedarf
  als eigenes Template-Feature erfassen.
- **Kit-eigene `mise.toml` unverändert:** ihr Lock ist bereits vollständig, ein
  `lockfile_platforms` dort behebt keinen Fehler (User chose: Empfehlung übernommen).
- **Template-HOW-TO nicht nachgezogen:** sie beschreibt die Skills nur grob; die
  Lock-Prüfung ist dort ein Detail und rechtfertigt keinen eigenen Template-Release.

**Pairing:** project-template TPL-020 (VERSION 0.13.3). Die Paarungsprüfung aus F-035
steht noch aus (dort vermerkt).

---

## TPL-020 — mise.lock carries platform URLs for CI (2026-10-23)

**Problem:** `core/mise.toml` named `mise install` as the generator of `mise.lock`. That
is not reliable: for tools already installed on the machine it writes versions without
any download URLs, and a lockfile holding only some platforms keeps exactly that set
through every later `mise install` or plain `mise lock`. A downstream project created
from template 0.13.2 then failed in CI with
`No lockfile URL found for <tool>@<version> on platform linux-x64 (--locked mode)`.

**What was built (2 template files + sync):**

- `core/mise.toml`: header names `mise lock` as the generator and states that CI installs
  with `--locked` and needs a URL for every platform in `lockfile_platforms`;
  `[settings]` pins `lockfile_platforms` to the seven common mise platforms —
  `linux-x64`, `linux-x64-musl`, `linux-arm64`, `linux-arm64-musl`, `macos-x64`,
  `macos-arm64`, `windows-x64`.
- `MANIFEST.md` § Version stamp: `mise.lock` is generated with `mise lock`, the platform
  set comes from `lockfile_platforms`.
- Sync invariant: `VERSION` 0.13.3 (patch) + `CHANGELOG.md` entry (Fixed, Migration note,
  Not changed, Known limitation). No `MANIFEST.md` file-list change.

**Verification:** `core/mise.toml` combined with each module part (`go`, `python`,
`ts-node`) — plain `mise lock` wrote URLs for every tool on all seven platforms, except
pnpm on `macos-x64`. A lockfile holding only `macos-arm64` was repaired to the full set
by plain `mise lock`. `just check` green.

**Findings at prep (verified 2026-10-23 against mise 2026.10.6, Renovate 44.181.0,
`jdx/mise-action` v4.2.0):**

- `lockfile_platforms` exists since mise 2026.4.8. With it, `mise lock` covers the set
  plus the current platform; without it, plain `mise lock` keeps the platforms already in
  the lockfile (the common set only for a new one).
- Renovate's mise manager runs `mise lock <tools>` without `--platform`, so the setting
  governs its updates as well.
- `jdx/mise-action` adds `--locked` itself whenever the repository holds a `mise.lock`.
  The intake assumption that the template CI does not enforce the lock was wrong.

**Notable decisions:**

- **All seven platforms over a minimal set** (user decision): every OS, Intel Mac and
  Windows included, so no contributor's `mise lock` ever changes the platform set. The
  intake proposal had pinned only `linux-x64` + `macos-arm64`; a minimal set would have
  meant lockfile churn for every contributor outside it.
- **The setting is the single source of the set** — no `mise lock --platform …` in the
  header or the MANIFEST, unlike the intake sketch. A flag next to the setting would
  state the set twice and could drift.
- **No CI change.** An explicit `install_args: --locked` would duplicate what the action
  already does and add diff to every downstream workflow; recorded in the CHANGELOG under
  *Not changed*.
- **Migration stated once, in the CHANGELOG:** existing projects regenerate `mise.lock`
  with `mise lock`; coding-kit's `/update-conventions` (its F-031) executes that step,
  the command is the fallback until then.
- **Known limitation, not fixed here:** pnpm stopped publishing a `macos-x64` binary
  during the 11.x line, and the most recent releases also lack `linux-arm64-musl`.
  Projects on the `ts-node` module cannot lock or install pnpm there — an upstream gap.
  Installing pnpm another way (e.g. via the npm backend) would be a separate backlog item.

---

## F-028 — Utility-Skill handoff (2026-09-16)

**Aufgabe:** Am Kontextlimit wurde der Handoff an einen frischen Chat jedes Mal per Hand
angefordert („ausführlichen Handover-Prompt zum Kopieren, nur Kontext übergeben, nichts
bauen, nur noch nicht Dokumentiertes"). Das sollte ein projektunabhängiger Skill werden.
Direkt über `/add-skill` gebaut, ohne vorherigen Backlog-Eintrag.

**Was entstanden ist (Plugin 0.19.0):**

- **handoff** (`plugins/coding-kit/skills/handoff/SKILL.md`) — schreibt einen
  kopierfertigen Handoff-Prompt: Grundsatz (übergeben / verweisen / nie übergeben /
  ehrlich bleiben), elfteilige Gliederung in zwei Blöcken — **Orientierung** (Einstieg,
  Ziel, Zuletzt, Stand, Als Nächstes inkl. Reihenfolge-Vorgabe) vor **Hintergrund**
  (Entscheidungen, Fallstricke, Absprachen, Offen, Quellen) —, leere Abschnitte entfallen,
  Richtwert typisch bis ~150 Zeilen, feste Schlussanweisung („Stand bestätigen, auf
  Anweisung warten; steht die Anweisung schon in der Nachricht, loslegen"). Optionales
  Argument = Fokus bzw. geplanter nächster Schritt.
- **Begleit-Änderungen:** `plugin.json` 0.19.0 + Utility-Aufzählung, `CHANGELOG.md`,
  `README.md` (Tabellenzeile; veraltete Struktur-Zeile „Die vier Core-Skills" auf
  „Die Skills (ein Ordner je Skill)" korrigiert).

**Notable decisions:**

- **Maßstab je Zeile statt Themenliste:** „Würde der neue Chat ohne sie etwas falsch
  machen, doppelt tun oder erneut fragen?" — löst den Zielkonflikt „möglichst
  ausführlich, aber nicht überladen" an jeder einzelnen Zeile, nicht über eine Längenvorgabe
  allein. Dokumentiertes (Dateien, Git, CLAUDE.md, Memory, in der Session Geschriebenes)
  nur als Verweis.
- **Richtwert statt Klammer:** der erste Entwurf hatte 30–100 Zeilen. Die Untergrenze
  widersprach „leere Abschnitte weglassen" und hätte nach kurzen Sessions Füllstoff
  erzwungen; 100 Zeilen (grob 2–3 k Tokens) hätten nach langen Sessions ausgerechnet das
  „Warum" gekürzt. Überladen wird ein neuer Chat durch Kopien und vorsorgliches Lesen,
  nicht durch Länge. Ganz ohne Zahl wird es erfahrungsgemäß zu lang — daher „typisch bis
  ~150 Zeilen, nach kurzen Sessions deutlich weniger".
- **Orientierung vor Hintergrund:** im ersten Entwurf standen Stand, ausstehende
  Bestätigungen und nächster Schritt verstreut (Abschnitte 3, 7, 9) — der neue Chat las
  erst Entscheidungen, bevor er erfuhr, wo es weitergeht. Neu ist ausdrücklich
  **Zuletzt** (letzte Aktion und was darauf wartet): genau das steht in keiner Datei und
  nicht im git log.
- **Reihenfolge-Vorgabe generisch erkannt, nicht kopiert:** einige Projekte führen neben
  der Template-Konvention („offene Aufgaben in Ausführungsreihenfolge") eine eigene
  Reihenfolge — in zwei gefundenen Formen: eigene Überschrift mit Pfeilkette der
  F-Nummern bzw. Überschrift über der ganzen offenen Liste. Daher kein fester Wortlaut,
  sondern eine Überschriften-Suche (`reihenfolge|order`, an die Doku-Sprache anpassbar),
  gegen beide Formen und gegen ein Projekt ohne Vorgabe geprüft. Der Handoff nennt
  Fundstelle und nächsten Eintrag, kopiert die Vorgabe aber nicht — sie kann sich im
  neuen Chat ändern (z. B. durch step-done), die Datei bleibt maßgeblich. **Bewusst nicht
  aufgenommen:** die Vorgabe zur Kit-Konvention zu machen, die auch prep-step/build-step
  beachten — hier wirkt sie nur in Chats, die mit einem Handoff starten.
- **Kontextsparsam, weil der Skill genau am Limit läuft:** knapper Skill-Text; leeres
  Argument **ohne Rückfrage** (bewusste Abweichung vom sonst üblichen M1-Fallback wie bei
  refine-prompt — eine Rückfrage kostet den Kontext, der fehlt); höchstens ein
  Shell-Aufruf (Git-Stand plus Überschriften-Suche), keine Datei-Lesevorgänge. Kein
  M4-Block (einschrittig), kein Projektkontext-Schritt (Utility, soll auch außerhalb von
  Kit-Projekten und ohne Git laufen).
- **Hartes Schreibverbot** per `disallowed-tools: Write, Edit, NotebookEdit` (Muster wie
  teach-step) und ausdrücklich **kein Memory-Update**, obwohl die House-Defaults
  Graphiti-Speichern ohne Nachfrage vorsehen: Zusätzliche Aufrufe am Limit gefährden die
  Ausgabe selbst. Dokumentationsbedarf landet im Prompt unter „Offen" und wird im neuen
  Chat auf Anweisung erledigt.
- **„Quellen" statt „Zuerst lesen":** die genannten Dateien liest der neue Chat, sobald
  die Arbeit sie berührt — nicht vorsorglich, sonst startet er wieder überladen.
- **Ausgabe als ein Codeblock mit vier Backticks**, damit innere Code-Schnipsel die
  Kopiervorlage nicht zerbrechen.
- **Name `handoff`** (Nutzerwahl gegenüber `handover`/`context-handover`); nur manuell
  aufrufbar. **Nicht in project-templates HOW-TO** — wie refine-prompt Session-Werkzeug,
  weder Dev-Loop noch Projekt-Pflege.

**Verifikation:** `just check` grün (Frontmatter, JSON, Privacy); Secrets-/Privacy-Scan
des Diffs ohne Befund; Überschriften-Suche gegen zwei Projekte mit unterschiedlicher
Reihenfolge-Form (Treffer) und eines ohne Vorgabe (kein Treffer) geprüft. Ein Praxistest
steht noch aus: das installierte Plugin kommt vom GitHub-Marketplace, der Skill ist erst
nach Push + Plugin-Update (oder in einer Session mit `--plugin-dir plugins/coding-kit`)
aufrufbar.

---

## TPL-017 — HOW-TO sync for fragment companion actions (2026-08-11)

**Problem:** coding-kit 0.18.0 (its F-022) built the counterpart to 0.13.1 — a generic
mechanism that reads a fragment's install-time requirement at runtime and executes it in the
same step, formulated once in `/choose-stack § Begleithandlungen beim Fragment-Einbau` and
referenced from `new-project`, `prep-step § 2a`, `step-done § 1a` and `update-conventions`
step 6. `core/HOW-TO-CODE-WITH-CLAUDE.md`, which describes the skills for project users,
mentioned none of it.

**What was built (1 file + sync):**

`core/HOW-TO-CODE-WITH-CLAUDE.md`, three rows, each one clause: `/choose-stack` and
`/update-conventions` in the maintenance table, `/prep-step` in the dev-loop table. Sync
invariant: `VERSION` 0.13.2 + `CHANGELOG.md` naming the counterpart. `MANIFEST.md` untouched
— no files added, removed or re-policied.

**Notable decisions:**

- **`/prep-step` yes, `/step-done` no** — the discretionary call the task left open. Both
  tables answer "what will this skill do to my project", and `/prep-step` produces a plan the
  user confirms item by item; a fragment that also changes a project file makes the plan
  contain a change the row did not lead them to expect. `/step-done`'s backstop only *reports*
  a gap and never blocks, so nothing new reaches the user through it, and its row is one of
  the terse ones. Adding the clause there would have cost brevity for no user-visible effect.
- **No kit jargon in the rows.** They say "a fragment can require a change in the project
  itself", never "companion action" — the tables are written from the user's side, and the
  term belongs to the kit's internal vocabulary.
- **The optional catalog marker was declined.** Rationale in the `CHANGELOG` under *Not
  changed*: the requirement lives in the fragment prose, which is what the kit reads, and a
  marker would be a second assertion about that prose that no check can enforce — whether a
  text "contains a requirement" is not mechanically decidable, so the validator cannot catch
  drift, and a fragment gaining a requirement without its marker would be skipped silently.
  That trades a cheap read of seven fragments for a fail-open gap. Recorded together with the
  revisit trigger (several fragments carrying requirements, or one missed in practice) and the
  form to prefer then — a declaration line inside the fragment rather than a catalog column,
  because co-location is what stops the two from drifting.
- Consequently **no follow-up is requested in the kit.** The offer to exploit a marker there
  (check only marked fragments) lapses with the marker itself.

**Verification:** the counterpart was read in the coding-kit working tree at the named commit
rather than reconstructed from the task text — the plugin cache here still holds 0.17.0, so
the installed copy could not have answered it. That reading is what settled two points: the
kit hardcodes nothing and takes what to do from the fragment prose itself, which is the
argument against a second marker; and `update-conventions` checks per fragment in the slot
even when the text is unchanged, which is what the `/update-conventions` row now states.
`just check` green; both tables re-read after the edits, rows intact and still one line each.

---

## F-022 — Begleithandlungen beim Fragment-Einbau (2026-08-11)

**Aufgabe:** ausgelöst von project-template 0.13.1 (dortiges TPL-016). Das `nextjs`-Fragment
verlangt seither eine Handlung, die kein Skill ausgeführt hat: Ein Projekt, das Next
adoptiert, muss eine `AGENTS.md` haben, **bevor** `next dev` das erste Mal läuft. Sonst
schreibt Nexts Agent-Rules-Generator seinen Managed-Block in die `CLAUDE.md` und erneuert
ihn dort bei jedem Lauf — und ein nachträglich angelegtes `AGENTS.md` holt ihn nicht mehr
heraus. Der Fragment-Text stand also im Projekt, ohne dass ihn jemand ausführte.

**Was gebaut wurde (5 Skills + Begleit-Änderungen):**

`choose-stack`: neuer Abschnitt **§ Begleithandlungen beim Fragment-Einbau** — die einzige
Fundstelle der Mechanik. Verlangt ein Fragment beim Einbau eine Handlung am Projekt und
nicht nur den Text im Slot, wird sie im selben Schritt ausgeführt, im Plan ausgewiesen und
einzeln bestätigt. Zwei Eigenheiten sind ausdrücklich benannt: die Prüfung ist von der
Idempotenz-Regel **entkoppelt** (Fragment schon im Slot → Text übersprungen,
Begleithandlung trotzdem geprüft), und eine Begleithandlung darf eine **Reihenfolge**
vorschreiben plus einen Zustand benennen, den späteres Nachholen allein nicht heilt. Im
Modus-B-Bullet steht der Querverweis an der Idempotenz-Regel.

Referenzen statt Duplikate an den vier Einbau-Stellen: `new-project` (Fragment-Assembly),
`prep-step` § 2a und `step-done` § 1a (Begleithandlung im Vorschlag mitausweisen),
`choose-stack` Modus B. Zusätzlich `update-conventions` Schritt 6: Prüfung je Fragment im
Slot **auch bei unverändertem Fragment-Text**, offene Fälle mit Diff angeboten.

**Notable decisions:**

- **Generisch statt fragmentspezifisch.** Kein `if nextjs then …`. Was zu tun ist, liest
  der Skill zur Laufzeit aus dem Fragment; das Kit hardcodet kein Framework-Wissen. Das
  ist dieselbe Arbeitsteilung, die schon fürs Trigger-Mapping gilt (Template = Daten,
  Kit = Logik) und die die Authoring-Konvention fordert („kein hartkodierter
  Projektzustand", „nichts hardcoden"). Künftige Fragmente mit Begleithandlung kosten
  damit **null** Skill-Änderungen.
- **Einmal formuliert, viermal referenziert.** Die Untersuchung ergab, dass alle vier
  Einbau-Stellen ohnehin schon auf `/choose-stack` verweisen („Mechanik wie
  /choose-stack"). Die Mechanik gehörte deshalb genau dorthin; die vier Stellen bekamen
  nur je einen Satz, damit die Referenz nicht überlesen wird.
- **Entkopplung von der Idempotenz-Regel war der eigentliche Fix.** Die bestehende Regel
  „`fragment:NAME` schon vorhanden → überspringen" hätte die Begleithandlung genau in den
  Projekten verschluckt, die sie am nötigsten brauchen.
- **`update-conventions` als fünfte Stelle ergänzt** — sie stand nicht in der
  Ausgangsliste, ist aber der **einzige** Pfad, der Bestandsprojekte erreicht: die
  anderen vier greifen nur beim Einbau, und ein Projekt, das `nextjs` vor 0.13.1 bekam,
  wäre sonst nie eingeholt worden.
- **Keine Versionsstände im Skill-Text** (Authoring-Konvention): die Verzweigung ist kein
  Public API, das Fragment verweist selbst auf die installierte Quelle.

**Verifikation:** die Behauptung des Auftrags wurde nicht übernommen, sondern gegen eine
frisch installierte Next-Version dreifach nachgemessen. (1) `writeAgentFiles` in
`node_modules/next/dist/server/lib/generate-agent-files.js` zeigt die Verzweigung
`agentsMdExists && (agentsMdHostsBlock || !claudeMdHostsBlock)` → `AGENTS.md`; sonst
`claudeMdExists` → `CLAUDE.md`; sonst beide anlegen. Der Aufruf sitzt in `start-server.js`
beim Dev-Boot, gated auf `agentRules !== false` (Default an) und auf erkannten Agenten
(`@vercel/detect-agent`, u. a. `CLAUDECODE`). (2) Fünf Fixtures direkt gegen
`writeAgentFiles`: nur `CLAUDE.md` → Block in `CLAUDE.md`, kein `AGENTS.md` angelegt;
`CLAUDE.md` + `AGENTS.md` → Block in `AGENTS.md`, `CLAUDE.md` übersprungen; keine von
beiden → beide angelegt; nur `AGENTS.md` → dorthin; **Block bereits in `CLAUDE.md`,
`AGENTS.md` nachträglich angelegt → weiterhin `CLAUDE.md`** (daher die Reihenfolge-Regel).
(3) Zwei echte `next dev`-Läufe mit Request: ohne `AGENTS.md` meldete Next „Generated
CLAUDE.md", der Block stand in der Governance-Datei, `git diff` zeigte sie geändert; mit
vorhandener `AGENTS.md` meldete Next „Generated AGENTS.md", `CLAUDE.md` blieb
byte-identisch. Alle drei Messungen stimmen überein und decken sich mit F-016 drüben.
`just check` grün.

---

## TPL-016 — Correct the `agentRules` routing in the `nextjs` fragment (2026-08-11)

**Problem:** reported from a downstream sync (0.11.2 → 0.13.0) and confirmed here. The
`agentRules` rule written in TPL-015 described Next's agent-file routing wrongly: it claimed the
managed block always lands in `AGENTS.md` with only an import added to `CLAUDE.md`. That is the
greenfield path, taken only when **neither** file exists — the `create-next-app` case. Projects
from this template always ship a `CLAUDE.md` and never an `AGENTS.md`, so they systematically
hit the other branch, which writes the block **into `CLAUDE.md`** and rewrites it on every
`next dev`. The rule therefore produced the exact outcome it was written to prevent.

**What was built (1 file + sync):**

`modules/standards/nextjs.md`: the single `agentRules` bullet becomes two. The first states the
routing by file state and makes the actionable requirement explicit — create `AGENTS.md` when
adopting Next, before the first `next dev`, because that is what moves the block out of the
governance file. The second carries the remediation order and the `agentRules: false` fallback,
and points at the installed source for verification, since the routing is not public API.
Sync invariant: `VERSION` 0.13.1 + `CHANGELOG.md`. `MANIFEST.md` untouched — no files added,
removed or re-policied.

**Notable decisions:**

- **Rescue the rule rather than reverse it.** Reverting to `agentRules: false` would have
  discarded the version-matched docs pointer a second time — the very thing the fragment's lead
  rule demands. Creating `AGENTS.md` satisfies the branch condition and keeps the benefit.
- **State the branching, not just the happy path.** The reporter offered "create `AGENTS.md`" or
  "describe the behaviour honestly and recommend `agentRules: false`" as alternatives; the rule
  now does both jobs, because the requirement alone becomes a trap for a project that already
  ran `next dev` once.
- **No version numbers in the rule text**, per the repo convention: it points at
  `node_modules/next/dist/server/lib/generate-agent-files.js` in the installed version instead of
  naming the release the behaviour was measured on.
- The reported side note — that the greenfield branch *overwrites* `CLAUDE.md` with `@AGENTS.md`
  rather than appending — is technically moot and deliberately not mentioned in the fragment:
  that branch runs only when the file does not exist, so there is nothing to overwrite.

**Verification:** measured against a throwaway Next project at the version in question, three
ways in agreement. (1) The installed `generate-agent-files.js` shows the branch order —
`agentsMdExists && (agentsMdHostsBlock || !claudeMdHostsBlock)` → `AGENTS.md`; else
`claudeMdExists` → `CLAUDE.md`; else scaffold both. (2) Calling `writeAgentFiles` directly on
prepared fixtures: `CLAUDE.md` only → block into `CLAUDE.md`, no `AGENTS.md` created;
`CLAUDE.md` + `AGENTS.md` → block into `AGENTS.md`, `CLAUDE.md` skipped; neither → both
scaffolded; **block already in `CLAUDE.md`, `AGENTS.md` added later → still `CLAUDE.md`**, which
is where the remediation order comes from. (3) Two real `next dev` runs with a request against
each: with only a `CLAUDE.md` the block appeared inside it and no `AGENTS.md` was created; with
an `AGENTS.md` present `CLAUDE.md` was byte-identical afterwards and both the block and
`AGENTS.md`'s own content were in place. `just check` green.

---

## TPL-015 — Fail-closed env deny set + vendor-aligned `agentRules` rule (2026-08-11)

**Problem:** two follow-ups from review of TPL-013/TPL-014. (1) The enumerated env deny of TPL-014
covers the framework-conventional names only; short forms (`.env.prod`, `.env.ci`) and copy
variants (`.env.bak`, `.env.old`) fall through, and because read-only tools need no approval
inside the working directory they are readable **without a prompt**. That silently reversed the
fail-safe posture TPL-001 had documented in `core/.claude/README.md`. (2) The `agentRules` rule in
the new `nextjs` fragment told projects to disable Next's agent-rules generator, justified by a
governance conflict that does not hold up.

**What was built (6 files):**

`core/.claude/settings.json` and the template's own `.claude/settings.json`: the fourteen
enumerated env entries are replaced by six patterns per tool that carve the `.env.example`
exception out by hand — `**/.env` and `**/.env[0-9a-z_-]*` for the undotted forms (`.envrc`),
then `**/.env.[0-9a-df-z_-]*`, `**/.env.e[0-9a-wy-z_-]*`, `**/.env.ex[0-9b-z_-]*` and
`**/.env.example?*`, each class excluding exactly the letter that spells `example`. The
`.env.example` allow entries are back in force. `core/.gitignore`: `.env` + `.env.*` collapse
to `.env*`, keeping `!.env.example`. `core/.claude/README.md`: the stale TPL-001 caveat is
replaced by the rationale plus the two matcher properties the construction depends on.
`modules/standards/docker.md`: unchanged in the end (see below).
`modules/standards/nextjs.md`: the `agentRules` bullet is rewritten. Sync invariant: `VERSION`
0.13.0 + `CHANGELOG.md`. `MANIFEST.md` untouched — no files added, removed or re-policied.

**Notable decisions:**

- **Owner's call: keep the conventional dotted `.env.example`.** The first implementation took
  the opposite route — rename the placeholder to `env.example` so it falls outside the `.env*`
  namespace, which allows a single gapless deny pair and needs no allow entry at all. That was
  built and verified end to end, then reverted when the owner asked for the conventional
  spelling with the leading dot. The cost of the chosen route is six cryptic patterns per
  tool in a JSON file that admits no comments; it is paid down by the rationale block in
  `core/.claude/README.md`.
- **Known residual, documented rather than closed:** a suffix starting with `exa` that is not
  `example` (`.env.exact`, `.env.examine`) and exact truncations (`.env.e`, `.env.exa`) match
  no deny rule. Closing them costs one more pattern per prefix letter and neither shape is a
  real env filename.
- **`agentRules` reversed to vendor-aligned.** The claimed conflict was overstated: Next only
  adds an `AGENTS.md` import to `CLAUDE.md`, which lands outside the `section:claude-*` markers
  and is preserved by `/update-conventions` — so the governance file is not actually contested.
  Disabling the generator threw away the version-matched docs pointer, which is the very thing
  the fragment's lead rule demands and which the vendor's own evals show helps. The rule now
  leaves it on, treats `AGENTS.md` as framework-owned, and commits the managed block; the
  vendor documents that deleting it only re-creates the churn.

**Verification:** measured against the real matcher via headless `claude -p` runs in a scratch
project, not reasoned from the pattern syntax — which mattered twice, because the reasoning was
wrong both times.

1. **There is no negation.** With deny `Read(**/.env.[!e]*)` the result was `.env.foo`
   *allowed* and `.env.example` *blocked* — the exact inverse of gitignore semantics. `[^e]`
   behaved identically, so both forms are read as positive sets containing `e`. A rule written
   on the gitignore assumption would have opened a hole and blocked the placeholder.
2. **Matching is case-insensitive.** The first character-class draft used `[0-9A-Za-df-z_-]`,
   reasoning that `A-Z` covers `.env.PROD`. It blocked everything including `.env.example`,
   because the uppercase range swallowed the lowercase `e` the class was meant to exclude.
   Dropping `A-Z` fixed it — and the lowercase ranges cover uppercase names anyway.

Acceptance test of the shipped configuration: `.env.example` allowed, while `.env`,
`.env.local`, `.env.bak`, `.env.prod`, `.env.2024`, `.envrc`, `.env.e2e`, `.env.export`,
`.env.example.local` and `.env.keys` are all blocked. Edit verified separately under
`--permission-mode acceptEdits` (which deny still overrides): the append to `.env.example`
landed on disk, the same append to `.env.local` was blocked. `.gitignore` cross-checked with
`git check-ignore` in a throwaway repo — every `.env*` ignored, `.env.example` tracked.
`just check` green.

---

## TPL-014 — Fix `.env.example` shadowed by the broad env deny rule (2026-08-11)

**Problem:** reported from work on a downstream project: the tracked `.env.example`
placeholder could not be created or edited. Both settings files listed
`Read(**/.env.example)` / `Edit(**/.env.example)` under `permissions.allow`, but also the
broad `Read(**/.env.*)` / `Edit(**/.env.*)` under `permissions.deny`. Deny wins over allow, so
the broad rule shadowed the intended exception — while `.gitignore` explicitly includes the
file via `!.env.example`.

**What was built (2 files):**

`core/.claude/settings.json` (shipped to projects) and the template's own
`.claude/settings.json` — both carried the identical defect and both were fixed. The broad
`**/.env.*` is replaced, for `Read` and `Edit` alike, by the secret-bearing variants:
`.env.local`, `.env.*.local`, `.env.development`, `.env.production`, `.env.test`,
`.env.staging` (`**/.env` was already listed separately and stays). Sync invariant:
`VERSION` 0.12.0 + `CHANGELOG.md` (the entry covers `core/` only — the template's own settings
file is not template content). `MANIFEST.md` untouched: `core/.claude/settings.json` is already
policied `managed`, and the change is content, not policy.

**Notable decisions:**

- **No negation-based fix**, because none exists: the permission reference states that Read and
  Edit rules use gitignore pattern syntax and that a broad deny rule "blocks every matching
  call, including calls that also match a narrower allow rule, so a deny rule can't carry
  allowlist exceptions". A `!`-style exemption inside a deny pattern is therefore not an option,
  and the explicit enumeration is the only reliable fix.
- A gitignore character-class construction (`**/.env.[!e]*` plus one pattern per prefix of
  `example`) would be exhaustive and fail-closed, but needs roughly sixteen cryptic patterns
  per tool in a file that ships to every project. Rejected on readability and maintenance
  grounds.
- **Known residual gap, deliberately accepted:** the enumeration covers the framework-
  conventional names, not every conceivable one. An unlisted variant such as `.env.prod` or
  `.env.ci` is no longer denied, and since read-only tools need no approval inside the working
  directory, it would be readable without a prompt — the old broad rule blocked it.

> **Superseded by TPL-015 (2026-08-11).** Two corrections to the entry above. First, the
> suggested follow-up — a catch-all `ask` rule `Read(**/.env.[!e]*)` — was **wrong and would
> have backfired**: measured against the real matcher, neither `[!e]` nor `[^e]` negates.
> Both are read as positive sets containing `e`, so the rule would have blocked
> `.env.example` and left every other variant open, i.e. the exact inverse of its purpose.
> Second, the residual gap was not merely theoretical but a reversal of a documented posture:
> TPL-001 accepted a possibly-blocked `.env.example` as "the intended failure direction", and
> this entry silently traded that fail-safe stance for a fail-open one — `.env.bak`, a literal
> copy of a real `.env`, became silently readable. TPL-015 restores the fail-closed behaviour
> with a deny set that carves the `.env.example` exception out via positive character classes.

**Verification:** both files re-read after the edit and diffed against each other — identical
permission blocks, `**/.env.*` gone from both, `.env.example` allow entries intact;
`just check` green (the validator parses both as JSON).

---

## TPL-013 — Standards fragment `nextjs` (App Router) (2026-08-11)

**Problem:** the catalog had no Next.js fragment. `react` alone does not cover the App
Router-specific traps that surfaced in a downstream project — the server/client boundary,
Server Actions as public endpoints, and `NEXT_PUBLIC_*` as a publication decision rather than
a convenience prefix.

**What was built (2 files):**

New `modules/standards/nextjs.md`, body wrapped in `<!-- fragment:nextjs -->` …
`<!-- /fragment:nextjs -->`, in six blocks: a lead rule to read the version-matched docs
bundled at `node_modules/next/dist/docs/` instead of writing from memory; server/client
boundary (`"use client"` as a leaf, `server-only` on credential-bearing modules,
`NEXT_PUBLIC_*`, Server Actions validating and authorising themselves); routing & data
(Route Handlers deferring to the `api-design` fragment, explicit caching, file conventions,
Metadata API, `proxy.ts` vs. the deprecated `middleware.ts`); assets & build (`next/image`,
self-hosted `next/font`, standalone `HOSTNAME`, `agentRules: false`, Biome over `next lint`);
configuration (the `NODE_ENV`/`PORT` overwrite, the lazy `instrumentation.ts` hook that
swallows a rejected `register()`); and imports. `modules/standards/README.md` gets the catalog
row (trigger `next`). Sync invariant: `VERSION` 0.12.0 + `CHANGELOG.md`.

**Notable decisions:**

- **Retrofit-only — no module declares the fragment.** All three stack modules declare
  `Standards fragments: (none)`, and `react`/`prisma` are already retrofitted per project via
  `/choose-stack` or `/prep-step`. Beyond consistency there is a hard reason: the fragment's
  extensionless-import rule contradicts the `.js`-extension rule of `fragment:ts-node`, so
  declaring it on the module would ship two conflicting import rules to every plain TypeScript
  project. The fragment therefore names itself the documented exception and points at
  `.claude/convention-overrides.md`.
- `MANIFEST.md` untouched — adding a catalog fragment registers it in
  `modules/standards/README.md`, not in the manifest, which names fragments only as examples.
  Same shape as TPL-006.
- Catalog row placed directly below `react` rather than appended: the two are read together,
  and the table has no declared ordering.
- **Version-bound wording avoided** per the repo rule against static tool-version claims in
  template texts. The source notes named "Next.js 16" for both the docs-changed warning and the
  `proxy.ts` rename; the fragment states the substance instead ("recent majors changed APIs,
  conventions and file structure", "`middleware.ts` is the deprecated predecessor"), which
  stays true across majors.
- **Unverifiable specifics dropped:** the source notes claimed the build rejects `proxy.ts` and
  `middleware.ts` coexisting under error code `E900`. The official message page documents the
  rename as a deprecation and names no such code, so the fragment keeps the actionable rule
  ("never keep both in a tree") without the code.

**Verification:** claims checked against the vendor documentation rather than from memory —
the AI-agents guide confirms the bundled docs path `node_modules/next/dist/docs/`, that a
`next dev` run writes a managed block into `AGENTS.md`/`CLAUDE.md`, and `agentRules: false` as
the documented opt-out; the message page confirms `proxy.ts` replacing `middleware.ts` and the
codemod. `just check` green: fragment markers balanced, no unknown placeholders, privacy lint
clean (`0.0.0.0` is on the validator's allowlist).

---

## TPL-012 — ts-node seed files ship Biome-clean (2026-08-11)

**Problem:** reported from a fresh `/new-project` run: every new TypeScript project starts
with a red `just check`. `files/src/index.test.ts` and `files/vitest.config.ts` used single
quotes, while `biome.json` sets no quote-style override — so Biome formats to its default
(double quotes) and the first `biome ci --error-on-warnings` fails with two format errors.
Two config infos came with it: the `$schema` URL pinned 2.5.2 against a CLI resolved from
`^2.5.2` (2.5.7 at the time), and `linter.rules.recommended` is deprecated.

**What was built (5 files):**

`modules/ts-node/files/src/index.test.ts` and `files/vitest.config.ts` reformatted to
double quotes (output of `biome check --write`, no other change).
`modules/ts-node/files/biome.json`: `$schema` →
`./node_modules/@biomejs/biome/configuration_schema.json`;
`linter.rules.recommended: true` → `linter.rules.preset: "recommended"` (the replacement
Biome's own `migrate` emits). `modules/ts-node/MODULE.md`: two maintenance notes — why the
schema is resolved locally, and that `files/**/*.ts` must go through `biome check --write`
before it lands. Sync invariant: `VERSION` 0.11.3 + `CHANGELOG.md`; `MANIFEST.md` untouched
(no files added/removed, no policy change).

**Notable decisions:**

- Fix on the source side, not via `javascript.formatter.quoteStyle: "single"` — the seed
  code follows the formatter's default instead of the config carrying an override for the
  sake of two sample files.
- Local `$schema` instead of bumping the pin to 2.5.7: the URL form would silently drift
  again on the next Biome patch (the Renovate preset has no custom manager for schema
  URLs), the local path always tracks the installed CLI. Trade-off: in a fresh clone the
  schema resolves only after `pnpm install`.

**Verification:** the module was instantiated in a scratch dir (placeholders substituted,
`pnpm install`, Biome 2.5.7 resolved): before the fix `biome ci --error-on-warnings`
reported 2 format errors + 2 infos, afterwards it is clean (no errors, no infos);
`tsc --noEmit` and `vitest run` (1/1) green. Cross-check of the sibling modules against
their formatters: `gofmt -l` on `modules/go/files` empty, `ruff format --check` on
`modules/python/files` clean (its only complaint is the unresolved `{{PROJECT_NAME_SNAKE}}`
placeholder, which is valid Python only after instantiation) — the defect was ts-node-only.

---

## F-019 — Pflege-Skill go-public: Projekt nachträglich public-ready machen (2026-07-20)

**Aufgabe:** public-only-Dateien werden bei privaten Projekten bewusst nicht
instanziiert; für den späteren Weg an die Öffentlichkeit gab es keinen geführten
Prozess — und niemand prüfte systematisch das eigentliche Risiko: Secrets/
Personendaten in der gesamten Git-Historie, TBD-Lizenz, fehlende Repo-Settings.

**Was entstanden ist (Plugin 0.17.0; 2 Substeps, ein Release):**

- **F-019a — Skill-Kern:** Neuer Pflege-Skill
  `plugins/coding-kit/skills/go-public/SKILL.md` (`disable-model-invocation`).
  Fallerkennung zur Laufzeit (`gh repo view`): A privat → Umstellung, B nur lokal
  → Anlage + initialer Push, C schon public → Preflight trotzdem vollständig
  (nachträgliche Funde sind dort bereits öffentlich), dann nur Nachzug-/
  Abschluss-Check. Preflight blockierend, fail-closed, vier Gates:
  Historien-Secrets-Scan (Scanner zur Laufzeit aus lefthook/mise aufgelöst,
  gitleaks nur Fallback, fehlender Scanner = rot), Privacy-Scan des committeten
  Baums **inkl. Commit-Metadaten** (Autor-/Committer-E-Mails der Historie —
  Ergänzung während der Umsetzung, kein Datei-Scan findet das), LICENSE nicht
  TBD, private/-Hygiene über die Historie (Ausnahme: managed
  `private/README.md`). Befund-Optionen: bereinigen / History-Rewrite **nur als
  Anleitung** (`git filter-repo` + Force-Push, nie automatisch) / begründete
  False-Positive-Einstufung (protokolliert) / Abbruch.
- **F-019b — Nachzug, Übergang, Abschluss-Check:** Verbindliche Reihenfolge
  **Nachzug vor Übergang** (Nutzer-Entscheidung: nie unvollständig online) —
  update-conventions läuft mit neuer **Sichtbarkeits-Prämisse** („behandle als
  public"), public-only-Dateien und Template-Updates entstehen und werden
  committet, bevor irgendetwas öffentlich wird; hartes Gate im Skill. Übergang je
  Fall nach Klartext-Bestätigung: `gh repo edit --visibility public`
  (`--accept-visibility-change-consequences` per Feature-Detection) bzw.
  `gh repo create` + Push nur mit ausdrücklicher laufbezogener Freigabe aus
  demselben Lauf. Repo-Settings wie new-project § 4c (Topics inkl. Marker
  `coding-kit`, Push-Protection). Der Languages-Block bleibt unangetastet
  (F-020: Sprache sichtbarkeitsentkoppelt). Abschluss-Check: CodeQL läuft an,
  Vollständigkeit, Settings, `just check`, Graphiti-Update.
- **update-conventions-Erweiterung:** Sichtbarkeits-Prämisse in Intro + A2.3
  dokumentiert (gilt auch für die A3-Heuristik); Default bleibt die tatsächliche
  Sichtbarkeit via `gh repo view`.
- **Begleitanpassungen:** plugin.json 0.17.0 (+ go-public in der
  Description-Aufzählung), CHANGELOG, README-Zeile; project-template 0.11.2
  (HOW-TO-Pflegezeile für `/go-public`, VERSION + CHANGELOG dort).
- **Geänderte Dateien:** `plugins/coding-kit/skills/go-public/SKILL.md` (neu),
  `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`;
  im project-template: `core/HOW-TO-CODE-WITH-CLAUDE.md`, `VERSION`,
  `CHANGELOG.md`.

---

## F-021 — update-conventions: Vollabdeckung aller Template-Dokumente (inkl. seed) (2026-07-20)

**Aufgabe:** update-conventions prüfte nur managed Dateien und Modul-Parts —
seed-Dateien samt ihrer Template-Struktur-Anteile (CLAUDE.md-Blöcke,
PROGRESS-Skelett, REQUIREMENTS-Kopfnotiz, README-Struktur) blieben ungeprüft, und
im Template gelöschte/umbenannte Dateien behandelte der Lauf nicht.
Template-Gegenstück: project-template TPL-011 (`section:NAME`-Zonen-Vertrag in
MANIFEST § Seed sections, Marker in sechs seed-Skeletten, VERSION 0.11.0) — war
bei Planungsbeginn bereits fertig; F-021 ist die rein kit-seitige Auswertung.

**Was entstanden ist (Plugin 0.15.0 + 0.16.0; 2 Substeps, 2 Commits):**

- **F-021a — seed-Abgleich abschnittsweise (0.15.0):** update-conventions liest in
  § 0 das Zonen-Inventar aus MANIFEST § Seed sections mit Feature-Detection
  (fehlt der Abschnitt — älterer Template-Stand —, entfallen seed-Abgleich und
  Marker-Migration still; `manifest-format` bleibt 1). Neuer A2-Schritt 7: die
  markierten Zonen der Template-Fassung werden instanziiert (rückaufgelöste
  Projektwerte aus A2.2) und einzeln gegen die Ist-Zone gedifft — je Zone
  übernehmen / lassen / Override, nie die ganze Datei ersetzen oder anlegen;
  gelöschtes Markerpaar = dauerhafter Opt-out (nur melden, nie ungefragt
  wiederherstellen); `claude-graphiti` fehlt legitim bei Projekten ohne
  Graphiti-Block. Neuer A3-Schritt 7: Marker-Migration für Alt-Projekte (reine
  Wrapper aus dem Inventar um wiedererkennbare Zonen, je Datei bestätigt; nicht
  Wiederauffindbares = Opt-out). Grundsatz präzisiert: seed nie als Ganzes,
  markierte Zonen abschnittsweise. new-project § 4b stellt klar, dass
  `section:NAME`-Markerpaare bei der Instanziierung erhalten bleiben.
- **F-021b — entfernte/umbenannte Template-Dateien (0.16.0):** neuer A2-Schritt 8:
  Core-Tabelle des Stempel-Stands (Stempel-Commit über die `VERSION`-Dateihistorie
  des Template-Checkouts auflösen, dann `git show <commit>:MANIFEST.md`) gegen die
  aktuelle diffen; Umbenennung → Umzug anbieten, Entfernung → Rückbau anbieten —
  je Datei bestätigt, Overrides gelten. Fallback ohne auflösbaren Stempel-Commit
  (shallow clone, zu alter Stempel): nur im CHANGELOG des Update-Fensters
  dokumentierte Fälle, nichts erraten. seed-Dateien werden nie gelöscht oder
  verschoben, nur gemeldet.
- **Entscheidungen:** Zwei Commits mit je eigenem Version-Bump (0.15.0/0.16.0),
  Historie deckungsgleich mit dem CHANGELOG (Nutzer-Wahl). Keine Heuristik für
  markerlose seed-Dateien im deterministischen Pfad — Alt-Projekte laufen über die
  bestätigte A3-Migration. LICENSE bleibt bewusst ohne Zonen (verwaltet
  `/choose-license`).
- **Begleitanpassungen:** plugin.json 0.15.0→0.16.0, CHANGELOG-Einträge,
  README-Zeile + Skill-Description um seed-Zonen und Rückbau/Umzug erweitert;
  project-template 0.11.1 (HOW-TO-Zeile zu `/update-conventions` nachgezogen,
  dortige Sync-Invariante: VERSION-Bump + CHANGELOG).
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`;
  im project-template: `core/HOW-TO-CODE-WITH-CLAUDE.md`, `VERSION`,
  `CHANGELOG.md`.

---

## TPL-011b — Section markers applied to the seed skeletons (2026-07-20)

**Problem:** TPL-011a defined the `section:NAME` contract and inventory in `MANIFEST.md`;
the markers themselves were still missing from the seed skeletons.

**What was built (7 files):**

Wrapped the template-owned zones exactly per the MANIFEST § Seed sections inventory —
wrappers only, no prose changed: `core/CLAUDE.md` (`claude-graphiti` nested inside the
`template:optional:graphiti` block, `claude-startup` around the reading guidance below
the adapt slot, `claude-conventions` and `claude-workflow` including their headings),
`core/PROGRESS.md` (`progress-head`), `core/PROGRESS-ARCHIVE.md` (`archive-head`),
`core/REQUIREMENTS.md` (`requirements-head`), `core/README.md`
(`readme-getting-started` incl. heading and recipe table),
`core/.claude/convention-overrides.md` (`overrides-head`). `CHANGELOG.md` 0.11.0 entry
updated to state the markers shipped.

**Notable decisions / deviations:**

- **Deviation from the plan (owner's call):** TPL-011a and TPL-011b were committed together,
  so both ship as VERSION 0.11.0 — the planned separate 0.11.1 bump for b was dropped
  (the sync invariant is per commit, one bump suffices).
- Zones whose heading is fully template-owned (Conventions, Workflow, Getting started)
  include the heading inside the markers; `claude-startup` excludes its heading because
  the section also carries the project-specific status sentence and adapt slot.

**Verification:** `just check` green; grep over the six files shows exactly the nine
marker pairs of the inventory, all balanced (validator); `sed` proof that
`claude-graphiti` sits inside the optional block.

---

## TPL-011a — Seed section-marker contract + validator (2026-07-20)

**Problem:** Seed files are living documents `/update-conventions` never touches — but
they carry template-owned zones (CLAUDE.md's Graphiti/startup/conventions/workflow blocks,
the skeleton head notes) that evolve with the template and never reached existing projects.
TPL-011 defines a section-marker contract so those zones become individually syncable;
this substep ships the contract and validation, TPL-011b applies the markers.

**What was built (5 files; VERSION 0.10.0 → 0.11.0):**

- `MANIFEST.md`: `<!-- section:NAME -->` … `<!-- /section:NAME -->` registered in
  § Markers (lowercase-kebab, unique across the template); seed policy reworded — marked
  zones are individually offerable (diff shown, confirmed per section), the file as a
  whole never; new § Seed sections with contract prose (deleting a marker pair = permanent
  opt-out; evaluation is coding-kit logic) and the agreed zone inventory: `core/CLAUDE.md`
  (`claude-graphiti` inside the optional block, `claude-startup`, `claude-conventions`,
  `claude-workflow`), `progress-head`, `archive-head`, `requirements-head`,
  `readme-getting-started`, `overrides-head`.
- `scripts/validate.py`: `check_fragment_markers` generalized to `check_paired_markers` —
  one regex (`PAIRED_MARKER_RE`) and per-kind stacks cover `fragment:` and `section:`
  balanced/ordered closing; section names must additionally be unique per file.
- `VERSION` 0.11.0, `CHANGELOG.md` entry.

**Notable decisions:**

- `manifest-format` stays 1: the addition is backward-compatible — older kit versions
  ignore the markers, kit F-021 feature-detects by marker presence.
- MANIFEST documents markers only with the uppercase `NAME` placeholder so the docs
  themselves never trip the balanced-marker check (same convention as `fragment:`).

**Verification:** `just check` green before and after; spot test with an intentionally
broken file caught duplicate, mismatched, and unclosed `section:`/`fragment:` markers
(5 findings), clean again after removal.

---

## F-020 — Sprach-Matrix: granulare Sprachwahl je Projekt (2026-07-19)

**Aufgabe:** Die Projektsprache war eine einzige Dimension („Sprache der lebenden
Doku") mit sichtbarkeitsgekoppeltem Default (Deutsch privat / Englisch public).
Sprache hängt aber am Thema/Publikum, nicht an der Sichtbarkeit — ein privates
Projekt kann public werden (F-019), ohne dass die Sprache wechseln soll.
Template-Gegenstück: project-template TPL-010 (Languages-Block, fünf
`LANG_*`-Platzhalter, VERSION 0.10.0) — im Pairing direkt miterledigt.

**Was entstanden ist (Plugin 0.14.0; 2 Substeps, ein Release):**

- **F-020a — Erhebung & Instanziierung:** new-project Schritt 5 ist die
  Preset-Frage (A Arbeitssprache + Englisch nach außen [Default] / B alles Englisch /
  C alles Arbeitssprache / D individuell je Dimension, freie Sprachwahl), Vorschlag
  aus der Short-Info — die Sichtbarkeits-Frage sagt explizit, dass sie die
  Sprachwahl nicht beeinflusst. §4b füllt die fünf `LANG_*`-Platzhalter. Globale
  CLAUDE.md-Vorlage: Haus-Default Englisch bleibt, ein Projekt-Languages-Block
  gewinnt je Dimension; Alt-Konvention wird weiter gelesen. Immer englisch:
  Identifier, Conventional-Tokens, Status-Tokens, Governance-Doku.
- **F-020b — Betrieb & Migration:** step-done liest den Languages-Block (§0), prüft
  die Kommentar-/Docstring-Sprache im Review (§1) und schlägt Commit-Prosa in der
  Commit-Sprache vor (§6; ohne Block englisch, Tokens immer englisch); build-step
  schreibt Kommentare in der Kommentar-Sprache (§2); update-conventions löst die
  fünf Werte rück (A2.2, mit Alt-Projekt-Fallback) und bietet die
  Languages-Block-Migration als bestätigten Schritt an (neuer A3-Schritt 6 +
  Hinweis in A2.7) — nötig, weil CLAUDE.md `seed` ist und nie automatisch
  angefasst wird.
- **Entscheidung (Nutzer) — prospektive Migration:** Beim Sprachwechsel wird nichts
  rückwirkend übersetzt; neue Einträge folgen ab sofort den gewählten Sprachen,
  Struktur-Überschriften (z. B. PROGRESS-Skelett) dürfen übersetzt werden, die
  Historie bleibt unverändert. Gemischte Tabellen sind akzeptiert — sie
  dokumentieren den Wechselzeitpunkt.
- **Bewusst nicht angefasst:** die generische Phrase „Sprache der lebenden Doku" in
  ~10 Skills — sie bleibt gültig und zeigt auf die Block-Zeile (Diff-Minimierung).
- **Begleitanpassungen:** plugin.json 0.14.0, CHANGELOG, new-project-description;
  README-new-project-Zeile brauchte keine Änderung.
- **Geänderte Dateien:** `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/skills/build-step/SKILL.md`,
  `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `templates/global-CLAUDE.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
  `CHANGELOG.md`.

---

## TPL-010 — Per-dimension language matrix (2026-07-19)

**Problem:** Project language was a single dimension (`LIVING_DOC_LANGUAGE`, living
docs only) whose default was coupled to repo visibility (German if private, English if
public). Language follows the project's topic and audience, not its visibility — a
private project may go public later without its language changing.

**What was implemented (VERSION 0.10.0):**

- `core/CLAUDE.md`: Languages block with five independently chosen dimensions —
  `{{LANG_LIVING_DOCS}}`, `{{LANG_CLAUDE_MD}}`, `{{LANG_COMMENTS}}`,
  `{{LANG_COMMITS}}`, `{{LANG_README}}`. Explicitly not configurable: identifiers,
  Conventional-Commit tokens, status tokens, governance docs (always English). Git
  bullet now reads "Conventional Commits (tokens English), prose in {{LANG_COMMITS}}".
- `core/PROGRESS.md`, `core/REQUIREMENTS.md`, `core/HOW-TO-CODE-WITH-CLAUDE.md`:
  switched to the new placeholders.
- `MANIFEST.md` registry: `LIVING_DOC_LANGUAGE` replaced by the five `{{LANG_*}}`
  rows; visibility-coupled default removed — values come from the `/new-project`
  language preset (default: English).
- `scripts/validate.py`: placeholder allowlist updated accordingly (old token out,
  five new tokens in).
- **Decision:** the registry default is neutral (English); opinionated presets
  (e.g. working-language docs with English outward-facing content) live in the
  coding-kit interview, not in the template. Migration of pre-0.10.0 projects is
  `/update-conventions` work (kit side, tracked there as F-020).

---

## TPL-009 — Align docs with the current coding-kit skill set (2026-07-19)

**Problem:** The coding-kit plugin (0.13.0) gained fragment-catalog capabilities in several
skills, and convention inheritance became exclusively downward (template → project; the
promote path was removed) — the docs in this repo still described the older state.

**What was changed (7 files; VERSION 0.8.0 → 0.9.0):**

- `core/HOW-TO-CODE-WITH-CLAUDE.md` (managed): both skill tables updated — `/prep-step`
  checks standards coverage for newly introduced frameworks/dependencies (dependency
  signals **and** characteristic triggers; proposes catalog fragments or project-local
  authoring with a manual template-adoption proposal); `/step-done` gains the non-blocking
  diff-based standards-coverage backstop (also added as step 3 in the detail section);
  `/choose-stack` composes declared catalog fragments (idempotent per `fragment:NAME`
  marker) and retrofits characteristic fragments after confirmation; `/update-conventions`
  syncs fragment-granular and downward only; `/define-requirements` asks the catalog's
  characteristic triggers in the interview.
- `modules/standards/README.md`: catalog intro rewritten — `/prep-step` matches both
  trigger types; characteristic triggers are asked at the requirements interview, at
  feature planning, and retrofittable via `/choose-stack`.
- Sync direction made explicit: new `MANIFEST.md` § Sync direction, a paragraph under
  Versioning in the root `README.md`, and a "Where conventions originate" section in the
  root `CONTRIBUTING.md` — conventions originate in the template and flow downward only;
  contributions from projects arrive as manually initiated adoption proposals (template
  session or GitHub issue), never as automatic writes. The standards-fragments policy row
  now states project-local fragments are never written to, only reported.
- `VERSION`, `CHANGELOG.md` (entry [0.9.0]).

**Notable decisions:**

- A repo-wide grep (promote/upstream/bidirectional and paraphrases) found no doc actively
  describing an upward sync — the hits were unrelated (Code of Conduct, SECURITY, nginx
  upstream) plus a historical note in CHANGELOG 0.2.0, which stays untouched as history.
  The new policy is therefore stated affirmatively rather than by deleting old text.
- No plugin version number in template texts (per the no-static-versions rule); the
  CHANGELOG entry says "current coding-kit".

**Verification:** `just check` (validator) green; diff reviewed in full; secrets/privacy
scan clean; MANIFEST cross-reference (§ Sync direction) resolves.

---

## F-018 — Konventions-Vererbung nur noch abwärts (2026-07-19)

**Aufgabe:** update-conventions war bidirektional — die AUFWÄRTS-Richtung („promote")
schrieb aus Projekten ins Template. Architektur-Entscheidung des Nutzers: Änderungen
immer zuerst in der Vorlage, Vererbung fließt ausschließlich Template → Projekt.

**Was entstanden ist (Plugin 0.13.0):**

- **update-conventions ist reine Abwärts-Maschine:** promote-Argument,
  Richtungsfrage und der komplette AUFWÄRTS-Abschnitt entfernt; Grundsatz
  „Vererbung fließt ausschließlich abwärts; dieser Skill schreibt nie ins Template"
  im Kopf. Entscheidungsset je Datei/Fragment dreiteilig (übernehmen / so lassen /
  Override registrieren) mit Verweis „Vorlage zuerst ändern, dann erneut syncen".
  Nebenbefund gefixt: veralteter Querverweis „Commit-Frage wie A2.6" → „A2.7"
  (seit der F-014-Umnummerierung falsch).
- **Neu: Abschnitt „Übernahme-Vorschlag"** als Ersatz für promote — projektlokale
  Fragmente bleiben erlaubt, werden aber nie automatisch ins Template gehoben.
  Stattdessen fertiges Material zum manuellen Anstoßen: kopierfertiger
  Beispiel-Prompt für eine project-template-Session (generalisieren,
  `modules/standards/<name>.md` + Katalog-Zeile, Sync-Invariante) oder ein
  GitHub-Request (`gh issue create -R OWNER/project-template`, OWNER zur Laufzeit,
  Override via `CODING_KIT_TEMPLATE_REPO`).
- **Drei Ausgabe-Stellen des Übernahme-Vorschlags:** update-conventions
  (Bestandsfälle beim Sync-Lauf), prep-step 2a Fall B (direkt nach der Anlage eines
  projektlokalen Fragments), step-done 1a (neu angelegte Fragment-Blöcke im Diff —
  fängt auch ad-hoc Angelegtes).
- **Begleitanpassungen:** plugin.json 0.13.0, CHANGELOG-Eintrag, README-Zeile
  update-conventions („nur abwärts"), Frontmatter-`description` neu; „promote"-
  Restvorkommen per grep verifiziert (nur noch CHANGELOG-Historie).
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/skills/prep-step/SKILL.md`,
  `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.

---

## F-017 — Eigenschafts-Trigger für Standards-Fragmente auswerten (2026-07-19)

**Aufgabe:** Der Fragment-Katalog des project-template kennt Mapping-Zeilen mit
Projekteigenschafts-Triggern (`*characteristic:*`; erster Fall: `audit-logging` mit
„service with user/admin mutations"). Solche Trigger sind über Paket-Manifeste nicht
erkennbar — ohne Kit-Unterstützung würde ein Eigenschafts-Fragment nie gezogen.

**Was entstanden ist (Plugin 0.12.0; der prep-step-Teil kam bereits mit F-015/0.10.0):**

- **define-requirements — Interview-Punkt 5:** die `*characteristic:*`-Zeilen aus
  `modules/standards/README.md` werden zur Laufzeit gelesen und je Zeile als
  Ja/Nein-Frage gestellt (z. B. audit-logging → „Gibt es Nutzer-/Admin-Aktionen, die
  Daten verändern?"), Default nein. **Gate:** nur bei erreichbarem Template (im
  /new-project-Flow ohnehin aufgelöst), sonst stilles Überspringen. Treffer →
  Constraint + Decision-Log-Eintrag in der REQUIREMENTS.md **und** Bestandteil der
  „Rückgabe an den Aufrufer" (Liste bejahter Eigenschafts-Fragmente).
- **new-project § 4b:** komponiert die im Interview bejahten Eigenschafts-Fragmente
  in die anzuhängende Fragmentliste mit — ohne diese Zeile wäre die
  Interview-Antwort verpufft.
- **choose-stack Modus B:** Eigenschafts-Fragmente sind nachrüstbar — sie sind in
  keinem `MODULE.md` deklariert; je Trigger wird gefragt, ob die Eigenschaft aufs
  Projekt zutrifft (Projektentscheidung, Default nein), angehängt nur nach
  Bestätigung mit derselben idempotenten Mechanik.
- **Skalierungs-Einschätzung:** aktuell eine characteristic-Zeile im Katalog → eine
  Interview-Frage; wächst linear, Ja/Nein mit Default nein — bewusst keine
  Extra-Mechanik.
- **Begleitanpassungen:** plugin.json 0.12.0, CHANGELOG-Eintrag, README-Zeilen
  (choose-stack, define-requirements), define-requirements-`description`.
- **Geänderte Dateien:** `plugins/coding-kit/skills/define-requirements/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/skills/choose-stack/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Strang komplett:** Mit F-017 ist die Composable-CODING-STANDARDS-Arbeit auf
  Kit-Seite abgeschlossen (F-012–F-017); beide Signaltypen des Katalogs werden an
  allen Lebenszyklus-Punkten ausgewertet.

---

## F-016 — step-done: Standards-Coverage-Backstop (2026-07-19)

**Aufgabe:** Auch mit der Erkennung in prep-step (F-015) konnte ein Framework ohne
zugehöriges Standards-Fragment durchrutschen — etwa wenn es erst während der
Umsetzung dazukam. Es fehlte ein Backstop am Ende des Zyklus.

**Was entstanden ist (Plugin 0.11.0):**

- **Neuer Schritt „1a. Standards-Abdeckung (Backstop)"** in step-done, zwischen
  Review (§1) und Secrets-Scan (§2). **Entscheidung — diff-basiert statt
  Projekt-Vollaudit:** Gate = der Diff des Schritts führt neue Dependencies in
  Paket-Manifesten oder neue Signal-Dateien (Dockerfile, nginx.conf, …) ein UND das
  Projekt hat einen `module:coding-standards`-Slot; sonst stilles Überspringen.
  Ein Voll-Scan je Substep wäre unverhältnismäßig; historische Lücken (Framework
  kam vor Einführung des Fragment-Systems) bleiben ein möglicher späterer
  audit-code-Erweiterungspunkt — bewusst nicht als F-Nummer aufgenommen.
- **Match** gegen das zur Laufzeit gelesene Katalog-Mapping
  (`modules/standards/README.md`, Auflösung wie choose-stack § 0);
  `*characteristic:*`-Zeilen matchen diff-basiert naturgemäß nicht (Planungsmaterie
  von prep-step 2a bzw. F-017).
- **Nicht blockierend:** Lücke wird gemeldet + Anhängen vorgeschlagen (Mechanik wie
  choose-stack, idempotent); lehnt der Nutzer ab, wird die offene Lücke im
  Archiv-Eintrag vermerkt, damit sie sichtbar bleibt.
- **Begleitanpassungen:** plugin.json 0.11.0, CHANGELOG-Eintrag,
  README-Tabellenzeile step-done, Frontmatter-`description`.
- **Geänderte Dateien:** `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- Damit ist der „Standards wachsen mit"-Zyklus geschlossen: prep-step schlägt vor
  (F-015), choose-stack baut ein (F-013), update-conventions pflegt (F-014),
  step-done fängt Durchrutscher (F-016).

---

## F-012 — add-skill: Template-HOW-TO synchron halten (2026-07-19)

**Aufgabe:** Die Skill-Übersicht in project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md`
fiel hinter den Skill-Bestand des coding-kit zurück — kein Prozessschritt erinnerte
beim Anlegen/Ändern von Skills an die Pflege der Template-Übersicht.

**Was entstanden ist (repo-lokal, kein Plugin-Release):**

- **Neuer Haken in der Vollständigkeits-Checkliste** (Schritt 3) von
  `.claude/skills/add-skill/SKILL.md`: Gehört der neue/geänderte Skill zum
  Projekt-Alltag (Dev-Loop) oder zur Projekt-Pflege, wird die Skill-Übersicht in
  project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md` mitgepflegt — Template zur
  Laufzeit auflösen (wie `/coding-kit:choose-stack` § 0), die passende der beiden
  Tabellen treffen (Dev-Loop mit „What happens"-Spalte, Pflege nur „When to use"),
  Sync-Invariante jenes Repos einhalten (VERSION-Bump + CHANGELOG im selben Commit).
  Rein kit-interne Skills (wie add-skill selbst) bleiben draußen.
- **Entscheidung:** keine Plugin-Begleitänderungen — add-skill ist repo-lokal
  (`.claude/skills/`), kein Plugin-Inhalt; die Kit-Sync-Invariante greift nicht
  (konsistent mit der F-009-Verbuchung).
- **Vermerk für die nächste project-template-Session:** Die HOW-TO-Zeilen für
  prep-step/choose-stack/update-conventions sind durch F-013–F-015 bereits leicht
  veraltet (u. a. fehlt der Standards-Abdeckungs-Check) — Drift dort beheben; der
  neue Checklisten-Haken verhindert künftige.
- **Geänderte Dateien:** `.claude/skills/add-skill/SKILL.md`.

---

## F-015 — prep-step: Framework-Erkennung mit Fragment-Vorschlag (2026-07-19)

**Aufgabe:** Führt eine Aufgabe ein neues Framework/eine neue Dependency ein, wuchs
der Standards-Bestand des Projekts nicht mit — kein Prozessschritt bemerkte das
fehlende Fragment („Standards wachsen mit").

**Was entstanden ist (Plugin 0.10.0):**

- **Neuer Schritt „2a. Standards-Abdeckung prüfen (Fragment-Check)"** in prep-step,
  zwischen Analyse (§2) und Größenbewertung (§3). **Kosten-Gate:** läuft nur, wenn
  die Analyse neue Frameworks/Dependencies identifiziert UND das Projekt einen
  `<!-- module:coding-standards -->`-Slot hat; sonst stilles Überspringen — kein
  Template-Clone je prep-step-Lauf (das Kit-Repo selbst z. B. hat keinen Slot).
- **Match beider Signaltypen** gegen das zur Laufzeit gelesene Trigger-Mapping
  (`modules/standards/README.md` des aufgelösten Templates): Dependency-Signale
  gegen die neuen Dependencies **und** `*characteristic:*`-Eigenschafts-Trigger
  gegen die Aufgabenbeschreibung. Damit ist der prep-step-Touchpoint von **F-017
  miterledigt**; F-017 verbleibt mit define-requirements-Interview +
  choose-stack-Nachrüstpfad.
- **Vorschlags-Pfade:** Katalog-Fragment vorhanden, aber kein `fragment:NAME`-Marker
  im Projekt → Anhängen als Plan-Bestandteil vorschlagen (Mechanik wie
  `/choose-stack`, idempotent); Treffer-Thema ohne Katalog-Fragment → projektlokales
  Fragment autoren + Promote via `/update-conventions` (AUFWÄRTS) anbieten. **Nur
  vorschlagen, nie still einbauen** — Entscheidung fällt mit der Plan-Freigabe.
- **Plan-Vorlage (§4):** neue Zeile „Standards-Abdeckung" (entfällt, wenn 2a
  übersprungen wurde); Frontmatter-`description` erweitert.
- **Begleitanpassungen:** plugin.json 0.10.0, CHANGELOG-Eintrag,
  README-Tabellenzeile prep-step.
- **Geänderte Dateien:** `plugins/coding-kit/skills/prep-step/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Erkennungsqualität bewusst heuristisch** (Skill-Text, kein Parser) — F-016
  fängt Durchrutscher als Backstop am Zyklusende.

---

## F-014 — update-conventions: Pro-Fragment-Refresh (2026-07-19)

**Aufgabe:** update-conventions aktualisierte CODING-STANDARDS als einen Modul-Part.
Mit Append-Slot und Pro-Fragment-Markern (F-013) musste der Abwärts-Abgleich
fragment-granular werden — ohne projektlokal ergänzte Fragmente zu überschreiben.

**Was entstanden ist (Plugin 0.9.0):**

- **Zwei Diff-Ebenen abwärts:** A2.3 Sonderfall `CODING-STANDARDS.md` — die
  Soll-Fassung wird mit dem **Ist-Slot des Projekts** befüllt, der Datei-Diff zeigt
  damit nur Core-Änderungen (§1–12). Neuer A2-Schritt 6 „Fragment-Abgleich": die
  `fragment:NAME`-Blöcke im Slot einzeln gegen ihr Template-Pendant diffen
  (Sprachfragment ↔ `CODING-STANDARDS.part.md` des Moduls, Katalog-Fragmente ↔
  `modules/standards/<name>.md`) mit denselben Entscheidungen wie je Datei
  (übernehmen / lassen / Override / promoten). Ohne Template-Pendant → projektlokal:
  nie anfassen, nur auflisten; Inline-`<!-- override: … -->` im Block schützt genau
  dieses Fragment.
- **Neu deklarierte Fragmente:** fehlt im Projekt ein inzwischen vom `MODULE.md`
  deklariertes Katalog-Fragment → Anhängen anbieten (Mechanik wie `/choose-stack`,
  idempotent). Reihenfolge-Regel: Bestehendes in-place ersetzen, Neues ans
  Slot-Ende — nie umsortieren (kosmetische Diffs vermeiden).
- **AUFWÄRTS:** projektlokales Fragment kann generalisiert in den Katalog promotet
  werden (`modules/standards/<name>.md` + Katalog-Zeile mit Trigger-Mapping im
  dortigen README); Frontmatter-`description` erweitert.
- **Entscheidung:** keine `manifest-format`-Erhöhung — das Template hat den
  Fragment-Vertrag innerhalb von Format 1 ergänzt, das bestehende Gate in §0 genügt;
  §0 liest zusätzlich MANIFEST § Standards fragments + `modules/standards/README.md`.
  Der A3-Heuristik-Pfad erbt die Fragment-Logik über die gemeinsame Soll-Erzeugung.
- **Begleitanpassungen:** plugin.json 0.9.0, CHANGELOG-Eintrag, README-Tabellenzeile
  update-conventions.
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.

---

## F-013 — choose-stack: Multi-Fragment-Einbau (2026-07-19)

**Aufgabe:** choose-stack installierte den EINEN `CODING-STANDARDS.part.md` eines
Stack-Moduls in den §13-Slot. Das project-template komponiert CODING-STANDARDS
inzwischen aus framework-granularen Fragmenten (Vertrag: MANIFEST § Standards
fragments; umgesetzt dort seit Template-VERSION 0.7.0, verifiziert gegen 0.8.0) —
ein Modul deklariert MEHRERE Fragmente, der Ein-Part-Einbau griff nicht mehr.

**Was entstanden ist (Plugin 0.8.0):**

- **choose-stack §0:** liest zusätzlich MANIFEST § Standards fragments und
  `modules/standards/README.md` (Fragment-Katalog).
- **choose-stack Modus B — Append-Prozedur:** Standards-Fragmente werden im Slot
  `<!-- module:coding-standards -->` **angehängt**, nie ersetzt. Fragmentliste in
  Reihenfolge: eigenes Sprachfragment (`CODING-STANDARDS.part.md`) + Katalog-Fragmente
  laut `Standards fragments:`-Zeile des `MODULE.md`, tolerant gelesen (fett/plain;
  `(none)`/leer/fehlend = keine). Die Quell-Dateien tragen ihre
  `<!-- fragment:NAME -->`-Marker bereits — nichts wird gewrappt. **Idempotent** je
  Marker: Vorhandenes nie doppelt einbauen, nie erneuern (Erneuern =
  `/update-conventions`); der docs-only-Platzhalter im Slot fällt beim Erst-Einbau weg.
- **Modulwechsel:** Sprachfragment wird gegen das neue getauscht; Katalog-Fragmente
  bleiben stehen und werden nur aufgelistet („noch aktuell?"). **Entscheidung
  (Nutzer):** kein automatisches Entfernen — Katalog-Fragmente sind cross-cutting und
  können den Sprachwechsel überleben; Entfernen ist Projektentscheidung.
- **new-project:** Referenz des Modul-Einbaus nachgezogen — „Standards-Fragmente
  anhängen" statt „CODING-STANDARDS-Slot füllen".
- **Begleitanpassungen:** plugin.json 0.8.0, CHANGELOG-Eintrag, README-Tabellenzeile
  choose-stack.
- **Geänderte Dateien:** `plugins/coding-kit/skills/choose-stack/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Abgrenzung:** Fragment-Refresh downstream bleibt F-014 (update-conventions);
  Erkennungs-/Backstop-Logik bleibt F-015/F-016; Eigenschafts-Trigger bleibt F-017.

---

## TPL-008 — Ship the privacy lint + private blocklist to projects (2026-07-18)

**Problem:** Downstream projects had only gitleaks (secrets) as a commit gate — nothing
caught private names, local paths, IPs, or private emails, although the conventions demand
living docs stay publishable. The template repo gained this guard in TPL-004b; projects had
none of it. The coding-kit `/step-done` privacy scan is soft and does not know the owner's
private names.

**What was built (7 files; VERSION 0.7.1 → 0.8.0):**

- `core/scripts/privacy-lint.sh` (new managed file): POSIX sh + grep, no other toolchain.
  Generic patterns always on (absolute local paths, IPs and emails outside the documentation
  allowlists — defaults mirror this repo's `validate.py`); optional gitignored
  `private/blocklist.txt` (one term per line, `#` comments, case-insensitive substring)
  adds project-private terms, silently skipped where absent (CI). Scans the staged files
  lefthook passes; `--all` re-invokes over `git ls-files` (NUL-safe) for tree audits;
  skips `private/`, `mise.lock`, binary/empty files.
- `core/lefthook.yml`: third pre-commit job `privacy-lint` next to secrets-scan/format.
- `core/private/README.md`: blocklist convention documented; `core/CONTRIBUTING.md`:
  secrets-policy section now names the full pre-commit gate (gitleaks + privacy lint).
- `MANIFEST.md` (new managed-file row), `VERSION`, `CHANGELOG.md`.

**Notable decisions:**

- **Shell instead of Python** (decided with the owner): the core toolchain guarantees no
  Python (mise pins just/lefthook/gitleaks), and the patterns are plain regexes — POSIX
  sh + grep exist in every git environment. On Windows that means Git Bash or WSL; a bare
  cmd/PowerShell setup fails loudly, never silently (noted in the script header).
- Downstream CI integration deliberately out of scope — justfiles are module-owned;
  the pre-commit gate is the deliverable.
- Kept as a hard, deterministic complement to the model-driven `/step-done` privacy scan;
  the blocklist is the only control that knows the owner's actual private names.

**Verification:** 9-case sandbox suite green on macOS/BSD grep (clean file, path/IP/email
leaks, allowlisted values, blocklist hit case-insensitive, blocklist absent → silent skip,
binary skip, `--all` aggregation, no-args exit 0); `just check` green — the validator scans
the new script without false positives from its own regex literals.

---

## TPL-007 — Refresh repo docs for the fragment catalog (2026-07-18)

**Problem:** After TPL-002/TPL-003/TPL-006 the repo docs lagged behind the fragment mechanism: the
root README still described a module's standards contribution as "a language section" and did
not mention the `modules/standards/` catalog at all; `modules/README.md` listed only stack
modules, leaving the `standards/` directory unexplained.

**What was built (4 files; VERSION 0.7.0 → 0.7.1):**

- `README.md` (repo-own doc, outside template content): structure overview now describes the
  fragment mechanism (language fragment + declared catalog fragments) and lists
  `modules/standards/` with the trigger→fragment mapping.
- `modules/README.md`: pointer that `standards/` is not a stack module but the cross-cutting
  fragment catalog, linking its README.
- `VERSION`, `CHANGELOG.md` (patch bump — catalog/module README is template content per
  TPL-002/TPL-003 precedent; the root README alone would not have bumped).

**Verification:** `just check` green; wording matches `MANIFEST.md` § Standards fragments;
`core/README.md` checked and deliberately unchanged (project-facing seed, references no
fragment mechanics).

---

## TPL-006 — Audit / activity-logging standard (2026-07-18)

**Problem:** Mutating and administrative actions should leave an audit trail, but this is
neither a web framework nor one of the TPL-003 fragments — it went uncaptured, and a downstream
project inheriting the template's standards would have lost the rule.

**What was built (4 files; VERSION 0.6.0 → 0.7.0):**

- `modules/standards/audit-logging.md` (new): accountability trail for services with
  user/admin mutations — what must be logged (domain mutations, permission/role changes,
  auth and admin operations, including denied attempts), what an entry carries (actor,
  action, target, timestamp, outcome — never secrets or full payloads), properties
  (append-only, coupled to the mutation, queryable, deliberate retention), and the
  separation from application logging (accountability vs. debugging).
- `modules/standards/README.md`: registered the fragment; the catalog mapping now supports
  **project-characteristic triggers** alongside dependency signals, for fragments no package
  manifest can reveal.
- `VERSION`, `CHANGELOG.md`.

**Notable decisions:**

- **Catalog fragment, not a core section** (decided with the owner): an audit trail is real
  architecture and would be wrong to impose on libraries, CLIs, or local tools.
- **Trigger is a project characteristic** ("service with user/admin mutations"), evaluated by
  coding-kit — in the requirements interview at instantiation, or when a matching feature is
  planned. This repo only defines the data and the contract, as with dependency signals.

**Verification:** `just check` green (fragment markers balanced, no dangling declarations,
privacy + blocklist lint); no module declares the fragment — valid, it is pulled per project
characteristic.

---

## TPL-005 — Async in-flight / promise-dedup concurrency standard (2026-07-18)

**Problem:** Several independent triggers starting the same expensive or side-effectful async
operation (a token refresh, a migration, a cache populate, an external call) cause duplicate
work, wasted load, or corruption from a half-done shared state. Surfaced during the TPL-003
source analysis; not web-framework-specific.

**What was built (3 files; VERSION 0.5.0 → 0.6.0):**

- `core/CODING-STANDARDS.md` §7, heading extended to "Error handling, resilience &
  concurrency": two new bullets — **deduplicate concurrent async work** (the first caller
  stores its in-flight promise/future and every concurrent caller awaits that same one;
  applies where shared mutable state, several independent async triggers, and expensive or
  side-effectful work meet; cheap idempotent reads need no guard) and **completion marker
  last** (the "done" flag is set only after the awaited work completes, so concurrent readers
  never observe a half-finished state as done).
- `VERSION`, `CHANGELOG.md`.

**Notable decisions:**

- **Core, not a catalog fragment** (decided with the owner): the pattern has no
  dependency-based trigger — the situation emerges mid-development, and a fragment pulled
  only after someone notices the problem class arrives too late. As a conditional rule it
  costs unaffected projects almost nothing.
- **Heading extension instead of a new numbered section** — §§8–13 keep their numbers; the
  §13 slot is referenced externally (MANIFEST, module docs), so renumbering would ripple.

**Verification:** `just check` green; §7 re-read; the only §7 cross-reference in the tree
(`modules/go/CODING-STANDARDS.part.md`) refers to the section number, which is unchanged.

---

## TPL-004b — Remediate real-name leaks: private blocklist check in the validator (2026-07-18)

**Problem:** Nothing prevented a private name from slipping into the public tree again — the
privacy lint only covered generic patterns (paths, IPs, emails), not the owner's project
names, and the name list itself must never live in the public tree.

**What was built (1 file — repo tooling, no VERSION bump):**

- `scripts/validate.py`: new `check_blocklist` — loads `private/blocklist.txt` if present
  (one term per line, `#` comments) and flags any case-insensitive substring hit in scanned
  files. The blocklist is gitignored (`private/*`) and absent in CI, where the check silently
  skips; locally lefthook's pre-commit runs `just check`, so the gate fires before every
  commit. `private/` is in SKIP_DIRS, so the list itself is never scanned and its terms never
  appear in CI output.
- `private/blocklist.txt` (untracked): seeded with the owner's private project names.

**Verification:** `git check-ignore` confirms the blocklist is ignored; `just check` green
with the seeded list; a temporary fixture containing a listed term made the check fail
(exit 1), removed → green again; with the blocklist moved aside the validator stays green
(CI-safe silent skip).

**This completes TPL-004:** history purged and force-pushed (TPL-004a), recurrence guarded by the
local blocklist gate (TPL-004b). Generalizing the remediation procedure into a reusable
coding-kit skill remains a coding-kit backlog idea.

---

## TPL-004a — Remediate real-name leaks: history rewrite + force-push (2026-07-18)

**Problem:** A concrete downstream project name had been committed and pushed in the initial
build (in `modules/go/MODULE.md` and the TPL-001 archive entry). The working tree was scrubbed
in TPL-002b, but the published history still held the name.

**What was done (history-only operation; no tracked file changes, no VERSION bump):**

- Full detection first: history-wide scan of all refs (blobs, commit messages, spelling
  variants) against the owner's private name blocklist plus personal-data patterns (emails,
  IPs, local paths, real names). Result: exactly one leaked string in two files across four
  commits; commit identities all GitHub-noreply; nothing else.
- Rewrote the history in a fresh scratchpad clone with `git filter-repo --replace-text`,
  literally replacing the leaked name with a redaction token. All commits got new SHAs (root
  commit included); the rewrite was force-pushed to `origin/main` after explicit owner
  approval — also publishing the previously unpushed TPL-002a–TPL-003b commits in rewritten form.
- Working repo switched onto the rewritten history (`git reset --soft`, uncommitted work
  preserved); old local objects purged via `git reflog expire` + `git gc --prune=now`;
  scratchpad artifacts (clone + replacements file) deleted.

**Verification:** history-wide scan after the rewrite = 0 hits (rewritten clone and working
repo); HEAD tree hash identical before/after (byte-identical content); `git ls-remote` shows
`main` on the rewritten head; `just check` green.

**Notable decisions:**

- **Accepted residual risk, no GitHub support request:** the old, now-unreferenced commits
  stay reachable on GitHub via direct SHA URLs until garbage-collected. Accepted because the
  leaked string is a project name (not a secret) and the repo has no forks or stars, so the
  old SHAs are effectively known to no one.
- The repo's own agent guardrail (deny on `git push --force`) was respected: the force-push
  was executed by the owner in their terminal, not by the agent.
- Downstream re-fix was not needed: `MODULE.md` is never copied into instantiated projects
  (MANIFEST module contract), so no instantiated repo ever carried the leak.

---

## TPL-003b — Web-standards fragments: api-design + docker + nginx (2026-07-17)

**Problem:** After TPL-003a (react, prisma), the web catalog still lacked the API and
infrastructure standards a full-stack project needs.

**What was built (6 files; VERSION 0.4.0 → 0.5.0):**

- `modules/standards/api-design.md` (new): thin-routes/fat-services, URL/method/status
  conventions, schema-validated request/response, and the web security boundary (explicit
  permission-based authorization, rate limiting, forbidden patterns, credentials & data
  protection, security headers).
- `modules/standards/docker.md` (new): multi-stage images, non-root runtime, layer caching,
  healthchecks, PID-1 signal handling, compose, entrypoint & startup.
- `modules/standards/nginx.md` (new): reverse-proxy hardening — per-location header
  re-declaration, WebSocket, compression, SPA cache strategy, HSTS placement.
- `modules/standards/README.md`: three mapping rows; `VERSION`, `CHANGELOG.md`.

**Notable decisions:**

- Generalized from real full-stack sources and senior-hardened (idempotency, `Retry-After`,
  cursor pagination, no stack traces to clients; proxy timeouts / modern TLS). Name-free, no
  version pins; project-specific rules (RBAC internals, activity-log calls, a GDPR ticket
  reference) removed.
- A coverage check against the sources confirmed no framework-general rule was dropped.

**Verification:** `just check` green (markers balanced, no dangling declarations, privacy lint).

**This completes TPL-003:** the web standards catalog now holds react, prisma, api-design, docker,
nginx. Composing them into a project is the coding-kit side (a full-stack module or the prep-step
hook), tracked separately.

---

## TPL-003a — Web-standards fragments: react + prisma (2026-07-17)

**Problem:** The composable-standards catalog (`modules/standards/`) existed but held no
fragments — a full-stack project had nothing to compose for its frontend/data layer.

**What was built (5 files; VERSION 0.3.1 → 0.4.0):**

- `modules/standards/react.md` (new): React standard — function components + hooks, typed props,
  custom hooks, local/server-state discipline, component size, design-token/slot-based styling,
  accessibility, i18n, performance.
- `modules/standards/prisma.md` (new): Prisma standard — deliberate querying (no N+1, paginate,
  transactions, one shared client, explicit constraint handling) and immutable migrations with
  DB-enforced integrity.
- `modules/standards/README.md`: registered both in the framework→fragment mapping.
- `VERSION`, `CHANGELOG.md`.

**Notable decisions:**

- Generalized from real full-stack sources and **senior-hardened** (not a copy): added
  server-state-via-cache-layer, stable list keys, controlled inputs, accessibility and a lazy-UI
  error boundary to `react`; deliberate `select`, one shared client, explicit constraint-violation
  handling and indexing to `prisma`.
- **Name-free**, no version pins; project-specific rules (domain abstractions, project theme
  specifics) deliberately left out. A coverage check against the sources confirmed no
  framework-general rule was dropped.

**Verification:** `just check` green (markers balanced, no dangling declarations, privacy lint);
both fragments self-wrapped and mapped. (Same commit also lands the TPL-003 plan and the TPL-005/TPL-006
intake.)

---

## TPL-002c — Composable CODING-STANDARDS: validator support (2026-07-17)

**Problem:** Nothing enforced the new fragment contract, so a malformed fragment marker or a
`MODULE.md` declaring a non-existent catalog fragment would pass silently.

**What was built (1 file — repo tooling, no VERSION bump):**

- `scripts/validate.py`: two new checks — (a) `check_fragment_markers` scans every file for
  `<!-- fragment:NAME -->` markers and stack-verifies they are balanced and well-nested; (b)
  `check_fragment_declarations` parses each `modules/*/MODULE.md` "Standards fragments"
  declaration and flags any fragment name absent from the `modules/standards/` catalog.

**Notable decisions:**

- The marker regex matches lowercase-kebab names only (`[a-z0-9][a-z0-9-]*`), so documentation
  placeholders (`fragment:NAME` uppercase, `fragment:<name>` bracketed) never false-positive —
  keeping the MANIFEST / README / §13 example markers clean.
- No VERSION bump: `validate.py` is repo tooling, not shipped template content.

**Verification:** `just check` green on the real repo; temporary fixtures confirmed both checks
fire (unclosed `fragment:zzz`; dangling declaration `nope`), then removed and re-verified green.

**This completes TPL-002** (composable CODING-STANDARDS fragments): contract + catalog scaffold
(TPL-002a), module migration (TPL-002b), validator (TPL-002c). Web fragments follow in TPL-003; the
coding-kit-side assembly is tracked separately.

---

## TPL-002b — Composable CODING-STANDARDS: migrate existing modules (2026-07-17)

**Problem:** After TPL-002a defined the fragment contract, the existing stack modules still shipped
their `CODING-STANDARDS.part.md` as unwrapped blocks — not conforming to the new append/marker
scheme.

**What was built (8 files):**

- `modules/{go,python,ts-node}/CODING-STANDARDS.part.md`: each wrapped in
  `<!-- fragment:<module> -->` … `<!-- /fragment:<module> -->` markers; rule text unchanged
  (marker-only diff — exactly 6 insertions total, markers balanced open=close per module).
- `modules/{go,python,ts-node}/MODULE.md`: added a `Standards fragments: (none)` declaration —
  these single-package language modules pull no catalog fragments.
- `VERSION` 0.3.0 → 0.3.1; `CHANGELOG.md` entry.

**Also in this commit (privacy scrub, not TPL-002b scope):** replaced a concrete downstream project
name with a neutral wording in `modules/go/MODULE.md` and the TPL-001 archive entry, per the
repo-wide no-real-names rule. Remediating the already-published git history is tracked as TPL-004.

**Notable decisions:**

- Fragments self-wrap (the marker lives in the fragment file), so the coding-kit assembly just
  concatenates — no wrapping at runtime.
- A module's own language part is `fragment:<module>`; catalog fragments are declared separately
  and are none for these three.

**Verification:** `just check` green; marker-only diff confirmed; markers balanced; declarations
present in all three `MODULE.md`; working-tree name scan clean.

---

## TPL-002a — Composable CODING-STANDARDS: fragment contract + catalog scaffold (2026-07-17)

**Problem:** The §13 stack slot took a single inserted module part, so a project could not
compose standards for several frameworks or grow them over time. TPL-002a lays the contract for
composable fragments; migration (TPL-002b) and validator support (TPL-002c) follow.

**What was built (5 files):**

- `MANIFEST.md`: registered the `<!-- fragment:NAME -->` … `<!-- /fragment:NAME -->` marker;
  updated the `module:coding-standards` marker and the `CODING-STANDARDS.part.md`
  module-contract row to append/wrap semantics; new "## Standards fragments" section (catalog,
  the `MODULE.md` `Standards fragments:` declaration, policy, assembly boundary).
- `core/CODING-STANDARDS.md`: §13 slot now documents append + per-fragment markers.
- `modules/standards/README.md` (new): catalog scaffold — framework→fragment mapping table
  (empty until fragments are authored) + how a module declares fragments.
- `VERSION` 0.2.0 → 0.3.0; `CHANGELOG.md` entry.

**Notable decisions:**

- Central reusable catalog `modules/standards/` (not fragments buried per stack module) — a
  fragment like `react`/`docker` can be pulled by any module that needs it.
- Fragments are self-wrapping (each file carries its own `fragment:NAME` markers); skills
  concatenate, no wrapping at runtime.
- A module pulls its own language fragment implicitly and declares additional catalog fragments
  via a `Standards fragments:` line in its `MODULE.md`.
- Runtime assembly stays coding-kit logic; TPL-002 defines only the contract + data + validator.
  Full end-to-end composition needs the coding-kit `choose-stack` change (tracked separately).

**Verification:** `just check` (validator) green; §13 slot and MANIFEST section reviewed;
internal link `../../MANIFEST.md` resolves; secrets/privacy scan clean.

---

## F-011 — build-step vom step-done-Handoff entkoppeln (2026-07-14)

**Was entstanden ist (Plugin 0.7.0):**

- **Anlass (Nutzer-Beobachtung, aus einem update-conventions-Lauf in einem Downstream-Projekt):**
  build-step ließ je Substep *immer* step-done laufen. Unerwünscht bei interaktiver
  Einzelarbeit — der Nutzer will vor dem Abschluss selbst prüfen und ggf. anpassen; das
  automatische Durchlaufen soll nur im autonomen `/goal`-Lauf über mehrere Subfeatures
  gelten.
- **Modus-Split in build-step:** Neuer expliziter Erkennungssatz im Kopf von „2.
  Umsetzung" — aktiver `/goal`-Lauf mit erteilter Commit-Freigabe = **autonom**, jede
  andere Nutzung = **interaktiv**. Schritt 5 verzweigt: interaktiv wird step-done nur
  **empfohlen** (nächster Substep erst nach Nutzer-Abschluss bzw. „weiter"), autonom
  läuft step-done je Substep automatisch wie bisher (die `/goal`-Abschlussbedingung
  verlangt es). Description, Loop-Satz und Abschluss-/DONE-Markierung entsprechend
  nachgezogen.
- **Begleitanpassungen:** plugin.json 0.7.0, CHANGELOG-Eintrag, README (build-step-
  Tabellenzeile + Zyklus-Prosa: step-done ist interaktiv ein bewusster eigener Schritt).
- **Entscheidung:** Unterscheidungssignal ist der laufende `/goal`-Kontext + die
  laufbezogene Commit-Freigabe, nicht ein neues Argument — kein Bruch am `/goal`-Flow,
  dessen Abschlussbedingung step-done ohnehin explizit nennt.
- **Nicht hierher (in project-template notiert):** MANIFEST listet `core/private/README.md`
  ohne existierende Datei (Template-Bug); dessen reichere AI-DISCLOSURE ist noch nicht
  als promote/override entschieden.

---

## F-010 — Status-Marker-Konvention + Grenze add-feature/prep-step (2026-07-13)

**Was entstanden ist (Plugin 0.6.0):**

- **Anlass (Nutzer-Beobachtung):** add-feature-Einträge waren oft schon fast fertige
  Pläne, prep-step legte noch einmal nach; außerdem war einem Eintrag nicht anzusehen,
  ob er nur aufgenommen (→ prep-step) oder schon geplant (→ build-step) ist.
- **Status-Marker-Konvention:** `**Status:**`-Zeile direkt unter der
  Eintrags-Überschrift mit sprachinvarianten Tokens — `BACKLOG` (setzt add-feature) →
  `PLANNED` (setzt prep-step, zusätzlich `(PLANNED)` an der Index-Zeile); fertig
  bleibt Done-Tabelle + `(DONE)` im FEATURE-INDEX. Toleranz für Alt-Einträge ohne
  Status-Zeile (Substeps vorhanden ≈ geplant; Zeile bei nächster Berührung nachziehen).
- **add-feature geschärft:** „Mögliche Umsetzung" → „Lösungsskizze", explizit
  unverbindlich: keine Dateilisten, keine Zerlegung in Schritte, keine
  Abnahmekriterien (bleibt prep-step); optionale Ablauf-/Ansatz-Zusatzabschnitte
  gestrichen; Alt-Überschriften werden nicht umbenannt.
- **prep-step geschärft:** hinterfragt die Skizze statt sie zu übernehmen (jede
  Annahme gegen den aktuellen Codestand verifizieren, eigene Alternativen mit
  Begründung); Plan-Vorlage um „Bewertung der Lösungsskizze" ergänzt; setzt `PLANNED`
  auch bei kleinen Aufgaben; zieht die Skizze bei Abweichung auf den beschlossenen
  Stand nach.
- **Begleitanpassungen:** build-step prüft den Marker beim Plan-Laden (`BACKLOG` →
  erst prep-step empfehlen); step-done ersetzt `(PLANNED)` durch `(DONE)` und nimmt
  die Status-Zeile nicht mit ins Archiv; `docs/skill-authoring.md` führt die
  Konvention als Pflicht-Baustein; README (Tabellenzeilen, Zyklus-Satz), CHANGELOG,
  plugin.json 0.6.0.
- **Entscheidung:** Trennung add-feature/prep-step bleibt bestehen (Erfassungs- ≠
  Umsetzungszeitpunkt; build-step hängt am prep-step-Output; add-feature muss als
  billiges Scope-Schutz-Ventil erhalten bleiben) — statt eines Merges wurde die
  Grenze geschärft und per Marker sichtbar gemacht.

---

## F-009 — Repo-lokaler Pflege-Skill add-skill (2026-07-13)

**Was entstanden ist (Repo-Infrastruktur, kein Plugin-Inhalt — daher kein
Version-Bump):**

- **`.claude/skills/add-skill/SKILL.md`** — standardisiert Anlage und Änderung von
  Plugin-Skills in diesem Repo: Kontext laden (`docs/skill-authoring.md` als
  referenzierte Quelle der Wahrheit, nicht dupliziert) → M1-Kurz-Interview
  (neu/ändern, Name + Kategorie, Trigger, Frontmatter-Flags, Pflicht-Bausteine) →
  Bauen mit Write-then-Verify → **Begleit-Änderungs-Checkliste** (plugin.json-Version
  UND Description-Aufzählung, CHANGELOG, README-Tabelle UND Prosa, ggf.
  Authoring-Doku) → Verifizieren (`just check`, `/reload-plugins`) → Abschluss mit
  explizitem PROGRESS/ARCHIVE-Schritt (F-Nummer vergeben, step-done; auf
  Nutzerwunsch eigens betont).
- Modell-Aufruf bewusst erlaubt (kein `disable-model-invocation`): der Skill zieht
  automatisch, wenn der Nutzer einen Kit-Skill bauen/ändern will.
- Projekt-CLAUDE.md: Verweis auf `/add-skill` bei den Strukturregeln;
  Dogfooding-Zyklus um build-step ergänzt.
- Entscheidungen: repo-lokal statt im Plugin (Plugin-Skills werden global
  installiert — Repo-Pflege wäre dort Ballast); CLAUDE.md hält nur Invarianten,
  Prozeduren gehören in Skills (progressive disclosure). Ausbau-Ideen notiert:
  `just new-skill`-Scaffold-Rezept, validate.py-Prüfung „jeder Skill hat eine
  README-Zeile".

---

## F-008 — Workflow-Skill build-step + autonome Läufe (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **build-step** — schließt die Lücke der Implementierungsphase (bisher formloses
  „setze F-xxx um"): prep-step-Plan laden, Substeps mit Verifikation je Schritt
  abarbeiten (Write-then-Verify, just-Checks, Abnahmekriterien einzeln gegen
  Tool-Ausgaben abhaken), je Substep Übergabe an step-done. Leitplanken: Plan-Treue,
  Scope-Schutz (Entdeckungen → add-feature statt still mitbauen), nie pushen, keine
  History-Rewrites, PROGRESS-Pflege nur via step-done.
- **Modus `autonom`:** baut nicht, sondern richtet einen `/goal`-Lauf ein (verifiziert
  gegen die Claude-Code-Doku: /goal hält die Session Turn für Turn am Arbeiten, bis
  ein Prüfmodell die Bedingung als erfüllt bewertet; Skills können /goal nicht selbst
  absetzen). Ablauf: Kontext + Plan laden → Voraussetzungen nennen (Trust-Dialog,
  Hooks, Auto-Modus für unbeaufsichtigte Läufe) → einmalige laufbezogene
  Commit-Freigabe einholen → fertige Goal-Zeile ausgeben (Varianten mit/ohne
  Freigabe, Turn-Limit als Stopp-Klausel, ~5 Turns je Substep) → enden; der Lauf
  startet mit dem Absenden der Goal-Zeile durch den Nutzer.
- **Commit-Granularität entschieden:** step-done + Commit je Substep (prep-step
  zerlegt in einzeln lauffähige Substeps = natürliche Commit-Grenzen; Commits sind
  im autonomen Lauf die Checkpoints gegen Entgleisung).
- **step-done erweitert:** Ausnahme-Regel zur Commit-Frage — bei dokumentierter
  laufbezogener Freigabe committen ohne Nachfrage (nach grünen Checks/Scans, nie
  Push); ohne Freigabe im autonomen Lauf Commit-Vorschlag festhalten und
  weiterarbeiten statt auf Antwort blockieren (schließt die Grauzone, in der ein
  Goal-Lauf sonst raten würde).
- **Vorlagen-Sync:** Halbsatz in `templates/global-CLAUDE.md` und (per
  Übernahme-Regel der Vorlage) in der live `~/.claude/CLAUDE.md`: laufbezogene
  Freigabe zählt als Fragen, Push bleibt tabu.
- README: build-step-Zeile, Zyklus-Satz mit drei Implementierungswegen
  (build-step / teach-step / frei + step-done), neue Anleitung „Autonomer Lauf
  (build-step + /goal)".

---

## F-007 — Workflow-Skill teach-step (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **teach-step** — Lehrer-Modus für die Implementierungsphase: der Nutzer setzt eine
  Aufgabe (F-Nummer) selbst um, der Skill leitet sokratisch an, gibt gestufte Hilfe
  (Leitfrage → Tipp → Hinweis mit Datei:Zeile → Pseudocode → Musterlösung nur auf
  ausdrückliche Anfrage, erklärt statt zum Kopieren), kontrolliert per `git diff` +
  Re-Lesen und lässt Tests über die just-Rezepte laufen.
- **Schreibverbot zweistufig:** hart via `disallowed-tools: Write, Edit, NotebookEdit`
  im Frontmatter; für Bash per Anweisung (nur lesend/prüfend — keine Redirects, kein
  `sed -i`/`rm`/`mv`, kein `git add`/`commit`). Bitten um Selbst-Implementierung lehnt
  der Skill ab und bietet stattdessen das Beenden des Lehrer-Modus an.
- **Lern-Interview (M1), gemeinsam mit dem Nutzer designt:** (1) Vertrautheit mit
  drei verhaltensverankerten Stufen (Neuland/Grundlagen/Routiniert — jede Option
  nennt, was sie bewirkt), (2) Lernziel mit vier Optionen (Default „Struktur &
  Verdrahtung" — welche Datei wohin, wie Teile verbunden werden; dazu Sprache &
  Syntax, Konzept & Design, Diese Codebase). Der Führungsgrad wird nicht abgefragt,
  sondern abgeleitet (Trittsteine/Wegweiser/Kompass, per Zuruf änderbar);
  Nachkalibrierungs-Regel: Antworten sind Startpunkt, kein Vertrag.
- **Graphiti-Lernprofil (optional):** Level/Themen des Nutzers in der persönlichen
  group_id (Konvention `main`) nachschlagen und fortschreiben — bekannte Antworten
  überspringen das Interview.
- Abgrenzung: PROGRESS-Pflege, Scans und Commit bleiben bei `step-done`; teach-step
  schreibt keine Doku und committet nie.
- Entscheidungen: Platzierung im coding-kit statt eigenem Trainer-Plugin (an
  prep-step/step-done-Workflow gekoppelt; Extraktion später billig). Bash bewusst
  erlaubt, damit der Lehrer Tests laufen lassen kann — Nutzer entschied sich gegen
  das strengere Bash-Verbot.

---

## F-006 — Utility-Skill refine-prompt (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **refine-prompt** — übergebenen Prompt analysieren (Ziel, Zielgruppe, Ausgabeformat,
  impliziter Kontext), Schwachstellen benennen (Unklarheiten, fehlende Rollen-/
  Kontextangaben, fehlende Erfolgskriterien), nach Prompt-Engineering-Best-Practices
  neu formulieren und den verbesserten Prompt anschließend ausführen. Ausgabe:
  Schwachstellen → verbesserter Prompt (kopierbar) → Ergebnis.
- Nur manuell aufrufbar (`disable-model-invocation: true`); bei leerem `$ARGUMENTS`
  wird nach dem Prompt gefragt (M1). Kein Projektkontext-/M4-Baustein nötig — der
  Skill fasst nichts im Projekt an.
- Erster Skill der neuen Kategorie **Utility-Skills** (Plugin-Description entsprechend
  erweitert); Skill-Text vom Nutzer ausformuliert, bei der Aufnahme gegen
  `docs/skill-authoring.md` geprüft (Korrekturen: Namespacing `/coding-kit:refine-prompt`,
  M1-Fallback ergänzt).

---

## F-005 — Pflege-Skills (2026-07-07)

**Was entstanden ist (Plugin 0.4.0):**

- **update-conventions** — bidirektionaler Konventions-Sync mit drei Ästen:
  - *Abwärts mit Stempel:* Projekte via Marker-Topic (`gh search repos … topic:coding-kit`)
    plus lokale Checkouts finden; CHANGELOG-Fenster zwischen Stempel und aktueller
    VERSION zeigen; Soll-Fassung jeder managed Datei (Core + Modul-Parts) mit
    rückaufgelösten Projektwerten instanziieren und gegen den Ist-Stand diffen;
    je Datei: übernehmen / so lassen / als Override registrieren / promoten.
    Override-Schutz greift vor dem Diffen (`convention-overrides.md` + Inline-Marker);
    seed-Dateien und public-only-Regeln werden respektiert; Abschluss: Stempel auf neue
    VERSION, `just check` grün, Commit-Frage.
  - *Abwärts ohne Stempel (Altprojekte):* heuristischer Abgleich + Migrationen als
    einzeln bestätigte Schritte — instructions.md→CLAUDE.md, Entfernen lokaler
    Core-Skill-Kopien (nur bei installiertem Plugin; durch den Kollisionstest aus F-001
    abgesichert, projektspezifische Skills bleiben immer), Renovate-Onboarding,
    Tooling-Nachrüstung, abschließend Stempel-Angebot.
  - *Aufwärts („promote"):* projektlokale Änderung generalisieren (Werte → Platzhalter,
    englisch, personendatenfrei) und in den Kern heben — Template-Sync-Invariante im
    selben Commit (VERSION + CHANGELOG + ggf. MANIFEST), danach optional Abwärts-Lauf;
    alternativ Registrierung als Override. Pro Änderung genau eine Entscheidung.
- **check-upstreams** — Watchliste `upstreams.json` im Kit-Repo (bewusst nicht im
  Plugin-Install-Verzeichnis: sie wird geschrieben und committed). Je Eintrag:
  Erstprüfung (Ist-Zustand) oder Folgeprüfung (`gh api compare <ref>...HEAD` +
  Releases), Bewertung gegen den hinterlegten Zweck, Übernahme-Vorschläge (Umsetzung
  via add-feature als F-Nummer), Ref-/Datums-Update nach Bestätigung. /loop-tauglich
  (dann nur berichten).
- **Watchliste initial:** `AlexPEClub/ai-coding-starter-kit` mit Ref auf Analysestand
  (HEAD `21a97bb…`, letzter Push 2026-06-03 — Analyse vom 2026-07-07 deckt ihn ab) und
  `betterleaks/betterleaks` (verifiziert: existiert, MIT, vom gitleaks-Autor;
  gitleaks erhält nur noch Security-Patches) mit `last_checked_ref: null` —
  die Erstprüfung bewertet Reifegrad und Migrationsaufwand für den Scanner-Wechsel.

**Entscheidungen:**

- update-conventions diffe **instanziierte Soll-Fassung vs. Ist** statt
  Drei-Wege-Merge über historische Template-Stände — robuster, und der Stempel
  liefert trotzdem Determinismus (Update-Fenster + CHANGELOG-Kontext).
- Beide Skills `disable-model-invocation: true` — Pflegeläufe startet nur der Nutzer.

---

## F-004 — Globale CLAUDE.md-Vorlage (2026-07-07)

**Was entstanden ist:** `templates/global-CLAUDE.md` — die schlanke Vorlage der globalen
House-Defaults (Sprache & Stil, Git-/Commit-Regeln inkl. Laufzeit-Auflösung der
Noreply-E-Mail, Graphiti-Regeln mit group_id-Quelle Root-CLAUDE.md + `main` für
Übergreifendes, Arbeitsweise mit Write-then-Verify, F-Nummern-Workflow, private/-
Konvention, Verweis auf die Plugin-Skills). Die Datei ist bewusst schlank (lädt in jede
Session) und identisch mit `~/.claude/CLAUDE.md` auf dem Rechner — dadurch funktioniert
der bestehende Installer-Schritt (cp bei Neueinrichtung, diff-Hinweis bei Abgleich) ohne
Code-Änderung; er war ab F-001 vorbereitet und ist jetzt aktiv.

**Migration (einmalige Nutzeraktion, erledigt):** Inhalte der Legacy-Datei
`~/.claude/instructions.md` überführt und modernisiert — group_id-Quelle ist jetzt die
Root-CLAUDE.md des Projekts (nicht mehr `.claude/instructions.md`); hartkodierte
E-Mail-Adressen durch Laufzeit-Auflösung via `gh api` ersetzt (die Vorlage ist public —
keine Identität im Text). Die Legacy-Datei wurde nach Backup in `private/` gelöscht
(sie wurde von Claude Code ohnehin nicht geladen).

**Entscheidungen:**

- Vorlage und lokale Datei bleiben byte-identisch und generisch (keine persönlichen
  Werte nötig — alles Persönliche kommt zur Laufzeit oder aus der Personal-Config).
- Kein plugin.json-Bump: `templates/` und Installer sind Repo-, nicht Plugin-Inhalt;
  die Sync-Invariante (Version + CHANGELOG) gilt nur für Skills/Hooks.

---

## F-003 — /new-project-Orchestrator (2026-07-07)

**Was entstanden ist:** `plugins/coding-kit/skills/new-project/SKILL.md` (Plugin 0.3.0) —
der Orchestrator über dem project-template, nach dem Muster des bewährten
Maschinen-Anlage-Skills (Inputs sammeln statt raten, nichts ungefragt, Templates aus
der Quelle statt inline):

- **Schritt 0 (M1):** „Was soll das Projekt können?" → Short-Info (ein Satz, publishbar),
  mehrfach wiederverwendet (Repo-Beschreibung, CLAUDE.md, README, Graphiti, Namensfindung);
  bei Projekten aus einem Quelldokument (z. B. STARTPROMPT-Datei) wird die Short-Info
  daraus vorgeschlagen.
- **Abfragen** mit Defaults, Sub-Skills aufrufbar, Aufschieben erlaubt: Name (/name-it),
  Sichtbarkeit (privat), Lizenz (/choose-license; TBD nur bei privat), Modul
  (/choose-stack; offen → docs-only), Doku-Sprache (Deutsch bei privat, Englisch bei
  public), group_id (= Name; „kein Graphiti" möglich), Anforderungen jetzt
  (/define-requirements) oder später.
- **Plan → Bestätigung → Ausführung**, jeder außenwirksame Schritt einzeln bestätigt:
  `gh repo create --template --clone` (kein git init) + lokale Autor-Config via gh api;
  Instanziierung streng nach den MANIFEST-Tabellen (Platzhalter-Registry,
  template:adapt konkretisieren, template:optional graphiti/security-tool,
  public-only-Dateien, LICENSE-Handling inkl. TBD); Modul-Einbau nach Modul-Kontrakt;
  Aufräumen aller Template-eigenen Dateien mit git-status-Gegenprüfung;
  `.claude/template-version`-Stempel; Repo-Settings (Beschreibung = Short-Info, Topics
  mit Marker `coding-kit`, Squash-Merge, Push-Protection mit Feature-Detection);
  Verifikation `mise trust && mise install && just setup && just check`;
  Personendaten-grep + Verschieben von Quelldokumenten nach `private/`;
  Erst-Commit nur nach OK; Graphiti-Seeding falls MCP läuft.
- **Robustheit:** Trockenlauf via Argument `dry-run` (zeigt Fragen, Plan und
  Ziel-Dateiliste, führt nichts aus), Kontext-Recovery-Block, `manifest-format`-Check
  (kann Format 1, bricht sonst mit Hinweis auf Kit-Update ab), Fehlerpfad bei belegtem
  Repo-Namen.

**Entscheidungen:**

- `disable-model-invocation: true` — Repo-Anlage darf nie spontan vom Modell ausgelöst
  werden; nur der Nutzer startet den Orchestrator.
- Instanziierung koppelt an die MANIFEST-Tabellen zur Laufzeit statt an einkopierte
  Dateilisten — Template-Änderungen brechen den Skill nicht (Kopplung nur über die
  `manifest-format`-Version).
- Quell-STARTPROMPTs wandern nach `private/` des neuen Projekts (gitignored) — die
  publishbare Essenz steckt bereits in Short-Info/REQUIREMENTS.

---

## F-002 — Begleit-Skills (2026-07-07)

**Was entstanden ist:** Fünf Skills unter `plugins/coding-kit/skills/` (Plugin 0.2.0) —
einzeln nutzbar und von `/new-project` (F-003) aufrufbar; jede SKILL.md definiert dafür
explizit ihre „Rückgabe an den Aufrufer":

- **name-it** — Kandidaten nach Kriterien (kurz, sprechend, kollisionsarm,
  lowercase-kebab-tauglich), Verfügbarkeits-Checks zur Laufzeit (GitHub via gh,
  npm-Registry, PyPI-JSON-API; Domain nur auf Wunsch via RDAP), Websuche gegen
  Namensvettern. Rückgabe: gewählter Name.
- **choose-license** — M1-Kurzinterview (Sichtbarkeit, kommerzielle Nutzung, Copyleft,
  Dependency-Lage), Empfehlung Default Apache-2.0, Alternativen MIT/MPL-2.0, GPL/AGPL
  nur als bewusste Entscheidung, „TBD" gültig (nur privat). Standalone schreibt es
  LICENSE + Paket-Metadaten nach Bestätigung. Rückgabe: SPDX-Id oder TBD.
- **choose-stack** — Modus A Neuanlage (Bedarf aus Short-Info, aktuelle Framework-Lage
  per Websuche verifiziert, Stubs klar ausgewiesen, „offen" → docs-only); Modus B
  Bestandsprojekt (EIN Modul nachrüsten/wechseln nach MANIFEST-Modul-Kontrakt, Diff +
  Bestätigung je Datei, Override-Schutz, Verifikation via mise install + just setup +
  just check). Template-Repo wird zur Laufzeit aufgelöst (lokaler Checkout, sonst
  gh clone von `<login>/project-template`; Override `CODING_KIT_TEMPLATE_REPO`).
  Grenze dokumentiert: laufende Modul-Updates = `/update-conventions`. Rückgabe:
  Modulname (+ CODEQL-Sprache, geschriebene Dateien).
- **define-requirements** — M1-Interview aus der Short-Info (Ziele, Kern-Features,
  Nicht-Ziele, Constraints; Vorschläge bestätigen lassen statt offen fragen) →
  REQUIREMENTS.md in M5-Struktur (= Template-Skelett `core/REQUIREMENTS.md`) → initiale
  PROGRESS.md mit einer F-Nummer je Anforderung + FEATURE-INDEX. Verwaltet den
  Auflöse-Trigger (vollständig überführt + Nutzer bestätigt → Kurzfassung in CLAUDE.md,
  Entscheidungen als ADR sichern, Datei löschen).
- **refine-requirements** — M2-Diagnose „Was führt dich zurück zur Spec?" mit drei
  Pfaden (Änderung von außen / Implementierungs-Lücke / Grundsatz-Challenge); darf
  Features splitten (neue Nummern via FEATURE-INDEX); immer datierte Decision-Log-
  Einträge (Product/Technical getrennt, Historie supersedieren statt umschreiben);
  arbeitet nach Auflösung der REQUIREMENTS.md auf PROGRESS + ADRs weiter.

**Entscheidungen:**

- Alle fünf mit `disable-model-invocation: false`, damit der `/new-project`-Orchestrator
  (F-003) sie als Sub-Skills aufrufen kann; präzise descriptions verhindern Spontanfeuer.
- Neuer optionaler Personal-Config-Schlüssel `CODING_KIT_TEMPLATE_REPO` (Default bleibt
  Laufzeit-Auflösung `<github-login>/project-template` — kein Hardcode).

---

## F-001 — Kit-Grundgerüst (2026-07-07)

**Was entstanden ist:**

- **Marketplace** `.claude-plugin/marketplace.json` — Name `xnyzer`, Plugin per relativem
  `source: "./plugins/coding-kit"` → `/plugin marketplace add xnyzer/coding-kit` und
  `/plugin install coding-kit@xnyzer` funktionieren direkt.
- **Plugin** `plugins/coding-kit/` — `plugin.json` (Version 0.1.0), vier Core-Skills,
  Stop-Hook.
- **Skills** (generalisiert aus erprobten projektlokalen Vorlagen, personendatenfrei,
  stack-agnostisch): `add-feature`, `prep-step`, `step-done`, `audit-code`. Gemeinsame
  Bausteine: Projektkontext aus der Projekt-CLAUDE.md (group_id, Doku-Sprache,
  Sicherheits-Postur), Checks nur über just-Standardrezepte, F-Nummern-Toleranz (alt
  lesen, F-NNN schreiben), Kontext-Recovery-Block (M4), Write-then-Verify (M3) in
  step-done, Privacy-Scan der lebenden Doku in step-done, Commit-E-Mail-Check zur
  Laufzeit via `gh api` (kein Hardcode).
- **Stop-Hook** `hooks/stop-reminder.sh` — projekterkennend (PROGRESS.md mit
  FEATURE-INDEX oder `.claude/template-version`), blockt einen Stopp höchstens einmal
  (`stop_hook_active`-Schutz) und verweist auf `/coding-kit:step-done`; in fremden Repos
  vollständig still.
- **Renovate-Preset** `default.json` (Root): `config:recommended` +
  `helpers:pinGitHubActionDigests` + Label `dependencies`; Doku in
  `docs/renovate-preset.md`. Kit und project-template extenden es selbst (Dogfooding).
- **Installer** `install.sh` — idempotent: prüft gh/claude, richtet Marketplace + Plugin
  ein, legt `~/.claude/coding-kit.env` an (via `gh api` vorbefüllt, chmod 600), bietet
  Toolchain-Installation an; globale CLAUDE.md-Einrichtung folgt mit F-004.
- **Doku:** deutsches `README.md`, `docs/skill-authoring.md` (verbindliche
  Authoring-Konvention), `CLAUDE.md` (Dogfooding), Governance auf Englisch
  (LICENSE Apache-2.0, CODE_OF_CONDUCT CC 3.0, SECURITY, CONTRIBUTING, AI-DISCLOSURE).
- **Qualität:** `scripts/validate.py` (JSON/YAML/TOML-Syntax, Plugin-/Marketplace-/
  Skill-Frontmatter-Checks, Privacy-Lint) via `just check`, lefthook (gitleaks +
  Validator), gehärtete CI (permissions minimal, Actions SHA-gepinnt, Concurrency).

**Entscheidungen:**

- Stop-Hook blockt (JSON `decision: block`) statt nur zu echoen — die Erinnerung erreicht
  das Modell zuverlässig; der `stop_hook_active`-Schutz verhindert Schleifen.
  Hook-Ausgabe auf Englisch, weil sie in beliebigen (oft öffentlichen) Projekten wirkt.
- Kit versioniert über `plugin.json` + `CHANGELOG.md` (keine separate VERSION-Datei wie
  im Template — die Skills koppeln an die MANIFEST-Formatversion des Templates, nicht an
  Kit-Versionen).
- `project-template/renovate.json` (Root) im Zuge dessen aufs Preset umgestellt
  (TODO(D3) dort erledigt; Root-Datei ist nicht manifest-verwaltet → kein VERSION-Bump).

---

## TPL-001 — Initial template build (2026-07-07)

**Problem:** No reusable template existed; every new project re-derived its setup from old
projects.

**What was built (90 files):**

- **Root meta level:** own CLAUDE.md (structure rules + sync invariant: managed-file
  change ⇒ VERSION bump + CHANGELOG entry + MANIFEST update), PROGRESS/-ARCHIVE, README,
  VERSION 0.1.0, CHANGELOG, MANIFEST (manifest-format 1: placeholder registry, marker
  conventions, file policies managed/seed/public-only/module, module contract, standard
  recipe set), governance (CONTRIBUTING, SECURITY, AI-DISCLOSURE, CODE_OF_CONDUCT on
  Contributor Covenant 3.0, Apache-2.0 LICENSE), hardened `.claude/settings.json`,
  `scripts/validate.py` (JSON/YAML/TOML syntax, placeholder registry, privacy lint),
  own CI (`just check` via SHA-pinned checkout v7.0.0 + mise-action v4.2.0), lefthook
  (gitleaks + validator), mise.toml + committed cross-platform mise.lock.
- **core/:** CLAUDE.md template (Graphiti as optional block), CODING-STANDARDS with
  write-then-verify (§10), trunk-based/squash (§11) and module slot (§12), CONTRIBUTING,
  SECURITY (adapt slots), HOW-TO-CODE-WITH-CLAUDE (contributor setup incl. plugin
  install), AI-DISCLOSURE (optional security-tool block), PROGRESS skeletons with
  FEATURE-INDEX (F-NNN), REQUIREMENTS (out-of-scope, dated decision logs, open-question
  checkboxes), M6-hardened settings.json + convention-overrides registry + skills README,
  issue forms + PR template, hardened ci.yml with `# module:ci-jobs` append marker,
  CodeQL toggle workflow (public-only, `{{CODEQL_LANGUAGES}}`), docs-only justfile
  (recipe contract setup/dev/test/lint/format/check/build), mise.toml (just/lefthook/
  gitleaks, lockfile=true), lefthook.yml (gitleaks + `just format` with stage_fixed),
  renovate.json (extends the coding-kit preset), .gitignore with `.env*`/private/
  conventions and module append marker, editorconfig/gitattributes, ADR scaffold.
- **modules/:** docs-only (core defaults), ts-node (pnpm + strict tsconfig per current
  `tsc --init` set + nodenext ESM + Biome + vitest; no Corepack dependency), python
  (uv + src layout + uv_build + ruff + pyright strict + pytest), go (distilled from a
  production Go service gold standard: gofmt gate, golangci-lint v2 standard set, -race
  tests, go-licenses gate locally + as CI job), swift-ios/java as documented stubs.

**Notable decisions:**

- Template content under `core/` + `modules/`, repo root owns its own docs/CI — resolves
  the dogfooding-vs-template conflict (root CLAUDE.md can't be both).
- Module justfile **replaces** the core justfile (no merge logic); the recipe set is the
  stable contract skills/CI call.
- CodeQL needs a language ⇒ registered placeholder `{{CODEQL_LANGUAGES}}` provided by the
  module; docs-only projects don't get the workflow.
- core/LICENSE ships the real Apache-2.0 text (canonical apache.org copy) as default;
  `/choose-license` replaces it only on deviation/TBD.
- Known caveat documented in `core/.claude/README.md`: deny rules beat allow rules, so
  `.env.example` may be blocked too depending on Claude Code version (fail-safe
  direction; D8 smoke test verifies empirically).

**Verification:** `just check` (validator) green; all four justfiles parse; lefthook
configs valid; `mise install` + `mise lock` work (28 platform entries); gitleaks clean;
personal-data grep zero hits.
