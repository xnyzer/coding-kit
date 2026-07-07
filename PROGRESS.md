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

---

## Offene Aufgaben — von oben nach unten abarbeiten

_Keine vorbereiteten Aufgaben. Nächstes Deliverable aus dem Backlog via
`/coding-kit:prep-step` vorbereiten._

---

## Feature-Ideen (Backlog)

### F-002 — Begleit-Skills

**Problem:** Projektanlage braucht wiederkehrende Einzelentscheidungen (Name, Lizenz,
Stack, Anforderungen), die heute ad hoc getroffen werden.

**Idee:** Fünf einzeln nutzbare Skills, die auch `/new-project` aufruft: `/name-it`,
`/choose-license`, `/choose-stack` (Neuanlage + Bestandsprojekt-Nachrüstung),
`/define-requirements` (M1-Interview → REQUIREMENTS.md → PROGRESS.md),
`/refine-requirements` (M2-Diagnose mit drei Pfaden, darf Features splitten).

**Abhängigkeiten:** F-001.

### F-003 — /new-project-Orchestrator

**Problem:** Neue Projekte entstehen noch durch Ableiten aus Altprojekten.

**Idee:** Orchestrator-Skill: Short-Info erheben (M1), Abfragen mit Defaults
(Name/Lizenz/Stack/Sichtbarkeit/Doku-Sprache/group_id/Anforderungen), Plan anzeigen,
nach Bestätigung ausführen: `gh repo create --template`, Platzhalter füllen, Modul
einsetzen, `template-version` stempeln, Verifikation (`mise install && just setup &&
just check`), Erst-Commit nur nach OK, Graphiti-Seeding. Trockenlauf-Modus.

**Abhängigkeiten:** F-002.

### F-004 — Globale CLAUDE.md-Vorlage

**Problem:** Die globalen House-Defaults liegen in einer Legacy-Datei, die Claude Code
nicht lädt; der Installer kann die globale CLAUDE.md noch nicht einrichten.

**Idee:** Schlanke Vorlage `templates/global-CLAUDE.md` im Kit (persönliche Werte aus der
Personal-Config), Migration der Legacy-Inhalte, Installer-Schritt aktivieren.

**Abhängigkeiten:** F-001.

### F-005 — Pflege-Skills

**Problem:** Konventions-Updates erreichen Bestandsprojekte nicht; externe Vorbild-Repos
werden nicht systematisch beobachtet.

**Idee:** `/update-conventions` (bidirektional: Template → Projekte via
template-version + MANIFEST; Projekt → Template als „promote"; Override-Schutz;
Migrationen für Altprojekte) und `/check-upstreams` (Watchliste externer Repos mit
persistiertem zuletzt-geprüft-Ref; Startliste: AlexPEClub/ai-coding-starter-kit sowie
der angekündigte gitleaks-Nachfolger „Betterleaks").

**Abhängigkeiten:** F-001; Kollisionstest-Ergebnis aus dem Grundgerüst bestimmt die
Cleanup-Strategie für lokale Skill-Kopien.

---

<!-- FEATURE-INDEX
next-feature: F-006
F-001 Kit-Grundgerüst (DONE)
F-002 Begleit-Skills
F-003 /new-project-Orchestrator
F-004 Globale CLAUDE.md-Vorlage
F-005 Pflege-Skills
-->
