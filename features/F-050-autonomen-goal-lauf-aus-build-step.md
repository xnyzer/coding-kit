---
id: F-050
title: Autonomen /goal-Lauf aus build-step entfernen
type: change
status: DONE
size: M
created: 2026-10-29
done: 2026-10-30
depends-on:
superseded-by:
---

# F-050 — Autonomen /goal-Lauf aus build-step entfernen

## Erfassung

**Problem:** build-step kann mit dem Argument „autonom" einen `/goal`-Lauf vorbereiten,
in dem Substeps ohne Prüfung durch den Nutzer gebaut, verbucht und committet werden. Das
passt nicht zu einer Arbeitsweise, in der der Nutzer jedes Ergebnis prüft, braucht
Sonderregeln in mehreren Skills und Dokumenten und hängt am Verhalten eines eingebauten
Claude-Code-Befehls; echte Läufe sind nicht belegt. Jede neue Regel für die Bau-Skills —
zuletzt der Workaround-Stopp aus F-034 — müsste den Modus zusätzlich bedenken.

**Ziel:** Der autonome Modus und alle Regeln, die nur für ihn gelten, entfallen. Gleich
bleiben der interaktive Zyklus build-step → step-done je Substep, die Freigabe für
Verbuchung und Commit und „Push nur auf Bitte".

**Lösungsskizze:**
- build-step: das Argument „autonom" und den Abschnitt zum autonomen Lauf entfernen, die
  Unterscheidung der Modi beim Abschluss eines Substeps auflösen.
- step-done: die Commit-Ausnahme für den autonomen Lauf entfernen — jede Verbuchung und
  jeder Commit braucht wieder die Freigabe.
