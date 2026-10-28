---
id: F-043
title: Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen
type: feature
status: DONE
size:
created: 2026-10-25
done: 2026-10-25
depends-on:
superseded-by:
---

# F-043 — Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen

## Verlauf

### F-043a — Fragmente aufteilen (2026-10-25)

Teil von F-043 (Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen; F-043b–c
folgen).

**Problem:** Das Fragment eines Stack-Moduls mischte Regeln, die für jeden Code der
Sprache gelten, mit Regeln, die nur mit der Toolchain des Moduls stimmen. Ein Projekt,
das die Sprache ohne ihr Modul als Werkzeugsprache nutzt, bekam deshalb gar keine
Sprachregeln.

**Was entstanden ist (1.3.0, unveröffentlicht):**

- **Sprachfragmente (neu):** `python-lang`, `typescript-lang` und `go-lang` im Katalog,
  je mit einem Satz zum Geltungsbereich („whatever toolchain runs it"). python: Type
  Hints, Safe calls, Namensregeln, Dependencies; typescript: strikte Typen, kein `any`,
  Safe calls, Namensregeln, Dependencies; go: Formatierung, `go vet`, Namensregeln,
  Fehler, Context, Nebenläufigkeit, Safe calls, Tests, Dependencies.
- **Modul-Fragmente gekürzt:** Überschriften „Python toolchain (python module)" usw.; sie
  behalten Runtime, Paketmanager, Layout, Checker, Linter, Test-Werkzeug, Lock-Datei und
  just-Rezepte. Aufgeteilte Zeilen: pyright strict (Modul) neben den Type Hints
  (Sprache); `noExplicitAny` und `--error-on-warnings` (Modul) neben „kein `any`"
  (Sprache); `just format`, `just check` und das Lizenz-Gate (Modul) neben gofmt und den
  permissiven Lizenzen (Sprache). Das go-Modul-Fragment hat noch vier Regeln.
- **Module:** `Standards fragments:` mit dem Sprachfragment in den drei `MODULE.md`; die
  Parts-Tabelle nennt das Modul-Fragment.
- **Katalog:** drei Zeilen oben mit den Signalen; „How a module pulls fragments"
  beschreibt Modul- und Sprachfragment.
- **MANIFEST:** §§ Markers, Module contract (Reihenfolge Modul-Fragment, deklarierte
  Fragmente, `FRAGMENTS`) und Standards fragments (neuer Punkt „Language fragments") mit
  den neuen Begriffen; § Detection: Das Sprachfragment einer Werkzeugsprache gilt weiter
  und wird über seine Signale vorgeschlagen. § Answers: Die `FRAGMENTS`-Zeile nennt auch
  Fragmente aus der Erkennung und das Sprachfragment einer Werkzeugsprache — sie war
  seit F-042 veraltet (nicht im Plan, gehört zum selben Vertrag).
- **Core-`CODING-STANDARDS.md` §13:** Blöcke je Sprache, Toolchain oder Framework; ein
  Modul bringt seine Toolchain-Regeln und die deklarierten Fragmente, eine Sprache ohne
  ihr Modul nur ihre Sprachregeln.
- **Tests:** Helfer `slot_order`; Render-Fälle für die Reihenfolge im Slot bei python,
  ts-node und go, ein deklariertes Fragment in `FRAGMENTS` erscheint nur einmal, ein
  docs-only-Projekt mit `FRAGMENTS=python-lang` bekommt das Sprachfragment allein (der
  Platzhaltertext entfällt); Erkennung: docs-only mit `tool:python` meldet
  `fragment python-lang missing`.
- **Version:** `plugin.json` 1.3.0, CHANGELOG-Eintrag mit `### Template` (Aufteilung,
  beides zusammen übernehmen, Override-Hinweis, Signale).

**Verifikation:** `just check` grün (Validator, 484 Skript-Tests unter dash und bash,
18 davon neu). Zeilenabgleich gegen HEAD: Jede Regel der drei alten Fragmente steht
wörtlich oder als aufgeteilte Zeile im Modul- oder im Sprachfragment. Versionsregel gegen
`origin/main` grün.

**Notable decisions:**
- Die Regel zur Lock-Datei steht in beiden Teilen: toolchain-neutral im Sprachfragment
  („committed lock file"), mit der konkreten Datei im Modul-Fragment — sonst hätte eine
  Werkzeugsprache keine Regel zu Dependencies.
- `-race` bleibt als Regel im Sprachfragment (Nebenläufigkeit); dass `just test` es
  umsetzt, steht im justfile und nicht noch einmal im Modul-Fragment.
- Kommentar und Kopf von `template-sync.sh` sowie die Skills sprechen noch vom
  „Sprachfragment" des Moduls; umgestellt wird in F-043b, zusammen mit der Erkennung,
  die deklarierte Fragmente als `covered` zählt.

**Geänderte Dateien:**
`plugins/coding-kit/template/modules/standards/{python-lang,typescript-lang,go-lang}.md`
(neu), `plugins/coding-kit/template/modules/{python,ts-node,go}/{CODING-STANDARDS.part.md,MODULE.md}`,
`plugins/coding-kit/template/modules/standards/README.md`,
`plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/CODING-STANDARDS.md`,
`tests/template-sync/{run,render,detect}.sh`,
`plugins/coding-kit/.claude-plugin/plugin.json`, `plugins/coding-kit/CHANGELOG.md`,
`PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-043b — Erkennung, Validator und Skills (2026-10-25)

Teil von F-043 (Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen; F-043a
siehe darunter, F-043c folgt).

**Problem:** Mit den Sprachfragmenten aus F-043a deklarieren die Module erstmals
Katalog-Fragmente. `detect` zählte ein Fragment aber nur nach seinem Marker im Slot,
`update-conventions` hängte neue Fragmente ans Slot-Ende, ein durch Override geschütztes
Modul-Fragment blieb stumm, und `choose-stack` führte `FRAGMENTS` beim Modulwechsel nicht
nach.

**Was entstanden ist (1.3.0, unveröffentlicht):**

- **`detect`:** Ein Fragment, das das Modul der Antworten deklariert, ist `covered`, auch
  ohne Marker — der Render bringt es mit. Der Modulname wird wie beim Rendern geprüft; ein
  unbekanntes Modul zählt nicht. Skript-Kopf und Kommentar mit dem Begriff
  Modul-Fragment; MANIFEST § Detection: Zustandstabelle und „ohne Antworten zählt nur der
  Slot".
- **Validator:** `check_fragment_names` meldet ein Katalog-Fragment, das wie ein Modul
  heißt.
- **`update-conventions`:** Schritt 2 „ohne das Modul-Fragment". Schritt 6: das
  Modul-Fragment gegen `CODING-STANDARDS.part.md`, Katalog- und Sprachfragmente gegen den
  Katalog; ein geschütztes Fragment wird nicht angeboten, zeigt aber den Diff Basis →
  Render zur Info, wenn es sich zwischen Basis-Snapshot und Render geändert hat (ohne
  Snapshot: Projekt → Template); Neues kommt an seine Stelle aus dem Render (hinter den
  nächsten Vorgänger aus `<tmp>/soll`, der im Slot steht, ohne Vorgänger an den
  Slot-Anfang).
- **`choose-stack`:** Modus B setzt Fragmente an ihre Stelle aus dem Render (unter den
  Katalog-Fragmenten das Sprachfragment zuerst); beim Wechsel wird das Modul-Fragment an
  seiner Stelle getauscht, das Sprachfragment des Alt-Moduls bleibt als Katalog-Fragment
  stehen; `FRAGMENTS` wird in beide Richtungen nachgeführt; § Begleithandlungen nennt das
  Sprachfragment einer Werkzeugsprache.
- **`new-project`:** Schritt 4b mit den neuen Begriffen.
- **Tests:** `detect` mit den Antworten eines python-Projekts ohne Slot →
  `fragment python-lang covered`; ohne Antworten → `missing`.
- **CHANGELOG** 1.3.0 ergänzt. add-skill-Checkliste: `plugin.json` (Version schon 1.3.0,
  Beschreibung unverändert), README, HOW-TO und Authoring-Doku geprüft — keine Änderung
  nötig.

**Verifikation:** `just check` grün (Validator, 490 Skript-Tests unter dash und bash,
6 davon neu). Gegenprobe an einer Scratch-Kopie: Ein Katalog-Fragment `go.md` meldet der
Validator als Kollision mit dem Modul `go`. Versionsregel gegen `origin/main` grün. Die
Skill-Texte selbst testet F-043c mit `--plugin-dir`.

**Notable decisions:**
- „Template-Fassung geändert" heißt beim geschützten Fragment: verschieden zwischen
  Basis-Snapshot und Render, nicht zwischen Projekt und Template — es weicht gewollt ab
  und würde sonst bei jedem Lauf gemeldet.
- Die Render-Position gilt für jedes neue Fragment, nicht nur für Sprachfragmente;
  bestehende werden weiterhin nie umsortiert.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`plugins/coding-kit/template/MANIFEST.md`, `scripts/validate.py`,
`tests/template-sync/detect.sh`,
`plugins/coding-kit/skills/{update-conventions,choose-stack,new-project}/SKILL.md`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-043c — Test, Release, Gegenprobe (2026-10-25)

Schließt F-043 ab (Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen;
F-043a–b siehe darunter).

**Problem:** Aufteilung, Erkennung und Skill-Texte waren gebaut und per Skript getestet,
aber noch nicht in echten Skill-Läufen geprüft, nicht veröffentlicht und beim Nutzer nicht
installiert.

**Was entstanden ist (Release 1.3.0):**

- **Läufe an Kopien** (`claude -p --plugin-dir`, die Entscheidungen standen im Prompt):
  - docs-only-Projekt (Stempel 1.2.0, `module:python` abgelehnt): `python-lang` über
    `tool:python` angeboten, an den Slot-Anfang gesetzt und in `FRAGMENTS` eingetragen;
    der folgende `status`-Lauf schlägt nichts mehr vor; `just check` grün.
  - ts-node-Projekt, gerendert mit dem Template von 1.2.1 (`FRAGMENTS=audit-logging`):
    `detect` meldet `typescript-lang covered`, obwohl der Marker noch fehlt; das
    Modul-Fragment wird ersetzt, `typescript-lang` steht direkt dahinter und vor
    `audit-logging`, keine Regel doppelt oder fehlend, `FRAGMENTS` unverändert.
  - Dieselbe Kopie mit Override im Modul-Fragment: `ts-node` bleibt unangetastet, der
    Diff Basis → Render erscheint zur Info samt Hinweis auf die doppelten Regeln;
    `typescript-lang` richtig eingefügt.
  - Die Endstände sind per Skript nachgeprüft (Slot gegen Katalog und Modul-Fragment,
    `detect`, `status`). Schreibzugriffe unter `.claude/` blieben gesperrt; die
    vorbereiteten Dateien kopierte der Tester stellvertretend.
- **Funde aus den Tests** (mit Freigabe mitgenommen):
  - **Biome 2.6 formatiert Markdown und YAML.** Über den Caret-Bereich bekommt ein neues
    ts-node-Projekt diese Version, und `just check` war in jedem neuen ts-node-Projekt
    rot. `biome.json` schließt beides jetzt per `files.includes` aus; grün mit 2.6.3 und
    2.5.15, in einer Kopie als `template-only` gemergt und dort grün. Notiz im
    `MODULE.md`, CHANGELOG unter `### Template`.
  - **`base-from-history`** fand Releases ohne Template-Änderung nicht (1.2.1). Jetzt gilt
    das Template des Commits, der die Version gesetzt hat; reine Kit-Versionen vor 1.0
    bleiben abgewiesen. Vier neue Prüfungen je Shell (498 gesamt).
  - Die zsh-Wortaufteilung beim `snapshot`-Aufruf ist als Punkt in F-045 notiert.
- **Release 1.3.0:** Korrekturen (`a0e7070`) und Release-Commit (`3cecdd4`) nach
  Personendaten-, Blocklist- und gitleaks-Prüfung gepusht; CI grün. Plugin beim Nutzer
  auf 1.3.0, der Cache ist mit dem Repo dateigleich.
- **Gegenprobe:** `/coding-kit:update-conventions` am echten docs-only-Projekt:
  `python-lang` angenommen (Slot und `FRAGMENTS`), Stempel 1.3.0, im Projekt committet;
  `detect` meldet `covered`, `status` nur die drei `keep`-Dateien.
- **Messung zu Modell und Effort** (Kostenfrage des Nutzers), je ein Update desselben
  docs-only-Projekts: Opus 5.5 auf `xhigh` 1,67 USD (29 Werkzeugaufrufe), Opus 5.5 auf
  `medium` 1,19 USD (18), beide vollständig; Sonnet 5.5 auf `medium` 0,31 USD (7), aber
  ohne Zonen-Abgleich, Lock-Prüfung und Prüfung entfernter Ziele. Die Testläufe dieses
  Substeps kosteten zusammen rund 9 USD. Daraus entstand F-046.

**Planungsentscheidungen von F-043** (aus dem Elterneintrag):
- Sprachfragmente sind Katalog-Fragmente `<sprache>-lang`, nach der Sprache benannt;
  Begriffe Modul-Fragment und Sprachfragment.
- Nur umsortieren, keine neuen Regeln; Signale ohne Dateiendungen (wie F-042).
- Reihenfolge im Slot wie im Vertrag: Modul-Fragment, deklarierte Fragmente, `FRAGMENTS`.
- `detect` zählt vom Modul der Antworten deklarierte Fragmente als `covered`.
- Neue Fragmente kommen an ihre Stelle aus dem Render, Bestehendes wird nie umsortiert;
  geschützte Fragmente zeigen Template-Änderungen zur Info.
- `FRAGMENTS` folgt dem Modulwechsel in beide Richtungen; kein Katalog-Fragment darf wie
  ein Modul heißen.

**Notable decisions:**
- ts-node-Testprojekte aus dem Template von 1.2.1 gerendert statt eines echten Projekts
  auf 0.13.2: Der Weg vom aktuellen Stand nach 1.3.0 wird ohne teure Migration geprüft.
- Release vor dem Abschluss-Eintrag (wie F-042d): Die Gegenprobe braucht das installierte
  Plugin.
- Biome per Ausschlussmuster statt per `markdown`/`yaml`-Abschnitt: Biome vor 2.6 weist
  diese Schlüssel ab, und Lock-Dateien in Bestandsprojekten halten ältere Versionen.

**Im selben Commit:** F-046 (Verbrauchsanalyse des Kits und Empfehlungen zu Modell und
Effort) ins Backlog, als letzter Punkt der Empfohlenen Reihenfolge; der zsh-Fund und das
Ergebnis der Sonnet-Messung als Ergänzungen in F-045.

**Geänderte Dateien:** `plugins/coding-kit/template/modules/ts-node/files/biome.json`,
`plugins/coding-kit/template/modules/ts-node/MODULE.md`,
`plugins/coding-kit/scripts/template-sync.sh`, `tests/template-sync/sync.sh`,
`plugins/coding-kit/CHANGELOG.md` (Korrekturen und Release-Commit 1.3.0), `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.
