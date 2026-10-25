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

---

## Offene Aufgaben — von oben nach unten abarbeiten

### F-042 — Neue Sprachen und Frameworks erkennen und Vorlagen nachziehen

**Status:** PLANNED

**Problem:** Die Erkennung aus F-015, F-016 und F-017 deckt nur Standards-Fragmente ab
und greift nur, wenn eine Aufgabe ein Framework neu einführt. Eine neue Sprache, für die
das Template ein Stack-Modul hat, fällt durch: Ein docs-only-Projekt hat Python so von
Hand in `mise.toml` und justfile eingebaut, ohne Modul. Bekommt das Template später ein
Fragment oder ein Modul für etwas, das ein Projekt längst nutzt, zieht es außerdem niemand
nach — `update-conventions` hängt nur Fragmente an, die das `MODULE.md` deklariert.

**Idee:** Ein deterministischer Abgleich der Projektsignale (Paket-Manifeste,
Signal-Dateien, Tools in `mise.toml`) mit den Auslösern des Fragment-Katalogs und mit neuen
Modul-Signalen. Er läuft bei neuer Nutzung (prep-step, step-done) und beim Nachzug
(`update-conventions`) und schlägt `/choose-stack` oder das Anhängen von Fragmenten vor —
immer erst nach Bestätigung.

**Entschieden (2026-10-25):**
- Signale tragen einen Typ: `npm:`, `pypi:` und `go:` für Dependencies, `file:` für
  Dateimuster, `tool:` für Einträge in `[tools]` der `mise.toml`. Die Auslöser-Spalte des
  Katalogs mischt heute Paket- und Dateinamen, `nginx` ist mehrdeutig — ohne Typ gibt es
  keinen deterministischen Abgleich.
- Modul-Signale stehen als `Signals:`-Zeile im jeweiligen `MODULE.md`, nicht in
  `modules/README.md`: Das Skript liest das `MODULE.md` ohnehin, das Modul bleibt in sich
  vollständig. Stubs haben keine Zeile und werden nie vorgeschlagen; ein ausgebautes Modul
  bringt seine Zeile mit, und `update-conventions` schlägt es Projekten vor, die die
  Sprache schon nutzen.
- Ein Fragment gilt als vorhanden, wenn sein `fragment:NAME`-Marker im Slot steht — nicht
  nach `FRAGMENTS` der Antworten. Der Slot ist der tatsächliche Stand, und die Erkennung
  läuft so auch in Projekten ohne Antworten-Datei. `MODULE` kommt aus den Antworten; ohne
  sie entfällt nur die Modul-Prüfung.
- Drei Aufrufarten: der ganze Baum (`update-conventions`), nur gegenüber HEAD neue Signale
  (`--changed`, `step-done` — alte Lücken kehren dort nicht wieder) und nur übergebene
  Signale (`prep-step`, für geplante Dependencies).
- Dauerhafte Ablehnung als Zeile `module:NAME` bzw. `fragment:NAME` in der Rules-Tabelle
  der `.claude/convention-overrides.md`, mit Grund und Datum: Die Tabelle gibt es in jedem
  Projekt, und eine Ablehnung betrifft keine einzelne Datei. „Diesmal nicht" wird nicht
  gespeichert — der nächste `update-conventions`-Lauf bietet wieder an.
- Zweitsprachen: Der Modul-Kontrakt bleibt bei einem Modul je Projekt. Eine Sprache ohne
  ihr Modul gilt als Werkzeugsprache — einmal gemeldet, dann Modul nachrüsten
  (`/choose-stack`) oder mit Grund ablehnen; ihre Toolchain bleibt handgebaut und als
  `keep` registriert. Das Sprachfragment des Moduls taugt nicht als Zweitfragment, weil es
  an die Toolchain gebunden ist; die Aufteilung ist F-043.
- Keine Dateiendungen als Signal (ein einzelnes Skript löst sie aus); keine Leser für
  Cargo, Gemfile oder Maven, solange kein Template-Inhalt sie braucht.
- In `update-conventions` läuft die Erkennung vor dem Rendern: Ein angenommenes Fragment
  steht dann schon in `FRAGMENTS`, und der Fragment-Abgleich hängt es an.

