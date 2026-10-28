---
id: F-042
title: Neue Sprachen und Frameworks erkennen, Vorlagen nachziehen
type: feature
status: DONE
size:
created: 2026-10-24
done: 2026-10-25
depends-on:
superseded-by:
---

# F-042 — Neue Sprachen und Frameworks erkennen, Vorlagen nachziehen

## Verlauf

### F-042a — Signal-Vertrag und Daten (2026-10-25)

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

### F-042b — `detect` im Skript (2026-10-25)

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

### F-042c — Skills und Doku (2026-10-25)

Teil von F-042 (Neue Sprachen und Frameworks erkennen und Vorlagen nachziehen; F-042a–b
siehe darunter, F-042d folgt).

**Problem:** `detect` (F-042b) gab es, aber kein Skill rief es auf: prep-step und
step-done glichen Dependencies weiter von Hand mit dem Katalog ab, und nur für
Fragmente; update-conventions sah nie, wofür das Template inzwischen Vorlagen hat.

**Was entstanden ist (1.2.0, unveröffentlicht):**

- **prep-step § 2a** „Standards- und Modul-Abdeckung (Erkennung)": greift auch bei neuen
  Sprachen und Toolchains und ohne Fragment-Slot. Die geplanten Dinge werden als
  typisierte Signale benannt und mit `detect <template> <projekt> <Signal…>` geprüft.
  Fragment `missing` → Anhängen samt Begleithandlung, `FRAGMENTS` und `keep`-Zeilen;
  Modul `missing` → `/choose-stack` als eigener Schritt oder Werkzeugsprache mit
  Rules-Zeile `module:NAME` und `keep`-Zeilen. Eigenschafts-Trigger hält das Modell
  weiter selbst gegen die Aufgabe. Die Plan-Vorlage heißt „Standards- und
  Modul-Abdeckung".
- **step-done § 1a** über `detect --changed`: meldet nur, was der Schritt neu einführt;
  Fragment- und Modul-Lücken mit denselben Wegen, dauerhaft ablehnen als Rules-Zeile, nie
  blockierend; ohne Antworten-Datei Hinweis auf die Migration.
- **update-conventions:** Erkennung als Block in Schritt 2 — nach den Antworten, vor dem
  Rendern —, damit ein angenommenes Fragment in `FRAGMENTS` steht (sofern das Modul es
  nicht selbst deklariert) und Schritt 6 es anhängt; ein fehlendes Modul wird an
  `/choose-stack` verwiesen; dauerhaft ablehnen → Rules-Zeile, diesmal nicht → nichts
  gespeichert. Migrationen laufen durch die Erkennung, `status` berichtet sie, die
  Revision (Schritt 10) bietet Ablehnungen ohne Signale zum Austragen an.
- **choose-stack Modus B:** Empfehlung aus den Signalen (`declined` als frühere
  Entscheidung nennen); beim Wechsel eine Ablehnung des neuen Moduls und die
  `keep`-Zeilen der handgebauten Toolchain zum Austragen anbieten.
- **Doku:** Skill-Beschreibungen, README (Skill-Tabelle, Repo-Struktur), Template-HOW-TO
  (Skill-Tabelle, Backstop in „What `/step-done` does"), CHANGELOG (Skills, `### Template`
  für die HOW-TO); `docs/skill-authoring.md` nennt prep-step bei den Nutzern von
  `template-sync.sh` (nicht im Plan genannt).

**Verifikation:** Nicht-interaktiver Lauf von `update-conventions status` mit
`claude -p --plugin-dir plugins/coding-kit` an einer Scratch-Kopie des
docs-only-Projekts: Der Bericht zeigt „Modul `python`: `missing`, ausgelöst durch
`tool:python` in `mise.toml`" und empfiehlt die Werkzeugsprache; Prüfsummen aller 77
Dateien und `git status` der Kopie danach unverändert; Kopie und Temp-Ergebnisse
gelöscht. Alle vier `detect`-Aufrufe der Skills passen zum Skript-Kopf. `just check` grün
(424 Prüfungen).

**Notable decisions:**
- Die Erkennung ist in update-conventions ein Block von Schritt 2 statt eines neuen
  Schritts: Andere Skills verweisen auf die Schrittnummern (`A2 Schritt 5` …).
- Ein fehlendes Modul führt in update-conventions und step-done nur zu einer Empfehlung
  für `/choose-stack` — Modulwechsel bleiben in einem Skill.

