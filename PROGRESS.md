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

---

## Offene Aufgaben — von oben nach unten abarbeiten

_Keine vorbereiteten Aufgaben. Nächstes Deliverable aus dem Backlog via
`/coding-kit:prep-step` vorbereiten._

---

## Feature-Ideen (Backlog)

_Neue Ideen via `/coding-kit:add-feature` — sie bekommen die nächste F-Nummer._

> **Kontext F-013–F-016 (Composable CODING-STANDARDS):** project-template stellt den
> §13-Slot (`<!-- module:coding-standards -->`) von „einmal einfügen" auf **anhängen**
> um — mit Pro-Fragment-Markern, einem Fragment-Katalog (vorgeschlagen
> `modules/standards/`: react, prisma, api-design, docker, nginx, …) und einem
> Framework→Fragment-Mapping; Stack-Module **deklarieren** ihre Fragmente. Der exakte
> Fragment-Vertrag (Marker-Schema, Katalog-Ort, Deklarationsform) entsteht in
> **project-template F-002** (Autoring der Web-Fragmente: dortiges F-003). F-013–F-016
> koppeln an diesen Vertrag — gegen das F-002-Ergebnis planen oder co-designen.
> Stand: seit project-template VERSION 0.7.0 liegt der Katalog mit Mapping vor
> (`modules/standards/README.md`, manifest-format 1); Mapping-Zeilen können auch
> Eigenschafts-Trigger tragen → F-017.

### F-012 — add-skill: Template-HOW-TO synchron halten

**Status:** BACKLOG

**Problem:** Die Skill-Übersicht in project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md`
fällt hinter den Skill-Bestand des coding-kit zurück — neue oder geänderte Skills werden
dort nicht nachgezogen, weil kein Prozessschritt daran erinnert.

**Idee:** Der repo-lokale Skill add-skill bekommt in Schritt 3
(Vollständigkeits-Checkliste) einen zusätzlichen Haken: Gehört der neue/geänderte Skill
zum Projekt-Alltag (Dev-Loop) oder zur Projekt-Pflege, wird die Skill-Übersicht in
project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md` mitgepflegt — unter Beachtung der
Sync-Invariante jenes Repos (VERSION + CHANGELOG).

**Lösungsskizze:**
- Checklisten-Punkt in `.claude/skills/add-skill/SKILL.md` Schritt 3 ergänzen.
- Kriterium formulieren, wann ein Skill in die Template-Übersicht gehört
  (Dev-Loop/Pflege ja, rein kit-interne Skills nein).

**Abhängigkeiten:** keine — unabhängig von project-template F-002, kann vorgezogen
werden.

### F-015 — prep-step: Framework-Erkennung mit Fragment-Vorschlag

**Status:** BACKLOG

