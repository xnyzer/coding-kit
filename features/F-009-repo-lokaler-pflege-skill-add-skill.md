---
id: F-009
title: Repo-lokaler Pflege-Skill add-skill
type: feature
status: DONE
size:
created: 2026-07-13
done: 2026-07-13
depends-on:
superseded-by:
---

# F-009 — Repo-lokaler Pflege-Skill add-skill

## Verlauf

### F-009 — Repo-lokaler Pflege-Skill add-skill (2026-07-13)

**Was entstanden ist (Repo-Infrastruktur, kein Plugin-Inhalt — daher kein
Version-Bump):**

- **`.claude/skills/add-skill/SKILL.md`** — standardisiert Anlage und Änderung von
  Plugin-Skills in diesem Repo: Kontext laden (`docs/skill-authoring.md` als
  referenzierte Quelle der Wahrheit, nicht dupliziert) → M1-Kurz-Interview
  (neu/ändern, Name + Kategorie, Trigger, Frontmatter-Flags, Pflicht-Bausteine) →
  Bauen mit Write-then-Verify → **Begleit-Änderungs-Checkliste** (plugin.json-Version
  UND Description-Aufzählung, CHANGELOG, README-Tabelle UND Prosa, ggf.
  Authoring-Doku) → Verifizieren (`just check`, `/reload-plugins`) → Abschluss mit
  explizitem PROGRESS/ARCHIVE-Schritt (F-Nummer vergeben, step-done; auf
  Nutzerwunsch eigens betont).
- Modell-Aufruf bewusst erlaubt (kein `disable-model-invocation`): der Skill zieht
  automatisch, wenn der Nutzer einen Kit-Skill bauen/ändern will.
- Projekt-CLAUDE.md: Verweis auf `/add-skill` bei den Strukturregeln;
  Dogfooding-Zyklus um build-step ergänzt.
- Entscheidungen: repo-lokal statt im Plugin (Plugin-Skills werden global
  installiert — Repo-Pflege wäre dort Ballast); CLAUDE.md hält nur Invarianten,
  Prozeduren gehören in Skills (progressive disclosure). Ausbau-Ideen notiert:
  `just new-skill`-Scaffold-Rezept, validate.py-Prüfung „jeder Skill hat eine
  README-Zeile".
