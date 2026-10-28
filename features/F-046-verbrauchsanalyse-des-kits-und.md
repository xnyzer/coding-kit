---
id: F-046
title: Verbrauchsanalyse des Kits und Empfehlungen zu Modell und Effort
type: feature
status: BACKLOG
size:
created: 2026-10-25
done:
depends-on:
superseded-by:
---

# F-046 — Verbrauchsanalyse des Kits und Empfehlungen zu Modell und Effort

## Erfassung

**Problem:** Niemand weiß, was die Kit-Skills im Betrieb verbrauchen und ob der Workflow
(add-feature → prep-step → build-step → step-done, dazu update-conventions) gegenüber einer
direkten Umsetzung ohne Kit nennenswert mehr Aufwand kostet. Nutzer haben keine
Empfehlung, welches Modell und welcher Effort für welchen Lauf reichen. Die Testläufe aus
F-043c lagen mit Opus 5.5 auf `xhigh` bei 0,79 bis 2,98 USD je Lauf, eine Migration von
0.13.2 bei rund 3,70 USD.

**Idee:** Wenn alle geplanten Features gebaut sind, eine komplette Analyse: jeder Skill
über verschiedene Projekte und Lauftypen gemessen (Kosten, Tokens, Werkzeugaufrufe,
Vollständigkeit der Schritte), dazu derselbe Auftrag einmal direkt umgesetzt, ohne
Kit-Workflow. Daraus Empfehlungen zu Modell und Effort je Skill und Lauftyp mit
Kostenschätzung — und erst dann der Abschnitt dazu in der README.

**Lösungsskizze:**
- Messaufbau wie in F-043c: `claude -p --output-format stream-json` an Wegwerf-Kopien;
  Kosten aus `total_cost_usd`, Tokens getrennt nach Cache-Schreiben, Cache-Lesen und
  Ausgabe, Werkzeugaufrufe, Abgleich, ob alle Pflichtschritte des Skills liefen.
- Matrix aus Skills, Projekttypen (docs-only, ts-node, python, go …) und Einstellungen
  (mindestens Opus und Sonnet, je auf `medium` und `high`); mehrere Läufe je Zelle, weil
  ein einzelner Lauf streut.
- `update-conventions` zusätzlich gesondert: Er läuft in jedem Projekt bei jedem Release
  und ist der teuerste Pflege-Lauf. Je Projekttyp messen: `status`, Routine-Update,
  Update mit Konflikten oder geschützten Fragmenten, Migration eines alten Stempels ohne
  Snapshot, Modulwechsel über `choose-stack`.
- Vergleich mit direkter Umsetzung: eine typische Aufgabe einmal über den Kit-Workflow,
  einmal als direkter Auftrag; Kosten und Ergebnis (Tests, Review-Funde, Doku, Commits)
  nebeneinander.
- Ergebnis: Abschnitt in der README (unter „Tägliche Nutzung") mit Empfehlung je Lauftyp
  und Kostenspanne, Messwerten mit Datum, Modell und Effort sowie der Messmethode zum
  Nachmessen; das Rezept für Testläufe in `docs/skill-authoring.md`.
- Wo die Messung Einsparungen zeigt, Folgeaufgaben über `/coding-kit:add-feature`
  vorschlagen (z. B. mehr ins Skript, kürzere Skill-Texte, Effort im Frontmatter).

**Ausgangsdaten** (F-043c, 2026-10-25, je ein Update desselben docs-only-Projekts):
- Opus 5.5 auf `xhigh`: 1,67 USD, 29 Werkzeugaufrufe, alle Schritte.
- Opus 5.5 auf `medium`: 1,19 USD, 18 Werkzeugaufrufe, alle Schritte.
- Sonnet 5.5 auf `medium`: 0,31 USD, 7 Werkzeugaufrufe — ohne Zonen-Abgleich,
  Lock-Prüfung und Prüfung entfernter Ziele; der Endstand stimmte nur, weil sich dort
  nichts geändert hatte.
- Cache-Lesen kostet bei Opus 5.5 und Sonnet 5.5 gleich viel; gespart wird vor allem
  über weniger Werkzeugaufrufe, nicht über das Modell allein.

**Noch zu analysieren:**
- Messbudget und wie viele Läufe je Zelle für eine belastbare Aussage reichen.
- Wie die direkte Umsetzung fair verglichen wird (gleiche Aufgabe, gleiche Abnahme).
- Ob Kostenzahlen in der README stehen dürfen, obwohl das Repo statische Versionsstände
  in Texten meidet — mit Datum und Messmethode oder nur als Größenordnung.
- Ob Skills `effort:` oder `model:` im Frontmatter setzen sollen: Das überschreibt die
  Wahl jedes Nutzers, und wie lange die Effort-Vorgabe gilt, lässt die Doku offen.

**Abhängigkeiten:** alle übrigen Einträge der Empfohlenen Reihenfolge — gemessen wird der
Endstand; besonders F-036 und F-045 verändern den Verbrauch.