**Lösungsskizze** (Stand Planung 2026-10-25):
- MANIFEST § Detection: Signal-Typen; Quellen (`package.json`: dependencies,
  devDependencies, peerDependencies, optionalDependencies; `pyproject.toml`:
  `[project]`-Dependencies, optional-dependencies, `[dependency-groups]`, Poetry;
  `requirements*.txt`; `require` in `go.mod` ohne `// indirect`; `[tools]` der
  `mise.toml`; Dateimuster auf den Dateinamen); Suchbereich `git ls-files` (getrackt plus
  ungetrackt und nicht ignoriert, ohne `.claude/template-base/`); Bewertung; Ablehnung.
  § Deviation registry: Rules-Zeilen `module:NAME`/`fragment:NAME` sind maschinenlesbar.
- `template-sync.sh detect [--changed] TEMPLATE PROJECT [SIGNAL…]`: eine Zeile je Treffer mit Art
  (Modul oder Fragment), Name, Zustand (`covered`, `missing`, `declined`) und den
  auslösenden Signalen samt Fundort. Aus Projektdateien wird nichts ausgeführt.
- `prep-step` § 2a auch für neue Sprachen und Toolchains, mit `detect` über die geplanten
  Signale; `step-done` § 1a über `detect --changed`; `update-conventions` mit eigenem
  Schritt vor dem Rendern, im Modus `status` als Bericht; `choose-stack` Modus B nutzt die
  Signale für die Empfehlung. Eigenschafts-Auslöser bleiben Planungsmaterie (`prep-step`,
  `define-requirements`).
- Keine neuen Dependencies (POSIX sh, awk, git).

**Abhängigkeiten:** F-041 (erledigt). Vor F-043.

#### F-042c — Skills und Doku

