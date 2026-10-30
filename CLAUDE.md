# coding-kit — Claude Instructions

## Graphiti Memory (Knowledge Graph)
**group_id**: `coding-kit`

- Erst den Graph fragen, dann Dateien durchsuchen:
  `search_memory_facts(query="…", group_ids=["coding-kit"])`.
- Schreiben nach der Graphiti-Regel der globalen Kit-Regeln (`group_id: "coding-kit"`):
  Wissen ohne Ort im Repo und je abgeschlossenem Feature ein kurzer Wegweiser.
- Wissen zum Template bis 0.16.0 liegt noch unter der group_id `project-template` — bei
  Template-Fragen beide abfragen (`group_ids=["coding-kit", "project-template"]`), neu
  gespeichert wird nur unter `coding-kit`.
- Optional — ohne laufenden Graphiti-MCP still überspringen.

## Überblick

Dieses Repo ist Claude-Code-**Plugin (Skills, Stop-Hook, Projekt-Template) + Marketplace +
Renovate-Preset + Installer** — das ganze Scaffolding-System. Das Template lag bis 0.16.0
im eigenen Repo project-template; seit 1.0.0 liegt es mit importierter Historie im Plugin.
Details: `README.md`.

### Ziele

- Neue Projekte mit einem Befehl aufsetzen — Repo, Template, Stack-Modul, Lizenz,
  Anforderungen (`/coding-kit:new-project`).
- Bestandsprojekte aktuell halten, ohne ihre eigenen Anpassungen zu verlieren
  (`/coding-kit:update-conventions`).
- Jede Aufgabe durch denselben Zyklus führen — aufnehmen, spezifizieren, bauen,
  abschließen — mit Checks, Scans und Freigaben.
- Die globalen Kit-Regeln und die Personal-Config auf jeden Rechner bringen.

### Nicht-Ziele

- Kein Produkt für fremde Teams: das Kit dient primär dem Eigenbedarf; das Repo ist
  öffentlich und nachnutzbar.
- Keine Inhalte konkreter Projekte: Downstream-Projekte werden weder genannt noch vom
  Kit aus geändert — ein Projekt holt Änderungen selbst.

### Rahmenbedingungen

- Läuft als Claude-Code-Plugin; Plugin, Template und globale Regeln teilen eine Version
  und ein CHANGELOG.
- Baut auf GitHub auf (Marketplace, Plugin, `gh`); ohne GitHub fallen diese Teile weg,
  der Arbeitszyklus läuft lokal über git und just weiter.
- Öffentliches Repo — Publishing-Hygiene und Sprachgrenze siehe Strukturregeln.
- Skripte in POSIX-Shell und awk; die Tests laufen unter dash und bash, mit dem
  System-awk und mawk.

## Strukturregeln (verbindlich)

- **Repo-Root = dieses Repo selbst** (eigene Doku, CI, `features/`). Das **Plugin** lebt
  vollständig unter `plugins/coding-kit/`; der Marketplace zeigt per relativem `source`
  darauf. `default.json` im Root ist das Renovate-Preset (Pfad-Konvention von Renovate —
  nicht verschieben).
- **Projekt-Template** unter `plugins/coding-kit/template/` (`MANIFEST.md`, `core/`,
  `modules/`) — nur innerhalb des Plugins landet es im Plugin-Cache. Skills lesen es
  ausschließlich über `${CLAUDE_PLUGIN_ROOT}/template`; `MANIFEST.md` ist der Vertrag
  zwischen Skills und Template, `just check` prüft ihn mechanisch.
- **Template-Anweisungen nie als Repo-Regeln laden:** `.claude/settings.json` schließt per
  `claudeMdExcludes` alle Anweisungsdateien unter `plugins/coding-kit/template/` aus.
  Sonst lädt Claude Code `template/core/CLAUDE.md` (Platzhalter, Regeln für ein
  Downstream-Projekt) als Regel fürs Kit, sobald eine Datei in dem Ordner gelesen wird.
  Die Begründung steht hier, weil JSON keine Kommentare kennt; der Validator prüft die
  Zeile.
- **Globale Regeln** unter `plugins/coding-kit/global/` (`coding-kit.md`): kommen mit
  dem Plugin auf den Rechner und werden nach `~/.claude/rules/coding-kit.md` gerendert
  (`template-sync.sh render-global`) — kein Projektinhalt, deshalb nicht in `template/`,
  und deutsch.
- **Sprachgrenze:** Kit-Inhalte (README, Doku, Skill-Texte, CHANGELOG) Deutsch. Englisch
  ist nur, was in Projekte gelangt oder dort wirkt: der Template-Inhalt
  (`plugins/coding-kit/template/**`), Governance-Doku dieses Repos, Commit-Messages,
  Hook-Ausgaben, das Renovate-Preset.
