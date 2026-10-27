# coding-kit — Progress

Lebende Aufgabenliste. **Done-Tabelle** oben, **offene Aufgaben in Ausführungsreihenfolge**
darunter, **Feature-Index** ganz am Ende.

So funktioniert's: `/coding-kit:add-feature` nimmt neue Aufgaben auf (F-Nummer),
`/coding-kit:prep-step` bereitet vor und zerlegt, `/coding-kit:step-done` schließt ab.

---

## Done

Seit 1.0.0 (F-039). Ältere Aufgaben — Kit bis 0.20.0, Template bis 0.16.0
(`TPL-NNN`) — stehen mit Detail in `PROGRESS-ARCHIVE.md`.

| Step | Beschreibung | Fertig |
|------|--------------|--------|
| F-039a | Import und Grundgerüst → **project-template-Historie (37 Commits, bis 0.16.0) unter `plugins/coding-kit/template/` importiert (Template-Nummern als `TPL-NNN`), Repo-eigenes entfernt; CHANGELOG unter dem Plugin mit eingefrorenen Abschnitten; Validator prüft das Template (Registry aus dem MANIFEST, Blocklist repo-weit); Versionsregel vor jedem Commit und in der CI; Version 1.0.0 (unveröffentlicht).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |
| F-039b | Dokumente zusammenführen → **ein Archiv für beide Reihen (55 Einträge, Template als `TPL-NNN`, neueste oben, Kopf erklärt das Schema); Done-Tabelle neu ab 1.0.0; offene Einträge auf ein Repo umgeschrieben, F-026 in F-039/F-032 aufgegangen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |
| F-039c | Skills und Vertrag auf das gebündelte Template → **Template-Auflösung über `${CLAUDE_PLUGIN_ROOT}/template` (kein Klon, Checkout oder Override); new-project baut ein leeres Repo und stempelt die Plugin-Version; update-conventions mit Update-Fenster aus `### Template` und der MANIFEST-Tabelle für entfernte/umbenannte Ziele; Vertragsprüfungen im Validator; HOW-TO-Nachzug aus F-038a; toter `security-tool`-Verweis entfernt.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |
| F-039d | Repo-Doku und Regeln → **CLAUDE.md, README, CONTRIBUTING, Authoring- und Renovate-Doku auf ein Repo umgestellt (Template im Plugin, Versionsregel inkl. Template, Test mit `--plugin-dir`, TPL-Nummern, Einfrier-Regel entfernt); `add-skill` zieht die HOW-TO im selben Commit nach; Marketplace-Beschreibung; Stempel-Satz im Template-`.claude/README.md` korrigiert.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |
| F-039e | Test, Release, Gegenprobe → **lokaler Test an einer Projekt-Kopie (Stempel 0.13.2), Release 1.0.0 gepusht (CI grün), Plugin aktualisiert, Gegenprobe an einem echten Projekt, project-template archiviert. F-039 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-24 |
| F-041a | Renderer → **`template-sync.sh render` schreibt die reine Instanziierung deterministisch aus `.claude/template-answers` (MANIFEST § Answers, exakte Einsetzregeln); ein Render von 0.13.2 reproduziert zwei Bootstrap-Commits bis auf Handkonkretisierungen; Lizenzabsatz in `CONTRIBUTING.md` mit TBD-Variante; Validator, Versionsregel und Tests (dash/bash) im Kit; Version 1.1.0 (unveröffentlicht).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-24 |
| F-041b | Merge und Erkennung → **`template-sync.sh` kann `merge` (Drei-Wege je Datei mit `git merge-file`, Klassen von `identical` bis `conflict`, `keep`/`skip` aus der Files-Tabelle), `status`, `changed`, `snapshot` und `base-from-history`; Vergleich ohne Zeilenende-, Endzeilen- und Slot-Unterschiede; die drei Abweichungen des docs-only-Projekts mergen konfliktfrei; Skript-Tests im Pre-Commit nur bei passenden Dateien.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-24 |
| F-041c | Vertrag und update-conventions → **`manifest-format: 2` mit Basis-Snapshot und Abweichungs-Registry (Files/Rules, Arten `skip`/`keep`/`adapt`); Template-Inhalt nachgezogen (Registry-Vorlage, `.gitattributes`, `.claude/README.md`, HOW-TO, `nextjs`/`astro`); `update-conventions` mergt dreiwegig, ohne Argument nur das aktuelle Projekt, Modi `status`/`revise`, Migration mit Basis aus der Template-Historie; Skript mit `--base`.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-24 |
| F-041d | Übrige Skills → **`new-project` instanziiert über den Renderer (Antworten und Snapshot im Erst-Commit); `choose-stack` wechselt Module über Render und Merge; `step-done` meldet geänderte managed Dateien ohne Registry-Zeile (Schritt 1b); Fragment-Einbau mit `FRAGMENTS` und `keep`-Zeilen; `choose-license` und `go-public` ziehen die Antworten nach; Baustein „Hilfsskripte".** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-24 |
| F-041e | Test, Release, Gegenprobe → **Migrationstests an Kopien eines docs-only- und eines ts-node-Projekts (Zusätze erhalten, Snapshot gesetzt, Prüfungen grün, `biome ci` mit Snapshot); Mischbasis und `.claude/`-Freigaben in `update-conventions`; Release 1.1.0 gepusht (CI grün), Plugin aktualisiert; Gegenprobe am echten docs-only-Projekt ohne unregistrierte Abweichung. F-041 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-24 |
| F-042a | Signal-Vertrag und Daten → **MANIFEST § Detection (Signal-Typen `npm:`, `pypi:`, `go:`, `tool:`, `file:`, Dateiliste aus git, Zustände `covered`/`declined`/`missing`, Werkzeugsprache); Ablehnung als Rules-Zeile `module:NAME`/`fragment:NAME`; Katalog typisiert (`docker` mit Compose-Varianten, `nginx` präzisiert, `api-design` auch für Python und Go); `Signals:`-Zeilen in den vollen Modulen; Validator prüft Typen, Katalog und Module; Version 1.2.0 (unveröffentlicht).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-042b | `detect` im Skript → **`template-sync.sh detect [--changed] TEMPLATE PROJECT [SIGNAL…]`: Leser für `package.json` (auch minifiziert), `pyproject.toml`, `requirements*.txt`, `go.mod`, `mise.toml` und Dateimuster über die git-Dateiliste ohne Snapshot; Zustände aus Antworten, Slot-Markern und Rules-Zeilen; `--changed` nur gegenüber HEAD neue Signale, übergebene Signale ohne Baum; 64 Tests je Shell inklusive frisch gerenderter Projekte; der Validator gleicht die Typliste des Skripts mit dem MANIFEST ab.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-042c | Skills und Doku → **prep-step § 2a prüft geplante Signale per `detect` (Fragment oder Modul fehlt → Anhängen, `/choose-stack` oder Werkzeugsprache); step-done § 1a über `detect --changed`; update-conventions erkennt in Schritt 2 vor dem Rendern (Fragment → `FRAGMENTS`, Modul → `/choose-stack`, dauerhaft ablehnen → Rules-Zeile), `status` berichtet, die Revision trägt Ablehnungen ohne Signale aus; choose-stack empfiehlt aus den Signalen; HOW-TO, README und CHANGELOG nachgezogen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-042d | Test, Release, Gegenprobe → **Läufe an Kopien eines docs-only- und eines ts-node-Projekts (ablehnen, anhängen, diesmal nicht; der folgende `status` ohne Vorschlag für Abgelehntes; Migration von 0.13.2 mit Erkennung); Release 1.2.0 gepusht (CI grün), Plugin aktualisiert; Gegenprobe am echten docs-only-Projekt (`module:python` abgelehnt); Fund aus den Tests: Stellvertreter-Optionen `--answers`, `--registry`, `--snapshot` (1.2.1, unveröffentlicht). F-042 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-043a | Fragmente aufteilen → **Sprachfragmente `python-lang`, `typescript-lang`, `go-lang` im Katalog (Signale ohne Dateiendungen); die drei Modul-Fragmente auf die Toolchain gekürzt und als Modul-Fragment benannt, `Standards fragments:` in den `MODULE.md`; MANIFEST, Katalog und §13 mit den neuen Begriffen; Render- und Erkennungs-Tests für Slot-Reihenfolge und Werkzeugsprache; Version 1.3.0 (unveröffentlicht).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-043b | Erkennung, Validator und Skills → **`detect` zählt vom Modul der Antworten deklarierte Fragmente als `covered`; der Validator meldet Katalog-Fragmente mit Modulnamen; update-conventions und choose-stack setzen neue Fragmente an ihre Stelle aus dem Render, geschützte Fragmente zeigen Template-Änderungen zur Info, `FRAGMENTS` folgt dem Modulwechsel in beide Richtungen; Begriffe Modul- und Sprachfragment in den Skills.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-043c | Test, Release, Gegenprobe → **Läufe an Kopien eines docs-only- und eines mit 1.2.1 gerenderten ts-node-Projekts (Sprachfragment angeboten, Modul-Fragment ersetzt, Stelle aus dem Render, Override mit Info-Diff); Funde mitgenommen: Biome auf Code beschränkt, `base-from-history` für Releases ohne Template-Änderung; Release 1.3.0 gepusht (CI grün), Plugin aktualisiert; Gegenprobe am echten docs-only-Projekt (`python-lang` angenommen); Messung zu Modell und Effort → F-046. F-043 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-044a | Erkennung: Zustand `unknown` und Ablehnung `tool:NAME` → **`detect` meldet nach Modulen und Fragmenten jedes Tool aus `[tools]` der `mise.toml`, für das das Template keine Konvention hat (`unknown`, mit Rules-Zeile `tool:NAME` `declined`); bekannt sind Tools aus der Core- und den Modul-`mise.toml` sowie deklarierte `tool:`-Signale, Backend-Tools zählen nie; MANIFEST und Registry-Kopf beschreiben Zustand und Zeile.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-044b | Skill `propose-to-template` → **erster Hintergrund-Skill (`user-invocable: false`): Claude startet ihn mit einem Fund (Tool ohne Vorlage, projektlokales Fragment, Abweichung an einer managed Datei) und bekommt einen generalisierten, personendatenfreien Übernahme-Vorschlag — kopierfertig als Issue (Standard, `gh issue create` als Text) oder als Prompt für eine Session im Kit-Repo; nichts wird abgeschickt. CONTRIBUTING beschreibt solche Vorschläge, die Authoring-Doku Hintergrund-Skills.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-044c | Skills anbinden, Testlauf, Release → **update-conventions, step-done und prep-step bieten je Tool ohne Vorlage den Vorschlag fürs Template (`propose-to-template`) oder die Ablehnung `tool:NAME` an, choose-stack rät dafür kein Modul; der alte Abschnitt „Übernahme-Vorschlag" entfällt; Funde aus zwei Testläufen mitgenommen (Material getrennt nach Projekt und Vorschlag, Prompt als Entwurfsauftrag mit Recherche, festes Issue-Gerüst, keine verschachtelten Backticks, Datumsformat der Spalte Since); Release 1.4.0 gepusht (CI grün), Plugin aktualisiert. F-044 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-25 |
| F-045a | `zones` und die Override-Regel → **`template-sync.sh zones` vergleicht seed-Zonen und Fragmente im Slot mit dem Render (Zustände von `identical` bis `broken`) und schreibt das Ergebnis mit eingesetzten Blöcken nach `OUT` — alle oder per Name, neue Fragmente an ihrer Stelle aus dem Render; Marker gelten nur allein auf einer Zeile (MANIFEST, `detect`, Validator); Kopfzone der Registry ohne Marker-Text; `snapshot` weist unbekannte Ziele ab; Version 1.5.0 (unveröffentlicht).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-045b | `lock-check` → **`template-sync.sh lock-check` prüft die `mise.lock` gegen `lockfile_platforms` und die CI-Plattform aus `runs-on` (Runner-Labels von GitHub) und meldet je Lock-Eintrag `complete`, `gaps`, `ci-gap`, `no-url`, `unlocked` oder `stale`; Backends ohne Download-URL (laut mise-Doku, z. B. npm, cargo) sind nie eine Lücke; Gegenprobe mit echtem `mise lock`; Known-limitation-Nachtrag zu pnpm.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-045c | Skills anbinden → **update-conventions gleicht Fragmente und seed-Zonen über `zones` ab (nach dem Kopieren der Merge-Ergebnisse, teilweise Zustimmung per zweitem Lauf) und prüft die Lock-Datei über `lock-check`; choose-stack wertet `lock-check` aus und setzt Fragmente in Modus B über `zones` ein; „ein Fragment anhängen" für alle Skills festgelegt; Authoring-Doku: Einsetzen im Skript, mawk-Tests.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-045d | Testlauf, Release, Gegenprobe → **Lauf von update-conventions mit `--plugin-dir` an einem Projekt aus Template 1.4.0 (0,91 USD): Zonen, Fragmente und Lock-Datei nur über `zones` und `lock-check`, teilweise Zustimmung per zweitem Lauf, Endstand per Skript geprüft; Fund mitgenommen: vor `mise trust` fragen; Release 1.5.0 gepusht (CI grün), Plugin aktualisiert; Gegenprobe an einem Downstream-Projekt ohne Fund (0,56 USD). F-045 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-047 | Skript-Tests zusätzlich mit mawk → **`run.sh` hängt je einen Durchgang mit mawk und gawk an, wenn installiert und nicht das Standard-awk (erkannt über `awk -W version`); die Zusammenfassung nennt die geprüften awks; ein eingeschleustes `NF`-Array fällt nur im mawk-Durchgang auf; Doku nachgezogen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-040a | Kit-Datei, Werte, Render → **die globalen Regeln liegen als `global/coding-kit.md` im Plugin (fünf Zonen, Kennung, Sprachregel der Vorlage, Artifact-Regel, Erklär-Niveau mit vier Stufen und Notiz); `template-sync.sh render-global` rendert sie mit den Werten der Personal-Config, ohne die Datei auszuführen, und `zones` gleicht das Ergebnis mit einem Config-Ordner ab; `claudeMdExcludes` hält die Template-CLAUDE.md aus Sessions im Kit-Repo; Validator, Versionsregel und Tests nachgezogen; Version 1.6.0 (unveröffentlicht).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-040b | Interview-Skill `explain-level` → **neuer Skill `/coding-kit:explain-level`: Interview zu Antwortsprache und Erklär-Niveau (Programmieren, Shell, Git, Frameworks, Projekt-Werkzeuge, Code mitlesen), Vorschlag für Stufe und Notiz mit dem Stufentext der Kit-Datei, einzige Stelle, die die Werte abfragt; `template-sync.sh set-global` schreibt die Werte in eine Kopie der Personal-Config (erste Zuweisung ersetzt, spätere entfernt, Rest unverändert, für die Shell wörtlich maskiert); README, plugin.json, CHANGELOG.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-040c | Abgleich in update-conventions, Niveau in den Skills → **`update-conventions global` (Teil G) richtet die globalen Kit-Regeln ein und gleicht sie je Zone über `zones` ab, jeder andere Lauf prüft sie einmal mit; fehlende Werte über `explain-level`, Migration einer alten Kit-Kopie in einem Schritt mit der Einrichtung, eine selbst angelegte CLAUDE.md nur mit Widerspruchs-Hinweis; Stand als Basis im Plugin-Datenordner; teach-step ohne Graphiti-Lernprofil; `propose-to-template` mit der Fund-Art globale Regel; Authoring-Regel zum Erklärstil; HOW-TO nennt `global`.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-040d | Session-Hinweis, Installer, Nutzer-Doku → **SessionStart-Hook meldet eine alte Kit-Kopie, geänderte Kit-Regeln oder Werte und eine unlesbare Personal-Config (Render gegen die Basis, schreibt nie, endet immer ohne Fehler); `install.sh` schreibt nichts Globales mehr und verweist auf `update-conventions global`; `templates/` und der `curl`-Weg entfallen; README mit Warnkasten, Werten, Abweichungen, den Aufrufen von `update-conventions` und dem Session-Hinweis; der Validator gleicht die Stufen im README ab; Verweise in F-024, F-029, F-030 und F-033 nachgezogen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-048 | Frontmatter-Pflichtfelder für Skills → **alle 20 Skills setzen `disable-model-invocation` und `user-invocable` ausdrücklich (Startverhalten unverändert, per Skript verglichen), zwölf mit Argument zeigen ein `argument-hint`; der Validator verlangt beide Flags als `true`/`false`, lehnt einen Skill ab, den niemand starten könnte, lässt nur die 20 dokumentierten Felder zu und prüft die Grenze von 1536 Zeichen; Authoring-Doku mit Feldübersicht, `default-enabled` gestrichen; Hinweise in F-027 und F-037.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-26 |
| F-040e | Testlauf, Release, erster echter Abgleich → **vier Testläufe mit `--plugin-dir` (Neueinrichtung, Migration einer alten Kit-Kopie, eigene CLAUDE.md, Interview; zusammen 2,65 USD) ohne Handarbeit, Endstand per Skript geprüft; Fund mitgenommen: die env-Datei nicht ausgeben; Release 1.6.0 gepusht (CI grün), Plugin aktualisiert; erster echter Abgleich: Kit-Regeln eingerichtet, alte CLAUDE.md gelöscht, Lernprofil aus Graphiti entfernt; Gegenprobe per `InstructionsLoaded`-Hook. F-040 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-27 |
| F-049a | Skript, Tests, Vertrag → **`zones` unterscheidet über eine Basis neue (`new`), abgewählte (`opted-out`), unbestätigte (`unconfirmed`) und entfernte (`removed`) Zonen, setzt neue an ihrer Stelle aus dem Render ein und entfernt gestrichene; abgewählte und unbestätigte nur per Name; Override-Zählung auch für Zonen; `snapshot --seeds` schreibt die Seed-Basis `<Ziel>.seed`, die `status`, `merge` und `changed` nicht lesen; MANIFEST §§ Base snapshot und Seed sections; Version 1.7.0 (unveröffentlicht).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-27 |
| F-049b | Skills anbinden → **update-conventions bietet neue Zonen zum Einsetzen oder als Opt-out an, gestrichene zum Entfernen oder Behalten, fragt Zonen ohne Basis einmal und holt abgewählte per Name zurück (A2 Schritte 6, 7, 9, A3, G3); Schritt 9 setzt die Seed-Basen in jedem Lauf; new-project setzt sie beim Anlegen; README-Zeile nachgezogen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-27 |
| F-049c | Text ohne Marker erkennen → **`zones` findet den Text einer fehlenden Zone wörtlich in der Datei: ohne Basis-Eintrag `bare`, per Name legt das Skript nur die Marker darum — ebenso beim Zurückholen einer abgewählten Zone; eine Abwahl in einer Datei ganz ohne Marker bleibt `opted-out`; update-conventions bietet „Marker setzen" / „so lassen" an, die Marker-Migration von Hand bleibt für geänderten Text (Fund aus dem ersten Testlauf).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-27 |
| F-049d | Testlauf und Release → **drei Läufe mit `--plugin-dir` (zusammen 2,11 USD): Projekt mit neuer, abgewählter, entfernter und unbestätigter Zone — der erste fand „Text ohne Marker" (→ F-049c), der wiederholte setzte alles über `zones` um; global eine neue Kit-Zone eingesetzt, die Abwahl respektiert; Release 1.7.0 gepusht, CI grün, Plugin aktualisiert. F-049 damit komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-27 |