**Problem:** Führt eine Aufgabe ein neues Framework oder eine neue Dependency ein,
wächst der Standards-Bestand des Projekts nicht mit — es gibt keinen Prozessschritt, der
das fehlende Fragment bemerkt („Standards wachsen mit").

**Idee:** prep-step erkennt in §2 (Analyse), wenn die Aufgabe ein Framework einführt,
für das im Projekt noch kein Standards-Fragment vorliegt. Existiert im Katalog ein
passendes Fragment, schlägt es dessen Anhängen vor; existiert keins, schlägt es vor,
eins zu autoren und ins Template zurückzugeben.

**Lösungsskizze:**
- Erkennungs-Hook in `plugins/coding-kit/skills/prep-step/SKILL.md` §2 ergänzen
  (Framework→Fragment-Mapping aus dem Katalog nutzen).
- Vorschlags-Pfade: Fragment anhängen (Mechanik aus F-013) bzw. Autoring + Upstream-
  Rückgabe anstoßen.

**Abhängigkeiten:** project-template F-002 (Katalog + Mapping); baut sinnvoll auf F-013
auf (Anhänge-Mechanik).

### F-016 — step-done: Standards-Coverage-Backstop

**Status:** BACKLOG

**Problem:** Auch mit Erkennung in prep-step (F-015) kann ein Framework ohne
zugehöriges Standards-Fragment durchrutschen — etwa wenn es erst während der Umsetzung
dazukommt. Es fehlt ein Backstop am Ende des Zyklus.

**Idee:** step-done verifiziert beim Abschluss, dass für die im Projekt tatsächlich
genutzten Frameworks die passenden Standards-Fragmente vorhanden sind, und meldet
Lücken — nichts wird ohne seinen Standard abgeschlossen.

**Lösungsskizze:**
- Coverage-Check in `plugins/coding-kit/skills/step-done/SKILL.md` ergänzen
  (genutzte Frameworks ermitteln, gegen vorhandene Fragment-Marker abgleichen).
- Nutzt dasselbe Framework→Fragment-Mapping wie F-015; meldet Lücken, blockiert aber
  nach Nutzerentscheid nicht zwingend.

**Abhängigkeiten:** project-template F-002 (Fragment-Vertrag + Mapping); inhaltlich
verwandt mit F-015 (gemeinsames Mapping), aber unabhängig umsetzbar.

### F-017 — Eigenschafts-Trigger für Standards-Fragmente auswerten

**Status:** BACKLOG

**Problem:** Der Fragment-Katalog des project-template (ab dessen VERSION 0.7.0,
`modules/standards/README.md`, manifest-format 1) kennt Mapping-Zeilen mit
Projekteigenschafts-Triggern (*characteristic:* …; erster Fall: `audit-logging` mit
„service with user/admin mutations"). Solche Trigger sind über Paket-Manifeste nicht
erkennbar — sie müssen aus Projektwissen kommen. Ohne Kit-Unterstützung wird ein
Eigenschafts-Fragment nie gezogen.

**Idee:** Die Kit-Skills werten die im Katalog deklarierten Eigenschafts-Trigger zur
Laufzeit aus — an drei Stellen im Lebenszyklus: Anforderungs-Interview,
Feature-Planung, Nachrüstung im Bestandsprojekt. Nichts wird hardcodiert; Trigger-Daten
kommen ausschließlich aus dem Katalog-README.

**Lösungsskizze:**
- define-requirements bzw. /new-project-Flow: deklarierte Eigenschafts-Trigger im
  Interview abfragen (z. B. „Gibt es Nutzer-/Admin-Aktionen, die Daten verändern?");
  Treffer → Fragment bei der Instanziierung mitkomponieren.
- prep-step §2: Feature-Beschreibung zusätzlich gegen die Eigenschafts-Trigger matchen
  (komplementär zur Dependency-Erkennung aus F-015); Treffer ohne vorhandenes
  Fragment → Anhängen vorschlagen.
- choose-stack (Bestandsprojekt-Modus): Eigenschafts-Fragmente nachrüstbar machen —
  sie sind in keinem MODULE.md deklariert; Auswahl als Projektentscheidung mit
  Bestätigung wie beim Modulwechsel.
- Mapping zur Laufzeit aus dem Katalog-README lesen (manifest-format 1) — nichts im
  Kit hardcoden.

**Abhängigkeiten:** F-013 (Fragment-Anhänge-Mechanik); der prep-step-Teil wird
idealerweise zusammen mit F-015 umgesetzt (gleiche Stelle, komplementärer Signaltyp).

---

<!-- FEATURE-INDEX
next-feature: F-018
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
F-012 add-skill: Template-HOW-TO synchron halten
F-013 choose-stack: Multi-Fragment-Einbau (DONE)
F-014 update-conventions: Pro-Fragment-Refresh (DONE)
F-015 prep-step: Framework-Erkennung mit Fragment-Vorschlag
F-016 step-done: Standards-Coverage-Backstop
F-017 Eigenschafts-Trigger für Standards-Fragmente auswerten
-->