**Im selben Commit:** F-044 (Sprachen ohne Vorlage erkennen und dem Template vorschlagen)
ins Backlog, Reihenfolge F-042 → F-043 → F-044 — aus einer Frage beim Bau: Java und
Swift sind Stubs ohne Signale, und Sprachen ohne Modul meldet heute kein Skill.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{prep-step,step-done,update-conventions,choose-stack}/SKILL.md`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`, `README.md`,
`docs/skill-authoring.md`, `plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.

### F-042d — Test, Release, Gegenprobe (2026-10-25)

Schließt F-042 ab (Neue Sprachen und Frameworks erkennen und Vorlagen nachziehen; F-042a–c
siehe darunter).

**Problem:** Erkennung, Skills und Doku waren gebaut und einzeln getestet, aber noch nicht
an echten Projekten durchgespielt, nicht veröffentlicht und beim Nutzer nicht
installiert.

**Was entstanden ist (Release 1.2.0, dazu 1.2.1 unveröffentlicht):**

- **Läufe an Kopien** (`claude -p --plugin-dir`, die Entscheidungen standen im Prompt):
  - docs-only-Projekt (Stempel 1.1.0): Die Erkennung meldet `module python missing` über
    `tool:python`; dauerhaft abgelehnt als Werkzeugsprache (Rules-Zeile
    `module:python`), HOW-TO und Registry-Kopf übernommen, Stempel 1.2.0, `just check`
    grün. Der folgende `status`-Lauf meldet `declined` ohne neuen Vorschlag.
  - ts-node-Projekt (Stempel 0.13.2) mit zwei eingebauten Testsignalen
    (`deploy/nginx/site.conf`, `tools/migrate/go.mod` — dort war sonst alles abgedeckt):
    Migration samt Erkennung; `nginx` angehängt (`FRAGMENTS`, Slot, `covered`), `go`
    diesmal nicht — der folgende `status`-Lauf bietet es wieder an und erkennt die
    Platzhalter als solche. `just check` grün bis auf die Docker-abhängige `stack-check`.
  - Schreibzugriffe unter `.claude/` blieben gesperrt; die vorbereiteten Dateien kopierte
    der Tester stellvertretend für die Freigabe.
- **Release 1.2.0:** CHANGELOG datiert (`46ef30b`), Push von fünf Commits nach
  Personendaten-, gitleaks- und Versionsregel-Prüfung; CI grün (Validator und 424
  Prüfungen unter Ubuntu, dash und bash). Plugin beim Nutzer auf 1.2.0, der Cache enthält
  `detect` und ist mit dem Repo dateigleich.
- **Gegenprobe:** `/coding-kit:update-conventions` am echten docs-only-Projekt: Der
  Python-Treffer wurde gemeldet und als Werkzeugsprache abgelehnt (Rules-Zeile
  `module:python`), HOW-TO und Registry-Kopf sind angekommen, Stempel 1.2.0, im Projekt
  committet; `detect` meldet `declined`, `status` nur die drei `keep`-Dateien.
- **Fund aus den Tests** (mit Freigabe mitgenommen, 1.2.1, unveröffentlicht): Ohne
  Schreibrecht unter `.claude/` sahen `detect` und `merge` die vorbereiteten Antworten
  und die Registry nicht; ein Testlauf baute dafür eine Spiegelkopie mit angepasstem
  Skript. Jetzt nimmt `template-sync.sh` Stellvertreter: `--answers FILE` (`detect`),
  `--registry FILE` (`status`, `changed`, `merge`, `detect`) und `--snapshot DIR`
  (`status`, `changed`, `merge`; `snapshot` schreibt dorthin). Alle Optionen liest
  `parse_opts`; ein Befehl weist eine fremde Option ab. `update-conventions` § 0
  beschreibt den Weg und schließt Skript-Anpassung und Spiegelkopie aus; die Liste der
  sensiblen Dateien nennt jetzt auch den Stempel. `docs/skill-authoring.md`
  § Hilfsskripte führt das Muster. 21 neue Prüfungen je Shell (466 gesamt),
  Fehlerinjektion mit vier eingebauten Fehlern (alle gefangen); ein Prüflauf an einer
  Kopie auf 1.1.0 nutzte `--registry` und `--snapshot` ohne Spiegelkopie und kam zum
  richtigen Endstand.

**Planungsentscheidungen von F-042** (aus dem Elterneintrag):
- Signale typisiert (`npm:`, `pypi:`, `go:`, `tool:`, `file:`); Modul-Signale als
  `Signals:`-Zeile im `MODULE.md`, Stubs ohne.
- Ein Fragment ist `covered`, wenn sein Marker im Slot steht; ein Modul nach `MODULE` der
  Antworten.
- Drei Aufrufarten: ganzer Baum (`update-conventions`), `--changed` (`step-done`),
  übergebene Signale (`prep-step`).
- Dauerhafte Ablehnung als Rules-Zeile `module:NAME`/`fragment:NAME`; „diesmal nicht"
  wird nicht gespeichert.
- Ein Modul je Projekt; eine Sprache ohne ihr Modul ist Werkzeugsprache. Die Aufteilung
  der Sprachfragmente ist F-043.
- Keine Dateiendungen als Signal, keine Leser für Cargo, Gemfile oder Maven.

**Notable decisions:**
- Testsignale in der ts-node-Kopie statt eines anderen Projekts: Dort war alles
  abgedeckt, die drei Entscheidungswege brauchten Treffer.
- Release 1.2.0 vor dem Abschluss-Eintrag (wie F-041e): Die Gegenprobe braucht das
  installierte Plugin.
- Stellvertreter-Optionen statt eines Umwegs im Skill: Alles Deterministische bleibt im
  Skript, und der Skill rechnet mit den vorbereiteten Dateien weiter.

**Im selben Commit:** F-045 (Zonen-Abgleich und Lock-Prüfung ins Skript) ins Backlog —
zwei weitere Funde des Prüflaufs: Zonen-Abgleich und Lock-Prüfung baut das Modell heute
selbst nach, und die Kopfzone der Registry-Vorlage enthält einen marker-ähnlichen Text.

**Geänderte Dateien:** `plugins/coding-kit/CHANGELOG.md` (Release-Commit 1.2.0 und
Eintrag 1.2.1), `plugins/coding-kit/.claude-plugin/plugin.json`,
`plugins/coding-kit/scripts/template-sync.sh`,
`plugins/coding-kit/skills/update-conventions/SKILL.md`, `tests/template-sync/sync.sh`,
`tests/template-sync/detect.sh`, `docs/skill-authoring.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.