---

## Offene Aufgaben — von oben nach unten abarbeiten

### F-036 — Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt

**Status:** PLANNED

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
  (`S`/`M`/`L`, ab prep-step), `created`, `done`, `depends-on`, `superseded-by`. Nicht:
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
  - *Spezifikation* (prep-step, Phase 1): Abnahmekriterien AK-n als Gegeben/Wenn/Dann
    inkl. Negativfällen; Randfälle R-n mit erwartetem Verhalten; Nicht-Ziele; Tests je AK;
    Einbettung; offene Fragen mit `[KLÄREN]`; Entscheidungen datiert mit Grund
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
  blockierendes `[KLÄREN]`, Abhängigkeiten erledigt oder eingeplant, Einbettung geprüft,
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
- **Index-Skript** im Template (`scripts/features-index.sh`, POSIX-Shell, Name
  vorläufig): erzeugt die Tabelle und prüft in `just check` Pflichtfelder, `id` passend
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

#### F-036a — Vorlagen und Index-Skript

**Was:** Template: `features/INDEX.md` (seed, Zone `index-head`, Reihenfolge, erzeugte
Tabelle zwischen Markern, `next-feature`), `features/F-000-template.md` (managed);
CLAUDE.md-Vorlage: Überblick mit den Unterabschnitten Ziele, Nicht-Ziele und
Rahmenbedingungen (Projektinhalt, kein Template-Text), Zonen `claude-startup` und
`claude-workflow` auf `features/`; HOW-TO (Workflows, wichtige
Dateien), README, ADR-README, PR-Vorlage und `private/README.md` nachziehen;
`scripts/features-index.sh` (erzeugen und prüfen), justfile-Rezept zum Erzeugen,
Prüfung in `just check`. `core/PROGRESS.md`, `core/PROGRESS-ARCHIVE.md` und
`core/REQUIREMENTS.md` entfernen. MANIFEST: Zieltabelle, Seed-Zonen (neu `index-head`;
weg `progress-head`, `archive-head`, `requirements-head`), erste
Zeilen in „Removed and renamed targets", Beschreibung von `{{LANG_LIVING_DOCS}}`.
Validator, Tests, Version 2.0.0 mit CHANGELOG-Eintrag samt `### Template`.