- **Publishing-Hygiene (Repo ist public):** keine Personendaten, keine absoluten lokalen
  Pfade, keine privaten IPs/Hostnames; konkrete Downstream-Projekte nie beim Namen nennen,
  auch nicht in Feature-Dateien, Verlauf oder CHANGELOG („ein Downstream-Projekt"). Identität nie
  hardcoden — zur Laufzeit ermitteln (`git config`, `gh api user`) oder aus
  `~/.claude/coding-kit.env` (Personal-Config, nie committed); im Template nur
  registrierte Platzhalter (MANIFEST § Placeholders). `just check` lintet das samt
  privater Blocklist (`private/blocklist.txt`); vor jedem Push zusätzlich
  Personendaten-grep.
- **Keine statischen Versionsstände** in Texten; technisch nötige Pins (Action-SHAs,
  mise-Tools) hält Renovate aktuell.
- **Versionsregel:** Jede inhaltliche Änderung an Skills, Hooks, Skripten oder Template
  braucht eine Version über dem gepushten Stand
  (`plugins/coding-kit/.claude-plugin/plugin.json`) und einen Eintrag dafür in
  `plugins/coding-kit/CHANGELOG.md`; mehrere Commits dürfen sich eine unveröffentlichte
  Version teilen. Ändert sich Template-Inhalt, bekommt der Eintrag einen Abschnitt
  `### Template` (den liest `/update-conventions`). Werden Template-Dateien angelegt,
  entfernt oder umgewidmet, zieht das MANIFEST im selben Commit nach; verlässt ein Ziel
  die Core-Tabelle, kommt eine Zeile in `## Removed and renamed targets`.
  `just version-rule` prüft das vor jedem Commit und in der CI.
- Neue Skills folgen `docs/skill-authoring.md` — erst lesen, dann bauen. Anlage und
  Änderung laufen über den repo-lokalen Skill `/add-skill` (`.claude/skills/`): er
  führt durch Konvention, Begleit-Änderungen und Abschluss inkl. Pflege der Feature-Datei —
  für Plugin-Skills wie für repo-lokale. Claude darf ihn selbst starten.
- **Feature-Dateien nur mit Freigabe:** Jede neue oder geänderte Feature-Datei
  (`features/F-NNN-*.md`), jede Änderung an `features/INDEX.md` und an den
  Ziel-Abschnitten im Überblick wird zuerst als Vorschau gezeigt und erst nach
  ausdrücklichem OK des Nutzers geschrieben — auch wenn ein Skill sie anlegt. Lange
  Entwürfe gehen nach `private/` und werden nach dem Übernehmen gelöscht. Claude darf
  add-feature und add-skill selbst starten; die Freigabe gilt dem Eintrag. Die
  Plugin-Skills tragen die Regel als Freigabe-Gate (`docs/skill-authoring.md`).
- **Nummern:** Aufgaben sind `F-NNN`, je eine Datei `features/F-NNN-kurzname.md`, auch
  für Template-Arbeit; `features/INDEX.md` führt Reihenfolge, Tabelle und nächste
  Nummer. Die Tabelle erzeugt `just features-index`, `just check` prüft sie. `TPL-NNN`
  sind die Aufgaben des früheren project-template-Repos — sie stehen nur in
  `docs/project-template-history.md` und in der importierten Historie und bekommen
  keine neuen Nummern.

## Konventionen

- Conventional Commits, Englisch, Imperativ; Body endet mit
  `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Commit-E-Mail muss die GitHub-Noreply-Adresse sein — vor jedem Commit
  `git config user.email` prüfen, ggf. via `gh api user` auflösen.
  **Nie automatisch committen — erst fragen.**
- `just check` muss vor jedem Commit grün sein; der Pre-Commit-Hook prüft zusätzlich
  gitleaks und die Versionsregel (`just setup` installiert die Hooks).

## Workflow & Skills

Aufgaben sind F-Nummern in `features/` (Übersicht: `features/INDEX.md`). Das Kit nutzt seine
eigenen Plugin-Skills (Dogfooding): `/coding-kit:add-feature` → `/coding-kit:prep-step` →
`/coding-kit:build-step` → `/coding-kit:step-done` (je Substep); Audits via
`/coding-kit:audit-code`.

Eine Session in diesem Repo läuft mit dem **installierten** Plugin, nicht mit dem
Arbeitsstand. Geänderte Skills oder Template-Inhalte testet man mit
`claude --plugin-dir plugins/coding-kit` — dann kommen beide aus dem Arbeitsstand.
