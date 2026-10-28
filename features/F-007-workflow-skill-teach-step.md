---
id: F-007
title: Workflow-Skill teach-step
type: feature
status: DONE
size:
created: 2026-07-13
done: 2026-07-13
depends-on:
superseded-by:
---

# F-007 — Workflow-Skill teach-step

## Verlauf

### F-007 — Workflow-Skill teach-step (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **teach-step** — Lehrer-Modus für die Implementierungsphase: der Nutzer setzt eine
  Aufgabe (F-Nummer) selbst um, der Skill leitet sokratisch an, gibt gestufte Hilfe
  (Leitfrage → Tipp → Hinweis mit Datei:Zeile → Pseudocode → Musterlösung nur auf
  ausdrückliche Anfrage, erklärt statt zum Kopieren), kontrolliert per `git diff` +
  Re-Lesen und lässt Tests über die just-Rezepte laufen.
- **Schreibverbot zweistufig:** hart via `disallowed-tools: Write, Edit, NotebookEdit`
  im Frontmatter; für Bash per Anweisung (nur lesend/prüfend — keine Redirects, kein
  `sed -i`/`rm`/`mv`, kein `git add`/`commit`). Bitten um Selbst-Implementierung lehnt
  der Skill ab und bietet stattdessen das Beenden des Lehrer-Modus an.
- **Lern-Interview (M1), gemeinsam mit dem Nutzer designt:** (1) Vertrautheit mit
  drei verhaltensverankerten Stufen (Neuland/Grundlagen/Routiniert — jede Option
  nennt, was sie bewirkt), (2) Lernziel mit vier Optionen (Default „Struktur &
  Verdrahtung" — welche Datei wohin, wie Teile verbunden werden; dazu Sprache &
  Syntax, Konzept & Design, Diese Codebase). Der Führungsgrad wird nicht abgefragt,
  sondern abgeleitet (Trittsteine/Wegweiser/Kompass, per Zuruf änderbar);
  Nachkalibrierungs-Regel: Antworten sind Startpunkt, kein Vertrag.
- **Graphiti-Lernprofil (optional):** Level/Themen des Nutzers in der persönlichen
  group_id (Konvention `main`) nachschlagen und fortschreiben — bekannte Antworten
  überspringen das Interview.
- Abgrenzung: PROGRESS-Pflege, Scans und Commit bleiben bei `step-done`; teach-step
  schreibt keine Doku und committet nie.
- Entscheidungen: Platzierung im coding-kit statt eigenem Trainer-Plugin (an
  prep-step/step-done-Workflow gekoppelt; Extraktion später billig). Bash bewusst
  erlaubt, damit der Lehrer Tests laufen lassen kann — Nutzer entschied sich gegen
  das strengere Bash-Verbot.