**Dateien:** `plugins/coding-kit/template/MANIFEST.md`; unter
`plugins/coding-kit/template/core/`: `features/INDEX.md`, `features/F-000-template.md`,
`CLAUDE.md`, `HOW-TO-CODE-WITH-CLAUDE.md`, `README.md`,
`docs/adr/README.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `private/README.md`, `justfile`,
`scripts/features-index.sh` (entfernt: `PROGRESS.md`, `PROGRESS-ARCHIVE.md`,
`REQUIREMENTS.md`); `scripts/validate.py`, `tests/template-sync/features.sh` (neu),
`tests/template-sync/run.sh`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`plugins/coding-kit/CHANGELOG.md`.

**Abhängigkeiten:** keine.

**Abnahmekriterien:**
- [ ] Ein frisch gerendertes Projekt besteht `just check`; sein INDEX ist leer und
      gültig, seine CLAUDE.md hat im Überblick die Abschnitte Ziele, Nicht-Ziele und
      Rahmenbedingungen.
- [ ] Tests: Erzeugen ergibt die Tabelle aus den Kopfblöcken (Sortierung, Links, Status,
      Datum) und lässt Kopf und Reihenfolge unangetastet; Prüfen fängt fehlendes
      Pflichtfeld, `id` ungleich Dateiname, unbekannten Status, fehlendes `done` oder
      `superseded-by`, Titel über 70 Zeichen, doppelte Nummer, zu niedriges
      `next-feature`, veraltete Tabelle und Erledigtes in der Reihenfolge.
- [ ] Läuft unter dash und bash, mit System-awk und mawk.
- [ ] Vertragsprüfungen und Versionsregel grün; `just check` grün.

#### F-036b — Kern-Skills

**Was:** add-feature (Beratung: Problem vor Lösung, Gegenargument, Alternativen, vier
Empfehlungen, DROPPED auf Wunsch; legt Datei und Kopfblock an, erzeugt die Tabelle,
schlägt einen Platz in der Reihenfolge vor). prep-step (Größe aus drei Signalen; Phase 1
Spezifikation in der Tiefe je Größe — Interview, Example Mapping, drei Blickwinkel plus
Sicherheit, Einbettung, Abraten erlaubt; Ready-Prüfung; Phase 2 Plan mit Substeps;
PLANNED; lange Entwürfe nach `private/`). build-step (liest die Datei, Nicht-Ziele als
Scope-Schutz, sammelt Abweichungen für step-done). step-done (Verlauf-Eintrag je Substep,
Abnahmekriterien mit Beleg, IN-PROGRESS bzw. DONE, Tabelle erzeugen, Reihenfolge
nachziehen; kein Archiv mehr). teach-step. Freigabe-Gate-Text in allen fünf und in
`docs/skill-authoring.md`. Altformat: Bei einer `PROGRESS.md` mit FEATURE-INDEX und ohne
`features/INDEX.md` auf die Migration verweisen. `/add-skill` läuft mit.

**Dateien:** `plugins/coding-kit/skills/{add-feature,prep-step,build-step,step-done,teach-step}/SKILL.md`,
`docs/skill-authoring.md`, `README.md`, `plugins/coding-kit/CHANGELOG.md`.

**Abhängigkeiten:** F-036a.

**Abnahmekriterien:**
- [ ] Die fünf Skills lesen und schreiben nur noch `features/` und die Ziel-Abschnitte
      der CLAUDE.md; jeder
      Punkt aus „Entschieden" zu Beratung, Größe, Tiefe, Ready, Status und Verlauf ist
      einem Skill zugeordnet.
- [ ] Bei altem Format verweisen sie auf die Migration statt zu raten.
- [ ] `just check` grün.

#### F-036c — Anforderungs- und Randskills, Hook, Doku

**Was:** define-requirements (Interview → Ziel-Abschnitte im Überblick der CLAUDE.md, je
Kern-Feature eine schlanke Datei mit BACKLOG, Reihenfolge, Tabelle;
Eigenschafts-Trigger als Rahmenbedingung; Auflöse-Regel entfällt). refine-requirements
(arbeitet auf den Ziel-Abschnitten der CLAUDE.md, Feature-Dateien und ADRs; Teilen und
Streichen über SUPERSEDED und DROPPED; Umplanung der Reihenfolge).
new-project, handoff, audit-code, check-upstreams auf die neuen Dateien;
update-conventions erkennt Kit-Projekte auch an `features/INDEX.md`; der Stop-Hook
ebenso. Globale Kit-Regeln (Satz zu F-Nummern in `PROGRESS.md`), Kit-README,
`.claude/skills/add-skill`. `/add-skill` läuft mit.

**Dateien:** `plugins/coding-kit/skills/{define-requirements,refine-requirements,new-project,handoff,audit-code,check-upstreams,update-conventions}/SKILL.md`,
`plugins/coding-kit/hooks/stop-reminder.sh`, `tests/template-sync/hook.sh`,
`plugins/coding-kit/global/coding-kit.md`, `README.md`, `.claude/skills/add-skill/SKILL.md`,
`plugins/coding-kit/CHANGELOG.md`.

**Abhängigkeiten:** F-036b.

**Abnahmekriterien:**
- [ ] Eine Suche nach `PROGRESS`, `REQUIREMENTS` und `FEATURE-INDEX` über Plugin und
      Template findet nur noch Migration, Altformat-Erkennung und CHANGELOG.
- [ ] Test: Der Stop-Hook meldet sich in einem Projekt mit `features/INDEX.md` und
      offenen Änderungen und bleibt in einem fremden Repo still.
- [ ] `just check` grün.

#### F-036d — Migration

**Was:** Skriptbefehl in `template-sync.sh` für den mechanischen Teil (siehe
„Entschieden"), schreibt nach `OUT` und listet Unzugeordnetes; Kopf-Doku des Skripts,
MANIFEST beschreibt den Befehl. Migrationsschritt in update-conventions: altes Format
erkennen, Skript laufen lassen, REQUIREMENTS verteilen, Titel kürzen, Unzugeordnetes
klären, Diff und Bestätigung je Datei, Altdateien erst danach löschen.

**Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`tests/template-sync/migrate.sh` (neu), `tests/template-sync/run.sh`,
`plugins/coding-kit/skills/update-conventions/SKILL.md`,
`plugins/coding-kit/template/MANIFEST.md`, `plugins/coding-kit/CHANGELOG.md`.

**Abhängigkeiten:** F-036a (Format von INDEX und Feature-Datei), F-036c
(update-conventions).

**Abnahmekriterien:**
- [ ] Tests: Standardformat; geplanter Eintrag mit Substeps; Archiv neueste zuerst →
      Verlauf aufsteigend; Done-Zeile ohne Archiv-Abschnitt; Nummer ohne Inhalt;
      „aufgegangen in" → SUPERSEDED; Altformate wie „Schritt 1.2" werden gelistet, nicht
      geraten; mit und ohne REQUIREMENTS.md; dash und bash, System-awk und mawk.
- [ ] Kopien eines docs-only- und eines ts-node-Projekts: jede F-Nummer als Datei und im
      INDEX, jeder offene Eintrag und jeder Archiv-Abschnitt wortgleich übernommen (per
      Skript gegengeprüft), danach `just check` grün.

#### F-036e — Testläufe, Release, Umstellung des Kits

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
- [ ] Alle Läufe ohne Handarbeit, Endstand per Skript geprüft, Kosten je Lauf genannt.
- [ ] Release 2.0.0 gepusht, CI grün, Plugin aktualisiert.
- [ ] Das Kit arbeitet mit `features/`: 49 Feature-Dateien, Tabelle erzeugt,
      TPL-Verlauf in eigener Datei, `just check` grün.
- [ ] Gegenprobe an einem Downstream-Projekt ohne Inhaltsverlust.

---

## Feature-Ideen (Backlog)

_Neue Ideen via `/coding-kit:add-feature` — sie bekommen die nächste F-Nummer._

**Empfohlene Reihenfolge** (Stand 2026-10-27; die Einträge darunter bleiben nach Nummer
sortiert):

1. **F-036** — großer Umbau; alle folgenden Features werden schon mit Spec-Phase und
   Feature-Datei geplant.
2. **F-034 + F-037** — Qualitätsstrang auf dem neuen prep-step/step-done.
3. **F-029 → F-033 → F-030** — Graphiti-Strang (F-030 ohne den `install.sh`-Teil).
4. **F-032 → F-024 → F-025** — Host-Strang; F-025 nimmt den `install.sh`-Teil von F-030
   mit. F-026 ist in F-039 aufgegangen, sein Rest (Kit-Repo-Herkunft in `check-upstreams`)
   in F-032.
5. **F-027** — sobald ein Windows-Rechner zur Verifikation verfügbar ist, gern mit F-025.
6. **F-046** — ganz am Ende, nach allen Features: misst den Endstand über verschiedene
   Projekte; erst dann kommt die Empfehlung zu Modell, Effort und Kosten in die README.

Strang 4 und 5 sind tauschbar: Graphiti-Kosten zuerst oder Betrieb auf anderen Rechnern
bzw. ohne GitHub zuerst.

### F-024 — Commit-Adresse aus der Personal-Config statt hart aus gh

**Status:** BACKLOG

**Problem:** `/step-done` § Autor-Config setzt `git config user.email` unbedingt auf die
GitHub-Noreply-Adresse und ermittelt sie über `gh api user`. Ohne GitHub schlägt die
Ermittlung fehl — und die Regel ist dort auch inhaltlich falsch, weil die Adresse des
eigenen Hosts in die Commits gehört. Das widerspricht der eigenen Kit-Regel, Identität
nicht zu hardcoden.

**Idee:** `CODING_KIT_GIT_NOREPLY_EMAIL` aus der Personal-Config wird zur Quelle der
Wahrheit, `gh api user` nur noch einer von zwei Ermittlungswegen. Fehlt beides, fragt der
Skill statt zu raten.

**Lösungsskizze:**
- Reihenfolge in step-done § Autor-Config: Personal-Config → `gh api user` → fragen; kein
  GitHub-Format mehr erzwingen.
- Gleiche Härte in den globalen Kit-Regeln entschärfen
  (`plugins/coding-kit/global/coding-kit.md`, Zone `global-git`): GitHub-Noreply als
  Default für GitHub-Projekte, Kernaussage bleibt „keine private Adresse".
- Weitere Fundstellen desselben Musters prüfen (u. a. `new-project` 4a) und die
  README-Zeile zum Schlüssel an die neue Rolle anpassen.
- Template-Seite: Die Noreply-Regel steht auch im Template (`template/core/CLAUDE.md`,
  `CODING-STANDARDS.md`, `CONTRIBUTING.md`, HOW-TO, `scripts/privacy-lint.sh`) — im
  selben Commit anpassen, gemeinsam mit F-032.

**Abhängigkeiten:** F-032 (Host-Profil bestimmt, welche Noreply-Adresse gilt) — sinnvoll
im selben Zug umzusetzen

### F-025 — install.sh: fehlender gh-Login und Plattform-Abdeckung

**Status:** BACKLOG

**Problem:** `install.sh` setzt GitHub und macOS voraus. Fehlt `gh` oder ist es nicht
angemeldet, bricht er in der ersten Prüfung ab, statt den Login anzubieten oder ohne
GitHub weiterzumachen — obwohl die README einen GitHub-freien Weg beschreibt. Die
Toolchain-Installation kennt nur `brew`; auf Linux ohne Brew und auf Windows bleibt es
bei einer Warnung. Plattform-Erkennung gibt es im Repo nirgends.

**Idee:** Der Installer wird Bootstrap für alle drei Plattformen und auch für Rechner
ohne GitHub: Voraussetzungen werden erkannt und benannt statt zur Abbruchbedingung
gemacht, fehlender Login wird angeboten, und die Toolchain kommt über den Paketmanager
der jeweiligen Plattform.

**Lösungsskizze:**
- Drei `gh`-Zustände unterscheiden (fehlt / vorhanden ohne Login / bereit) statt eines
  harten `fail`: Login anbieten, GitHub-freien Lauf als bestätigte Alternative — dann die
  Personal-Config ohne `gh api`-Vorbefüllung abfragen.
- Kein Template-Checkout mehr nötig — das Template kommt seit F-039 mit dem Plugin,
  auch auf dem GitHub-freien Weg.
- Plattform bestimmen und Paketmanager wählen: brew auf macOS, apt/dnf/pacman auf Linux,
  winget/scoop auf Windows; prüfen, ob `mise` der plattformneutrale Weg für
  just/lefthook/gitleaks ist und nur mise selbst plattformspezifisch installiert wird.
  Wird kein Paketmanager gefunden: Abbruch mit Hinweis auf die manuelle Installation
  statt stiller Warnung (Toolchain ist der letzte Schritt, alles Übrige ist dann bereits
  eingerichtet).
- Windows: Lauf in einer Bash prüfen und benennen (der Stop-Hook verlangt sie ohnehin);
  Abbruchmeldungen so ausgeben, dass sie beim Start per Dateizuordnung nicht mit dem
  Fenster verschwinden.
- Defaults plattformgerecht wählen — das Projekte-Verzeichnis nicht auf ein englisches
  „Documents" festlegen.
- Zeilenenden sind kein Thema: `.gitattributes` erzwingt `eol=lf` für den ganzen Baum.

**Abhängigkeiten:** F-032 (zentrale Host-Erkennung — Skills und Installer nutzen
dieselbe Antwort auf „welcher Git-Server, welche Fähigkeiten").

### F-027 — Stop-Hook plattformfähig machen (Windows greift ins WSL)

**Status:** BACKLOG

**Problem:** `hooks.json` startet den Stop-Hook als
`bash "${CLAUDE_PLUGIN_ROOT}/hooks/stop-reminder.sh"`. Unter Windows wurde beobachtet,
dass der Hook nicht funktioniert; wahrscheinliche Ursache ist das `bash.exe` in
`System32`, das den WSL-Start auslöst — der Hook landet damit in einer Umgebung, in der
der übergebene Windows-Pfad nicht auflösbar ist. Auf Windows fällt damit die einzige
Erinnerung an `/step-done` aus, und ein fehlschlagender Hook erzeugt womöglich bei jedem
Stopp Lärm, statt still zu bleiben.

**Idee:** Der Einstiegspunkt darf sich nicht auf ein nacktes `bash` aus dem PATH
verlassen. Auf Windows wird die Bash der Git-Installation gezielt aufgelöst — git ist für
den Hook ohnehin Voraussetzung. Schlägt die Auflösung fehl, bleibt der Hook stumm statt
zu scheitern.

**Lösungsskizze:**
- Ursache auf einem Windows-Rechner bestätigen, bevor gebaut wird (WSL-Treffer oder
  anderer Grund).
- Prüfen, welche Plattformweichen `hooks.json` erlaubt (Doku zur Laufzeit lesen); sonst
  muss der Einstiegspunkt selbst die Shell bestimmen.
- Auf Windows die Git-Bash auflösen statt `System32\bash.exe` zu treffen.
- Das Skript bleibt inhaltlich unverändert — es ist bereits POSIX-kompatibel, das Problem
  ist der Interpreter.
- Stillschweigen im Fehlerfall wahren: keine Ausgabe, wenn keine passende Shell gefunden
  wird.
- Verifikation gehört auf einen echten Windows-Rechner; auf macOS und Linux ist nur
  Nicht-Regression prüfbar.

**Noch zu analysieren:**
- Seit F-040d startet auch der Session-Hinweis (`hooks/session-start.sh`) über `bash`; die
  Lösung muss beide Hooks abdecken. Für Befehle in Skill-Texten gibt es das
  Frontmatter-Feld `shell` (`bash` oder `powershell`, siehe F-048) — prüfen, ob ein Skill
  es braucht.

**Abhängigkeiten:** keine. Thematische Nähe zu F-025 (Plattform-Abdeckung), aber anderer
Gegenstand: Plugin-Inhalt statt Installer.

---

### F-029 — Graphiti-Schreibzugriffe auf Server-LLM-Kosten optimieren

**Status:** BACKLOG

**Problem:** Die Skills schreiben häufig und ohne gemeinsame Regel in Graphiti — dasselbe
Feature landet bei Aufnahme, Abschluss und Spec-Änderung jeweils als eigene Episode, oft
als ausführliche Prosa mit vielen beiläufigen Nennungen. Jede Episode löst auf dem
Graphiti-Server eine Kette von Extraktions-, Dedup- und Auflösungsschritten im
angebundenen LLM aus; der Verbrauch dort ist entsprechend hoch. Der Informationsgehalt
im Graph soll dabei nicht sinken — er dient als schnelle Alternative zur Repo-Suche und
spart so Entwicklungs-Tokens.

**Idee:** Eine zentrale Graphiti-Konvention, auf die alle Skills verweisen: weniger, dafür
gezielt geschnittene Episoden mit gesteuerter Extraktion, sodass der Server pro
gespeichertem Fakt weniger LLM-Arbeit leistet. Überholtes regelt der Graph selbst über
seine Zeitstempel — kein manuelles Löschen.

**Lösungsskizze:**
- Erst auswerten, dann ändern: Die Messung pro LLM-Call und Pipeline-Schritt läuft
  serverseitig; nach ein bis zwei Wochen Daten entscheiden — bis dahin keine
  Skill-Änderungen auf Verdacht. Die Vergleichsbasis beginnt erst mit einem
  serverseitigen Fix am 09.10.2026; ältere Werte stammen aus einer anderen
  Kostenstruktur und sind nicht vergleichbar.
- Arbeitshypothese: Stärkster Hebel ist die Zahl der Entitäten, die eine Episode
  erwähnt — jede kostet einen eigenen Attribut-Call plus Abgleich gegen den Graph.
  Die Episodenlänge wirkt nur indirekt (mehr Text → mehr Entitäten).
- Entitäten-Rauschen senken: Dateipfade, Funktionsnamen, Test-IDs und F-Nummern, die
  nicht Thema der Episode sind, nicht als eigene Entitäten entstehen lassen — im Text
  dürfen sie für die Suche stehen bleiben, wenn die Extraktion sie überspringt.
- Extraktion steuern: kurze `custom_extraction_instructions` (z. B. „einzelne
  Dateipfade und Test-IDs nicht als eigene Entitäten, außer sie sind das Thema") und
  `excluded_entity_types` testen; für einzelne, klar umrissene Fakten `add_triplet`
  statt freier Extraktion. Wirkung jeweils vorher/nachher messen.
- Episoden pro Arbeitsschritt zählen: mehrere Episoden eines Schritts zusammenfassen,
  dabei etwa 2.000–3.000 Zeichen pro Episode nicht deutlich überschreiten (sonst
  droht Abbruch der Extraktion).
- Ein Schreibanlass pro Feature statt mehrerer (z. B. nur beim Abschluss); andere Skills
  schreiben nur bei echten Entscheidungen. Mit F-036 liegt das Detail in der
  Feature-Datei — der Graph bekommt eine knappe Zusammenfassung mit Verweis statt
  ausführlicher Prosa, also weniger Entitäten.
- `reference_time` setzen, wo vergangene Ereignisse beschrieben werden, damit die
  zeitliche Auflösung ohne Nacharbeit stimmt; `update_communities` bleibt aus.
- Globale Kit-Regeln anpassen (Zone `global-graphiti`): Löschanweisung streichen,
  Splitting-Regel überdenken, auf die zentrale Konvention verweisen.
- Betroffen: alle Skills mit Graphiti-Schreibzugriff, `docs/skill-authoring.md`,
  die globalen Kit-Regeln.

**Noch zu analysieren:**
- Welchen Anteil die Kit-Skills am Gesamtverbrauch haben, verglichen mit Schreibern
  außerhalb des Kits — bestimmt, wie viel F-029 überhaupt bewirken kann.
- Ob die Entitäten-Hypothese hält und was daraus folgt (weniger Entitäten, weniger
  Episoden, kürzer).
- Wie viele Entitäten die Kit-Skills heute pro Episode erzeugen und welcher Anteil
  davon Rauschen ist.
- Ob übersprungene Entitäten die Auffindbarkeit im Graph spürbar verschlechtern —
  der Graph soll die Repo-Suche weiterhin ersetzen können.
- Wo die zentrale Konvention liegt, damit Plugin-Skills sie zur Laufzeit erreichen.

**Abhängigkeiten:** Auswertung der serverseitigen Kostenmessung (extern, ein bis zwei
Wochen Daten). F-036 — erst danach umsetzen, sonst werden Skills optimiert, die F-036
ohnehin umschreibt.

---

### F-030 — Graphiti-Episodenverlust erkennen und wiederherstellbar halten

**Status:** BACKLOG

**Problem:** `add_memory` meldet nur „queued" — ob eine Episode wirklich im Graph
ankommt, sieht der Skill nicht. Episoden, die der Graphiti-Server verliert, werden nie
erneut verarbeitet; wiederherstellen lassen sie sich nur aus den lokalen
Claude-Code-Transkripten. Die löscht Claude Code standardmäßig nach 30 Tagen — danach
ist ein Verlust endgültig.

**Idee:** Zwei Teile: Das Kit setzt die Aufbewahrungsdauer der Transkripte auf jedem
Rechner hoch (Empfehlung: 365 Tage), und ein Skill prüft an passender Stelle, ob die
zuletzt geschriebenen eigenen Episoden angekommen sind.

**Lösungsskizze:**
- Erfolgskontrolle: z. B. zu Sessionbeginn oder in `step-done` die letzten Episoden der
  Gruppe abrufen und mit den zuletzt geschriebenen abgleichen; Fehlendes melden (nicht
  automatisch nachschreiben). Leseaufrufe kosten keine Extraktion.
- `cleanupPeriodDays` in den Nutzer-Settings von Claude Code setzen — über `install.sh`,
  ohne bestehende Settings zu überschreiben (vorhandenen Wert respektieren oder
  nachfragen).
- Schlüssel und Default zur Laufzeit gegen die aktuelle Claude-Code-Doku prüfen.
- In den globalen Kit-Regeln bzw. im README kurz begründen, warum der Wert gesetzt
  wird.
- Speicherbedarf der Transkripte bei längerer Aufbewahrung im Blick behalten.

**Abhängigkeiten:** keine. Thematische Nähe zu F-029 (Graphiti). Den
`install.sh`-Teil (`cleanupPeriodDays`) zusammen mit F-025 bauen.

### F-032 — Host-unabhängiger Betrieb (ohne GitHub, andere Git-Server, nur Git)

**Status:** BACKLOG

**Problem:** Das Kit setzt GitHub voraus: `gh` bzw. `gh api user` steckt im Installer,
in `new-project` (Repo-Anlage, Settings, Topics, Autor-Config), `step-done`
(Noreply-Pflicht), `update-conventions` (Topic-Discovery, Template-Issue), `go-public`,
`name-it`, `check-upstreams` und `choose-stack`; dazu das Renovate-Preset (`github>…`)
und die CI unter `.github/`. Ohne GitHub-Konto — oder mit GitLab, Forgejo/Gitea,
Bitbucket, Azure DevOps, Codeberg, einem eigenen Server oder einem Bare-Repo auf
Platte/NAS — scheitern Skills an `gh`, statt den Schritt auszuweisen. Nimmt F-023
(new-project ohne GitHub) vollständig auf; dessen offene Frage „zentral oder lokal
erkennen" ist hiermit entschieden: zentral.

**Idee:** Ein zentrales Host-Profil beschreibt, welcher Git-Server im Spiel ist und
welche Fähigkeiten er bietet (Repo anlegen, Repo-Settings, Topics/Discovery, Issues,
Noreply-Adresse, Renovate, CI). Skills fragen Fähigkeiten ab statt `gh` aufzurufen;
fehlt eine, wird der Schritt ausgewiesen übersprungen, nicht durch Fehlschlag. Die
unterste Stufe „nur Git" (Bare-Repo oder gar kein Remote) muss immer vollständig
tragen.

**Lösungsskizze:**
- Host-Profil in der Personal-Config (Typ, CLI, Basis-URL) mit Erkennung aus dem
  Remote als Vorschlag; eine Stelle beschreibt die Fähigkeiten je Host, die Skills
  referenzieren sie — keine `gh`-Aufrufe mehr verstreut in den Skills.
- Host-Klassen nach Recherche: gehostet (GitHub, GitLab.com, Bitbucket Cloud, Azure
  DevOps, Codeberg, SourceHut), selbst gehostet (GitLab CE/EE, Forgejo, Gitea, Gogs,
  OneDev, Bitbucket Data Center, Gerrit), minimal/lokal (Bare-Repo via `file://`/SSH,
  Gitolite, Soft Serve, `git daemon`), Peer-to-Peer (Radicle). CLIs je nach Host
  (`gh`, `glab`, `tea`, `fj`/`berg`, `az repos`) — Pflegestand zur Planungszeit prüfen.
