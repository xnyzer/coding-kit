---
name: build-step
description: Vorbereitete Aufgabe (F-Nummer) diszipliniert umsetzen — liest Spezifikation und Plan aus der Feature-Datei (features/F-NNN-*.md), arbeitet Substeps mit Verifikation und Selbst-Review je Schritt ab (verständlich, einfach, sicher, lesbar, kein Workaround — gegen CODING-STANDARDS.md bzw. die Vorlage), behebt vorhandene Fehler im berührten Code, hält statt eines Workarounds an, hält die Nicht-Ziele ein und sammelt Abweichungen für step-done. Jeder Substep endet mit einer step-done-Empfehlung (du prüfst und schließt selbst ab). Nur manuell per /coding-kit:build-step aufrufbar.
argument-hint: "[F-Nummer]"
disable-model-invocation: true
user-invocable: true
---

# Aufgabe umsetzen (Bau-Modus)

Setzt eine vorbereitete Aufgabe um — plan-treu, verifiziert je Substep, ohne
Scope-Drift, Substep für Substep zusammen mit dem Nutzer.

Argument: F-Nummer (z. B. „F-004") oder Alt-Format (tolerant lesen). Ohne Nummer: das
erste Feature der empfohlenen Reihenfolge in `features/INDEX.md` vorschlagen und
bestätigen lassen. Ein weiteres Argument, das dieser Skill nicht kennt: es nennen und
nachfragen, was gemeint ist — nicht raten, nicht still übergehen.

## Leitplanken

- **Plan-Treue:** Substeps und Abnahmekriterien (`AC-n`) aus der Feature-Datei
  (`features/F-NNN-*.md`, Abschnitte Spezifikation und Plan) sind die verbindliche
  Checkliste. Ein Kriterium ist erfüllt, wenn es per Tool-Ausgabe belegt ist; den Beleg
  (Test, Check, Befehl) hältst du fest — abgehakt wird er in der Verbuchung von
  step-done.
- **Scope-Schutz:** Die **Nicht-Ziele** der Datei werden nicht gebaut, auch nicht
  „nebenbei". Entdeckungen unterwegs („das sollte man auch noch …") nicht still
  mitbauen. Du startest `/coding-kit:add-feature` dafür selbst — der Skill zeigt den
  Entwurf, eingetragen wird erst nach Freigabe des Nutzers.
- **Vorhandene Fehler beheben:** Ein Fehler, der schon im berührten Code steckt (falsches
  Verhalten, Sicherheitslücke, roter Check, Warnung), ist keine Entdeckung für später —
  im selben Substep beheben, mit einem Test belegen und als Fund für den Verlauf nennen.
  Vorher fragen, wenn die Korrektur groß ist, Verhalten ändert, auf das sich anderes
  verlässt, oder in einem anderen Teil des Projekts liegt; auf Wunsch wird daraus eine
  F-Nummer vom Typ `fix`. Fehler in vendortem oder erzeugtem Code (Fremdbibliothek,
  Build-Ausgabe) nur melden — die Korrektur gehört an die Quelle. Verbesserungen ohne
  Fehler bleiben Entdeckungen (Scope-Schutz).
- **Kein Workaround:** Ist die saubere Lösung im Plan nicht machbar — sie bräuchte mehr
  Umfang oder eine andere Architektur, oder sie bricht ein Nicht-Ziel —, anhalten: Grund
  nennen, Wege anbieten (Plan per datierter Entscheidung anpassen, neue F-Nummer, anders
  lösen) und auf den Nutzer warten. Kein Hack, kein `HACK` oder `TODO: fix later`, kein
  stilles Umgehen. Ist die saubere Lösung nur aufwendiger als gedacht, ist das kein
  Stopp, sondern eine Abweichung.
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
- **Nie pushen, nie ältere Historie ändern** (kein Amend, kein Rebase).
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
Tree?, (3) beim ersten unerledigten Substep weitermachen; erledigte Arbeit nicht
wiederholen.

## 1. Plan laden

- Die Feature-Datei lesen: Erfassung, Spezifikation (Abnahmekriterien, Randfälle,
  Nicht-Ziele, Tests, Entscheidungen), Plan mit Substeps, Verlauf.
