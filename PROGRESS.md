# coding-kit — Progress

Lebende Aufgabenliste. **Done-Tabelle** oben, **offene Aufgaben in Ausführungsreihenfolge**
darunter, **Feature-Index** ganz am Ende.

So funktioniert's: `/coding-kit:add-feature` nimmt neue Aufgaben auf (F-Nummer),
`/coding-kit:prep-step` bereitet vor und zerlegt, `/coding-kit:step-done` schließt ab.

---

## Done

| Step | Beschreibung | Fertig |
|------|--------------|--------|
| F-001 | Kit-Grundgerüst → **Plugin (4 Core-Skills, projekterkennender Stop-Hook), Marketplace „xnyzer", Renovate-Preset, Installer, Doku, Validator + CI.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-002 | Begleit-Skills → **name-it, choose-license, choose-stack, define-requirements, refine-requirements (Plugin 0.2.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-003 | /new-project-Orchestrator → **Short-Info → Abfragen → Plan → Instanziierung nach MANIFEST, Trockenlauf-Modus (Plugin 0.3.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-004 | Globale CLAUDE.md-Vorlage → **templates/global-CLAUDE.md (aktiviert den Installer-Schritt), Legacy-Migration abgeschlossen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-005 | Pflege-Skills → **update-conventions (bidirektional, Override-Schutz, Migrationen) + check-upstreams mit upstreams.json (Plugin 0.4.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-006 | Utility-Skill refine-prompt → **Prompt analysieren, Schwachstellen benennen, neu formulieren, ausführen (Plugin 0.5.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-007 | Workflow-Skill teach-step → **Lehrer-Modus: sokratisch angeleitete Eigenumsetzung, hartes Schreibverbot, Lern-Interview + Graphiti-Lernprofil (Plugin 0.5.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-008 | Workflow-Skill build-step + autonome Läufe → **Implementierungsphase als Skill (plan-treu, Verifikation je Substep, step-done je Substep); Modus `autonom` bereitet /goal-Läufe vor; laufbezogene Commit-Freigabe in step-done + globaler Vorlage (Plugin 0.5.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-009 | Repo-lokaler Pflege-Skill add-skill → **Prozedur für Anlage/Änderung von Plugin-Skills (`.claude/skills/`, kein Plugin-Inhalt): Authoring-Konvention, Begleit-Änderungs-Checkliste, Abschluss inkl. PROGRESS-Pflege.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-010 | Status-Marker-Konvention + schärfere Grenze add-feature/prep-step → **`Status:`-Zeile mit Tokens BACKLOG/PLANNED in PROGRESS-Einträgen, „Lösungsskizze" statt Vorab-Plan in add-feature, prep-step hinterfragt die Skizze gegen den Codestand; Begleitanpassungen in build-step/step-done (Plugin 0.6.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-011 | build-step vom step-done-Handoff entkoppeln → **interaktiv wird step-done nur empfohlen (Nutzer prüft/schließt selbst ab), nur im autonomen `/goal`-Lauf läuft es je Substep automatisch; Modus-Signal = aktiver /goal-Lauf mit Commit-Freigabe (Plugin 0.7.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-14 |
| F-013 | choose-stack: Multi-Fragment-Einbau → **Modus B hängt Sprachfragment + deklarierte Katalog-Fragmente idempotent an den §13-Slot an (Vertrag: project-template MANIFEST § Standards fragments); Modulwechsel tauscht nur das Sprachfragment, Katalog-Fragmente bleiben; new-project-Referenz nachgezogen (Plugin 0.8.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-014 | update-conventions: Pro-Fragment-Refresh → **zwei Diff-Ebenen (Core-Datei-Diff mit injiziertem Ist-Slot + Fragment-Abgleich je `fragment:NAME`), fehlende deklarierte Fragmente werden zum Anhängen angeboten, Fragment-Promote in den Katalog (Plugin 0.9.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-015 | prep-step: Framework-Erkennung mit Fragment-Vorschlag → **Schritt 2a „Standards-Abdeckung" mit Kosten-Gate; matcht Dependency-Signale UND Eigenschafts-Trigger (F-017-Touchpoint miterledigt); Vorschlags-Pfade Anhängen bzw. Autoring + Promote (Plugin 0.10.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-012 | add-skill: Template-HOW-TO synchron halten → **neuer Checklisten-Haken in Schritt 3: Dev-Loop-/Pflege-Skills pflegen die Skill-Übersicht in project-templates HOW-TO mit (Sync-Invariante jenes Repos); repo-lokal, kein Plugin-Release.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-016 | step-done: Standards-Coverage-Backstop → **Schritt 1a, diff-basiert (neue Manifest-Dependencies/Signal-Dateien) mit Katalog-Match zur Laufzeit; Lücke melden + Anhängen vorschlagen, nicht blockierend (Plugin 0.11.0). Zyklus F-013/014/015/016 damit geschlossen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-017 | Eigenschafts-Trigger für Standards-Fragmente → **define-requirements fragt characteristic-Zeilen im Interview ab, new-project komponiert bejahte Fragmente mit, choose-stack rüstet sie auf Bestätigung nach (Plugin 0.12.0). Composable-Standards-Strang komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-018 | Konventions-Vererbung nur noch abwärts → **AUFWÄRTS/promote aus update-conventions gestrichen; Ersatz: manuell anstoßbarer Übernahme-Vorschlag (Template-Session-Prompt oder GitHub-Request) an drei Stellen — Sync-Lauf, Fragment-Anlage, step-done-Diff (Plugin 0.13.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-020 | Sprach-Matrix: granulare Sprachwahl je Projekt → **new-project-Preset-Frage (entkoppelt von Sichtbarkeit), fünf `LANG_*`-Platzhalter, Commit-/Kommentar-Sprache in step-done/build-step, Languages-Block-Migration in update-conventions (prospektiv, nichts rückwirkend übersetzen); Pairing: project-template F-010 (Plugin 0.14.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-021 | update-conventions: Vollabdeckung aller Template-Dokumente → **seed-Abgleich abschnittsweise je `section:NAME`-Zone (Opt-out, Override, Feature-Detection) + A3-Marker-Migration + Marker-Erhalt in new-project (0.15.0); entfernte/umbenannte Template-Dateien via Stempel-Commit-Auflösung, Rückbau/Umzug je Datei bestätigt (0.16.0). Pairing: project-template F-011.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-20 |
| F-019 | Pflege-Skill go-public → **geführter, fail-closed Übergang private/lokal → public: vier blockierende Preflight-Gates (Historie-Secrets, Privacy inkl. Commit-Metadaten, Lizenz, private/-Hygiene), Nachzug vor Übergang via update-conventions-Sichtbarkeits-Prämisse, Push nur mit laufbezogener Freigabe (Plugin 0.17.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-20 |
| F-022 | Begleithandlungen beim Fragment-Einbau → **`/choose-stack` § Begleithandlungen als einzige Fundstelle (generisch, Fragment-Wissen bleibt im Template), von new-project/prep-step/step-done referenziert; entkoppelt von der Idempotenz-Regel; `update-conventions` prüft zusätzlich bei unverändertem Fragment-Text und erreicht damit als einziger Pfad Bestandsprojekte. Anlass/Pairing: project-template 0.13.1 (F-016), `nextjs`-Fragment (Plugin 0.18.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |

---

## Offene Aufgaben — von oben nach unten abarbeiten

_Keine vorbereiteten Aufgaben. Nächstes Deliverable aus dem Backlog via
`/coding-kit:prep-step` vorbereiten._

---

## Feature-Ideen (Backlog)

_Neue Ideen via `/coding-kit:add-feature` — sie bekommen die nächste F-Nummer._

### F-023 — new-project ohne GitHub (lokaler Bootstrap-Pfad)

**Status:** BACKLOG

**Problem:** `/new-project` legt das Repo ausschließlich über `gh repo create --template`
an (Schritt 4a). Auf Rechnern ohne GitHub-Konto ist das der einzige Schritt der Kette,
der lokal nicht erfüllbar ist — alles ab 4b (Instanziierung, Verifikation, Erst-Commit)
läuft ohnehin lokal. Der lokale Bootstrap muss derzeit jedes Mal per Hand vorbereitet
werden; die README beschreibt ihn nur als Workaround.

**Idee:** Der Skill erkennt zur Laufzeit, dass GitHub nicht verfügbar ist, und bietet den
lokalen Bootstrap an statt an `gh` zu scheitern: Kopie des Template-Checkouts, eigenes
`git init`, Autor-Config aus der Personal-Config. Die GitHub-Schritte entfallen
ausgewiesen, nicht durch Fehlschlag.

**Lösungsskizze:**
- Feature-Detection statt neuem Modus-Argument: fehlendes oder nicht authentifiziertes
  `gh` als Signal, lokaler Pfad wird bestätigt.
- 4a lokal: Template-Checkout kopieren, `git init`, Autor-Config; 4c (Repo-Settings/
  Topics) ausweisen und überspringen — für die Discovery trägt der
  `.claude/template-version`-Stempel.
- Doku-Begleitung: README-Abschnitt „Ohne GitHub" auf den Skill-Pfad umstellen, sobald
  er existiert.

**Abhängigkeiten:** keine

**Noch zu analysieren:**
- Gehört die Erkennung zentral (auch `name-it`, `update-conventions`, `check-upstreams`
  haben GitHub-Teilschritte) oder lokal in `new-project`? Das entscheidet, ob das Kit
  einen dokumentierten „kein-GitHub"-Betriebsmodus bekommt oder nur einen Sonderfall.
- Firmen-Hosts mit eigener CLI (Azure DevOps, GitLab): bewusst außerhalb oder späterer
  Erweiterungspunkt?

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

**Abhängigkeiten:** keine — unabhängig von F-023, aber sinnvoll im selben Zug umzusetzen

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
- Lokalen Template-Checkout mit anlegen — `git clone` der öffentlichen URL, braucht kein
  `gh`; für den GitHub-freien Weg der Hebel. Aktualität ist Sache von F-026.
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

**Abhängigkeiten:** keine. Berührung mit F-023 (dort steht die Frage, ob „kein GitHub"
zentral erkannt wird — die Antwort sollte für Skills und Installer dieselbe sein) und mit
F-026 (F-025 legt den Checkout an, F-026 hält ihn aktuell).

### F-026 — Template-Auflösung: Aktualität und Klontiefe

**Status:** BACKLOG

**Problem:** Die gemeinsame Template-Auflösung (`/choose-stack` § 0, referenziert von
`new-project` und `update-conventions`) nimmt den lokalen Checkout unter
`$CODING_KIT_PROJECTS_DIR/project-template`, sobald er existiert — und kein Skill
aktualisiert ihn. `update-conventions` liest dessen `VERSION` aber als aktuellen
Template-Stand und entscheidet daran, ob ein Projekt aktuell ist. Ein veralteter Checkout
lässt Projekte also fälschlich als aktuell gelten oder verteilt alte Dateistände, ohne
dass es auffällt. Zweiter Defekt: der Ersatzpfad klont mit `--depth 1`, während die
Stempel-Auflösung die `VERSION`-Historie durchgeht — mit Shallow-Klon nicht möglich.

**Idee:** Der lokale Checkout wird ausdrücklich Cache und nicht Quelle: vor Benutzung
auffrischen, wenn erreichbar, sonst bewusst offline weiterarbeiten und den Stand
ausweisen. Die Klontiefe richtet sich nach dem, was die Skills tatsächlich brauchen.

**Lösungsskizze:**
- § 0 um einen Refresh-Schritt erweitern; aufgelöste `VERSION` und Herkunft (live oder
  offline mit Datum) im Lauf benennen.
- Lokale Änderungen oder divergierte Historie im Checkout nicht still übergehen — melden
  und bestätigen lassen.
- Klontiefe am Bedarf ausrichten: die Stempel-Auflösung braucht `VERSION`-Historie.
- Auflösung von `gh` entkoppeln — für ein öffentliches Template genügt `git clone` der URL.

**Abhängigkeiten:** keine — sinnvoll zusammen mit F-025

---

<!-- FEATURE-INDEX
next-feature: F-027
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
F-023 new-project ohne GitHub (lokaler Bootstrap-Pfad)
F-024 Commit-Adresse aus der Personal-Config statt hart aus gh
F-025 install.sh: fehlender gh-Login und Plattform-Abdeckung
F-026 Template-Auflösung: Aktualität und Klontiefe
-->
