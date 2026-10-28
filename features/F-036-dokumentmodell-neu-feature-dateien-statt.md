---
id: F-036
title: Dokumentmodell neu — Feature-Dateien statt Übergangs-Artefakt
type: feature
status: DONE
size:
created: 2026-10-23
done: 2026-10-28
depends-on:
superseded-by:
---

# F-036 — Dokumentmodell neu — Feature-Dateien statt Übergangs-Artefakt

## Erfassung

**Problem:** Anforderungen und Aufgaben leben an mehreren Stellen und ziehen um.
`define-requirements` schreibt die Kern-Features in die `REQUIREMENTS.md` und zugleich als
F-Nummern in die `PROGRESS.md`; die Auflösung der REQUIREMENTS.md wird praktisch nie
erreicht. Ein Eintrag zieht vom Backlog über die offenen Aufgaben ins Archiv um, und jeder
Umzug ist eine Kopie, die auseinanderlaufen kann. Die Übersicht wächst mit jedem
Abschluss: Im Kit hat die `PROGRESS.md` 637 Zeilen (ein Lesezugriff schafft sie nicht
mehr ganz), Done-Zeilen haben im Mittel 490 Zeichen, das Archiv 4.719 Zeilen, und ein
Feature verteilt sich dort auf mehrere Abschnitte. Eine gründliche Spezifikation verlangt
kein Skill — Randfälle, prüfbare Abnahmekriterien, Tests und Nicht-Ziele fehlen —, und die
Beratung vor dem Bau (passt das, gibt es Besseres, lieber nicht?) ist nicht geregelt.

**Idee:** Jede Aufgabe bekommt eine Datei `features/F-NNN-kurzname.md`, die über ihren
ganzen Lebenslauf wächst — Erfassung, Spezifikation, Plan, Verlauf — und
PROGRESS-Eintrag, Archiv-Einträge und REQUIREMENTS.md ersetzt. `features/INDEX.md` ist die
knappe Übersicht. add-feature erfasst knapp und berät, prep-step spezifiziert je nach Größe
bis hin zum Interview. Vorbild sind die 3 Cs der agilen Praxis (Karte – Gespräch –
Bestätigung: add-feature – prep-step – Abnahmekriterien) und Spec-Workflows für
KI-Coding (ai-coding-starter-kit mit `features/INDEX.md`, GitHub Spec Kit).

**Entschieden (2026-10-27):**

- **Dateien:** `features/INDEX.md` (seed) ersetzt `PROGRESS.md`;
  `features/F-000-template.md` (managed, wie `docs/adr/0000-template.md`) ist die
  Vorlage; je F-Nummer eine Datei, Substeps darin. `PROGRESS.md`, `PROGRESS-ARCHIVE.md`
  und `REQUIREMENTS.md` entfallen. Dateiname `F-NNN-` plus Kurzname aus dem Titel (ASCII,
  klein, Bindestriche, etwa 40 Zeichen), beim Anlegen fest.
- **Flacher Ordner, kein Unterordner für Erledigtes:** Pfade bleiben stabil, Verweise aus
  anderen Dateien, ADRs, Commits und Graphiti brechen nicht. Werden es sehr viele, später
  nach Nummernbereichen bündeln, nie nach Status.
- **INDEX:** Kopf-Zone `index-head` (Template-Text) mit Zweck, Titelregel und
  Status-Legende samt Weg zwischen den Status. Darunter **Empfohlene Reihenfolge** — von
  Hand, mit Stand-Datum, Nummern mit einem Halbsatz Begründung, Stränge erlaubt; jederzeit
  auf Zuruf überarbeitbar (Vorschau, dann OK), add-feature, prep-step und step-done
  schlagen Änderungen vor, größere Umplanung über refine-requirements. Dann die Tabelle
  aller Features (ID mit Link, Titel, Status, Fertig-Datum), nach Nummer sortiert und
  **per Skript aus den Kopfblöcken erzeugt** (zwischen Markern, nicht von Hand ändern);
  `next-feature` als sichtbare Zeile.
- **Titelregel:** höchstens 70 Zeichen; sagt, was sich ändert — nicht wie, nicht warum,
  kein Ergebnisbericht; kein Status, keine Version, keine Klammer-Aufzählung. Verweise
  wie „aufgegangen in" trägt die Statusspalte.
- **Kopfblock** (Frontmatter, nur einfache `feld: wert`-Zeilen): `id`, `title`, `type`
  (`feature` neues Verhalten / `fix` falsches Verhalten / `change` Umbau, Doku, Pflege,
  Audit — steuert nur die Ziel-Abschnitte, die Nummer bleibt F-NNN), `status`, `size`
  (`S`/`M`/`L`, ab prep-step), `created`, `done` (Pflicht bei DONE, erlaubt bei DROPPED
  und SUPERSEDED, leer solange offen), `depends-on`, `superseded-by` (Listen
  kommagetrennt). Nicht:
  Priorität (trägt die Reihenfolge), Release-Version, Story Points.
- **Status** (Token englisch): `BACKLOG` erfasst (add-feature) → `PLANNED` Spezifikation
  und Plan freigegeben, Ready erfüllt (prep-step) → `IN-PROGRESS` erster Substep
  verbucht (step-done, in der freigegebenen Verbuchung) → `DONE` alles verbucht, alle
  Abnahmekriterien belegt (step-done; endgültig, Folgearbeit bekommt eine neue Nummer).
  Aus jedem offenen Status: `DROPPED` bewusst nicht oder nicht weiter umgesetzt, Grund in
  der Datei; `SUPERSEDED` aufgegangen in oder aufgeteilt auf andere Nummern
  (`superseded-by`). Beide behalten Datei und Nummer. Ein S-Feature ohne Substeps geht
  von PLANNED direkt nach DONE. Kein Status für „Spezifikation ohne Plan" — prep-step
  sieht es an der Datei.
