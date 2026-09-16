---
name: handoff
description: Schreibt am Kontextlimit einen kopierfertigen Handoff-Prompt für einen frischen Chat. Stellt die Orientierung voran (zuletzt, Stand, als Nächstes inkl. Reihenfolge-Vorgabe der Aufgabenliste) und übergibt sonst nur, was aus der Session noch nicht dokumentiert ist (Entscheidungen, Fallstricke, Absprachen, Offenes); für alles andere verweist er auf die Quelldateien. Baut und ändert nichts, projektunabhängig. Nur manuell per /coding-kit:handoff aufrufbar.
disable-model-invocation: true
disallowed-tools: Write, Edit, NotebookEdit
---

# Handoff-Prompt schreiben (/coding-kit:handoff)

Die Session ist am Kontextlimit. Schreibe einen Handoff-Prompt, den der Nutzer in einen
frischen Chat kopiert. **Nur Kontext übergeben — nichts bauen, nichts ändern, nichts
committen.** Den nächsten Befehl führt der Nutzer im neuen Chat selbst aus. Ziel: Der
neue Chat orientiert sich in Sekunden und es kann direkt weitergehen.

Optionaler Fokus: $ARGUMENTS

Ist $ARGUMENTS leer, **nicht nachfragen**, sondern direkt schreiben — jede Rückfrage
kostet Kontext, der gerade fehlt. Ist es gesetzt, gilt es als Schwerpunkt oder geplanter
nächster Schritt und bekommt im Handoff Vorrang.

## Grundsatz: übergeben, was sonst verloren geht

Maßstab für jede Zeile: **Würde der neue Chat ohne sie etwas falsch machen, doppelt tun
oder erneut fragen?** Wenn nein — weglassen.

- **Übergeben:** was nur im Gesprächsverlauf existiert — wo die Arbeit gerade steht und
  worauf sie wartet, Entscheidungen samt Begründung und verworfenen Alternativen,
  Erkenntnisse und Fallstricke, gescheiterte Ansätze (einzeilig, mit Grund), Absprachen
  und Korrekturen des Nutzers, halbfertige Arbeit, offene Fragen.
- **Verweisen statt kopieren:** was schon in Dateien, Git-Historie, CLAUDE.md oder
  Memory steht — Pfad nennen (bei Bedarf `datei:zeile` oder Abschnitt), Inhalt nicht
  wiederholen. Was in dieser Session in Dateien geschrieben wurde, gilt als dokumentiert.
- **Nie übergeben:** Secrets, Tokens, Passwörter (der Prompt wird herumkopiert);
  Code und Tool-Ausgaben in voller Länge; Erledigtes ohne Folgen für die weitere Arbeit.
- **Ehrlich bleiben:** nur, was in der Session belegt ist; Unsicheres als Annahme
  kennzeichnen. Wurde der Verlauf schon komprimiert, ist die Zusammenfassung die
  Quelle — Lücken benennen statt füllen.

## Vorgehen

1. **Stand prüfen — optional, höchstens ein Shell-Aufruf.** Nur für das, was aus dem
   Gespräch nicht sicher hervorgeht; beides in **einem** Aufruf bündeln:
   - Git-Repo: `git status --short && git log --oneline -5`.
   - Aufgabenliste des Projekts (aus CLAUDE.md oder Session bekannt, z. B.
     `PROGRESS.md`): nur Überschriften nach einer Reihenfolge-Vorgabe durchsuchen, z. B.
     `grep -niE -A2 '^#+ .*(reihenfolge|order)' PROGRESS.md` — Muster an die
     Doku-Sprache anpassen, die Datei nicht lesen.

   Sonst keine Tool-Aufrufe, keine Dateien lesen.
2. **Handoff schreiben** nach der Gliederung unten, in der Sprache des bisherigen
   Gesprächs.

## Gliederung

Abschnitte ohne Inhalt weglassen. Richtwert: **typisch bis ~150 Zeilen, nach kurzen
Sessions deutlich weniger** — die eigentliche Grenze ist der Maßstab oben, nicht die
Zahl.

**Orientierung zuerst** — kompakt, damit der neue Chat sofort weiß, wo es weitergeht:

1. **Einstieg** — ein Satz: Übernahme einer laufenden Session; Projekt und Branch.
2. **Ziel** — worum es in der Session ging (ggf. Aufgaben-/Ticket-Nummer).
3. **Zuletzt** — die letzte Aktion und was darauf wartet (offene Frage an den Nutzer,
   ausstehende Bestätigung, z. B. eine Commit-Frage).
4. **Stand** — erledigt / in Arbeit / nicht begonnen; uncommittete Änderungen je Datei
   mit Zweck und ob fertig oder halb.
5. **Als Nächstes** — erst der nächste Schritt im laufenden Vorgang, dann die nächste
   Aufgabe. Hat die Aufgabenliste eine **ausdrückliche Reihenfolge-Vorgabe** (eigene
   Überschrift oder Zeile, Wortlaut je Projekt verschieden): Fundstelle nennen, als
   verbindlich kennzeichnen und den nächsten Eintrag laut Vorgabe benennen — die
   Vorgabe nicht kopieren, die Datei bleibt maßgeblich. Ohne Vorgabe gilt die
   Reihenfolge der offenen Einträge in der Liste. Alles nur als Information — ausgeführt
   wird auf Anweisung.

**Hintergrund** — danach:

6. **Entscheidungen** — was entschieden wurde, warum, was verworfen wurde; mit dem
   Hinweis, sie nicht neu aufzurollen.
7. **Erkenntnisse & Fallstricke** — Ursachen, Eigenheiten der Umgebung, Sackgassen.
8. **Absprachen** — Vorgaben und Präferenzen des Nutzers aus dieser Session, die noch
   nirgends festgehalten sind.
9. **Offen** — ungeklärte Fragen und was noch dauerhaft dokumentiert werden sollte
   (wo — erledigt wird es erst auf Anweisung).
10. **Quellen** — höchstens ~5 Dateien, die für die weitere Arbeit maßgeblich sind; zu
    lesen, sobald die Arbeit sie berührt, nicht vorsorglich.
11. **Schlussanweisung (immer)** — sinngemäß: „Bestätige den Stand in 2–3 Sätzen und
    warte auf meine Anweisung; nichts bauen oder ändern, bevor ich es sage. Steht die
    Anweisung schon in dieser Nachricht, leg damit los."

## Ausgabe

- Genau **ein** Codeblock mit dem Prompt, außen mit **vier** Backticks umschlossen,
  damit innere Code-Schnipsel ihn nicht brechen — in einem Stück kopierbar.
- Davor höchstens eine Zeile („In einen neuen Chat kopieren:"), danach nichts.
- Pfade relativ zum Projekt-Root.
- Keine Schreibvorgänge, auch kein Memory-Update: Was dauerhaft festgehalten werden
  sollte, steht unter **Offen** — der neue Chat erledigt es auf Anweisung.