- `new-project` lokaler Bootstrap (aus F-023): `git init` statt `gh repo create` — das
  Template kommt seit F-039 aus dem Plugin, ein Checkout ist nicht nötig; Autor-Config
  aus der Personal-Config; Repo-Settings/Topics nur, wo der Host sie kann — Discovery
  trägt sonst der `.claude/template-version`-Stempel. README-Abschnitt
  „Ohne GitHub" auf den Skill-Pfad umstellen.
- Renovate: offiziell Azure, Bitbucket (Cloud/Server), Forgejo, Gitea, GitHub, GitLab;
  Gerrit und `local` experimentell. Preset-Referenz je Host klären.
- CI: GitHub Actions, Forgejo/Gitea Actions (weitgehend kompatibel), GitLab CI,
  Woodpecker, Bitbucket Pipelines, Azure Pipelines — Template-Seite betroffen
  (im selben Commit).
- Der GitHub-Request im Übernahme-Vorschlag (`update-conventions`, seit F-039 ein Issue
  im coding-kit-Repo) braucht einen Weg ohne `gh`; der kopierfertige Prompt für eine
  Kit-Session kommt bereits ohne aus.
- Template-Seite neben CI und Renovate: die Noreply-Regel in den Vorlagen (siehe
  F-024) — gemeinsam im selben Commit.
