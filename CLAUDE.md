# coding-kit — Claude Instructions

## Graphiti Memory (Knowledge Graph)
**group_id**: `coding-kit`

- Erst den Graph fragen, dann Dateien durchsuchen:
  `search_memory_facts(query="…", group_ids=["coding-kit"])`.
- Nach signifikanten Änderungen via `add_memory` aktualisieren (`group_id: "coding-kit"`).
- Optional — ohne laufenden Graphiti-MCP still überspringen.

## Überblick

Dieses Repo ist Claude-Code-**Plugin + Marketplace + Renovate-Preset + Installer** — die
prozedurale Hälfte des Scaffolding-Systems (die projektbezogene Hälfte ist
[project-template](https://github.com/xnyzer/project-template)). Details: `README.md`.

## Strukturregeln (verbindlich)

- **Repo-Root = dieses Repo selbst** (eigene Doku, CI, PROGRESS). Das **Plugin** lebt
  vollständig unter `plugins/coding-kit/`; der Marketplace zeigt per relativem `source`
  darauf. `default.json` im Root ist das Renovate-Preset (Pfad-Konvention von Renovate —
  nicht verschieben).
- **Sprachgrenze:** Kit-Inhalte (README, Doku, Skill-Texte) Deutsch. Englisch ist nur,
  was in Projekte gelangt oder dort wirkt: Governance-Doku dieses Repos, Commit-Messages,
  Hook-Ausgaben, das Renovate-Preset.
- **Publishing-Hygiene (Repo ist public):** keine Personendaten, keine absoluten lokalen
  Pfade, keine privaten IPs/Hostnames. Identität nie hardcoden — zur Laufzeit ermitteln
  (`git config`, `gh api user`) oder aus `~/.claude/coding-kit.env` (Personal-Config,
  nie committed). `just check` lintet das; vor jedem Push zusätzlich Personendaten-grep.
- **Keine statischen Versionsstände** in Texten; technisch nötige Pins (Action-SHAs,
  mise-Tools) hält Renovate aktuell.
- **Sync-Invariante:** Jede inhaltliche Änderung am Plugin (Skills, Hooks) bumpt im
  selben Commit die Version in `plugins/coding-kit/.claude-plugin/plugin.json` und
  bekommt einen `CHANGELOG.md`-Eintrag.
- Neue Skills folgen `docs/skill-authoring.md` — erst lesen, dann bauen. Anlage und
  Änderung laufen über den repo-lokalen Skill `/add-skill` (`.claude/skills/`): er
  führt durch Konvention, Begleit-Änderungen und Abschluss inkl. PROGRESS-Pflege.

## Konventionen

- Conventional Commits, Englisch, Imperativ; Body endet mit
  `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Commit-E-Mail muss die GitHub-Noreply-Adresse sein — vor jedem Commit
  `git config user.email` prüfen, ggf. via `gh api user` auflösen.
  **Nie automatisch committen — erst fragen.**
- `just check` muss vor jedem Commit grün sein (`just setup` installiert die Hooks).

## Workflow & Skills

Aufgaben sind F-Nummern in `PROGRESS.md` (+ `FEATURE-INDEX`-Block). Das Kit nutzt seine
eigenen Plugin-Skills (Dogfooding): `/coding-kit:add-feature` → `/coding-kit:prep-step` →
`/coding-kit:build-step` → `/coding-kit:step-done` (je Substep); Audits via
`/coding-kit:audit-code`.
