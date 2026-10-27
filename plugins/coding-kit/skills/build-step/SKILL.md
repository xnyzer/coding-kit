---
name: build-step
description: Vorbereitete Aufgabe (F-Nummer) diszipliniert umsetzen — liest Spezifikation und Plan aus der Feature-Datei (features/F-NNN-*.md), arbeitet Substeps mit Verifikation je Schritt ab, hält die Nicht-Ziele ein und sammelt Abweichungen für step-done. Interaktiv endet jeder Substep mit einer step-done-Empfehlung (du prüfst und schließt selbst ab); nur im autonomen /goal-Lauf läuft step-done je Substep automatisch. Mit Argument „autonom" wird nicht gebaut, sondern ein /goal-Lauf vorbereitet (Regeln laden, Freigabe für Verbuchen und Commits einholen, fertige Goal-Zeile ausgeben). Nur manuell per /coding-kit:build-step aufrufbar.
argument-hint: "[F-Nummer] [autonom]"
disable-model-invocation: true
user-invocable: true
---

# Aufgabe umsetzen (Bau-Modus)

Setzt eine vorbereitete Aufgabe um — plan-treu, verifiziert je Substep, ohne
Scope-Drift. Zwei Modi:

- **Ohne Zusatz-Argument:** direkt bauen, interaktiv in dieser Session.
- **Mit Argument „autonom":** nicht bauen, sondern einen `/goal`-Lauf vorbereiten
  (siehe Abschnitt „Autonomer Lauf").

Argument: F-Nummer (z. B. „F-004") oder Alt-Format (tolerant lesen). Ohne Nummer: das
erste Feature der empfohlenen Reihenfolge in `features/INDEX.md` vorschlagen und
bestätigen lassen.

## Leitplanken (beide Modi)

- **Plan-Treue:** Substeps und Abnahmekriterien (`AC-n`) aus der Feature-Datei
  (`features/F-NNN-*.md`, Abschnitte Spezifikation und Plan) sind die verbindliche
  Checkliste. Ein Kriterium ist erfüllt, wenn es per Tool-Ausgabe belegt ist; den Beleg
  (Test, Check, Befehl) hältst du fest — abgehakt wird er in der Verbuchung von
  step-done.
- **Scope-Schutz:** Die **Nicht-Ziele** der Datei werden nicht gebaut, auch nicht
  „nebenbei". Entdeckungen unterwegs („das sollte man auch noch …") nicht still
  mitbauen. Interaktiv startest du `/coding-kit:add-feature` dafür selbst — der Skill
  zeigt den Entwurf, eingetragen wird erst nach Freigabe des Nutzers. Im autonomen Lauf
  nur sammeln (niemand kann den Eintrag freigeben) und im Abschluss vorschlagen.
- **Abweichungen sammeln:** Weicht die Umsetzung vom Plan ab (anderer Weg, Teile kommen
  dazu oder fallen weg) oder fällt unterwegs eine Entscheidung, Abweichung bzw.
  Entscheidung und Grund festhalten und dem Nutzer nennen — step-done übernimmt sie in
  den Verlauf der Feature-Datei. Zeigt sich, dass ein Abnahmekriterium oder Nicht-Ziel
  nicht mehr stimmt: anhalten und fragen, nicht still umdeuten.
- **Freigabe-Gate:** Jede neue oder geänderte Feature-Datei (`features/F-NNN-*.md`), jede
  Änderung an `features/INDEX.md` und an den Ziel-Abschnitten im Überblick der
  `CLAUDE.md` wird zuerst als Vorschau gezeigt und erst nach ausdrücklichem OK des
  Nutzers geschrieben (ausgenommen: genau der zuvor freigegebene Text; die Tabelle
  erzeugt danach das Skript). Lange Entwürfe (etwa ab 40 Zeilen) gehen als Datei nach
  `private/` und werden nach dem Übernehmen gelöscht.
- **Nie pushen, nie ältere Historie ändern** (kein Amend/Rebase über den Lauf hinaus).
  Commits laufen ausschließlich über `/coding-kit:step-done` und dessen Regeln.
- Feature-Datei und Index (Verlauf, Abnahmekriterien, Status, Tabelle) pflegt nur
  step-done — dieser Skill setzt um, er verbucht nicht.

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md**: Überblick mit Zweck, Zielen, Nicht-Zielen und
Rahmenbedingungen, Sprache der lebenden Doku, Verweise auf `CODING-STANDARDS.md` /
`THREAT-MODEL.md`, Graphiti-group_id (Graphiti optional — ohne MCP still überspringen).
Nichts davon hardcoden.

**Altes Format:** Hat das Projekt eine `PROGRESS.md` mit `FEATURE-INDEX`-Block, aber keine
`features/INDEX.md`, arbeitet es noch mit dem Dokumentmodell vor coding-kit 2.0.0. Dann
nicht bauen: auf die Migration per `/coding-kit:update-conventions` verweisen.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: (1) Projekt-CLAUDE.md und die Feature-Datei neu
lesen — ihr Verlauf zeigt die verbuchten Substeps, (2) `git status` + `git diff` für den
tatsächlichen Arbeitsstand — welche Substeps sind schon committet, was liegt im Working
Tree?, (3) beim ersten
unerledigten Substep weitermachen; erledigte Arbeit nicht wiederholen. Eine in diesem
Lauf erteilte Freigabe für Verbuchen und Commits gilt nach Recovery weiter, sofern sie
im Verlauf dokumentiert ist — im Zweifel neu fragen.

## 1. Plan laden

- Die Feature-Datei lesen: Erfassung, Spezifikation (Abnahmekriterien, Randfälle,
  Nicht-Ziele, Tests, Entscheidungen), Plan mit Substeps, Verlauf;
  `CODING-STANDARDS.md` lesen (falls vorhanden).
- Unerledigte Abhängigkeiten (`depends-on`, Status nicht `DONE`) → stoppen und melden,
  nicht drumherum bauen.
- **Status prüfen** (Kopfblock): `BACKLOG` heißt nicht geplant → zuerst
  `/coding-kit:prep-step` empfehlen, nicht ungeplant losbauen (steht schon eine
  Spezifikation, fehlt nur der Plan). `PLANNED` → bauen. `IN-PROGRESS` → beim ersten
  Substep ohne Verlauf-Eintrag weitermachen. `DONE`, `DROPPED`, `SUPERSEDED` → nicht
  bauen; Folgearbeit bekommt eine neue Nummer.

## 2. Umsetzung — je Substep

**Modus erkennen:** Ein aktiver `/goal`-Lauf mit erteilter Lauf-Freigabe = **autonom**;
jede andere Nutzung = **interaktiv**. Der Modus steuert Schritt 5.

1. Substep-Ziel und Abnahmekriterien kurz nennen.
2. Umsetzen — Code-Kommentare/Docstrings in der Kommentar-Sprache des Projekts
   (Languages-Block der CLAUDE.md; ohne Block englisch). **Write-then-Verify:** nach
   jedem Edit die Datei re-lesen; nichts als erledigt melden, was nicht per
   Tool-Ausgabe belegt ist.
3. Checks stack-agnostisch über die just-Standardrezepte (`just check`, gezielt
   `just test` / `just lint`); ohne justfile die projektüblichen Checks aus
   CLAUDE.md/README. Rot → sofort fixen, nie rot weiterarbeiten.
4. Die Abnahmekriterien des Substeps einzeln gegen Tool-Ausgaben prüfen und je
   Kriterium den Beleg nennen (Test, Check, Befehl).
5. **Substep abschließen — modusabhängig:**
   - **Interaktiv (Normalfall):** step-done *nicht* automatisch starten. Den Substep als
     gebaut-und-verifiziert melden und `/coding-kit:step-done` **empfehlen** — du prüfst
     und passt ggf. an, bevor der Schritt wirklich fertig ist. Der nächste Substep folgt
     erst nach deinem Abschluss bzw. ausdrücklichem „weiter".
   - **Autonomer `/goal`-Lauf:** `/coding-kit:step-done` je Substep automatisch ausführen
     (Review, Scans, Verlauf und Status, Commit über die dort geregelte
     Freigabe-Ausnahme) — die `/goal`-Abschlussbedingung verlangt genau das. Dann direkt
     der nächste Substep.

Dann der nächste Substep, bis die Aufgabe komplett ist — autonom fortlaufend, interaktiv
erst, nachdem du den aktuellen Substep abgeschlossen hast.

## 3. Abschluss

Kurzes Fazit: was gebaut wurde, Abweichungen vom Plan (mit Begründung), welche neuen
Ideen aufgetaucht sind. Im autonomen Lauf hier die gesammelten Ideen als Vorschläge für
`/coding-kit:add-feature` auflisten (eingetragen wird erst nach Freigabe) — der letzte
step-done-Lauf hat die Eltern-F-Nummer bereits als DONE verbucht; interaktiv erledigst
du das mit deinem abschließenden step-done.

## Autonomer Lauf (Argument „autonom")

In diesem Modus **nicht bauen**. Stattdessen die Session für einen `/goal`-Lauf
einrichten — `/goal` ist ein eingebauter Claude-Code-Befehl, den nur der Nutzer
absetzen kann: Er hält die Session Turn für Turn am Arbeiten, bis ein Prüfmodell die
Abschlussbedingung als erfüllt bewertet.

1. Schritte 0–1 ausführen (Kontext und Plan laden).
2. Voraussetzungen benennen (nicht prüfbar — dem Nutzer sagen): aktuelles Claude Code
   mit bestätigtem Trust-Dialog und aktiven Hooks; für unbeaufsichtigte Läufe
   zusätzlich Auto-Modus bzw. ausreichende Tool-Permissions, sonst hält der Lauf am
   ersten Permission-Prompt an.
3. **Freigabe für Verbuchen und Commits einholen (M1, eine Frage):** „Darf ich in diesem
   Lauf nach jedem grünen Substep in der Feature-Datei verbuchen und committen?
   (Empfohlen: ja — Commits sind die Checkpoints des Laufs.)" Antwort ausdrücklich festhalten. Die
   Freigabe gilt nur für diesen Lauf, nur für die geplanten Substeps und nur nach
   grünen Checks und Scans; neue Feature-Dateien deckt sie nicht ab (die werden
   gesammelt), Push und History-Rewrites bleiben immer tabu.
4. **Goal-Zeile ausgeben** (kopierbar, Werte eingesetzt), Muster mit Freigabe:

   ```
   /goal Alle Substeps von F-NNN sind einzeln per step-done abgeschlossen
   und committet, `just check` ist grün, nichts wurde gepusht — oder stopp
   nach N Turns.
   ```

   Ohne Freigabe stattdessen: „… einzeln per step-done abgeschlossen,
   Verbuchungs- und Commit-Vorschläge liegen gesammelt vor, `just check` ist grün,
   nichts wurde verbucht, committet oder gepusht — oder stopp nach N Turns."
   Startwert für N: etwa fünf Turns je Substep.
5. Dem Nutzer die Bedienung nennen: Goal-Zeile absenden startet den Lauf sofort;
   `/goal` ohne Argument zeigt Status (Turns, Tokens, letzte Evaluator-Begründung);
   `/goal clear` bricht ab. Hinweis: der Stop-Reminder-Hook des Kits meldet sich
   während des Laufs weiter — das ist normal und wird von den Arbeits-Turns als
   „Arbeit im Gange, aufschieben" behandelt.
6. **Danach enden.** Das Bauen beginnt, wenn der Nutzer die Goal-Zeile absendet — die
   Arbeits-Turns folgen dann den Abschnitten „Leitplanken" bis „Abschluss" dieses
   Skills.

Für Läufe ganz ohne offene Session (`claude -p`): Auftrag und Freigabe gehören in den
Prompt, z. B. `claude -p "/coding-kit:build-step F-NNN autonom — Freigabe für Verbuchen
und Commits in diesem Lauf erteilt. Danach: /goal <Bedingung wie oben>"`.