- **Abschnitte der Feature-Datei:**
  - *Erfassung* (add-feature): Problem; Ziel — `feature`: Story „Als … möchte ich …,
    damit …", `fix`: Ist, Soll, Reproduktion, `change`: Ziel und was gleich bleiben muss;
    Lösungsskizze (unverbindlich); Abhängigkeiten; Noch zu analysieren.
  - *Spezifikation* (prep-step, Phase 1): Abnahmekriterien AC-n als Gegeben/Wenn/Dann
    inkl. Negativfällen; Randfälle EC-n mit erwartetem Verhalten; Nicht-Ziele; Tests je AC;
    Einbettung; offene Fragen mit `[CLARIFY]` (Kürzel englisch wie alle Tokens);
    Entscheidungen datiert mit Grund
    (überstimmt der Nutzer eine Empfehlung, steht das so da).
  - *Plan* (prep-step, Phase 2): Größe mit Begründung, Ansatz, Substeps F-NNNa ….
  - *Verlauf* (step-done, je Substep): was umgesetzt wurde und wie, mit den wichtigen
    Stellen (keine vollständige Dateiliste — die hat der Commit); Entscheidungen und
    warum; Abweichung vom Plan; Funde. Das Problem steht nur oben in der Datei,
    Planungsentscheidungen nur einmal.
  - Abnahmekriterien werden beim Abschluss mit Beleg abgehakt (Test, Check, Befehl).
  - Überschriften und Text in der Sprache der lebenden Doku, Feldnamen und Token
    englisch; die Vorlage ist englisch, ihre Hinweise stehen als HTML-Kommentare und
    fallen beim Ausfüllen weg.
- **Größe** (prep-step, vor dem Interview; nach der Spezifikation erneut geprüft): drei
  Signale, das höchste zählt — Aufwand (S unter 5 Dateien und 200 Zeilen, M bis 15 und
  500, L darüber), Unsicherheit (Lösung liegt auf der Hand / einzelne offene Fragen /
  viele offene Fragen, neue Technik, Spike nötig), Reichweite (eine Stelle / mehrere Teile
  des Projekts / Daten- oder Projektmigration, Sicherheits- oder Auth-Pfade, Vorlage für
  andere Projekte). Claude schlägt die Größe mit einem Satz Begründung vor, der Nutzer
  kann sie ändern.
- **Tiefe je Größe** (begrenzt auch nach oben, damit Kleines nicht lästig wird):
  - S: kein Interview, Claude legt eine Mini-Spezifikation mit 1–3 Abnahmekriterien vor;
    Randfälle ausdrücklich „keine" oder 1–2; Plan in Stichpunkten, keine Substeps.
  - M: Interview nur zu offenen Punkten (etwa 3–6 Fragen); Abnahmekriterien als
    Gegeben/Wenn/Dann mit Negativfall; 3–5 Randfälle; 1–3 Nicht-Ziele; Testfall je AK;
    kurze Einbettungsprüfung; 2–3 Substeps.
  - L: volles Interview, eine Frage je Runde mit Empfehlung, Example Mapping (je Regel
    Beispiele und Gegenbeispiele, offene Fragen getrennt); Stories priorisiert; Randfälle
    systematisch (Daten, Zustände, Fehler, Sicherheit, Migration); Nicht-Ziele Pflicht;
    Teststrategie; volle Einbettungsanalyse; 3–5 Substeps, bei großer Unsicherheit ein
    Spike zuerst. Braucht es mehr, in eigene F-Nummern teilen.
