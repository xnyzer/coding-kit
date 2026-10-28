---
id: F-012
title: add-skill hält die Template-HOW-TO synchron
type: feature
status: DONE
size:
created: 2026-07-17
done: 2026-07-19
depends-on:
superseded-by:
---

# F-012 — add-skill hält die Template-HOW-TO synchron

## Verlauf

### F-012 — add-skill: Template-HOW-TO synchron halten (2026-07-19)

**Aufgabe:** Die Skill-Übersicht in project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md`
fiel hinter den Skill-Bestand des coding-kit zurück — kein Prozessschritt erinnerte
beim Anlegen/Ändern von Skills an die Pflege der Template-Übersicht.

**Was entstanden ist (repo-lokal, kein Plugin-Release):**

- **Neuer Haken in der Vollständigkeits-Checkliste** (Schritt 3) von
  `.claude/skills/add-skill/SKILL.md`: Gehört der neue/geänderte Skill zum
  Projekt-Alltag (Dev-Loop) oder zur Projekt-Pflege, wird die Skill-Übersicht in
  project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md` mitgepflegt — Template zur
  Laufzeit auflösen (wie `/coding-kit:choose-stack` § 0), die passende der beiden
  Tabellen treffen (Dev-Loop mit „What happens"-Spalte, Pflege nur „When to use"),
  Sync-Invariante jenes Repos einhalten (VERSION-Bump + CHANGELOG im selben Commit).
  Rein kit-interne Skills (wie add-skill selbst) bleiben draußen.
- **Entscheidung:** keine Plugin-Begleitänderungen — add-skill ist repo-lokal
  (`.claude/skills/`), kein Plugin-Inhalt; die Kit-Sync-Invariante greift nicht
  (konsistent mit der F-009-Verbuchung).
- **Vermerk für die nächste project-template-Session:** Die HOW-TO-Zeilen für
  prep-step/choose-stack/update-conventions sind durch F-013–F-015 bereits leicht
  veraltet (u. a. fehlt der Standards-Abdeckungs-Check) — Drift dort beheben; der
  neue Checklisten-Haken verhindert künftige.
- **Geänderte Dateien:** `.claude/skills/add-skill/SKILL.md`.