- **Maßstab laden:** die `CODING-STANDARDS.md` des Projekts lesen; sie gilt, auch wo sie
  von der Vorlage abweicht. Fehlt sie, gelten als Ersatz die Abschnitte Mindset, Control
  flow und Secure coding der Vorlage
  `${CLAUDE_PLUGIN_ROOT}/template/core/CODING-STANDARDS.md` — einmal sagen, dass dieser
  Ersatz gilt. Mit Projektdatei wird die Vorlage nicht zusätzlich herangezogen.
- Unerledigte Abhängigkeiten (`depends-on`, Status nicht `DONE`) → stoppen und melden,
  nicht drumherum bauen.
- **Status prüfen** (Kopfblock): `BACKLOG` heißt nicht geplant → zuerst
  `/coding-kit:prep-step` empfehlen, nicht ungeplant losbauen (steht schon eine
  Spezifikation, fehlt nur der Plan). `PLANNED` → bauen. `IN-PROGRESS` → beim ersten
  Substep ohne Verlauf-Eintrag weitermachen. `DONE`, `DROPPED`, `SUPERSEDED` → nicht
  bauen; Folgearbeit bekommt eine neue Nummer.

## 2. Umsetzung — je Substep

Substeps sind nur die Überschriften `F-NNNa`, `F-NNNb` … im Plan. Ein Feature ohne sie
(Größe S: der Plan in Stichpunkten) ist **ein einziger Schritt** — alle Stichpunkte
umsetzen, dann einmal abschließen; die Stichpunkte sind keine Substeps.

1. Substep-Ziel und Abnahmekriterien kurz nennen.
2. Umsetzen — Code-Kommentare/Docstrings in der Kommentar-Sprache des Projekts
   (Languages-Block der CLAUDE.md; ohne Block englisch). **Write-then-Verify:** nach
   jedem Edit die Datei re-lesen; nichts als erledigt melden, was nicht per
   Tool-Ausgabe belegt ist.
3. Checks stack-agnostisch über die just-Standardrezepte (`just check`, gezielt
   `just test` / `just lint`); ohne justfile die projektüblichen Checks aus
   CLAUDE.md/README. Rot → sofort fixen, nie rot weiterarbeiten.
4. **Selbst-Review** des Diffs gegen den Maßstab (Abschnitt 1) — fünf Prüffragen:
   - **verständlich:** Versteht jemand, der neu im Code ist, die Änderung ohne deine
     Erklärung?
   - **einfach:** Ist es die einfachste tragfähige Lösung, ohne Abstraktion auf Vorrat?
   - **sicher:** Eingaben an Vertrauensgrenzen geprüft, keine Injection, Zugriffe
     berechtigt, keine Secrets?
   - **lesbar:** menschenlesbarer Quelltext, nie minifiziert oder auf eine Zeile gepresst
     (auch JSON, CSS, Konfiguration)? Minifiziertes aus einem Build-Werkzeug ist kein
     Fund, von Hand bearbeitetes schon — im Zweifel melden statt umformatieren.
   - **kein Workaround:** keine Umgehung, kein `HACK`, kein „später richtig"?

   Fragen ohne Bezug entfallen (etwa „sicher" bei einem Tippfehler), „lesbar" gilt
   immer. Funde beheben und die Checks erneut laufen lassen; ein Substep mit offenem Fund
   ist nicht fertig. Das Ergebnis in einer Zeile nennen, mit dem Maßstab darin:
   „Selbst-Review gegen die `CODING-STANDARDS.md`: …" bzw. „Selbst-Review gegen den
   Ersatz aus der Vorlage (Mindset, Control flow, Secure coding): …".
5. Die Abnahmekriterien des Substeps einzeln gegen Tool-Ausgaben prüfen und je
   Kriterium den Beleg nennen (Test, Check, Befehl).
6. **Substep abschließen:** step-done *nicht* automatisch starten. Den Substep als
   gebaut-und-verifiziert melden und `/coding-kit:step-done` **empfehlen** — du prüfst
   und passt ggf. an, bevor der Schritt wirklich fertig ist.

Dann der nächste Substep, bis die Aufgabe komplett ist — jeweils erst nach deinem
Abschluss des aktuellen Substeps bzw. ausdrücklichem „weiter".

## 3. Abschluss

Kurzes Fazit: was gebaut wurde, Abweichungen vom Plan (mit Begründung), welche neuen
Ideen aufgetaucht sind. Als DONE verbucht die F-Nummer dein abschließendes step-done.