- Sonderfälle für den autonomen Lauf in add-feature, den globalen Regeln, der
  Skill-Konvention und der README (Anleitung „Autonomer Lauf") streichen.
- Inkompatible Änderung, daher Hauptversion; die globalen Regeln kommen per
  `/coding-kit:update-conventions global` auf die Rechner. Das Template erwähnt den Modus
  nicht. Erledigte Feature-Dateien und alte CHANGELOG-Einträge bleiben, wie sie sind.
- F-037 begründet sein Problem auch mit dem autonomen Lauf — den Satz beim Planen von
  F-037 anpassen.

**Abhängigkeiten:** keine. F-034 baut darauf auf.

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben build-step nach der Änderung, dann gibt es kein Argument „autonom",
  keinen Abschnitt zum autonomen Lauf und keine Unterscheidung der Modi mehr: Jeder
  Substep endet mit der Empfehlung für `/coding-kit:step-done`, der nächste folgt erst
  nach dem Abschluss durch den Nutzer. Negativ: `autonom` und `/goal` kommen im Skill
  nicht mehr vor, auch nicht in Beschreibung und `argument-hint` — belegt:
  `grep -rn -i "autonom\|/goal" plugins/coding-kit/skills README.md` ist leer; build-step
  nach dem Edit neu gelesen.
- [x] AC-2 — Gegeben build-step bekommt neben der F-Nummer ein Argument, das er nicht
  kennt (z. B. „autonom" aus einem alten Prompt), dann nennt er es und fragt nach, statt
  zu raten. Negativ: Er baut nicht still los und ignoriert das Argument nicht — belegt:
  Textprüfung build-step, Einleitung (Regel für unbekannte Argumente).
- [x] AC-3 — Gegeben step-done, dann entfällt die Ausnahme für den autonomen Lauf: Jede
  Verbuchung und jeder Commit braucht die eine Freigabe aus Schritt 5, und der Skill sagt
  ausdrücklich, dass er nie pusht — gepusht wird nur auf Bitte des Nutzers. Negativ: kein
  Weg mehr, ohne Freigabe zu verbuchen oder zu committen — belegt: Textprüfung step-done,
  Schritt 5.
- [x] AC-4 — Gegeben add-feature, `docs/skill-authoring.md` und die README, dann nennen
  sie keinen autonomen Lauf mehr: kein Sonderfall im Freigabe-Gate, keine Anleitung
  „Autonomer Lauf", der Zyklus und die Freigabe für Feature-Dateien sind nur interaktiv
  beschrieben. Negativ: `grep` nach `autonom` und `/goal` in Skills, globalen Regeln,
  README und Skill-Konvention findet nichts — belegt: `grep -rn -i "autonom\|/goal"` über
  `plugins/coding-kit/skills`, `plugins/coding-kit/global`, `README.md` und
  `docs/skill-authoring.md` ist leer.
- [x] AC-5 — Gegeben die globalen Regeln, Abschnitt Git & Commits, dann lautet die erste
  Regel „Nie automatisch committen — erst fragen. Gepusht wird nur auf ausdrückliche
  Bitte." ohne Lauf-Freigabe; der Rest des Punkts (Checks vor Commits) bleibt. Negativ:
  keine Ausnahme, unter der ohne Nachfrage committet wird — belegt:
  `template-sync.sh render-global` mit leerer Personal-Config in einen Scratchpad-Ordner;
  der Abschnitt Git & Commits hat den neuen Text, die gerenderte Datei nennt weder
  „autonom" noch „/goal".
- [x] AC-6 — Gegeben das Release, dann steht die Version auf 3.0.0, und der
  CHANGELOG-Eintrag nennt die Streichung, ihren Grund und die einzige Folge-Handlung
  (`/coding-kit:update-conventions global` auf jedem Rechner); er hat keinen Abschnitt
  `### Template`. `just check` ist grün — belegt: `plugin.json` 3.0.0, CHANGELOG-Eintrag
  ohne `### Template`, `version-rule.py --since origin/main` OK, `just check` grün.

### Randfälle

- EC-1 — Ein alter Prompt oder eine Notiz ruft `build-step F-NNN autonom` auf → AC-2:
  nennen und nachfragen.
- EC-2 — Der Nutzer startet `/goal` von Hand und lässt build-step darin laufen → nicht
  verhindert; build-step hält nach jedem Substep für step-done an, step-done fragt vor
  dem Commit — ohne Nutzer kommt der Lauf nicht weiter.
- EC-3 — Ein Rechner hat noch die alten globalen Regeln → die alte Ausnahme verweist auf
  einen Modus, den kein Skill mehr anbietet, und bleibt folgenlos;
  `/coding-kit:update-conventions` meldet die geänderte Zone wie jede andere.
- EC-4 — Erledigte Feature-Dateien, alte CHANGELOG-Einträge und
  `docs/project-template-history.md` erwähnen den Modus → bleiben unverändert, sie
  beschreiben Geschichte.

### Nicht-Ziele

- `/goal` wird nicht technisch verhindert — nur das Kit bietet keinen Lauf mehr an.
- Erledigte Feature-Dateien und alte CHANGELOG-Einträge werden nicht umgeschrieben.
- Der Problem-Satz in F-037 wird erst beim Planen von F-037 angepasst.

### Tests

- AC-1, AC-4 → Befehl: `grep -rn -i "autonom\|/goal"` über `plugins/coding-kit/skills`,
  `plugins/coding-kit/global`, `README.md` und `docs/skill-authoring.md` ist leer.
- AC-2 → manuell: Textprüfung der Argument-Regel in build-step.
- AC-3 → manuell: Textprüfung von step-done Schritt 5 (keine Ausnahme, Push-Satz da).
- AC-5 → Befehl: `template-sync.sh render-global` mit leerer Personal-Config in einen
  Ordner im Scratchpad; die gerenderte Zone enthält den neuen Text.
- AC-6 → `just check` (Versionsregel, Validator).

### Einbettung

- build-step: außer dem Abschnitt „Autonomer Lauf" fallen die Modus-Erkennung, der
  zweite Weg beim Substep-Abschluss, der Satz zur Lauf-Freigabe in der Kontext-Recovery
  und die Sammel-Regeln für den autonomen Lauf (Scope-Schutz, Abschluss) weg; „Nie
  pushen" bleibt in den Leitplanken.
- Die Push-Regel stand in den globalen Regeln und in step-done nur im Satz zum
  autonomen Lauf — sie bleibt dort als eigener Satz erhalten (AC-3, AC-5).
- Der Stop-Hook ist nicht betroffen; seine Meldung gilt für jede Session.
- Rechner erhalten die globalen Regeln nach dem Plugin-Update über
  `/coding-kit:update-conventions global`; Projekte sind nicht betroffen (das Template
  erwähnt den Modus nicht).
- F-034 baut darauf auf und teilt sich die Version 3.0.0, solange sie unveröffentlicht
  ist.
- Kein Widerspruch zu Zielen, Nicht-Zielen oder ADRs.

### Offene Fragen

- keine

### Entscheidungen

- 2026-10-29 — Größe M: acht Dateien samt Version und CHANGELOG, überwiegend Streichungen.
- 2026-10-29 — Die globale Commit-Regel kennt keine Lauf-Freigabe mehr, jeder Commit wird
  einzeln gefragt; die Push-Regel steht als eigener Satz — statt einer allgemeinen
  Lauf-Freigabe ohne `/goal`-Beispiel, die den gestrichenen Modus durch die Hintertür
  zurückbrächte.
- 2026-10-29 — Unbekannte Argumente behandelt build-step allgemein (nennen, nachfragen)
  statt mit einem gezielten Hinweis auf den gestrichenen Modus — es bleibt keine Spur des
  alten Modus im Skill.
- 2026-10-29 — Hauptversion 3.0.0: Ein öffentliches Argument fällt weg (aus der
  Erfassung).

## Plan

**Größe:** M — acht Dateien samt Version und CHANGELOG, überwiegend Streichungen, keine
offenen Fragen.

**Ansatz:** Streichen statt umbauen: Der autonome Lauf und jede Regel, die nur für ihn
gilt, fallen weg; build-step bekommt stattdessen die allgemeine Regel für unbekannte
Argumente, und die Push-Regel bleibt in step-done und den globalen Regeln als eigener
Satz. Verworfen: den Modus behalten und nur aus der README nehmen oder als experimentell
kennzeichnen — die Sonderregeln blieben in den Skills, und jede neue Regel (zuerst
F-034) müsste ihn weiter bedenken. Die Skill-Änderungen laufen über `/add-skill`.
Erkennung (prep-step 2a): nichts Neues. Keine Config, keine Endpunkte, keine
Dependencies. Version 3.0.0; F-034 teilt sie, solange sie unveröffentlicht ist.

### F-050a — Skills

- build-step: Argument, Abschnitt und Modus-Unterscheidung entfernen, die Regel für
  unbekannte Argumente ergänzen (AC-1, AC-2).
- step-done: die Ausnahme in Schritt 5 entfernen, den Push-Satz ergänzen (AC-3).
- add-feature: den Sonderfall im Freigabe-Gate streichen (AC-4, Teil).
- Version 3.0.0 und CHANGELOG-Eintrag (AC-6, Teil).

### F-050b — Doku und globale Regeln

- README: Anleitung „Autonomer Lauf", die Sätze in Zyklus und Freigabe, die
  build-step-Zeile der Skill-Tabelle; `docs/skill-authoring.md`: den Satz im
  Freigabe-Gate (AC-4).
- Globale Regeln, Abschnitt Git & Commits: die neue Commit- und Push-Regel (AC-5).
- CHANGELOG-Eintrag vervollständigen; die Prüfungen aus Tests: Suche nach `autonom` und
  `/goal`, `render-global` in einen Scratchpad-Ordner, `just check` (AC-4, AC-5, AC-6).

## Verlauf

### F-050a — fertig 2026-10-30

**Umgesetzt:** build-step kennt nur noch einen Ablauf — Substep bauen, prüfen,
step-done empfehlen; Argument „autonom", der Abschnitt zum autonomen Lauf und die
Modus-Erkennung sind entfallen, ein unbekanntes Argument nennt der Skill und fragt nach
(Einleitung). step-done, Schritt 5, hat keine Commit-Ausnahme mehr und sagt
ausdrücklich: nie pushen, nie ältere Historie ändern, gepusht wird nur auf Bitte.
add-feature verliert den Sonderfall im Freigabe-Gate. Die README verliert die Anleitung
„Autonomer Lauf" und die Hinweise in Zyklus, Freigabe-Absatz und Skill-Tabelle. Version
3.0.0, CHANGELOG-Eintrag „unveröffentlicht".

**Entscheidungen:** In build-step heißt die Klammer bei „Nie pushen" jetzt „kein Amend,
kein Rebase" statt „über den Lauf hinaus" — ohne Lauf gibt es keine Ausnahme mehr.

**Abweichung vom Plan:** Die README-Änderungen kamen aus F-050b vor, weil die
`/add-skill`-Checkliste README-Zeile und -Prosa im selben Commit wie den Skill verlangt.
Der Absatz „Alle Skills sind stack-agnostisch", der unter der gestrichenen Anleitung
stand, sitzt jetzt bei den allgemeinen Skill-Absätzen. F-050b behält globale Regeln,
Skill-Konvention, CHANGELOG und Tests.

**Funde:** keine.

### F-050b — fertig 2026-10-30

**Umgesetzt:** Die globalen Regeln sagen im Abschnitt Git & Commits jetzt „Nie
automatisch committen — erst fragen. Gepusht wird nur auf ausdrückliche Bitte." — die
Lauf-Freigabe ist weg, die Push-Regel steht für sich. In `docs/skill-authoring.md`
entfällt der Satz zum autonomen Lauf im Freigabe-Gate. Der CHANGELOG-Eintrag 3.0.0 nennt
die globalen Regeln und die Folge-Handlung `/coding-kit:update-conventions global`.

**Entscheidungen:** keine neuen.

**Abweichung vom Plan:** keine — die README war schon mit F-050a erledigt.

**Funde:** keine.
