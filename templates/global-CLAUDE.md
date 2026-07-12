# Globale House-Defaults — Claude Code

> Gepflegt als Vorlage im coding-kit (`templates/global-CLAUDE.md`); auf neuen Rechnern
> richtet `install.sh` sie ein. Änderungen zuerst dort, dann hierher übernehmen.

## Sprache & Stil

- Antworte auf Deutsch (außer der Nutzer wechselt zu Englisch). Direkt und präzise.
- Code, Code-Kommentare, Commits, Governance-Doku: Englisch. Die Sprache der lebenden
  Doku (PROGRESS, REQUIREMENTS …) bestimmt die jeweilige Projekt-CLAUDE.md.

## Git & Commits (projektübergreifend)

- **Nie automatisch committen — erst fragen.** Eine ausdrückliche, laufbezogene
  Freigabe (z. B. für einen autonomen /goal-Lauf) zählt als Fragen; Push bleibt auch
  dann tabu. Vor Commits müssen die Projekt-Checks grün sein (`just check`, falls
  vorhanden).
- Conventional Commits, englisch, Imperativ; Body endet mit
  `Co-Authored-By: Claude <noreply@anthropic.com>`.
- **Commit-E-Mail = GitHub-Noreply, nie eine private Adresse** — gilt auch bei
  Amend/Rebase/Cherry-Pick. Vor jedem Commit `git config user.email` prüfen; bei
  Abweichung zur Laufzeit auflösen (nichts hardcoden):
  `git config --local user.email "$(gh api user --jq .id)+$(gh api user --jq .login)@users.noreply.github.com"`

## Graphiti Memory (falls MCP läuft — sonst still überspringen)

- **Erst den Graph fragen, dann Dateien durchsuchen** — zu Sessionbeginn und laufend als
  Nachschlagewerk (`search_memory_facts`, `search_nodes`). Gefundenes still anwenden.
- **group_ids:** Projektwissen → group_id aus der **Root-CLAUDE.md des Projekts**
  (Konvention: Projektname). Persönliches und Übergreifendes (Präferenzen, Infra) → `main`.
- Fehlt die group_id im Projekt: erst im Graph suchen, sonst den Nutzer fragen und die
  bestätigte group_id in die Root-CLAUDE.md des Projekts eintragen.
- **Speichern ohne Nachfrage** (`add_memory`): getroffene Entscheidungen, gelöste
  Probleme, geäußerte Präferenzen, Infra-Fakten — dichte Inhalte in mehrere Episoden
  splitten. Nicht speichern: Trivia, temporäres Debugging, bereits Vorhandenes.
  Veraltetes ersetzen (`delete_entity_edge`, dann neu speichern).

## Arbeitsweise

- Nachfragen statt raten. **Write-then-Verify:** nach jedem Edit re-lesen; nichts als
  erledigt melden, was nicht per Tool-Ausgabe belegt ist.
- Aufgaben laufen als F-Nummern in `PROGRESS.md`; Workflow-Skills kommen aus dem
  coding-kit-Plugin (`/coding-kit:new-project`, `:add-feature`, `:prep-step`,
  `:step-done`, `:audit-code`, …).
- Secrets und Privates nie ins Repo: operative Interna nach `private/` (gitignored);
  lebende Doku bleibt frei von Klarnamen, lokalen Pfaden und IPs — jedes Projekt bleibt
  jederzeit publishbar.
- Keine Versionsstände aus dem Gedächtnis behaupten — aktuelle Stände zur Laufzeit
  verifizieren (Websuche/Registry).