**Was:** `prep-step` § 2a: auch neue Sprachen und Toolchains, `detect` mit den geplanten
Signalen, Modul-Treffer → Verweis auf `/choose-stack`. `step-done` § 1a über
`detect --changed`, nicht blockierend, Ablehnung als Rules-Zeile anbieten.
`update-conventions`: Erkennungs-Schritt vor dem Rendern (Fragment anhängen samt
`FRAGMENTS` und Begleithandlung; fehlendes Modul → `/choose-stack` nach dem Lauf;
dauerhaft ablehnen → Rules-Zeile; diesmal nicht), Modus `status` als Bericht, die
Revision listet die Ablehnungen („noch gültig?"). `choose-stack` Modus B: Signale für die
Empfehlung. Template-HOW-TO, Skill-Tabelle im README und Skill-Beschreibungen;
`/add-skill` läuft mit.

**Dateien:**
`plugins/coding-kit/skills/{prep-step,step-done,update-conventions,choose-stack}/SKILL.md`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`, `README.md`,
`plugins/coding-kit/CHANGELOG.md`.

**Abhängigkeiten:** F-042b.

**Abnahmekriterien:**
- [ ] Nicht-interaktiver Lauf von `update-conventions status` mit `--plugin-dir` an einer
      Scratch-Kopie des docs-only-Projekts: Der Bericht zeigt den Modul-Treffer `python`,
      ins Projekt wird nichts geschrieben.
- [ ] Die Skills rufen `detect` nur mit den im Skript-Kopf beschriebenen Argumenten auf.
- [ ] `just check` grün.

#### F-042d — Test, Release, Gegenprobe

**Was:** Nicht-interaktive Läufe mit `claude -p --plugin-dir plugins/coding-kit` an
Scratch-Kopien des docs-only- und eines ts-node-Projekts: `update-conventions` mit
Erkennung (ablehnen, anhängen, diesmal nicht), danach `status` ohne Vorschlag für
Abgelehntes. Release 1.2.0: CHANGELOG datieren; Push nur auf ausdrückliche Bitte, vorher
Personendaten-grep über Diff, Commit-Metadaten und Messages; Plugin aktualisieren und den
Cache prüfen. Gegenprobe: `/update-conventions` am echten docs-only-Projekt — über den
Python-Treffer entscheidet der Nutzer.

**Abhängigkeiten:** F-042c.

**Abnahmekriterien:**
- [ ] Beide Kopien: Treffer wie erwartet, Ablehnung als Rules-Zeile, der folgende
      `status`-Lauf ohne Vorschlag für Abgelehntes, `just check` grün (die ts-node-Kopie
      braucht dafür laufendes Docker, sonst ist ihre `stack-check` unabhängig vom Kit rot).
- [ ] Release 1.2.0 gepusht, CI grün, Plugin aktualisiert.
- [ ] Gegenprobe am echten docs-only-Projekt: Python-Treffer gemeldet, die Entscheidung des
      Nutzers umgesetzt.

---

## Feature-Ideen (Backlog)

_Neue Ideen via `/coding-kit:add-feature` — sie bekommen die nächste F-Nummer._

**Empfohlene Reihenfolge** (Stand 2026-10-25; die Einträge darunter bleiben nach Nummer
sortiert):

1. **F-042 → F-043** — direkt nach F-041, weil es dieselbe Mechanik nutzt (Antworten-Datei,
   `choose-stack`, `template-sync.sh`); F-043 ist danach reiner Template-Inhalt, den
   `detect` von selbst vorschlägt.
2. **F-036** — großer Umbau; alle folgenden Features werden schon mit Spec-Phase und
   Feature-Datei geplant.
3. **F-034 + F-037** — Qualitätsstrang auf dem neuen prep-step/step-done.
4. **F-040** — vor den Strängen Graphiti und Host, deren Änderungen an der globalen
   Vorlage sonst bestehende Rechner nicht erreichen.
5. **F-029 → F-033 → F-030** — Graphiti-Strang (F-030 ohne den `install.sh`-Teil).
6. **F-032 → F-024 → F-025** — Host-Strang; F-025 nimmt den `install.sh`-Teil von F-030
   mit. F-026 ist in F-039 aufgegangen, sein Rest (Kit-Repo-Herkunft in `check-upstreams`)
   in F-032.
7. **F-027** — sobald ein Windows-Rechner zur Verifikation verfügbar ist, gern mit F-025.

Strang 5 und 6 sind tauschbar: Graphiti-Kosten zuerst oder Betrieb auf anderen Rechnern
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
- Gleiche Härte in `templates/global-CLAUDE.md` entschärfen: GitHub-Noreply als Default
  für GitHub-Projekte, Kernaussage bleibt „keine private Adresse".
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
- Globale CLAUDE.md-Vorlage anpassen: Löschanweisung streichen, Splitting-Regel
  überdenken, auf die zentrale Konvention verweisen.
- Betroffen: alle Skills mit Graphiti-Schreibzugriff, `docs/skill-authoring.md`,
  Vorlage der globalen CLAUDE.md.

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
- In der globalen CLAUDE.md-Vorlage bzw. README kurz begründen, warum der Wert gesetzt
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
- Alle Graphiti-Stellen (Skills, globale Vorlage, Template-Block, README) auf harte
  Kopplung prüfen — auch impliziten Text wie „erst den Graph fragen".
- Ersatz nur für Wissen ohne eigenen Ort: Entscheidungen, Nicht-Ziele und offene Fragen
  tragen nach F-036 Feature-Dateien und ADRs. Übrig bleiben u. a. das Lernprofil von
  `teach-step` (lebt heute nur im Graph) und Infra-Fakten — dafür
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
(keine verschachtelten Schleifen oder cleveren Ketten), bauen keine Workarounds und
sichern jeden Substep auch auf Secure Coding ab. Die Skills regeln den Prozess, den
Inhalt regelt die `CODING-STANDARDS.md`.

**Lösungsskizze:**
- `build-step`: aktive Qualitäts-Leitplanke. Selbst-Review je Substep, bevor er als
  fertig gemeldet wird: verständlich, einfach, sicher. Workaround-Stopp: Ist die saubere
  Lösung im Plan nicht machbar, anhalten und melden statt Hack (autonom: Lauf stoppen).
- Knapper Ersatz-Maßstab für Projekte ohne `CODING-STANDARDS.md` (Kernprinzipien,
  kein Duplikat der Vorlage).
- `teach-step`, `prep-step` (einfachstes Design planen, Security-Punkte je Substep
  benennen) und `step-done` (Review-Kriterien Verständlichkeit und Secure Coding)
  konsistent nachziehen.
- Inhaltliche Lücken der Vorlage (Lesbarkeit vor Cleverness, Secure Coding über Secrets
  hinaus) sind mit TPL-021 (project-template 0.14.0) bereits im Template;
  Bestandsprojekte erhalten sie über `/update-conventions`.

**Abhängigkeiten:** F-036 — schreibt prep-step und step-done grundlegend um, deshalb
erst danach (sonst doppelte Arbeit); zusammen mit F-037 umsetzen. Gegenstück:
TPL-021 (Inhalte der CODING-STANDARDS-Vorlage, erledigt) — die Skill-Kriterien darauf
abstimmen.

---

### F-036 — Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt

**Status:** BACKLOG

**Problem:** Anforderungen leben doppelt und laufen auseinander. `define-requirements`
schreibt die Kern-Features in die `REQUIREMENTS.md` und zugleich als F-Nummern in die
`PROGRESS.md`; die Auflösung der REQUIREMENTS.md (alles überführt, keine offene
Produktfrage, Nutzer bestätigt) wird praktisch nie erreicht, die Überführung in
CLAUDE.md, ADRs und PROGRESS bleibt Handarbeit. Zugleich fehlt je Feature eine
gründliche Spezifikation: Edge-Cases, prüfbare Abnahmekriterien, Testfälle,
Nicht-Ziele und offene Fragen werden nirgends verlangt, und die PROGRESS.md wächst
mit jedem Eintrag weiter.

**Idee:** Jede Information wird sofort an ihren endgültigen Ort geschrieben, ein
Übergangs-Dokument entfällt. Projektweites (Ziele, Nicht-Ziele, Constraints) landet in
der Projekt-CLAUDE.md, Grundsatzentscheidungen als ADR, jedes Feature in einer eigenen
Datei `features/F-NNN-….md`, die über seinen ganzen Lebenszyklus wächst: Erfassung,
Spezifikation, Plan, Abweichungen beim Bau, Abnahme. Die `PROGRESS.md` wird zur reinen
Übersicht. Vorbild: der Spec-Workflow aus AlexPEClub/ai-coding-starter-kit (Interview
eine Frage je Runde mit Empfehlung, Abnahmekriterien im Given/When/Then-Muster,
Out of Scope mit Verweisen, Entscheidungsprotokoll, offene Fragen als Checkboxen).

**Lösungsskizze:**
- `REQUIREMENTS.md` entfällt. `define-requirements` legt nur die Feature-Landkarte an
  (je Feature eine schlanke Datei mit Status BACKLOG + Übersichtszeile) und schreibt
  Projektweites direkt in CLAUDE.md bzw. ADRs; die Detail-Spec entsteht erst kurz vor
  dem Bau.
- `add-feature` legt die Feature-Datei an (Problem, Idee, Skizze), `prep-step` baut sie
  in zwei Phasen aus: Spezifikation per Interview (Edge-Cases, Abnahmekriterien,
  Testfälle, Nicht-Ziele, offene Fragen, Entscheidungen), dann Technik-Plan; Tiefe
  skaliert mit Klein/Mittel/Groß. `build-step` ergänzt Abweichungen, `step-done` hängt
  die Abnahme an und schließt ab — die Feature-Datei ersetzt den Archiv-Eintrag.
- Die Vorlage der Feature-Datei liegt im Template (`template/core/`; entschieden
  2026-10-23: Inhalt im Template, Prozess in den Skills), kommt per
  `update-conventions` in die Projekte und wird von den Skills zur Laufzeit gelesen —
  kein Duplikat.
- Übersicht bleibt knapp: Erledigtes ist dort nur ein Haken (F-Nummer, Titel, Datum),
  höchstens mit kurzem Kommentar, wenn ihn jemand beim Überfliegen braucht (offene
  Lücke, Folge-F-Nummer, Release-Version) — keine Zusammenfassungen; die stehen in der
  Feature-Datei. Anlass: Done-Tabellen in Projekten wachsen heute je Aufgabe um einen
  Absatz. Die Migration bietet an, bestehende lange Done-Zeilen zu kürzen.
- `refine-requirements` arbeitet auf CLAUDE.md, Feature-Dateien und ADRs; der
  Auflöse-Mechanismus fällt weg. Nicht-Ziele der Spec speisen den Scope-Schutz in
  `build-step`.
- Übrige Skills mit PROGRESS-/REQUIREMENTS-Bezug nachziehen (u. a. new-project,
  handoff, teach-step, audit-code); Konsistenzprüfung Übersicht ↔ Feature-Dateien als
  Check-Kandidat für `just check`.
- Bestandsprojekte: `update-conventions` bietet eine einmalige Migration an
  (REQUIREMENTS.md und offene PROGRESS-Einträge auf die Zielorte verteilen, Diff und
  Bestätigung je Datei); bestehende `PROGRESS-ARCHIVE.md` bleibt eingefroren.
- Die eigene PROGRESS des Kits erst in der Release-Phase umstellen — nach Push und
  Plugin-Update, mit der neuen Migration (zugleich erster Praxistest). Vorher arbeiten
  alle Sessions mit dem installierten alten Plugin, das die neue Struktur nicht kennt
  (entschieden 2026-10-23).

**Noch zu analysieren:**
- Name und Ort der Übersicht (`PROGRESS.md` behalten spart Migration) und ob der
  FEATURE-INDEX-Kommentar in der Übersichtstabelle aufgeht.
- Projektweite Inhalte in CLAUDE.md oder eigener Produktdatei — Schwelle, ab der
  ausgelagert wird.
- Status an einer Stelle oder an zweien (Datei-Kopf + Übersicht).

**Abhängigkeiten:** F-039 — das Template-Gegenstück (Vorlage der Feature-Datei,
Vorlagen PROGRESS/REQUIREMENTS/CLAUDE/HOW-TO/README, ADR-README, MANIFEST inkl.
Seed-Sections) entsteht im selben Commit wie die Skills. Berührt dieselben Skills wie
F-034 (prep-step, step-done) — F-034 folgt danach. Entlastet F-029 und F-033.

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

**Abhängigkeiten:** F-036 (Feature-Spec als Prüfgrundlage; ohne sie nur Prüfung gegen
den PROGRESS-Eintrag). Zusammen mit F-034 umsetzen — dessen Review-Kriterien
(verständlich, einfach, Secure Coding) sind der Prüfmaßstab des Reviewers.
Template-Seite: HOW-TO-Abschnitt „What `/step-done` does in detail" um den Review-Schritt
ergänzen — im selben Commit.

---

### F-040 — Globale CLAUDE.md mit dem Plugin ausliefern und abgleichen

**Status:** BACKLOG

**Problem:** Die Vorlage `templates/global-CLAUDE.md` erreicht einen Rechner nur einmal:
`install.sh` kopiert sie, wenn noch keine `~/.claude/CLAUDE.md` existiert, und meldet sonst
nur „wird nicht überschrieben". Danach driften Vorlage und installierte Fassung unbemerkt
auseinander — beobachtet in beide Richtungen: der Languages-Block-Absatz aus F-020 fehlt in
der installierten Fassung, eine dort ergänzte generische Regel (Artifacts nur mit
ausdrücklicher Erlaubnis veröffentlichen) fehlt in der Vorlage. F-024, F-029 und F-030
planen weitere Änderungen an der Vorlage, die bestehende Rechner ohne Abgleich nie
erreichen.

**Idee:** Die Vorlage wird mit dem Plugin ausgeliefert und kommt so mit jedem Update auf
den Rechner. Ein Abgleich zeigt die Unterschiede zur installierten Fassung abschnittsweise
und übernimmt nur Bestätigtes; persönliche Ergänzungen bleiben unangetastet. Generische
Regeln, die nur in der installierten Fassung stehen, werden als Übernahme-Vorschlag fürs
Kit gemeldet — die Vererbung bleibt abwärts wie bei den Konventionen (F-018).

**Lösungsskizze:**
- Vorlage in den Plugin-Ordner, aber nicht nach `template/`: dort liegt nur MANIFEST-Inhalt
  für Projekte, die globale Datei geht auf den Rechner und ist deutsch.
- Kit-eigene Abschnitte markieren, ähnlich den `section:NAME`-Zonen der seed-Dateien;
  alles Unmarkierte gilt als persönlich und wird nie angefasst.
- Abgleich mit Diff und Bestätigung je Abschnitt; `install.sh` richtet aus derselben
  Quelle ein.
- Bestehende Abweichung als erster Lauf auflösen (Languages-Absatz, Artifact-Regel).
- Pfad-Folgen: README lädt die Vorlage im manuellen Weg per `curl` über
  `…/main/templates/global-CLAUDE.md`, `install.sh` liest sie aus dem Checkout, der Kopf
  der Vorlage nennt ihren Pfad.
- Plugin-Änderung: Versions-Bump und CHANGELOG.

**Noch zu analysieren:**
- Welcher Skill den Abgleich trägt (`update-conventions`, ein eigener kleiner Skill oder
  ein Hinweis des Stop-Hooks bei Abweichung).
- Wie installierte Fassungen ohne Marker erkannt werden (einmalige Marker-Migration wie
  bei den seed-Dateien).
- Ob die alte `curl`-URL weiter funktionieren soll.

**Abhängigkeiten:** F-039 (Plugin-Struktur und Versionsregel stehen dann). Sinnvoll vor
F-024, F-029 und F-030 — deren Änderungen an der Vorlage erreichen bestehende Rechner erst
über den Abgleich.

### F-043 — Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen

**Status:** BACKLOG

**Problem:** Das Sprachfragment eines Stack-Moduls mischt Regeln, die für jeden Code der
Sprache gelten (Type Hints, sichere Aufrufe, Namensregeln, Lizenzen), mit Regeln, die nur
mit der Toolchain des Moduls stimmen (bei python: uv, src-Layout, pyright, ruff, pytest).
Ein Projekt, das eine Sprache ohne ihr Modul als Werkzeugsprache nutzt — etwa ein
docs-only-Projekt mit Python-Skripten aus der Standardbibliothek und `unittest` —,
bekommt deshalb gar keine Sprachregeln: Das ganze Fragment wäre dort zur Hälfte falsch.

**Idee:** Je Sprache ein Katalog-Fragment mit den toolchain-unabhängigen Regeln (z. B.
`python-lang`) und Signalen wie `tool:python` und `file:pyproject.toml`. Das Modul
deklariert es unter `Standards fragments:`, sein eigenes Fragment behält nur die
Toolchain-Regeln. `detect` aus F-042 schlägt das Sprachfragment dann in Projekten ohne
Modul von selbst vor — ohne Code-Änderung.

**Lösungsskizze:**
- python, ts-node und go: die Regeln je Sprachfragment sortieren, den Sprachteil als
  Katalog-Fragment mit Signalen anlegen, im `MODULE.md` deklarieren.
- Bestandsprojekte mit Modul: `update-conventions` erneuert das Modul-Fragment und hängt
  das Sprachfragment an; Reihenfolge im Slot prüfen.
- Reiner Template-Inhalt plus Beispiele im MANIFEST; keine neuen Dependencies.

**Noch zu analysieren:**
- Namensschema der Sprachfragmente; ob ein Modul-Fragment ohne Sprachteil noch für sich
  lesbar ist.
- Wie `update-conventions` ein geschrumpftes Fragment behandelt, das im Projekt ein
  Inline-Override trägt (der Override schützt das ganze Fragment).

**Abhängigkeiten:** F-042 (typisierte Signale im Katalog, `detect`).

---

<!-- FEATURE-INDEX
next-feature: F-044
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
F-036 Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt
F-037 Unabhängiges Review in step-done (Reviewer mit frischem Kontext)
F-038 Freigabe-Regel für PROGRESS-Einträge kit-weit; add-feature von Claude aufrufbar (DONE)
F-039 Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0 (DONE)
F-040 Globale CLAUDE.md mit dem Plugin ausliefern und abgleichen
F-041 Projektzusätze in managed Dateien erhalten, Abweichungen früh erkennen (DONE)
F-042 Neue Sprachen und Frameworks erkennen, Vorlagen nachziehen (PLANNED)
F-043 Sprachfragmente in Sprachregeln und Toolchain-Regeln aufteilen
-->