- **Beratung und Abraten:**
  - add-feature: Bringt der Nutzer eine fertige Lösung mit, zuerst das Problem dahinter
    festhalten — die Lösung wird Option, kein Auftrag. Das stärkste Gegenargument und
    Alternativen nennen (auch „nichts bauen", „Doku statt Code", „gibt es schon"). Eine
    von vier Empfehlungen: aufnehmen, an Bestehendes anhängen, anders lösen, nicht
    aufnehmen — auf Wunsch als Datei mit DROPPED und Grund, empfohlen, wenn die Idee
    wiederkommen kann.
  - prep-step: Einbettung prüfen — was berührt das Feature, was muss mitgeändert werden,
    was setzt die Anfrage stillschweigend voraus (Rückweg, Migration, Fehlermeldung,
    Berechtigung), was Bestehendes muss angepasst werden (im Feature oder als
    Folge-F-Nummer), Widerspruch zu Zielen, Nicht-Zielen, ADRs? Fragen aus drei
    Blickwinkeln (Nutzen, Umsetzung, Prüfung) plus Sicherheit. Ab M mindestens eine
    Alternative zur Skizze. Darf abraten und plant keinen Workaround; die Entscheidung
    bleibt beim Nutzer.
- **Ready** (Bedingung für PLANNED): Problem und Ziel klar, Größe gesetzt, jedes
  Abnahmekriterium prüfbar und mit Testidee, Randfälle betrachtet, Nicht-Ziele ab M, kein
  blockierendes `[CLARIFY]`, Abhängigkeiten erledigt oder eingeplant, Einbettung geprüft,
  Plan steht. **Done:** step-done wie heute, dazu alle Abnahmekriterien des Substeps mit
  Beleg, Verlauf geschrieben, INDEX aktuell.
- **Projektziele:** Ziele, Nicht-Ziele und Rahmenbedingungen als drei kurze
  Unterabschnitte im Überblick der Projekt-CLAUDE.md — ein Ort für „was ist das Projekt",
  in jeder Sitzung geladen, keine eigene Datei. Verworfen: eine eigene `PRODUCT.md` per
  `@`-Einbindung — sie wäre ein zweiter Ort neben dem Überblick, der schon Zweck, Umfang
  und Zielgruppe beschreibt, und nah an der alten REQUIREMENTS.md. Wird es in einem
  Projekt deutlich mehr, darf es ausgelagert und per `@` eingebunden werden — Ausnahme,
  nicht Vorlage. Entscheidungen zu einem Feature stehen in seiner Datei, Grundsätzliches
  als ADR.
- **Freigabe-Gate** gilt für `features/INDEX.md`, Feature-Dateien und die Ziel-Abschnitte
  der CLAUDE.md. Lange
  Entwürfe (etwa ab 40 Zeilen) legt der Skill nach `private/`, übernimmt sie nach dem OK
  und löscht den Entwurf.
- **Index-Skript** im Template (`scripts/features-index.sh` mit `write` und `check`,
  POSIX-Shell; Rezept `just features-index`): erzeugt die Tabelle und prüft in
  `just check` Pflichtfelder, `id` passend
  zum Dateinamen, erlaubte Status, `done` und `superseded-by` je Status, Titellänge,
  eindeutige Nummern, `next-feature` über der höchsten, aktuelle Tabelle und nur offene
  Features in der Reihenfolge. Der Pre-Commit-Hook prüft nur, er erzeugt nicht (sonst
  kämen ungesehene Änderungen in den Commit).
- **Migration — alles wird überführt, auch Erledigtes:** über update-conventions,
  einmalig, je Datei mit Diff und Bestätigung; Inhalt wortgetreu, nicht umformuliert.
  - Skriptbefehl in `template-sync.sh` (Name offen) für das Mechanische: FEATURE-INDEX →
    Nummern, Titel, Status („aufgegangen in" → SUPERSEDED); offene Einträge → Datei (Text
    unter Erfassung, Substeps unter Plan); Archiv-Abschnitte nach Nummer gruppiert, je
    Substep ein Verlauf-Eintrag, zeitlich aufsteigend, `created` und `done` aus frühestem
    und spätestem Datum; eine Done-Zeile ohne Archiv-Abschnitt wird selbst
    Verlauf-Eintrag; Nummern ohne Inhalt → Datei mit Vermerk; Unzugeordnetes wird
    gelistet, nicht geraten.
  - Skill für das, was Urteil braucht: REQUIREMENTS.md verteilen (Ziele, Nicht-Ziele,
    Rahmen → Überblick der CLAUDE.md; Entscheidungen → ADR oder Feature-Datei;
    Kern-Features ohne Nummer → neue Dateien; offene Fragen → die betroffene Datei),
    Reihenfolge-Text übernehmen, Titel über 70 Zeichen kürzen,
    Unzugeordnetes klären. Danach `PROGRESS.md`, `PROGRESS-ARCHIVE.md` und
    `REQUIREMENTS.md` nach Bestätigung löschen (Git behält sie).
  - Skills der neuen Version können nur das neue Format; bei einer alten `PROGRESS.md`
    verweisen sie auf die Migration.
- **Kit selbst:** zieht erst nach Release und Plugin-Update um (entschieden 2026-10-23),
  mit derselben Migration als erstem Praxistest; sie setzt keine
  `.claude/template-answers` voraus. Die 28 `TPL-NNN`-Abschnitte kommen in eine eigene
  Verlaufsdatei `docs/project-template-history.md`, nicht in die F-Reihe.
- **Version 2.0.0:** jedes Projekt muss migrieren, bevor es mit den neuen Skills
  weiterarbeitet.
- **Bewusst nicht übernommen:** Story Points, Velocity, Sprints (Werkzeuge für Teams mit
  Kapazität); viele Status bis „Deployed"; mehrere Dateien je Feature (Spec Kit, Kiro);
  Archiv-Umzug (OpenSpec); EARS-Schreibweise (Gegeben/Wenn/Dann passt direkt auf Tests);
  Story Map als eigenes Dokument.
- **Abgrenzung:** F-036 regelt die Beratung beim Planen, F-034 den Maßstab beim Bauen
  (Workaround-Stopp, Review-Kriterien). F-037 prüft gegen Abnahmekriterien, Randfälle und
  Nicht-Ziele der Datei. F-029 schreibt einen Graphiti-Anlass je Feature mit Verweis auf
  die Datei.

**Abhängigkeiten:** F-039 und F-049 (erledigt — neue und entfernte Zonen erreichen
bestehende Projekte). Berührt dieselben Skills wie F-034; F-034 und F-037 folgen danach.
Entlastet F-029 und F-033.

## Plan

### F-036e — Testläufe, Release, Umstellung des Kits

**Was:** Läufe mit `claude -p --plugin-dir plugins/coding-kit` an Stellvertreter-Ordnern,
Kosten je Lauf nennen: neues Projekt mit define-requirements; add-feature mit Abraten;
prep-step für ein S- und ein L-Feature; step-done mit Verlauf und erzeugter Tabelle;
Migration eines Bestandsprojekts. Release 2.0.0 nach dem bekannten Ablauf (Push nur auf
ausdrückliche Bitte, vorher Personendaten-grep). Nach dem Plugin-Update das Kit selbst
migrieren: TPL-Abschnitte nach `docs/project-template-history.md`; Kit-CLAUDE.md mit
Zielen und Nicht-Zielen im Überblick (aus Überblick und README, Vorschau) und den Regeln
zu PROGRESS und Nummern; README-Struktur; das Kit-`just check` prüft seine `features/`.
Gegenprobe an einem Downstream-Projekt.

**Dateien:** `plugins/coding-kit/CHANGELOG.md`, Funde aus den Läufen; Umstellung des
Kits: `features/` (neu), `docs/project-template-history.md` (neu),
`CLAUDE.md`, `README.md`, `justfile`; entfallen: `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

**Abhängigkeiten:** F-036d.

**Abnahmekriterien:**
- [x] Alle Läufe ohne Handarbeit, Endstand per Skript geprüft, Kosten je Lauf genannt
      — belegt: sechs Laufarten, Prüfskripte grün, Kosten im Verlauf.
- [x] Release 2.0.0 gepusht, CI grün, Plugin aktualisiert — belegt: Push 2a47334,
      CI-Lauf success, `claude plugin list` zeigt 2.0.0.
- [x] Das Kit arbeitet mit `features/`: 49 Feature-Dateien, Tabelle erzeugt,
      TPL-Verlauf in eigener Datei, `just check` grün — belegt: `just check` (2133
      Prüfungen), Wortgleich-Prüfung grün.
- [x] Gegenprobe an einem Downstream-Projekt ohne Inhaltsverlust — belegt: Kopie mit
      52 Dateien, Wortgleich-Prüfung grün, Original unverändert.

## Verlauf

### F-036a — Vorlagen und Index-Skript (2026-10-27)

Teil von F-036 (Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt; F-036b–e
folgen).

**Problem:** Das neue Dokumentmodell braucht zuerst seine Grundlage im Template: die
Feature-Dateien mit Vorlage und Index, ein Skript, das die Tabelle aller Features erzeugt
und den Ordner prüft, und einen Vertrag, auf den die Skills in F-036b–d bauen.

**Was entstanden ist (2.0.0, unveröffentlicht):**

- **`features/INDEX.md`** (seed): Zone `index-head` mit Zweck, Titelregel, Pflege der
  Reihenfolge und Status-Legende samt Weg zwischen den Status; darunter „Recommended
  order" (Projektinhalt), die Tabelle zwischen `<!-- features-index -->` und
  `<!-- /features-index -->` und die sichtbare Zeile `next-feature: F-001`.
- **`features/F-000-template.md`** (managed): Kopfblock und die Abschnitte Intake,
  Specification (Acceptance criteria, Edge cases, Non-goals, Tests, Embedding, Open
  questions, Decisions), Plan und History; Hinweise als HTML-Kommentare, Tiefe je Größe.
- **`scripts/features-index.sh`** (managed, POSIX-Shell und awk): `write` liest die
  Kopfblöcke aller `F-NNN-*.md` (ohne Vorlage), schreibt die Tabelle nach Nummer sortiert
  nur zwischen ihre Marker, behält einen übersetzten Tabellenkopf und schreibt nichts,
  solange ein Kopfblock kaputt ist; danach prüft es. `check` meldet fehlende
  Pflichtfelder, `id` ungleich Dateiname, falschen Dateinamen, unbekannte Felder,
  Anführungszeichen, unbekannten Typ, Status oder Größe, falsches Datum, `done` und
  `superseded-by` je Status, Titel über 70 Zeichen (Zeichen, nicht Bytes), doppelte
  Nummern, fehlende oder zu niedrige `next-feature`, veraltete Tabelle und Nummern in der
  Reihenfolge ohne Datei oder nicht offen. Fehlt `features/INDEX.md`, verweist es auf
  die Migration.
- **justfiles** (core, go, python, ts-node): `check` ruft die Prüfung auf, das neue
  Rezept `features-index` das Erzeugen; `MODULE.md` der Module und Stubs nachgezogen.
  **`lefthook.yml`:** Pre-Commit-Job `features-index`, nur bei Dateien in `features/`,
  prüft nur.
- **`CLAUDE.md`:** Überblick mit `### Goals`, `### Non-goals`, `### Constraints`
  (`template:adapt`); Zonen `claude-startup`, `claude-conventions`, `claude-workflow` auf
  `features/` umgestellt, Entscheidungen in der Feature-Datei oder als ADR.
- HOW-TO (Skill-Tabelle, Workflows, Größe, step-done, wichtige Dateien), README,
  ADR-README, PR-Vorlage, `private/README.md` (lange Entwürfe) nachgezogen.
- **Entfernt:** `core/PROGRESS.md`, `core/PROGRESS-ARCHIVE.md`, `core/REQUIREMENTS.md`
  samt Zonen `progress-head`, `archive-head`, `requirements-head`.
- **MANIFEST:** neuer § Features (Dateien, Kopfblock, Status, Abschnitte, Index,
  Skript), Marker-Zeile für die Tabelle, Zieltabelle, Seed-Zone `index-head`, drei
  Zeilen in „Removed and renamed targets" (2.0.0, `removed`, seed) mit Hinweis auf die
  Migration, Standard-Rezepte um `features-index`, Beschreibung von
  `{{LANG_LIVING_DOCS}}`.
- **Kit:** `tests/template-sync/features.sh` (neu, 49 Checks je Durchgang) in `run.sh`;
  `zones.sh` testet die Kopfzone ohne Marker jetzt an `features/INDEX.md`; der Helfer
  `markers_paired` zählt nur Marker allein auf einer Zeile. Validator: prüft Prüfung und
  Erzeugen in jeder justfile und den Pre-Commit-Job; die Marker-Prüfung gilt nur noch
  für Markdown im Template. `define-requirements`: Verweis auf die entfernte
  Template-Datei gestrichen (Umbau in F-036c).
- Version 2.0.0, CHANGELOG mit `### Template`.

**Verifikation:** `just check` grün mit 1947 Checks unter dash, bash und mawk (49 neu je
Durchgang); Versionsregel grün. Ein frisch gerendertes docs-only-Projekt besteht
`just check`, `just features-index` meldet die leere Tabelle als aktuell, die CLAUDE.md
hat die drei Unterabschnitte. Gegenprobe: Ohne Prüfzeile in einer Modul-justfile schlägt
der Validator an. gitleaks, Privacy-Muster und Blocklist ohne Fund.

**Notable decisions:**
- Namen: `scripts/features-index.sh` mit `check` und `write`, Rezept
  `just features-index` (Nutzerentscheidung).
- `done` ist nur bei DONE Pflicht, bei DROPPED und SUPERSEDED erlaubt — alte Einträge
  wie „aufgegangen in" haben oft kein Datum (Nutzerentscheidung).
- Der Pre-Commit-Hook prüft mit, nur bei Dateien in `features/` (Nutzerentscheidung;
  `lefthook.yml` kam dafür zur Dateiliste).
- Kürzel englisch: `AC-n`, `EC-n`, `[CLARIFY]` statt `AK-n`, `R-n`, `[KLÄREN]` — Tokens
  bleiben in jeder Projektsprache gleich und suchbar (Nutzer bestätigt).
- Listen im Kopfblock kommagetrennt (`depends-on: F-034, F-037`), kein `[]`: einfache
  `feld: wert`-Zeilen, und doch gültiges YAML.
- Die Reihenfolge liegt zwischen dem Ende der Zone `index-head` und dem Tabellenmarker;
  so findet das Skript sie auch bei übersetzter Überschrift.
- awk läuft mit `LC_ALL=C` und zählt Titelzeichen ohne UTF-8-Folgebytes — gleiches
  Ergebnis in jedem awk.

**Abweichungen vom Plan:** Die Modul-justfiles (go, python, ts-node) und ihre `MODULE.md`
kamen dazu — die justfile hat die Policy „module", jedes Modul ersetzt sie ganz.
`lefthook.yml` siehe oben. Validator und Test-Helfer lasen Marker-Text auch mitten in
einer Codezeile als Marker; beide folgen jetzt der MANIFEST-Regel „nur allein auf einer
Zeile". Der Pfadverweis in `define-requirements` musste mit, sonst wäre der Validator rot.

**Geänderte Dateien:** unter `plugins/coding-kit/template/`: `MANIFEST.md`,
`core/features/INDEX.md` (neu), `core/features/F-000-template.md` (neu),
`core/scripts/features-index.sh` (neu), `core/CLAUDE.md`,
`core/HOW-TO-CODE-WITH-CLAUDE.md`, `core/README.md`, `core/docs/adr/README.md`,
`core/.github/PULL_REQUEST_TEMPLATE.md`, `core/private/README.md`, `core/justfile`,
`core/lefthook.yml`, `modules/{docs-only,go,java,python,swift-ios,ts-node}/MODULE.md`,
`modules/{go,python,ts-node}/justfile`; entfernt: `core/PROGRESS.md`,
`core/PROGRESS-ARCHIVE.md`, `core/REQUIREMENTS.md`. Außerdem
`plugins/coding-kit/skills/define-requirements/SKILL.md`, `scripts/validate.py`,
`tests/template-sync/{features.sh (neu),run.sh,zones.sh}`,
`plugins/coding-kit/.claude-plugin/plugin.json`, `plugins/coding-kit/CHANGELOG.md`,
`PROGRESS.md`.

### F-036b — Kern-Skills (2026-10-27)

Teil von F-036 (Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt; F-036a
siehe darunter, F-036c–e folgen).

**Problem:** Mit F-036a hatte das Template Feature-Dateien und Index, aber die Skills des
Alltags schrieben noch in `PROGRESS.md` und Archiv. Beratung vor dem Bau, eine
gründliche Spezifikation und eine Größe, die die Tiefe steuert, verlangte keiner.

**Was entstanden ist (2.0.0, unveröffentlicht):**

- **add-feature:** hält zuerst das Problem fest (eine mitgebrachte Lösung wird Option),
  prüft gegen Ziele und Nicht-Ziele im Überblick der CLAUDE.md und gegen die Tabelle
  aller Features (auch DROPPED und SUPERSEDED), nennt das stärkste Gegenargument und
  Alternativen bis „nichts bauen" und empfiehlt eine von vier Möglichkeiten — aufnehmen,
  an Bestehendes anhängen, anders lösen, nicht aufnehmen (auf Wunsch als Datei mit
  DROPPED). Er legt `features/F-NNN-kurzname.md` an (Kopfblock, Erfassung mit Ziel je
  `type`), zählt `next-feature` hoch, erzeugt die Tabelle per Skript und schlägt einen
  Platz in der Reihenfolge vor.
- **prep-step:** Größe aus Aufwand, Unsicherheit und Reichweite (das höchste zählt,
  nach der Spezifikation erneut geprüft); Spezifikation in der Tiefe je Größe — S ohne
  Interview, M mit Fragen zu offenen Punkten, L mit vollem Interview und Example
  Mapping — mit `AC-n`, `EC-n`, Nicht-Zielen, Tests, Einbettung, `[CLARIFY]` und
  datierten Entscheidungen; Blickwinkel Nutzen, Umsetzung, Prüfung, Sicherheit; ab M eine
  Alternative; darf abraten (DROPPED, SUPERSEDED), plant keinen Workaround, schlägt ein
  ADR vor, wo eine Entscheidung über das Feature hinausgeht. Dann Plan (Größe, Ansatz,
  Substeps; Spike zuerst bei großer Unsicherheit, mehr als fünf → eigene Nummern),
  Ready-Prüfung, PLANNED, Vorschlag zur Reihenfolge. Die Erkennung (2a) blieb
  inhaltlich gleich.
- **build-step:** liest Spezifikation und Plan aus der Datei, die Nicht-Ziele sind Teil
  des Scope-Schutzes, je Abnahmekriterium wird der Beleg genannt, Abweichungen und
  Entscheidungen werden für step-done gesammelt; bei IN-PROGRESS geht es beim ersten
  Substep ohne Verlauf-Eintrag weiter.
- **step-done:** verbucht in der Feature-Datei — ein Verlauf-Eintrag je Substep
  (Umgesetzt, Entscheidungen, Abweichung vom Plan, Funde), Abnahmekriterien mit Beleg
  abgehakt, Status IN-PROGRESS bzw. DONE (S ohne Substeps direkt von PLANNED), Tabelle
  per Skript, Reihenfolge nachgezogen, Done-Prüfung vor der Vorschau; kein Archiv mehr.
- **teach-step:** führt aus Plan, Abnahmekriterien und Nicht-Zielen der Datei.
- **Alle fünf** erkennen ein Projekt im alten Format (`PROGRESS.md` mit FEATURE-INDEX,
  keine `features/INDEX.md`) und verweisen auf die Migration per update-conventions; das
  Freigabe-Gate gilt für Feature-Dateien, den Index und die Ziel-Abschnitte der
  CLAUDE.md, lange Entwürfe gehen nach `private/`.
- **docs/skill-authoring.md:** neuer Baustein Dokumentmodell, Status-Konvention mit
  allen sechs Status, Altformat-Erkennung, neuer Gate-Standardsatz. **README:** Zeilen
  der fünf Skills, Zyklus und Freigabe. CHANGELOG.

**Verifikation:** Eine Suche nach PROGRESS, REQUIREMENTS und FEATURE-INDEX in den fünf
Skills findet nur die Altformat-Stelle (und das Wort IN-PROGRESS). Jeder Punkt aus
„Entschieden" zu Beratung, Größe, Tiefe, Ready, Status und Verlauf per Suche einem Skill
zugeordnet, ohne Lücke. `just check` grün (Validator mit Längen der Beschreibungen,
1947 Script-Checks); Versionsregel grün; gitleaks, Privacy-Muster und Blocklist ohne
Fund. Ein Modell-Lauf mit den neuen Texten steht in F-036e an.

**Notable decisions:**
- Bei M und L wird die Spezifikation vorab freigegeben und darf in die Datei, der Status
  bleibt BACKLOG; erst der Plan setzt PLANNED — so braucht es keinen Status
  „spezifiziert", prep-step erkennt den Stand an der Datei.
- Jeder Skill legt nur die Abschnitte an, die er füllt (add-feature die Erfassung,
  prep-step Spezifikation und Plan, step-done den Verlauf); das Gerüst kommt aus der
  Vorlage des Projekts, ersatzweise aus dem Plugin.
- teach-step schreibt nie; statt eines eigenen Gate-Absatzes sagt sein Abschluss, dass
  für step-done das Freigabe-Gate gilt.

**Abweichungen vom Plan:** keine im Umfang. Die README-Zeile zu define-requirements und
der Absatz zum Stop-Hook blieben für F-036c, wo diese Teile umgebaut werden.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{add-feature,prep-step,build-step,step-done,teach-step}/SKILL.md`,
`docs/skill-authoring.md`, `README.md`, `plugins/coding-kit/CHANGELOG.md`,
`PROGRESS.md`.

### F-036c — Anforderungs- und Randskills, Hook, Doku (2026-10-27)

Teil von F-036 (Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt; F-036a–b
siehe darunter, F-036d–e folgen).

**Problem:** Nach F-036b arbeiteten die Kern-Skills mit Feature-Dateien, aber
define-requirements schrieb noch eine `REQUIREMENTS.md`, refine-requirements und die
übrigen Skills lasen PROGRESS und REQUIREMENTS, und der Stop-Hook erkannte ein Projekt
nur an der alten `PROGRESS.md`.

**Was entstanden ist (2.0.0, unveröffentlicht):**

- **define-requirements:** Das Interview (Ziele, Kern-Features mit dem Problem zuerst,
  Nicht-Ziele, Rahmenbedingungen, Eigenschafts-Trigger, neu: Reihenfolge) füllt die drei
  Ziel-Abschnitte im Überblick der Projekt-CLAUDE.md (Sprache der CLAUDE.md-Prosa,
  Eigenschafts-Treffer als Rahmenbedingung), legt je Kern-Feature eine schlanke Datei mit
  BACKLOG an (Format wie add-feature, ohne dessen Beratung), setzt die Reihenfolge und
  erzeugt die Tabelle. Grundsatzentscheidungen werden als ADR vorgeschlagen, offene
  Fragen landen mit `[CLARIFY]` in der betroffenen Datei oder unter den
  Rahmenbedingungen. Ohne `features/` legt er den Index aus dem Plugin-Template an und
  nutzt dessen Skript. Die Auflöse-Regel der REQUIREMENTS.md entfällt.
- **refine-requirements:** arbeitet auf Ziel-Abschnitten, Feature-Dateien und ADRs;
  Teilen und Zusammenlegen über SUPERSEDED mit `superseded-by`, Streichen über DROPPED
  (ggf. auch als Nicht-Ziel), DONE bleibt unangetastet; Entscheidungen datiert in der
  Feature-Datei oder als neues ADR; Umplanung der Reihenfolge; Tabelle per Skript.
- **new-project:** „später" lässt Ziel-Abschnitte und Index wie gerendert; 4e beschreibt,
  was define-requirements jetzt schreibt. **handoff:** liest nur die Reihenfolge aus
  `features/INDEX.md`. **audit-code:** Ziele, Nicht-Ziele und Rahmenbedingungen als
  Vertrag, für ein Feature seine Spezifikation. **check-upstreams:** „Aufgabenliste des
  Kits" statt Kit-PROGRESS.
- **update-conventions:** erkennt Kit-Projekte auch an `features/INDEX.md` (ohne Argument
  und bei `alle`), das alte Format weiter; Beispiel bei `no-file` angepasst. Die
  Migration selbst folgt in F-036d.
- **Stop-Hook:** erkennt Projekte an `.claude/template-version`, `features/INDEX.md` oder
  bis zur Migration an `PROGRESS.md` mit FEATURE-INDEX; die Erinnerung nennt die
  Verbuchung in der Feature-Datei; `hooks.json` beschreibt das.
- **Globale Kit-Regeln:** Aufgaben laufen als F-Nummern mit je einer Datei in
  `features/`.
- **Kit-README:** Zeilen zu define- und refine-requirements, Absatz zum Stop-Hook.
  **add-skill:** nennt die Aufgabenliste des Kits nur allgemein (wo sie liegt, sagt die
  Kit-CLAUDE.md), Pflicht-Bausteine um Altformat-Erkennung und das neue Gate ergänzt.
- **Tests:** `hook.sh` mit acht Fällen für den Stop-Hook.

**Verifikation:** Die Suche nach PROGRESS, REQUIREMENTS und FEATURE-INDEX über Plugin und
Template findet außerhalb des CHANGELOG nur die Altformat-Erkennung (Skills, Stop-Hook,
`hooks.json`) und die drei Migrationszeilen im MANIFEST. Der Stop-Hook meldet sich mit
`features/INDEX.md` und offenen Änderungen (auch bei einer neuen Datei, beim alten Format
und bei einem gestempelten Projekt) und bleibt still bei sauberem Baum, im zweiten Stopp
und in einem fremden Repo — Gegenprobe: der Hook aus HEAD schweigt bei einem Projekt nur
mit `features/INDEX.md`. `just check` grün mit 1971 Checks (8 neu je Durchgang);
Versionsregel grün; gitleaks, Privacy-Muster und Blocklist ohne Fund.

**Notable decisions:**
- add-skill nennt die Aufgabenliste des Kits nur allgemein: Das Kit zieht erst in
  F-036e um, so stimmt der Skill vorher und nachher ohne Übergangstext.
- Die Ziel-Abschnitte stehen in der Sprache der CLAUDE.md-Prosa, nicht der lebenden
  Doku — sie gehören zur CLAUDE.md.
- Der Stop-Hook erkennt das alte Format weiter, damit Projekte bis zur Migration erinnert
  werden.

**Abweichungen vom Plan:** keine im Umfang. Die README-Teile zur Struktur des Kits und
zu dessen eigener `PROGRESS.md` bleiben für F-036e.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{define-requirements,refine-requirements,new-project,handoff,audit-code,check-upstreams,update-conventions}/SKILL.md`,
`plugins/coding-kit/hooks/stop-reminder.sh`, `plugins/coding-kit/hooks/hooks.json`,
`tests/template-sync/hook.sh`, `plugins/coding-kit/global/coding-kit.md`, `README.md`,
`.claude/skills/add-skill/SKILL.md`, `plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`.

### F-036d — Migration (2026-10-27)

Teil von F-036 (Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt; F-036a–c
siehe darunter, F-036e folgt).

**Problem:** Skills und Template kannten nach F-036c nur noch `features/`, bestehende
Projekte hatten aber `PROGRESS.md`, `PROGRESS-ARCHIVE.md` und teils `REQUIREMENTS.md` in
sehr unterschiedlichen Spielarten. Ohne Migration könnten sie mit 2.0.0 nicht
weiterarbeiten; alles sollte überführt werden, auch Erledigtes, wortgetreu.

**Was entstanden ist (2.0.0, unveröffentlicht):**

- **`template-sync.sh migrate [--index FILE] [--sections A,B,C] PROJECT OUT`:** liest
  PROGRESS und Archiv, schreibt je F-Nummer `OUT/features/F-NNN-kurzname.md` und eine
  Ausgabeliste; ins Projekt schreibt es nichts.
  - FEATURE-INDEX in beiden Schreibweisen (`F-NNN Titel (STATUS)` und die
    `features:`-Liste); `(→ aufgegangen in …)` wird SUPERSEDED mit `superseded-by`.
  - Blöcke: Überschriften zählen nur außerhalb von Code-Blöcken; ein F-Eintrag endet an
    der nächsten Überschrift gleicher oder höherer Ebene, tiefere derselben Nummer
    bleiben darin. Der offene Eintrag geht unter die Erfassung (ohne `**Status:**`),
    seine offenen Substeps unter den Plan, die Archiv-Abschnitte (umgekehrte
    Dateireihenfolge, dann stabil nach Datum) und Done-Zeilen ohne eigenen
    Archiv-Abschnitt in den Verlauf; Überschriften behalten ihren Abstand zum Block.
  - Status: SUPERSEDED aus dem Index; mit offenem Eintrag dessen Status-Zeile, sonst
    PLANNED mit Substeps bzw. BACKLOG, IN-PROGRESS sobald Verlauf da ist; ohne Eintrag
    DONE bei Verlauf, sonst der Index-Status, sonst BACKLOG. Titel aus dem Index, sonst
    aus der Überschrift des Eintrags bzw. des Archiv-Abschnitts der Nummer.
  - Daten: `created` und `done` aus frühestem und spätestem Datum des Verlaufs; die
    Git-Historie der beiden Dateien liefert den Tag, an dem eine Nummer zuerst auftauchte
    (auch wenn er früher liegt), und den Tag, an dem ihre Index-Zeile `(DONE)` bekam.
  - Ausgabe: `feature`, `unassigned` (Block außerhalb jedes F-Eintrags mit
    Zeilenbereich), `empty`, `conflict`, `date … git`, `missing`, `type feature N`,
    `next-feature`, `requirements`, `index`. `--index` kopiert den gerenderten Index mit
    `next-feature`, `--sections` benennt die drei Abschnitte in der Doku-Sprache.
- **update-conventions A4:** Index-Vorlage aus dem Render, ohne Antworten aus
  Hilfsantworten; Skript; dann das Urteil — Reihenfolge-Text in den Index, REQUIREMENTS
  verteilen (Ziele in die CLAUDE.md, Entscheidungen als ADR oder in die Feature-Datei,
  Kern-Features ohne Nummer als neue Dateien, offene Fragen als `[CLARIFY]`),
  Unzugeordnetes klären, Konflikte und leere Nummern zeigen, lange Titel kürzen;
  Tabelle per `features-index.sh`; Vorschau gruppenweise mit Stichproben; übernehmen,
  danach die Altdateien löschen. A1 und A2 rufen A4 zwischen Schritt 5 und 6 auf, Schritt
  8 löscht die drei Altdateien nur über A4, `status` berichtet. Neues Argument
  `features`: nur die Migration, auch ohne Template-Antworten.
- **MANIFEST § Features:** Absatz zur Migration.
- **Tests:** `tests/template-sync/migrate.sh` (neu, 44 Checks je Durchgang) an einem
  kleinen Altprojekt, das jede Regel einmal trifft — Standardformat, geplanter Eintrag
  mit Substeps, Archiv neueste zuerst → Verlauf aufsteigend, Done-Zeile ohne
  Archiv-Abschnitt, Nummer ohne Inhalt, „aufgegangen in", „Schritt 1.2" gelistet, mit
  und ohne Archiv und REQUIREMENTS, Listen-Index, Git-Daten, Index-Kopie, Ablehnungen —
  und einer eigenständigen Wortgleich-Prüfung: Jede Inhaltszeile der Altdateien steht
  genau so oft in den Feature-Dateien, nichts kommt dazu.

**Verifikation:** `just check` grün mit 2103 Checks unter dash, bash und mawk (44 neu je
Durchgang); Gegenprobe der Wortgleich-Prüfung (gelöschte und erfundene Zeile werden
gemeldet). Kopien eines docs-only- und eines ts-node-Projekts: jede F-Nummer als Datei
und im Index (15 bzw. 52), Wortgleich-Prüfung grün, Index-Prüfung grün (ts-node nach dem
Kürzen zweier Titel über 70 Zeichen, wie es der Skill tut), `just check` der
docs-only-Kopie grün; mawk liefert für die ts-node-Kopie dasselbe Ergebnis Byte für
Byte. Probe am Kit: 49 Dateien, Wortgleich-Prüfung grün; gelistet werden die 28
TPL-Abschnitte und der Reihenfolge-Text, fünf Titel sind zu kürzen. Versionsregel grün;
gitleaks, Privacy-Muster, Blocklist und Projektnamen ohne Fund.

**Notable decisions:**
- `type` wird einheitlich `feature` und gemeldet — der Typ steuert nur die Form neuer
  Spezifikationen (Nutzerentscheidung).
- Fehlende Daten aus der Git-Historie, mit Quelle in der Ausgabe (Nutzerentscheidung).
- Bestätigung gruppenweise mit Stichproben statt je Datei; jede Datei auf Wunsch
  (Nutzerentscheidung) — die Wortgleichheit sichert das Skript.
- Ein offener Eintrag mit Verlauf wird IN-PROGRESS: Das ist die Definition des Status.
- Der Index kommt aus dem Render; das Skript setzt nur `next-feature` und rechnet ihn
  nicht selbst zusammen.

**Abweichungen vom Plan:** Das Argument `features` und die Optionen `--index` und
`--sections` kamen dazu — ein Repo ohne Template-Antworten (das Kit in F-036e) muss
migrieren können, und die Abschnitte stehen in der Doku-Sprache. `just check` der
ts-node-Kopie lief nicht (es bräuchte die Node-Abhängigkeiten, die alte justfile prüft
`features/` nicht); dort gilt die Index-Prüfung.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`tests/template-sync/migrate.sh` (neu), `tests/template-sync/run.sh`,
`plugins/coding-kit/skills/update-conventions/SKILL.md`,
`plugins/coding-kit/template/MANIFEST.md`, `plugins/coding-kit/CHANGELOG.md`,
`PROGRESS.md`.

### F-036e — fertig 2026-10-28

**Umgesetzt:**
- **Testläufe:** sechs Laufarten mit `claude -p --plugin-dir` an Stellvertreter-Ordnern,
  ohne Handarbeit, Endstand per Skript geprüft: define-requirements 0.85 USD, add-feature
  mit Abraten 0.49, prep-step S 0.58 und L 1.04, step-done für Substep 0.59 und
  S-Feature 0.52, update-conventions mit Migration 1.51 — zusammen 5.58 USD. Zwei Funde
  behoben: prep-step übernahm einen leeren Verlauf aus der Vorlage; A4 ließ Verweise auf
  die Altdateien stehen (neuer Schritt 7).
- **Release 2.0.0:** gepusht nach Personendaten-grep und gitleaks, CI grün, Plugin über
  den Marketplace auf 2.0.0 aktualisiert.
- **Umstellung des Kits:** `migrate` aus 2.0.0 mit den Abschnitten Erfassung, Plan,
  Verlauf ergibt 49 Feature-Dateien und `features/INDEX.md`. Die 28 TPL-Abschnitte
  stehen wortgleich in `docs/project-template-history.md`; `PROGRESS.md` und
  `PROGRESS-ARCHIVE.md` sind gelöscht. CLAUDE.md hat Ziele, Nicht-Ziele und
  Rahmenbedingungen im Überblick, die Regeln zu Freigabe und Nummern zeigen auf
  `features/`. README und `private/README.md` sind angepasst. Die justfile hat `just
  features` (Teil von `just check`) und `just features-index`, beide mit dem Skript aus
  dem Template; lefthook prüft bei Änderungen in `features/`.
- **2.1.0, Fund aus der Umstellung:** Markdown-Vorschauen lesen den Kopfblock als YAML;
  Titel mit Doppelpunkt machten ihn ungültig (zehn Dateien im Kit).
  `features-index.sh check` meldet Doppelpunkt, `#` und Sonderzeichen am Titelanfang an
  der Feature-Datei. `write` erzeugt zwei Tabellen (offen nach Nummer, abgeschlossen mit
  dem zuletzt Fertigen oben) und verlinkt die Nummern der empfohlenen Reihenfolge. Die
  Titelregel steht in der Index-Zone, der Vorlage, dem MANIFEST, add-feature, prep-step
  und update-conventions A4. 30 neue Skript-Tests.

**Entscheidungen:**
- Done-Tabelle der PROGRESS weggelassen; die Details stehen im Verlauf, die
  Kurzfassungen in Git (Nutzerentscheidung).
- Fünf zu lange Titel gekürzt, zehn mit Doppelpunkt umformuliert (Nutzerfreigabe). Der
  Satz zu F-026 fiel aus der Reihenfolge, weil dort nur offene Features stehen; sein
  Inhalt steht in F-032.
- Titel ohne Doppelpunkt, gesichert an der Feature-Datei; die Tabelle übernimmt den
  Titel unverändert (Nutzervorgabe).
- Zwei feste Tabellen statt Sortieren per Klick, das keine Markdown-Vorschau kann;
  erledigte unten (Nutzerentscheidung).
- Version 2.1.0 statt eines Patches, weil Tabellen und Links neues Verhalten sind.

**Abweichung vom Plan:** 2.1.0 kam als Fund dazu; das Release von 2.1.0 folgt nach
diesem Abschluss. Im Kit läuft zusätzlich ein lefthook-Job für `features/`.

**Funde:** keine offenen. Nach dem Release rendert `/coding-kit:update-conventions
global` die globalen Regeln neu; sie nennen noch `PROGRESS.md`.
