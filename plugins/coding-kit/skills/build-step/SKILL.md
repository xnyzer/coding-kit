---
name: build-step
description: Vorbereitete Aufgabe (F-Nummer) diszipliniert umsetzen — liest den prep-step-Plan, arbeitet Substeps mit Verifikation je Schritt ab und übergibt je Substep an step-done. Mit Argument „autonom" wird nicht gebaut, sondern ein /goal-Lauf vorbereitet (Regeln laden, Commit-Freigabe einholen, fertige Goal-Zeile ausgeben). Nur manuell per /coding-kit:build-step aufrufbar.
disable-model-invocation: true
---

# Aufgabe umsetzen (Bau-Modus)

Setzt eine vorbereitete Aufgabe um — plan-treu, verifiziert je Substep, ohne
Scope-Drift. Zwei Modi:

- **Ohne Zusatz-Argument:** direkt bauen, interaktiv in dieser Session.
- **Mit Argument „autonom":** nicht bauen, sondern einen `/goal`-Lauf vorbereiten
  (siehe Abschnitt „Autonomer Lauf").

Argument: F-Nummer (z. B. „F-004") oder Alt-Format (tolerant lesen). Ohne Nummer:
die oberste offene Aufgabe vorschlagen und bestätigen lassen.

## Leitplanken (beide Modi)

- **Plan-Treue:** Substeps und Abnahmekriterien aus der `PROGRESS.md` sind die
  verbindliche Checkliste; Häkchen erst, wenn das Kriterium per Tool-Ausgabe belegt ist.
- **Scope-Schutz:** Entdeckungen unterwegs („das sollte man auch noch …") nicht still
  mitbauen — notieren und via `/coding-kit:add-feature` als neue F-Nummer vorschlagen.
- **Nie pushen, nie ältere Historie ändern** (kein Amend/Rebase über den Lauf hinaus).
  Commits laufen ausschließlich über `/coding-kit:step-done` und dessen Regeln.
- PROGRESS-Pflege ebenfalls nur via step-done — dieser Skill setzt um, er verbucht nicht.

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md**: Zweck/Scope, Sprache der lebenden Doku, Verweise auf
`CODING-STANDARDS.md` / `REQUIREMENTS.md` / `THREAT-MODEL.md`, Graphiti-group_id
(Graphiti optional — ohne MCP still überspringen). Nichts davon hardcoden.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: (1) Projekt-CLAUDE.md und PROGRESS.md neu
lesen, (2) `git status` + `git diff` für den tatsächlichen Arbeitsstand — welche
Substeps sind schon committet, was liegt im Working Tree?, (3) beim ersten
unerledigten Substep weitermachen; erledigte Arbeit nicht wiederholen. Eine in diesem
Lauf erteilte Commit-Freigabe gilt nach Recovery weiter, sofern sie im Verlauf
dokumentiert ist — im Zweifel neu fragen.

## 1. Plan laden

- Aufgabe aus der `PROGRESS.md` lesen: Beschreibung, Substeps, Dateien,
  Abhängigkeiten, Abnahmekriterien; `CODING-STANDARDS.md` lesen (falls vorhanden).
- Unerledigte Abhängigkeiten → stoppen und melden, nicht drumherum bauen.
- **Status-Marker prüfen:** `BACKLOG` heißt nur aufgenommen, nicht geplant → zuerst
  `/coding-kit:prep-step` empfehlen, nicht ungeplant losbauen; `PLANNED` → bauen.
  Alt-Eintrag ohne Status-Zeile: kleine Aufgaben (siehe Größenmaßstab in prep-step)
  direkt umsetzen, bei Mittel/Groß zuerst prep-step empfehlen.

## 2. Umsetzung — je Substep

1. Substep-Ziel und Abnahmekriterien kurz nennen.
2. Umsetzen. **Write-then-Verify:** nach jedem Edit die Datei re-lesen; nichts als
   erledigt melden, was nicht per Tool-Ausgabe belegt ist.
3. Checks stack-agnostisch über die just-Standardrezepte (`just check`, gezielt
   `just test` / `just lint`); ohne justfile die projektüblichen Checks aus
   CLAUDE.md/README. Rot → sofort fixen, nie rot weiterarbeiten.
4. Abnahmekriterien einzeln gegen Tool-Ausgaben prüfen und abhaken.
5. `/coding-kit:step-done` für den Substep ausführen (Review, Scans, PROGRESS,
   Commit-Frage bzw. — im autonomen Lauf — die dort geregelte Freigabe-Ausnahme).

Dann der nächste Substep, bis die Aufgabe komplett ist.

## 3. Abschluss

Kurzes Fazit: was gebaut wurde, Abweichungen vom Plan (mit Begründung), was als neue
F-Nummer notiert wurde. Der letzte step-done-Lauf markiert die Eltern-F-Nummer als
DONE.

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
3. **Commit-Freigabe einholen (M1, eine Frage):** „Darf ich in diesem Lauf nach jedem
   grünen Substep committen? (Empfohlen: ja — Commits sind die Checkpoints des
   Laufs.)" Antwort ausdrücklich festhalten. Die Freigabe gilt nur für diesen Lauf,
   nur nach grünen Checks und Scans; Push und History-Rewrites bleiben immer tabu.
4. **Goal-Zeile ausgeben** (kopierbar, Werte eingesetzt), Muster mit Freigabe:

   ```
   /goal Alle Substeps von F-NNN sind einzeln per step-done abgeschlossen
   und committet, `just check` ist grün, nichts wurde gepusht — oder stopp
   nach N Turns.
   ```

   Ohne Commit-Freigabe stattdessen: „… einzeln per step-done abgeschlossen,
   Commit-Vorschläge liegen gesammelt vor, `just check` ist grün, nichts wurde
   committet oder gepusht — oder stopp nach N Turns." Startwert für N: etwa fünf
   Turns je Substep.
5. Dem Nutzer die Bedienung nennen: Goal-Zeile absenden startet den Lauf sofort;
   `/goal` ohne Argument zeigt Status (Turns, Tokens, letzte Evaluator-Begründung);
   `/goal clear` bricht ab. Hinweis: der Stop-Reminder-Hook des Kits meldet sich
   während des Laufs weiter — das ist normal und wird von den Arbeits-Turns als
   „Arbeit im Gange, aufschieben" behandelt.
6. **Danach enden.** Das Bauen beginnt, wenn der Nutzer die Goal-Zeile absendet — die
   Arbeits-Turns folgen dann den Abschnitten „Leitplanken" bis „Abschluss" dieses
   Skills.

Für Läufe ganz ohne offene Session (`claude -p`): Auftrag und Freigabe gehören in den
Prompt, z. B. `claude -p "/coding-kit:build-step F-NNN autonom — Commit-Freigabe für
diesen Lauf erteilt. Danach: /goal <Bedingung wie oben>"`.
