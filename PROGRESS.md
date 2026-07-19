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

---

## Offene Aufgaben — von oben nach unten abarbeiten

_Keine vorbereiteten Aufgaben. Nächstes Deliverable aus dem Backlog via
`/coding-kit:prep-step` vorbereiten._

---

## Feature-Ideen (Backlog)

_Neue Ideen via `/coding-kit:add-feature` — sie bekommen die nächste F-Nummer._

### F-019 — Pflege-Skill go-public: Projekt nachträglich public-ready machen

**Status:** BACKLOG

**Problem:** public-only-Dateien (CODE_OF_CONDUCT, codeql.yml, …) werden bei privaten
Projekten bewusst nicht instanziiert. Soll ein Projekt später öffentlich werden, gibt
es keinen geführten Weg — der reine Datei-Nachzug wäre via update-conventions möglich,
aber das eigentliche Risiko prüft niemand systematisch: Secrets/Personendaten in der
**gesamten Git-Historie**, TBD-Lizenz, fehlende Repo-Einstellungen.

**Idee:** Neuer Pflege-Skill go-public, der den Übergang orchestriert statt Mechanik
zu duplizieren: blockierendes Preflight-Audit, dann Übergang nach expliziter
Bestätigung, dann Datei-Nachzug via update-conventions, dann Abschluss-Check. Zwei
Startfälle: das GitHub-Repo existiert und ist private → Sichtbarkeit umstellen; das
Projekt war bisher nur lokal → GitHub-Repo public anlegen und nach Freigabe initial
pushen.

**Lösungsskizze:**
- Neuer Skill `plugins/coding-kit/skills/go-public/SKILL.md` (Pflege-Kategorie,
  `disable-model-invocation` — nur bewusster Nutzer-Start).
- Fallerkennung zur Laufzeit (`gh repo view`): existiert + private → Sichtbarkeit
  umstellen; existiert nicht → Repo-Anlage; schon public → nur Nachzug/Check.
- Preflight blockierend: gitleaks über die **volle Historie** (nicht nur Working
  Tree), Privacy-Scan des committeten Baums, LICENSE nicht TBD, `private/`
  gitignored; Funde → stoppen mit Optionen (bereinigen / History-Rewrite / Abbruch).
- Übergang je Fall nur nach expliziter Bestätigung: `gh repo edit --visibility
  public` bzw. `gh repo create` + initialer Push (ausdrückliche, laufbezogene
  Push-Freigabe — einzige Ausnahme vom Push-Tabu).
- Nachzug an `/update-conventions` delegieren (public-only-Dateien erscheinen dann
  regulär als Diff); Abschluss-Check: CodeQL-Workflow, Topics/Beschreibung,
  `just check` grün.

**Abhängigkeiten:** keine (nutzt bestehende update-conventions-Mechanik).

### F-021 — update-conventions: Vollabdeckung aller Template-Dokumente (inkl. seed)

**Status:** BACKLOG

**Problem:** update-conventions prüft nur managed Dateien und Modul-Parts. Die sieben
seed-Dateien (CLAUDE.md, PROGRESS.md, PROGRESS-ARCHIVE.md, REQUIREMENTS.md, README.md,
LICENSE, `.claude/convention-overrides.md`) werden nie geprüft — auch ihre
**Template-Struktur-Anteile** nicht (CLAUDE.md-Blöcke wie Graphiti/Languages/
Konventionen, PROGRESS-Skelett, REQUIREMENTS-Kopfnotiz, README-Struktur).
Template-Verbesserungen dort erreichen Bestandsprojekte nie, Drift bleibt unbemerkt.
Zweiter blinder Fleck: im Template gelöschte/umbenannte Dateien behandelt der Lauf
nicht.

**Idee:** Jeder Sync-Lauf prüft sämtliche Template-Dokumente. seed-Dateien werden nie
als Ganzes ersetzt, sondern **struktur-bewusst** abgeglichen: Template-Anteile gegen
die aktuelle Vorlage diffen und die Übernahme je Abschnitt anbieten; projektspezifische
Prosa bleibt unantastbar, Override-Schutz gilt. Mechanik-Kandidat: markierte
Abschnitte im seed-Skelett (Vorbild `fragment:NAME`) — der Vertrag dafür gehört ins
project-template (Pairing wie bei F-013/F-020).

**Lösungsskizze:**
- Abschnitts-Marker-Vertrag im project-template definieren (dort aufzunehmen):
  updatebare Zonen in seed-Skeletten markieren (z. B. CLAUDE.md: Graphiti-,
  Languages-, Konventions-Block; PROGRESS: Skelett-Kopf).
- update-conventions: neuer Schritt „seed-Abgleich (abschnittsweise)" — markierte
  Abschnitte diffen, Übernahme je Abschnitt anbieten, nie die ganze Datei ersetzen.
- Umgang mit im Template entfernten/umbenannten Dateien: erkennen und Rückbau/
  Umzug anbieten.

**Noch zu analysieren:** Marker-Schema (Kollision mit `override:`-Markern vermeiden);
ob README überhaupt sinnvolle Template-Zonen hat oder projektindividuell bleibt;
Verhalten bei Alt-Projekten ohne Abschnitts-Marker (Heuristik vs. erst Migration).

**Abhängigkeiten:** project-template (Abschnitts-Marker-Vertrag) — dort noch
aufzunehmen; baut auf F-020 auf (Languages-Block als erster Kandidat einer
updatebaren Zone).

---

<!-- FEATURE-INDEX
next-feature: F-022
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
F-019 Pflege-Skill go-public (Projekt nachträglich public-ready)
F-020 Sprach-Matrix: granulare Sprachwahl je Projekt (DONE)
F-021 update-conventions: Vollabdeckung aller Template-Dokumente (inkl. seed)
-->
