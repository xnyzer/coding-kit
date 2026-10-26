<!-- coding-kit:global-rules -->
<!-- section:global-head -->
<!--
Diese Datei gehört dem coding-kit-Plugin: /coding-kit:update-conventions erzeugt sie aus
der Kit-Vorlage und den Werten in ~/.claude/coding-kit.env und gleicht sie nach
Plugin-Updates abschnittsweise ab, immer erst nach Bestätigung.

Persönliche Werte stehen nur in ~/.claude/coding-kit.env. Nach einer Änderung dort
/coding-kit:update-conventions global ausführen; die env-Datei allein ändert nichts.

CODING_KIT_REPLY_LANGUAGE=""  # Sprache der Antworten, z. B. Deutsch, English; leer = Claude-Standard
CODING_KIT_EXPLAIN_LEVEL=""   # einsteiger | junior | fortgeschritten | senior; leer = Claude-Standard
CODING_KIT_EXPLAIN_NOTE=""    # freier Text, präzisiert die Stufe; leer = keine Notiz

Abweichen:
- Eine Regel anders: den Abschnitt hier ändern und darin eine eigene Zeile mit dem
  HTML-Kommentar "override: Grund" ergänzen; der Abgleich lässt ihn dann stehen.
- Eine Regel gar nicht: die beiden section-Markerzeilen des Abschnitts löschen; der
  Abgleich bietet ihn dann nie wieder an.
- Eigene Zusatzregeln: in ~/.claude/CLAUDE.md, die das Kit nie anfasst. Dort nicht das
  Gegenteil einer Regel von hier schreiben: Bei Widersprüchen entscheidet Claude beliebig.
-->
# coding-kit — globale Regeln
<!-- /section:global-head -->

<!-- section:global-language -->
## Sprache & Stil

<!-- template:optional:reply-language -->
- Antwortsprache: {{REPLY_LANGUAGE}} (außer der Nutzer wechselt die Sprache).
<!-- /template:optional:reply-language -->
- Direkt und präzise.
- Haus-Default: Code, Code-Kommentare, Commits, Governance-Doku Englisch. Definiert
  die Projekt-CLAUDE.md einen **Languages-Block**, gewinnt der je Dimension (lebende
  Doku, CLAUDE.md-Prosa, Kommentare, Commit-Prosa, README); Alt-Projekte mit
  einzeiliger Doku-Sprach-Angabe werden weiter so gelesen. Identifier und
  Conventional-Commit-Tokens bleiben immer englisch.
<!-- /section:global-language -->

<!-- section:global-explain -->
<!-- template:optional:explain -->
## Erklär-Niveau

Gilt für Antworten, Rückfragen, Pläne, Zusammenfassungen und Fehlerberichte — nicht für
Code, Kommentare, Commits und Doku-Inhalte im Projekt und nicht für die Strenge von
Prüfungen und Freigaben. Feste Ausgabeformate der Skills bleiben; die Sprache darin folgt
dem Niveau.
<!-- /template:optional:explain -->
<!-- template:optional:level-einsteiger -->

- **Stufe einsteiger:** wenig oder keine Programmiererfahrung. Einfache Sprache, kurze
  Sätze. Jeden Fachbegriff beim ersten Auftreten in einem Halbsatz erklären, gern mit
  einem Vergleich aus dem Alltag. Eine Frage auf einmal; Optionen immer mit ihren Folgen
  beschreiben und eine empfehlen. Vor jedem größeren Schritt sagen, was passiert und
  warum. Bei größeren Änderungen sagen, was sich geändert hat und welche Stellen sich zu
  lesen lohnen.
<!-- /template:optional:level-einsteiger -->
<!-- template:optional:level-junior -->

- **Stufe junior:** Grundlagen sitzen, wenig Erfahrung mit Frameworks, Architektur und
  Werkzeugen. Gängige Fachbegriffe ohne Erklärung, neue kurz erklären. Zusammenhänge und
  das Warum erklären: welche Datei wofür da ist, wie die Teile verbunden sind, warum diese
  Lösung. Gibt es mehrere übliche Wege, sie kurz nennen und einen empfehlen; bei
  Entscheidungen die Abwägung in einfachen Worten nennen. Bei größeren Änderungen sagen,
  was sich geändert hat und welche Stellen sich zu lesen lohnen.
<!-- /template:optional:level-junior -->
<!-- template:optional:level-fortgeschritten -->

- **Stufe fortgeschritten:** arbeitet selbstständig. Nur Neues, Ungewöhnliches und
  Abwägungen erklären, Bekanntes nicht. Fachsprache ist in Ordnung.
<!-- /template:optional:level-fortgeschritten -->
<!-- template:optional:level-senior -->

- **Stufe senior:** viel Erfahrung. Knapp und in Fachsprache, keine Grundlagen.
  Trade-offs, Risiken und Alternativen nennen; Details nur auf Nachfrage.
<!-- /template:optional:level-senior -->
<!-- template:optional:explain-note -->

- **Notiz des Nutzers** (präzisiert die Stufe; wo sie ihr widerspricht, gilt die Notiz):
  „{{EXPLAIN_NOTE}}"
<!-- /template:optional:explain-note -->
<!-- /section:global-explain -->

<!-- section:global-git -->
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
<!-- /section:global-git -->

<!-- section:global-graphiti -->
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
<!-- /section:global-graphiti -->

<!-- section:global-workflow -->
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
- **Nichts wird ohne ausdrückliche Erlaubnis als Artifact auf claude.ai veröffentlicht** —
  auch nicht privat, auch nicht „nur zum Ansehen". Ergebnisse entstehen zuerst als lokale
  Datei im Projekt (`docs/` oder `private/`, je nach Inhalt); der Upload ist eine eigene
  Frage, und es muss immer eine lokale Alternative geben. Gilt sinngemäß für jedes
  Verlassen des Rechners.
<!-- /section:global-workflow -->
