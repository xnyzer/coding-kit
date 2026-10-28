---
id: F-040
title: Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau
type: feature
status: DONE
size:
created: 2026-10-23
done: 2026-10-27
depends-on:
superseded-by:
---

# F-040 — Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau

## Verlauf

### F-040a — Kit-Datei, Werte, Render (2026-10-26)

Teil von F-040 (Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau;
F-040b–e folgen).

**Problem:** Die globalen Regeln lagen als `templates/global-CLAUDE.md` im Repo-Root,
außerhalb des Plugins, und kamen nur über `install.sh` einmal auf einen Rechner. Für den
Abgleich brauchte es eine Quelle im Plugin, die persönliche Werte aufnimmt, und einen
deterministischen Render.

**Was entstanden ist (1.6.0, unveröffentlicht):**

- **`plugins/coding-kit/global/coding-kit.md` (neu):** Kennung
  `<!-- coding-kit:global-rules -->` in der ersten Zeile, ein HTML-Kommentar für Menschen
  (wem die Datei gehört, die drei Schlüssel samt Optionen, wie man abweicht) und fünf
  `section:`-Zonen: `global-language`, `global-explain`, `global-git`, `global-graphiti`,
  `global-workflow`. Git und Graphiti sind wortgleich mit der Vorlage, Arbeitsweise trägt
  zusätzlich die Artifact-Regel wortgleich aus der installierten Fassung, Sprache & Stil
  die Languages-Block-Regel der Vorlage. Die Antwortsprache kommt aus
  `{{REPLY_LANGUAGE}}`, „Direkt und präzise" steht für sich. Neu ist der Abschnitt
  Erklär-Niveau: Geltungsbereich, vier Stufenblöcke (`einsteiger`, `junior`,
  `fortgeschritten`, `senior`) und die Notiz `{{EXPLAIN_NOTE}}`.
- **Stufentexte:** nach einer Einordnung im Gespräch ergänzt. `junior` nennt bei mehreren
  üblichen Wegen die Optionen und empfiehlt einen; `einsteiger` und `junior` sagen bei
  größeren Änderungen, was sich geändert hat und welche Stellen sich zu lesen lohnen.