- Aus F-026: `check-upstreams` leitet das Kit-Repo aus `gh api user` ab — das trägt nur
  beim Eigentümer und nie ohne `gh`. Die kanonische Quelle deklarieren (wie der
  Marketplace seine Quelle nennt), Personal-Config als Override.
- Publishing-Hygiene: Basis-URLs und Hostnamen selbst gehosteter Server sind privat —
  nur in der Personal-Config, nie im Repo oder in der lebenden Doku; Credentials
  bleiben im Store der jeweiligen CLI.

**Abhängigkeiten:** F-039 (Template-Gegenstücke entstehen im selben Commit). F-024 und
F-025 bauen auf der Host-Erkennung auf.

**Noch zu analysieren:**
- Welche Hosts in der ersten Ausbaustufe voll unterstützt werden (Vorschlag: GitHub,
  Forgejo/Gitea, GitLab, „nur Git"), welche nur als „nur Git" laufen.
- Liefert das Template mehrere CI-Varianten, oder wählt `new-project` je Host eine?
- Lässt sich die Arbeit sinnvoll in Substeps schneiden (Profil + Erkennung → Skills je
  Fähigkeit → Installer/Template)?

### F-033 — Betrieb ohne Graphiti absichern

**Status:** BACKLOG

**Problem:** Graphiti ist in den Skills bereits weitgehend optional („ohne MCP still
überspringen"), aber nie systematisch geprüft. Zudem geht Wissen, das sonst in den Graph
gegangen wäre (Entscheidungen, gelöste Probleme, Lernprofil), ohne Graphiti ersatzlos
verloren.

**Idee:** Ein Audit stellt sicher, dass jeder Skill, der Installer und die Vorlagen ohne
Graphiti vollständig laufen. Optional bekommt das Kit einen Ersatzweg für das Wissen,
das sonst im Graph landet.

**Lösungsskizze:**
- Alle Graphiti-Stellen (Skills, globale Kit-Regeln, Template-Block, README) auf harte
  Kopplung prüfen — auch impliziten Text wie „erst den Graph fragen".
- Ersatz nur für Wissen ohne eigenen Ort: Entscheidungen, Nicht-Ziele und offene Fragen
  tragen nach F-036 Feature-Dateien und ADRs. Übrig bleiben u. a. Infra-Fakten (das
  Lernprofil von `teach-step` entfällt mit F-040) — dafür
  Claude-Code-Auto-Memory, eine Datei unter `private/` oder bewusst kein Ersatz, dann
  dokumentiert.
- Der Graphiti-Block der CLAUDE.md-Vorlage im Template (`template/core/CLAUDE.md`) ist
  mitbetroffen — im selben Commit.

**Abhängigkeiten:** F-036 (übernimmt den Großteil des Ersatzwegs). Thematische Nähe zu
F-029/F-030 (Graphiti) und F-032 (gleicher Grundsatz: optionale Infrastruktur wird
ausgewiesen übersprungen).

---

### F-034 — Senior-Maßstab in den Bau-Skills (Lesbarkeit, keine Workarounds, Secure Coding)

**Status:** BACKLOG

**Problem:** Der inhaltliche Maßstab steht in der `CODING-STANDARDS.md` des Templates,
die Bau-Skills wenden ihn aber nicht aktiv an: `build-step` liest die Datei nur
(„falls vorhanden"). Qualität wird erst nachträglich in `step-done` geprüft, ohne
CODING-STANDARDS gibt es gar keine Messlatte, und im autonomen `/goal`-Lauf fehlt eine
Regel für den Fall, dass die saubere Lösung nicht im Plan liegt.

**Idee:** Die Bau-Skills arbeiten durchgängig wie ein Senior-Entwickler. Sie wählen die
einfachste tragfähige Lösung, schreiben Code, den der Nächste beim Ändern versteht
(keine verschachtelten Schleifen oder cleveren Ketten) und den ein Senior-Entwickler im
Diff prüfen kann — immer menschenlesbar, nie minifiziert —, bauen keine Workarounds und
sichern jeden Substep auch auf Secure Coding ab. Die Skills regeln den Prozess, den
Inhalt regelt die `CODING-STANDARDS.md`.

**Lösungsskizze:**
- `build-step`: aktive Qualitäts-Leitplanke. Selbst-Review je Substep, bevor er als
  fertig gemeldet wird: verständlich, einfach, sicher. Workaround-Stopp: Ist die saubere
  Lösung im Plan nicht machbar, anhalten und melden statt Hack (autonom: Lauf stoppen).
- **Menschenlesbarer Code:** Was die Skills schreiben, ist lesbarer Quelltext — nie
  minifiziert, komprimiert oder auf eine Zeile gepresst, auch nicht JSON, CSS oder
  Konfiguration —, damit ein Senior-Entwickler jede Änderung prüfen kann. Minifiziertes
  entsteht nur als Build-Ausgabe des Build-Werkzeugs und wird nie von Hand geschrieben
  oder bearbeitet. `build-step` prüft das im Selbst-Review, `step-done` im Review.
- Knapper Ersatz-Maßstab für Projekte ohne `CODING-STANDARDS.md` (Kernprinzipien,
  kein Duplikat der Vorlage).
- `teach-step`, `prep-step` (einfachstes Design planen; Security-Punkte je Substep
  deckt mit F-036 der Sicherheits-Blick der Spezifikation ab) und `step-done`
  (Review-Kriterien Verständlichkeit und Secure Coding) konsistent nachziehen.
- Inhaltliche Lücken der Vorlage (Lesbarkeit vor Cleverness, Secure Coding über Secrets
  hinaus) sind mit TPL-021 (project-template 0.14.0) bereits im Template;
  Bestandsprojekte erhalten sie über `/update-conventions`. Neu dazu: eine Regel in der
  `CODING-STANDARDS.md` der Vorlage (bei „Readable over clever", § 6): Quelltext ist
  menschenlesbar und nie minifiziert, Minifiziertes nur als Build-Ausgabe. Das ist
  Template-Inhalt und braucht deshalb einen CHANGELOG-Abschnitt `### Template`.

**Abhängigkeiten:** F-036 — schreibt prep-step und step-done grundlegend um, deshalb
erst danach (sonst doppelte Arbeit); zusammen mit F-037 umsetzen. Gegenstück:
TPL-021 (Inhalte der CODING-STANDARDS-Vorlage, erledigt) — die Skill-Kriterien darauf
abstimmen.

---

### F-037 — Unabhängiges Review in step-done (Reviewer mit frischem Kontext)

**Status:** BACKLOG

**Problem:** Das Review in `step-done` macht derselbe Kontext, der den Code geschrieben
hat. Er kennt jede Begründung und neigt dazu, seine eigenen Entscheidungen zu
bestätigen. Im autonomen `/goal`-Lauf prüft zwischen den Substeps zudem kein Mensch.

**Idee:** Nach grünen Checks prüft ein separater Agent ohne Schreibrechte den Diff mit
frischem Kontext. Er bekommt bewusst nur F-Nummer, Diff, Feature-Spec und
CODING-STANDARDS, keine Zusammenfassung vom Bauen. Er prüft gegen die Spezifikation:
Abnahmekriterien erfüllt, Edge-Cases behandelt, nichts aus „Out of Scope" berührt;
dazu Security und Lesbarkeit.

**Lösungsskizze:**
- Eigene Agent-Definition im Plugin mit gesperrten Schreib-Tools (analog teach-step);
  ob Plugins Agents mitliefern können, zur Umsetzungszeit gegen die aktuelle Doku
  prüfen. Der eingebaute `/code-review` reicht nicht, weil er die Spec nicht kennt.
- Neuer Schritt in `step-done` nach den grünen Checks, vor Secrets-Scan und Commit;
  Haupt-Agent bewertet jeden Befund (beheben oder mit Begründung verwerfen), der
  Nutzer sieht die Liste.
- Nach Größe staffeln: Klein ein oder kein Reviewer, Mittel/Groß zwei parallel
  (Korrektheit gegen Spec; Security + Lesbarkeit). Token-Kosten im Blick behalten.

**Noch zu analysieren:**
- Ob der Reviewer als Skill mit `context: fork` läuft (Subagent mit frischem Kontext,
  dazu `agent` und `background`; Frontmatter-Übersicht aus F-048) statt als eigene
  Agent-Definition.

**Abhängigkeiten:** F-036 (Feature-Spec als Prüfgrundlage; ohne sie nur Prüfung gegen
den PROGRESS-Eintrag). Zusammen mit F-034 umsetzen — dessen Review-Kriterien
(verständlich, einfach, Secure Coding) sind der Prüfmaßstab des Reviewers.
Template-Seite: HOW-TO-Abschnitt „What `/step-done` does in detail" um den Review-Schritt
ergänzen — im selben Commit.

---

### F-046 — Verbrauchsanalyse des Kits und Empfehlungen zu Modell und Effort

**Status:** BACKLOG

**Problem:** Niemand weiß, was die Kit-Skills im Betrieb verbrauchen und ob der Workflow
(add-feature → prep-step → build-step → step-done, dazu update-conventions) gegenüber einer
direkten Umsetzung ohne Kit nennenswert mehr Aufwand kostet. Nutzer haben keine
Empfehlung, welches Modell und welcher Effort für welchen Lauf reichen. Die Testläufe aus
F-043c lagen mit Opus 5.5 auf `xhigh` bei 0,79 bis 2,98 USD je Lauf, eine Migration von
0.13.2 bei rund 3,70 USD.

**Idee:** Wenn alle geplanten Features gebaut sind, eine komplette Analyse: jeder Skill
über verschiedene Projekte und Lauftypen gemessen (Kosten, Tokens, Werkzeugaufrufe,
Vollständigkeit der Schritte), dazu derselbe Auftrag einmal direkt umgesetzt, ohne
Kit-Workflow. Daraus Empfehlungen zu Modell und Effort je Skill und Lauftyp mit
Kostenschätzung — und erst dann der Abschnitt dazu in der README.

**Lösungsskizze:**
- Messaufbau wie in F-043c: `claude -p --output-format stream-json` an Wegwerf-Kopien;
  Kosten aus `total_cost_usd`, Tokens getrennt nach Cache-Schreiben, Cache-Lesen und
  Ausgabe, Werkzeugaufrufe, Abgleich, ob alle Pflichtschritte des Skills liefen.
- Matrix aus Skills, Projekttypen (docs-only, ts-node, python, go …) und Einstellungen
  (mindestens Opus und Sonnet, je auf `medium` und `high`); mehrere Läufe je Zelle, weil
  ein einzelner Lauf streut.
- `update-conventions` zusätzlich gesondert: Er läuft in jedem Projekt bei jedem Release
  und ist der teuerste Pflege-Lauf. Je Projekttyp messen: `status`, Routine-Update,
  Update mit Konflikten oder geschützten Fragmenten, Migration eines alten Stempels ohne
  Snapshot, Modulwechsel über `choose-stack`.
- Vergleich mit direkter Umsetzung: eine typische Aufgabe einmal über den Kit-Workflow,
  einmal als direkter Auftrag; Kosten und Ergebnis (Tests, Review-Funde, Doku, Commits)
  nebeneinander.
- Ergebnis: Abschnitt in der README (unter „Tägliche Nutzung") mit Empfehlung je Lauftyp
  und Kostenspanne, Messwerten mit Datum, Modell und Effort sowie der Messmethode zum
  Nachmessen; das Rezept für Testläufe in `docs/skill-authoring.md`.
- Wo die Messung Einsparungen zeigt, Folgeaufgaben über `/coding-kit:add-feature`
  vorschlagen (z. B. mehr ins Skript, kürzere Skill-Texte, Effort im Frontmatter).

**Ausgangsdaten** (F-043c, 2026-10-25, je ein Update desselben docs-only-Projekts):
- Opus 5.5 auf `xhigh`: 1,67 USD, 29 Werkzeugaufrufe, alle Schritte.
- Opus 5.5 auf `medium`: 1,19 USD, 18 Werkzeugaufrufe, alle Schritte.
- Sonnet 5.5 auf `medium`: 0,31 USD, 7 Werkzeugaufrufe — ohne Zonen-Abgleich,
  Lock-Prüfung und Prüfung entfernter Ziele; der Endstand stimmte nur, weil sich dort
  nichts geändert hatte.
- Cache-Lesen kostet bei Opus 5.5 und Sonnet 5.5 gleich viel; gespart wird vor allem
  über weniger Werkzeugaufrufe, nicht über das Modell allein.

**Noch zu analysieren:**
- Messbudget und wie viele Läufe je Zelle für eine belastbare Aussage reichen.
- Wie die direkte Umsetzung fair verglichen wird (gleiche Aufgabe, gleiche Abnahme).
- Ob Kostenzahlen in der README stehen dürfen, obwohl das Repo statische Versionsstände
  in Texten meidet — mit Datum und Messmethode oder nur als Größenordnung.
- Ob Skills `effort:` oder `model:` im Frontmatter setzen sollen: Das überschreibt die
  Wahl jedes Nutzers, und wie lange die Effort-Vorgabe gilt, lässt die Doku offen.

**Abhängigkeiten:** alle übrigen Einträge der Empfohlenen Reihenfolge — gemessen wird der
Endstand; besonders F-036 und F-045 verändern den Verbrauch.

---

<!-- FEATURE-INDEX
next-feature: F-050
F-001 Kit-Grundgerüst (DONE)
F-002 Begleit-Skills (DONE)
F-003 /new-project-Orchestrator (DONE)
F-004 Globale CLAUDE.md-Vorlage (DONE)
F-005 Pflege-Skills (DONE)
F-006 Utility-Skill refine-prompt (DONE)
F-007 Workflow-Skill teach-step (DONE)
F-008 Workflow-Skill build-step + autonome Läufe (DONE)
F-009 Repo-lokaler Pflege-Skill add-skill (DONE)
F-010 Status-Marker + Grenze add-feature/prep-step (DONE)
F-011 build-step vom step-done-Handoff entkoppeln (DONE)
F-012 add-skill: Template-HOW-TO synchron halten (DONE)
F-013 choose-stack: Multi-Fragment-Einbau (DONE)
F-014 update-conventions: Pro-Fragment-Refresh (DONE)
F-015 prep-step: Framework-Erkennung mit Fragment-Vorschlag (DONE)
F-016 step-done: Standards-Coverage-Backstop (DONE)
F-017 Eigenschafts-Trigger für Standards-Fragmente auswerten (DONE)
F-018 Konventions-Vererbung nur noch abwärts (DONE)
F-019 Pflege-Skill go-public (Projekt nachträglich public-ready) (DONE)
F-020 Sprach-Matrix: granulare Sprachwahl je Projekt (DONE)
F-021 update-conventions: Vollabdeckung aller Template-Dokumente (inkl. seed) (DONE)
F-022 Begleithandlungen beim Fragment-Einbau (DONE)
F-023 new-project ohne GitHub (lokaler Bootstrap-Pfad) (→ aufgegangen in F-032)
F-024 Commit-Adresse aus der Personal-Config statt hart aus gh
F-025 install.sh: fehlender gh-Login und Plattform-Abdeckung
F-026 Template-Auflösung: Aktualität, Herkunft und Klontiefe (→ aufgegangen in F-039/F-032)
F-027 Stop-Hook plattformfähig machen (Windows greift ins WSL)
F-028 Utility-Skill handoff (DONE)
F-029 Graphiti-Schreibzugriffe auf Server-LLM-Kosten optimieren
F-030 Graphiti-Episodenverlust erkennen und wiederherstellbar halten
F-031 mise.lock mit Plattform-Einträgen erzeugen (CI im --locked-Modus) (DONE)
F-032 Host-unabhängiger Betrieb (ohne GitHub, andere Git-Server, nur Git)
F-033 Betrieb ohne Graphiti absichern
F-034 Senior-Maßstab in den Bau-Skills (Lesbarkeit, keine Workarounds, Secure Coding)
F-035 Repo-übergreifende Übergabe statt Parallelarbeit (coding-kit ↔ project-template) (→ aufgegangen in F-039)
F-036 Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt (PLANNED)
F-037 Unabhängiges Review in step-done (Reviewer mit frischem Kontext)
F-038 Freigabe-Regel für PROGRESS-Einträge kit-weit; add-feature von Claude aufrufbar (DONE)
F-039 Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0 (DONE)
F-040 Globale Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau (DONE)
F-041 Projektzusätze in managed Dateien erhalten, Abweichungen früh erkennen (DONE)
F-042 Neue Sprachen und Frameworks erkennen, Vorlagen nachziehen (DONE)
F-043 Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen (DONE)
F-044 Sprachen ohne Vorlage erkennen und dem Template vorschlagen (DONE)
F-045 Zonen-Abgleich und Lock-Prüfung ins Skript (DONE)
F-046 Verbrauchsanalyse des Kits und Empfehlungen zu Modell und Effort
F-047 Skript-Tests zusätzlich mit mawk (DONE)
F-048 Frontmatter-Pflichtfelder für Skills und Übersicht der erlaubten Felder (DONE)
F-049 Neue Zonen erkennen und anbieten (DONE)
-->
