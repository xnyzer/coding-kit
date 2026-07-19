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

---

## Offene Aufgaben — von oben nach unten abarbeiten

_Keine vorbereiteten Aufgaben. Nächstes Deliverable aus dem Backlog via
`/coding-kit:prep-step` vorbereiten._

---

## Feature-Ideen (Backlog)

_Neue Ideen via `/coding-kit:add-feature` — sie bekommen die nächste F-Nummer._

> **Kontext (Composable CODING-STANDARDS):** Der Fragment-Vertrag des
> project-template (MANIFEST § Standards fragments, Katalog
> `modules/standards/README.md`, manifest-format 1) ist umgesetzt und die
> Kit-Mechanik dazu fertig — F-013 (choose-stack-Einbau), F-014
> (update-conventions-Refresh), F-015 (prep-step-Erkennung), F-016
> (step-done-Backstop), alle DONE. Offen ist nur noch F-017: Mapping-Zeilen können
> Eigenschafts-Trigger (`*characteristic:*`) tragen, die nicht aus Manifesten,
> sondern aus Projektwissen kommen.

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
- prep-step: **miterledigt in F-015** — dessen Schritt „2a. Standards-Abdeckung"
  matcht beide Signaltypen inkl. der Eigenschafts-Trigger gegen die
  Aufgabenbeschreibung.
- choose-stack (Bestandsprojekt-Modus): Eigenschafts-Fragmente nachrüstbar machen —
  sie sind in keinem MODULE.md deklariert; Auswahl als Projektentscheidung mit
  Bestätigung wie beim Modulwechsel.
- Mapping zur Laufzeit aus dem Katalog-README lesen (manifest-format 1) — nichts im
  Kit hardcoden.

**Abhängigkeiten:** F-013 (Fragment-Anhänge-Mechanik) — erledigt; der prep-step-Teil
ist in F-015 miterledigt, verbleibender Umfang: define-requirements-Interview +
choose-stack-Nachrüstpfad.

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
F-012 add-skill: Template-HOW-TO synchron halten (DONE)
F-013 choose-stack: Multi-Fragment-Einbau (DONE)
F-014 update-conventions: Pro-Fragment-Refresh (DONE)
F-015 prep-step: Framework-Erkennung mit Fragment-Vorschlag (DONE)
F-016 step-done: Standards-Coverage-Backstop (DONE)
F-017 Eigenschafts-Trigger für Standards-Fragmente auswerten
-->