- **`template-sync.sh render-global KIT ENV OUT` (neu):** liest die Personal-Config als
  Shell-Syntax, ohne sie auszuführen (`NAME="…"`, `'…'`, nacktes Wort, `export`,
  Kommentar dahinter, nur die Escapes `\"`, `\\`, `\$` und `` \` ``; eine spätere
  Zuweisung gewinnt), meldet je Wert `key <Name> <set|empty|missing>` und schreibt
  `OUT/rules/coding-kit.md`. Ein leerer Wert entfernt seinen Block. Eine Stufe ohne
  Block, ein unbekannter Block, ein offener Platzhalter und ein Tab oder `{{` in einem
  Wert brechen mit Exit 1 ab, ohne etwas zu schreiben. Die Einsetzregeln kommen aus
  `finalize`, wie bei `render`.
- **`finalize`** erkennt die Wertetabelle an `FILENAME == ARGV[1]` statt an
  `NR == FNR`: Mit leerer Tabelle hätte es die ganze Kit-Datei als Werte gelesen.
- **Repo:** `.claude/settings.json` (neu) mit `claudeMdExcludes` für
  `**/plugins/coding-kit/template/**`; Begründung und eine Strukturregel zu `global/` in
  der `CLAUDE.md`. `lefthook.yml` lässt die Skript-Tests auch bei Änderungen unter
  `global/` laufen.
- **Validator:** Kennung, Zonen, flache und bekannte Blöcke, Platzhalter nur aus
  `GLOBAL_KEYS` des Skripts, ein Schlüssel-Kommentar je Wert, Stufenliste im Kommentar
  gleich den Stufenblöcken, die `claudeMdExcludes`-Zeile. Markdown-Doku außerhalb des
  Templates darf die Werte-Platzhalter nennen. Die Versionsregel zählt `global/` zum
  Plugin-Inhalt.
- **Tests:** `tests/template-sync/global.sh` (neu): alle Werte, keine, leere, nur Notiz,
  nur Stufe, jede Stufe; Syntax der Personal-Config (spätere Zuweisung, einfache
  Anführungszeichen, CRLF, offenes Anführungszeichen, Text hinter dem Wert, Leerzeichen
  nach `=`, Tab, `{{`); unbekannte Stufe; Kit-Vertrag (unbekannter Block, offener
  Platzhalter, Verschachtelung) und Fehlerfälle der Operanden. Dazu `zones` auf
  Stellvertreter-Config-Ordnern: `identical`, `differs`, `override`, `opted-out`, ein
  geänderter Wert, eine fremde Datei (`unmarked`, nie umgeschrieben) und keine Datei
  (`no-file`).
- **Version:** `plugin.json` 1.6.0, CHANGELOG-Eintrag ohne `### Template` (Projekte
  betrifft der Schritt nicht).

**Verifikation:** `just check` grün mit 1425 Checks unter dash, bash und mawk (255 davon
neu); gawk ist lokal nicht installiert. Die übernommenen Abschnitte per Diff gegen Vorlage
und installierte Fassung geprüft. Fehlerinjektion im Validator: falsche Stufenliste,
unbekannter Block, Verschachtelung, fehlende Kennung, fremder Platzhalter, fehlender
Schlüssel-Kommentar, fehlende oder leere `claudeMdExcludes` — alle gemeldet, die echte
Datei sauber. Versionsregel mit temporärem Index: schlägt ohne Bump bei
`global/coding-kit.md` an.

**Notable decisions:**
- Flache statt verschachtelter Blöcke: So bleibt `finalize` die eine Umsetzung der
  Einsetzregeln. Der Abschnitt Erklär-Niveau hat dafür eigene Blöcke für Überschrift,
  Stufen und Notiz.
- Ohne Werte bleibt die Erklär-Zone als leeres Markerpaar stehen. Kommen Werte dazu,
  meldet `zones` sie als `differs` statt als `local`.
- Die Schlüssel stehen samt Kommentar im HTML-Kommentar der Kit-Datei: Claude Code
  entfernt solche Kommentare vor dem Laden, und der Abgleich übernimmt die Zeilen von dort
  (eine Quelle).
- `render-global` liest nur `CODING_KIT_*`-Zeilen und führt die Datei nie aus; eine Notiz
  mit `$` bleibt wörtlich.
- „Antwortsprache: X" statt „Antworte auf X", damit jeder Sprachname passt.

**Geänderte Dateien:** `plugins/coding-kit/global/coding-kit.md` (neu),
`plugins/coding-kit/scripts/template-sync.sh`, `tests/template-sync/global.sh` (neu),
`tests/template-sync/run.sh`, `scripts/validate.py`, `scripts/version-rule.py`,
`.claude/settings.json` (neu), `CLAUDE.md`, `lefthook.yml`,
`plugins/coding-kit/.claude-plugin/plugin.json`, `plugins/coding-kit/CHANGELOG.md`.

### F-040b — Interview-Skill `explain-level` (2026-10-26)

Teil von F-040 (Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau;
F-040a siehe darunter, F-040c–e folgen).

**Problem:** Die Werte für Antwortsprache und Erklär-Niveau aus F-040a brauchten eine
Stelle, die sie abfragt und in die Personal-Config schreibt. Eine Stufe aus dem Stand zu
wählen fällt schwer; die Einordnung soll aus wenigen Fragen zur eigenen Erfahrung
entstehen und für alle Nutzer gleich ablaufen.

**Was entstanden ist (1.6.0, unveröffentlicht):**

- **`plugins/coding-kit/skills/explain-level/SKILL.md` (neu):** liest die env-Datei und
  die Kit-Datei. Nennt der Nutzer den Wert schon, entfällt das Interview; sonst bis zu
  sieben Fragen (Antwortsprache, Programmieren, Shell, Git, Frameworks,
  Projekt-Werkzeuge, Code mitlesen), je mit Antwortoptionen und Empfehlung, und keine
  weitere, sobald die Einordnung eindeutig ist. Der Vorschlag wählt die Stufe nach der
  Programmiererfahrung und legt Lücken bei Werkzeugen in die Notiz, zitiert den
  Stufentext aus der Kit-Datei und fragt einmal: übernehmen, Stufe ändern oder Notiz
  ändern. Geschrieben wird über `set-global` nach `<tmp>`, geprüft mit `render-global`,
  gezeigt als Diff der drei Schlüssel und nach Freigabe kopiert; ohne Freigabe gibt der
  Skill die Datei in `<tmp>` an den Aufrufer zurück. Die Werte stehen nur in der
  env-Datei, nicht in Graphiti, Projektdateien oder im Gedächtnis von Claude Code.
  `disable-model-invocation: false`: Claude startet den Skill auf Zuruf und aus
  `update-conventions global`.
- **`template-sync.sh set-global KIT ENV OUT NAME=value…` (neu):** schreibt
  `OUT/coding-kit.env` (Modus 600). Je Schlüssel eine Zeile `NAME="Wert"` mit dem
  Kommentar aus der Kit-Datei; `\`, `"`, `$` und `` ` `` werden maskiert, sodass die
  Shell den Wert wörtlich liest. Die erste Zuweisung (auch hinter `export`) wird an ihrer
  Stelle ersetzt, spätere desselben Schlüssels fallen weg, fehlende kommen in der
  Reihenfolge der Schlüssel hinter einer Leerzeile ans Ende. Alle anderen Zeilen bleiben;
  CRLF bleibt CRLF, eine fehlende letzte Zeilenendung wird ergänzt. Abgelehnt werden
  andere und doppelte Schlüssel, Namen ohne Präfix, Tab, Zeilenumbruch oder `{{` in einem
  Wert und eine Stufe ohne Block. Ausgabe: `set <Name> <replaced|added>`, dann
  `written coding-kit.env`.
- **Gemeinsame Stufenprüfung:** `kit_levels` und `check_level` nutzen `render-global` und
  `set-global` gleichermaßen.
- **Begleit-Änderungen über `/add-skill`:** Zeile in der README-Skill-Tabelle,
  plugin.json-Beschreibung (explain-level, globale Kit-Regeln), CHANGELOG.
- **Tests:** in `tests/template-sync/global.sh` 33 Fälle je Durchgang für `set-global`:
  ganze Datei gegen die Erwartung (ersetzt hinter `export`, Duplikat entfernt, fremde
  Zeilen und Kommentare gleich, neue Schlüssel angehängt), Modus 600, die Shell liest die
  Werte wörtlich, `render-global` liest die Datei, neue Datei, leerer Wert, CRLF, fehlende
  letzte Zeilenendung, Leerzeile am Ende und alle Ablehnungen.

**Verifikation:** `just check` grün mit 1524 Checks unter dash, bash und mawk (99 davon
neu). Der Validator hielt den ersten Entwurf des Skills an, weil er
`template:optional:level-NAME` nannte — einen Block, den das Projekt-Template nicht hat;
die Stelle nennt jetzt nur `level-<Stufe>`. Secrets- und Privacy-Scan ohne Fund.

**Notable decisions:**
- Die Stufe folgt der Programmiererfahrung, Werkzeuglücken gehören in die Notiz: Eine
  niedrigere Stufe ließe Claude auch erklären, was der Nutzer schon kann.
- `set-global` entfernt spätere Zuweisungen desselben Schlüssels, weil in der Shell sonst
  die spätere Zeile gewönne.
- Der Kommentar einer Zeile kommt bei jedem Schreiben aus der Kit-Datei, damit die
  Optionen aktuell bleiben; ein eigener Kommentar hinter einer ersetzten Zeile geht dabei
  verloren.
- Die HOW-TO des Templates bleibt unverändert: Der Skill stellt den Rechner ein, nicht
  ein Projekt.
- `disable-model-invocation` fehlte zunächst (Standard `false`) und ist nachgezogen;
  daraus entstand F-048.
- Der echte Lauf mit `--plugin-dir` folgt in F-040e.

**Geänderte Dateien:** `plugins/coding-kit/skills/explain-level/SKILL.md` (neu),
`plugins/coding-kit/scripts/template-sync.sh`, `tests/template-sync/global.sh`,
`README.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`plugins/coding-kit/CHANGELOG.md`; dazu `PROGRESS.md` mit dem Backlog-Eintrag F-048.

### F-040c — Abgleich in update-conventions, Niveau in den Skills (2026-10-26)

Teil von F-040 (Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau;
F-040a–b siehe darunter, F-040d–e folgen).

**Problem:** Kit-Datei, Render und Werte (F-040a–b) waren da, aber kein Skill richtete die
globalen Regeln ein oder glich sie ab, und teach-step stützte sich noch auf ein
Lernprofil in Graphiti, das ohne Graphiti fehlte.

**Was entstanden ist (1.6.0, unveröffentlicht):**

- **`update-conventions`, Teil G (Kit → Rechner):** Argument `global`, auch außerhalb
  eines Projekts, und `global <ordner>` als Stellvertreter für Tests. Jeder andere Lauf
  außer `revise` prüft die Regeln nach dem letzten Projekt einmal mit, sobald sie
  eingerichtet sind oder eine alte Kopie da ist; `status` berichtet nur.
  - **G1 Stand:** Config-Ordner aus `CLAUDE_CONFIG_DIR` oder `~/.claude` (laut
    Claude-Code-Doku verschiebt die Variable den ganzen Ordner); Kennung der Kit-Datei
    (ohne Kennung ist sie fremd und wird nie angefasst); eine alte Kit-Kopie erkennt er an
    der Kopfzeile der früheren Vorlage; die Werte zeigt `render-global`.
  - **G2:** fehlende Werte über `explain-level`; `empty` gilt als beantwortet.
  - **G3:** Ersteinrichtung oder `zones --snapshot` je Zone, Übernahme wie bei den
    seed-Zonen (alle auf einmal oder per zweitem Lauf mit den angenommenen Namen).
  - **G4:** Migration einer alten Kit-Kopie zusammen mit der Einrichtung — Kit-Abschnitte
    heraus, unklare Zeilen einzeln (behalten, dem Kit vorschlagen, streichen); ohne
    Bereinigung wird auch keine Regeldatei geschrieben.
  - **G5:** Eine selbst angelegte CLAUDE.md wird nur gelesen; Widersprüche meldet er mit
    Lösungen, die der Nutzer selbst umsetzt.
  - **G6:** Stand nach jedem Dialog per `snapshot --snapshot` unter
    `${CLAUDE_PLUGIN_DATA}/global-base`.
- **Kit-Datei:** neue Zone `global-head` um Kommentar und Titel.
- **`explain-level`:** Ein Wert lässt sich bewusst leer setzen; nur ein fehlender
  Schlüssel gilt als offen.
- **`teach-step`:** kein Lernprofil in Graphiti mehr. Die Vorauswahl der
  Vertrautheitsfrage kommt aus der Stufe, die des Lernziels aus der Notiz; am Ende
  höchstens ein Notiz-Vorschlag mit Verweis auf `explain-level`.
- **`propose-to-template`:** Fund-Art „globale Regel" mit der Kit-Datei als Ziel
  (Material deutsch, Issue-Titel `global: …`, Kit-Regeln ohne `### Template`).
- **Doku:** Authoring-Regel „Erklärstil" in `docs/skill-authoring.md`; README-Zeilen zu
  update-conventions und propose-to-template; die HOW-TO des Templates nennt `global`
  (CHANGELOG `### Template`).

**Verifikation:** `just check` grün mit 1524 Checks unter dash, bash und mawk; alle
Skill-Frontmatter als YAML gelesen. Der Validator hielt einen Doppelpunkt mit Leerzeichen
in der Beschreibung von update-conventions an, behoben. Grep: „Lernprofil" steht nur noch
im teach-step-Satz, dass es keines gibt; kein `search_nodes` oder `add_memory` dazu.
Teil G setzt nichts von Hand ein (`render-global`, `zones`, `snapshot`). An einem
Stellvertreter-Ordner von Hand geprüft: `snapshot --snapshot` legt die Basis an, `zones`
arbeitet damit auf dem Config-Ordner. Der echte Lauf folgt in F-040e. Secrets- und
Privacy-Scan ohne Fund.

**Notable decisions:**
- Teil G läuft in normalen Läufen nur, wenn die Regeln eingerichtet sind oder eine alte
  Kopie da ist — wer die globalen Regeln nicht will, merkt nichts davon.
- Der Stand des letzten Abgleichs ist ein Snapshot über das Skript statt einer losen
  Kopie: deterministisch, und der Session-Hinweis (F-040d) vergleicht mit genau dieser
  Datei.
- Einrichtung und Migration einer alten Kopie nur gemeinsam: Sonst stünden alte und neue
  Regeln doppelt da, die Sprachregel sogar widersprüchlich.
- Zone `global-head`, weil der Kommentar mit Schlüsseln und Optionen auf den Rechnern
  sonst veraltet.
- Gefunden: Eine neue Zone der Kit-Datei oder des Templates meldet `zones` als
  `opted-out` und bietet sie nie an → F-049.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{update-conventions,teach-step,propose-to-template,explain-level}/SKILL.md`,
`plugins/coding-kit/global/coding-kit.md`, `docs/skill-authoring.md`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`, `README.md`,
`plugins/coding-kit/CHANGELOG.md`; dazu `PROGRESS.md` mit dem Backlog-Eintrag F-049.

### F-040d — Session-Hinweis, Installer, Nutzer-Doku (2026-10-26)

Teil von F-040 (Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau;
F-040a–c siehe darunter, F-040e folgt).

**Problem:** Seit F-040a–c kann `update-conventions global` die Kit-Regeln einrichten und
abgleichen, aber niemand erfuhr, wann das nötig ist. `install.sh` kopierte weiter die
alte Vorlage, und das README beschrieb noch den `curl`-Weg.

**Was entstanden ist (1.6.0, unveröffentlicht):**

- **`hooks/session-start.sh` (neu), Eintrag in `hooks.json` (Matcher `startup`):**
  meldet als SessionStart-Kontext (`hookSpecificOutput.additionalContext`) in einer
  Zeile eine alte Kit-Kopie in der CLAUDE.md des Config-Ordners (Kopfzeile der früheren
  Vorlage); geänderte Kit-Regeln oder Werte, wenn die Regeldatei die Kennung trägt und der
  Render mit den aktuellen Werten von der Basis `${CLAUDE_PLUGIN_DATA}/global-base`
  abweicht; eine Personal-Config, die `render-global` ablehnt. Ohne Kit-Regeln, bei einer
  fremden Regeldatei, ohne Datenordner und bei abgelehnten Änderungen schweigt er. Er
  schreibt nichts und endet immer mit 0 — ein anderer Exit-Code zeigte laut Doku eine
  Fehlermeldung.
- **`install.sh`:** Schritt 4 meldet eine alte Kit-Kopie, eine eigene CLAUDE.md und ob
  die Kit-Regeln eingerichtet sind; er schreibt nichts Globales und endet mit dem Verweis
  auf `update-conventions global`. Config-Ordner und Personal-Config folgen
  `CLAUDE_CONFIG_DIR`.
- **`templates/global-CLAUDE.md` entfernt**, der `curl`-Weg im README gestrichen.
- **README:** beide Einrichtungswege auf die Kit-Regeln umgestellt; neuer Abschnitt
  „Globale Kit-Regeln" mit Warnkasten (was das Kit mit den globalen Einstellungen macht),
  „Antwortsprache und Erklär-Niveau" (Schlüssel samt Kommentar, Stufen, Setzen und Ändern
  — die env-Datei allein reicht nicht) und „Eigene Abweichungen und Ergänzungen"; eine
  Tabelle der Aufrufe von `update-conventions`; Abschnitt „Session-Hinweis"; die
  Personal-Config um die drei Schlüssel ergänzt; Commit-Identität, Windows-Hinweis,
  Einleitung und Dateibaum nachgezogen.
- **Validator:** Die Zeile `CODING_KIT_EXPLAIN_LEVEL` im README muss dieselben Stufen
  nennen wie die Kit-Datei.
- **Tests:** `tests/template-sync/hook.sh` (neu) mit 22 Fällen je Durchgang an einem
  Stellvertreter-Config- und -Datenordner. `lefthook.yml` lässt die Skript-Tests auch bei
  Änderungen an den Hooks laufen.
- **PROGRESS:** Verweise auf die alte Vorlage in F-024, F-029, F-030 und F-033 auf die
  Kit-Regeln umgestellt.

**Verifikation:** `just check` grün mit 1590 Checks unter dash, bash und mawk (66 davon
neu); eine echte Ausgabe des Hooks mit Python als JSON gelesen. `install.sh --local`
zweimal in einem Test-HOME ausgeführt (der gh-Token nur als Umgebungsvariable des
Laufs): Mit alter Kit-Kopie wie mit eigener CLAUDE.md blieb die Datei byte-gleich, und
`rules/` entstand nicht; die echte Plugin-Konfiguration blieb unberührt, das Test-HOME
ist gelöscht. Grep: `templates/` und `curl` stehen nur noch im F-040-Eintrag, im Archiv
und im CHANGELOG. Die Fehlerprobe für die README-Prüfung (veränderte Stufenliste) schlägt
an. Secrets- und Privacy-Scan ohne Fund.

**Notable decisions:**
- Ein gemeinsamer Hinweis für „Kit geändert" und „Werte geändert": Beides vergleicht der
  Hook mit derselben Basis; getrennt ginge nur mit einer zweiten gespeicherten Datei, und
  die Lösung ist in beiden Fällen derselbe Befehl.
- Der Hook läuft nur beim Start einer neuen Session (`startup`), nicht nach `resume`,
  `clear` oder `compact`.
- Ohne Datenordner schweigt der Hook beim Vergleich, statt jede Session zu melden.
- Die Testdaten tragen die alte Kopfzeile nur bis zu dem Teil, an dem Hook und Abgleich
  die Kopie erkennen.

**Geänderte Dateien:** `plugins/coding-kit/hooks/session-start.sh` (neu),
`plugins/coding-kit/hooks/hooks.json`, `tests/template-sync/hook.sh` (neu),
`tests/template-sync/run.sh`, `install.sh`, `templates/global-CLAUDE.md` (entfernt),
`README.md`, `scripts/validate.py`, `lefthook.yml`, `plugins/coding-kit/CHANGELOG.md`,
`PROGRESS.md`.

### F-040e — Testlauf, Release, erster echter Abgleich (2026-10-27)

Schließt F-040 ab (Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau;
F-040a–d siehe darunter).

**Problem:** F-040a–d und F-048 waren nur durch Skript-Tests belegt. Ob die Skills in
einem echten Lauf ohne Handarbeit einrichten, migrieren und abfragen, zeigte erst ein
Modell-Lauf; danach folgten Release und der erste echte Abgleich auf dem Rechner des
Nutzers.

**Was entstanden ist (Release 1.6.0):**

- **Vier Testläufe** (`claude -p --plugin-dir`, Opus auf `medium`, Budget-Cap 4 USD je
  Lauf; zusammen 2,65 USD) an Stellvertreter-Ordnern:
  - Neueinrichtung (0,66 USD, 4 Turns): Regeln eingerichtet, Basis gesetzt, alle Zonen
    `identical`.
  - Alte Kit-Kopie mit zwei persönlichen Zeilen (0,73 USD, 5 Turns): Regeln eingerichtet;
    Kopfzeile und Kit-Abschnitte heraus, die alte Sprachregel als frühere Kit-Fassung
    gestrichen, beide persönlichen Zeilen behalten — auch die mitten in „Arbeitsweise".
  - Eigene CLAUDE.md mit zwei Widersprüchen (0,67 USD, 4 Turns): Regeln eingerichtet,
    die CLAUDE.md byte-gleich, beide Widersprüche mit Lösungen gemeldet.
  - Interview `explain-level` mit vorgegebenen Antworten (0,59 USD, 5 Turns): `junior`
    mit Notiz und Begründung, nur über `set-global` geschrieben.

  Den Endstand prüfte ein Skript gegen die Renders; das echte `~/.claude` blieb
  unverändert (Prüfsummen). Der Session-Hinweis löste in allen vier echten Sessions aus.
- **Fund mitgenommen** (`cf2951b`): Zwei Läufe gaben die env-Datei samt Identitätswerten
  aus. Teil G1 sagt jetzt, dass die `key`-Zeilen von `render-global` genügen.
- **Release 1.6.0** (`516cb90`, CHANGELOG datiert): Personendaten-Grep über zehn Commits
  samt Metadaten und Messages, Blocklist und gitleaks ohne Fund; Push, CI grün (Lauf
  40419045407, 1590 Checks unter gawk und mawk); Marketplace und Plugin von 1.5.0 auf
  1.6.0 aktualisiert, der Cache gleich dem Repo bis auf `.in_use`.
- **Erster echter Abgleich** in einer neuen Session: `explain-level` setzte Deutsch,
  `junior` und eine Notiz; `update-conventions global` richtete
  `~/.claude/rules/coding-kit.md` ein und löschte die alte Kit-Kopie `~/.claude/CLAUDE.md`,
  in der nichts Persönliches stand. Das Lernprofil in Graphiti ist gelöscht (zwei
  Episoden); die beiden mitgelöschten Notizen zu teach-step stehen bereits im Skill-Text.

**Verifikation:** Die Regeldatei entspricht dem Render der echten Werte, die Basis im
Plugin-Datenordner ist gesetzt, alle sechs Zonen sind `identical`, die env-Datei ist
privat; der Session-Hinweis schweigt. Gegenprobe mit einem `InstructionsLoaded`-Hook (zwei
Haiku-Läufe, zusammen 0,01 USD): Im Kit-Repo lädt Claude beim Lesen von
`template/core/justfile` nur die Kit-Regeln und die Repo-CLAUDE.md, in einem Ordner ohne
`claudeMdExcludes` dagegen auch die CLAUDE.md daneben. Die Kit-Regeln stehen einmal da,
eine zweite Sprachregel nicht.

**Notable decisions:**
- In den Testläufen 1–3 standen die Werte schon in der env-Datei, damit jeder Lauf genau
  einen Fall prüft; das Interview prüfte Lauf 4 für sich.
- Der erste Push scheiterte am Auto-Modus-Klassifikator, solange er mit weiteren Befehlen
  verkettet war; allein lief er durch.
- `/memory` beim Session-Start belegt nicht, dass eine verschachtelte CLAUDE.md ausbleibt —
  sie lädt erst beim Lesen einer Nachbardatei. Deshalb der Hook-Test mit Gegenprobe.
- Gefunden, nicht verfolgt: Die Skills lassen ihren `mktemp`-Ordner liegen; das
  Betriebssystem räumt ihn weg.

**Planungsentscheidungen von F-040** (aus dem Elterneintrag):

**Problem:** Die Vorlage `templates/global-CLAUDE.md` erreicht einen Rechner nur einmal:
`install.sh` kopiert sie, wenn noch keine `~/.claude/CLAUDE.md` existiert, und meldet sonst
nur „wird nicht überschrieben". Danach driften Vorlage und installierte Fassung unbemerkt
auseinander — beobachtet in beide Richtungen: der Languages-Block-Absatz aus F-020 fehlt in
der installierten Fassung, eine dort ergänzte generische Regel (Artifacts nur mit
ausdrücklicher Erlaubnis veröffentlichen) fehlt in der Vorlage. F-024, F-029 und F-030
planen weitere Änderungen an der Vorlage, die bestehende Rechner ohne Abgleich nie
erreichen. Der manuelle Weg im README (`curl … -o ~/.claude/CLAUDE.md`) überschreibt eine
eigene CLAUDE.md ohne Rückfrage. Ein Erklär-Niveau gibt es nicht: Wie ausführlich Claude
antwortet, kann niemand einmal festlegen; teach-step liest dafür ein Lernprofil aus
Graphiti, das ohne Graphiti fehlt.

**Idee:** Die Kit-Regeln kommen mit dem Plugin auf den Rechner, als eigene Datei neben der
persönlichen CLAUDE.md. Persönliche Werte (Antwortsprache, Erklär-Niveau) stehen an einer
Stelle und werden beim Abgleich eingesetzt. Der Abgleich zeigt Unterschiede abschnittsweise
und übernimmt nur Bestätigtes; eine selbst angelegte CLAUDE.md fasst das Kit nie an.

**Entschieden (2026-10-26):**
- **Ort:** Die Kit-Regeln liegen in `~/.claude/rules/coding-kit.md`. Claude Code lädt
  Nutzer-Regeln aus `~/.claude/rules/` in jeder Session wie die CLAUDE.md, ohne Rückfrage.
  `~/.claude/CLAUDE.md` gehört allein dem Nutzer. Quelle im Plugin:
  `plugins/coding-kit/global/coding-kit.md` — nicht in `template/`, denn sie ist kein
  Projektinhalt und deutsch. `templates/` entfällt.
- **Verworfen:** Zonen in der persönlichen CLAUDE.md (Marker-Migration einer fremden
  Datei); ein `@`-Import aus dem Plugin-Cache (der Pfad enthält die Version); ein
  SessionStart-Hook, der die Regeln selbst einspeist (keine Bestätigung, gilt ungefragt für
  jeden Plugin-Nutzer); eine CLAUDE.md im Plugin (lädt Claude Code nicht).
- **Widersprüche:** Claude Code hängt alle Anweisungsdateien aneinander, ohne Vorrang; bei
  einem Widerspruch entscheidet Claude beliebig. Deshalb nie über zwei Dateien abweichen.
  Gewollter Vorrang steht im Regeltext (wie beim Languages-Block). Abweichen heißt: die Zone
  in der Kit-Datei ändern und mit einer Override-Zeile schützen oder ihr Markerpaar löschen
  (dauerhafter Opt-out). Eigene Zusatzregeln gehören in `~/.claude/CLAUDE.md`.
- **Fremde Dateien:** Das Kit schreibt nie in eine `~/.claude/CLAUDE.md` ohne die Kopfzeile
  der alten Vorlage („Gepflegt als Vorlage im coding-kit …", gleich in allen drei
  Fassungen); dort meldet der Abgleich nur Widersprüche zu den Kit-Regeln. Eine alte
  Kit-Kopie wird nur mit Diff und Zustimmung bereinigt; bleibt nichts Persönliches übrig,
  bietet der Abgleich das Löschen an. Die Kit-Datei trägt eine eigene Kennung; eine fremde
  Datei gleichen Namens wird nie überschrieben.
- **Werte:** nur in `~/.claude/coding-kit.env`, die Optionen als Kommentar hinter dem Wert:
  `CODING_KIT_REPLY_LANGUAGE` (Antwortsprache, freier Text), `CODING_KIT_EXPLAIN_LEVEL`
  (`einsteiger | junior | fortgeschritten | senior`), `CODING_KIT_EXPLAIN_NOTE` (freier
  Text, präzisiert die Stufe; bei Widerspruch gilt die Notiz). Fehlt ein Wert oder ist er
  leer, entfällt seine Zeile. Claude Code setzt in Anweisungsdateien keine Variablen ein:
  Der Abgleich rendert die Kit-Datei, die Regeldatei ist erzeugt. Nur die env-Datei zu
  ändern reicht deshalb nicht — erst der Abgleich übernimmt. Gefragt werden die Werte nur
  im Interview-Skill `explain-level`; der Abgleich startet ihn, wenn Werte fehlen, und der
  Nutzer kann ihn jederzeit erneut aufrufen. `install.sh` fragt nicht. Stufenliste und
  Schlüssel-Kommentare stehen technisch nur in der Kit-Datei.
- **Erklär-Niveau:** gilt für Antworten, Rückfragen, Pläne, Zusammenfassungen und
  Fehlerberichte — nicht für Code, Kommentare, Commits und Doku-Inhalte im Projekt, nicht
  für die Strenge von Prüfungen und Freigaben. Skills schreiben keinen eigenen Erklärstil
  vor; feste Ausgabeformate bleiben, die Sprache darin folgt dem Niveau. teach-step nimmt
  das Niveau als Vorauswahl seiner Vertrautheitsfrage (`einsteiger` → Neuland, `junior` →
  Grundlagen, ab `fortgeschritten` → Routiniert), liest und schreibt kein Lernprofil mehr
  in Graphiti und schlägt am Ende höchstens einen neuen Notiz-Text vor.
- **Abgleich:** in `update-conventions`. `global` gleicht nur die Kit-Regeln ab, auch
  außerhalb eines Projekts, und richtet sie erstmals ein. Der normale Lauf und `alle`
  prüfen sie einmal mit, wenn sie eingerichtet sind oder eine alte Kopie da ist — sonst
  still; `status` berichtet mit. Vergleich und Einsetzen über `zones` (die Kit-Datei hat
  `section:`-Zonen).
- **Hinweis:** Ein SessionStart-Hook meldet in einer Zeile eine alte Kit-Kopie ohne
  Kit-Datei, eine seit dem letzten Abgleich geänderte Kit-Datei oder geänderte, noch nicht
  übernommene Werte. Sonst bleibt er still, auch bei Nutzern ohne globale Regeln. Den Stand
  des letzten Abgleichs merkt er sich in `${CLAUDE_PLUGIN_DATA}`; abgelehnte Änderungen
  lösen keinen neuen Hinweis aus.
- **Kein `curl`-Weg mehr:** Er überschreibt heute ohne Rückfrage und enthielte rohe
  Platzhalter. Ohne Klon: Plugin installieren, `/coding-kit:update-conventions global`.
  Keine Platzhalter-Datei am alten Pfad — der alte Befehl scheitert mit 404 und
  überschreibt nichts (geprüft).
- **Bestehende Abweichung:** Sprachregel aus der Vorlage, Artifact-Regel wortgleich ins
  Kit.
- **Template-CLAUDE.md im Kit-Repo:** Claude Code lädt `template/core/CLAUDE.md`, sobald
  eine Datei in diesem Ordner gelesen wird. `claudeMdExcludes` in der
  `.claude/settings.json` des Repos schließt alle Anweisungsdateien unter
  `plugins/coding-kit/template/` aus; die Begründung steht in der Repo-CLAUDE.md, weil JSON
  keine Kommentare kennt.
- **Nutzer-Doku im README:** Warnkasten, was das Kit mit den globalen Einstellungen macht;
  die Werte mit Optionen, wie man sie setzt und ändert; Abweichungen und eigene Regeln; die
  Modi von `update-conventions` zur Anwendung.

**Abhängigkeiten:** F-039 und F-045 (`zones`), beide erledigt. Vor F-024, F-029 und F-030
— deren Änderungen an den Kit-Regeln erreichen bestehende Rechner erst über den Abgleich.
Übernimmt aus F-033 das Lernprofil von teach-step.

**Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
`plugins/coding-kit/CHANGELOG.md` (Fund und Release), `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.
