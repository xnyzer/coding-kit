---
id: F-091
title: Migrationsprotokoll und Kit-Vorschläge nach jedem Abgleich schreiben
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-091 — Migrationsprotokoll und Kit-Vorschläge nach jedem Abgleich schreiben

## Erfassung

**Problem:** Nach einem Lauf von update-conventions bleibt nur der Commit. Was übernommen,
was behalten und was zurückgestellt wurde und warum, steht verstreut im Gesprächsverlauf
und geht mit der Session verloren. Vorschläge fürs Kit, die ein Lauf findet, stehen nur
im Chat. Bisher hat der Nutzer beides je Migration von Hand angefordert, mit wechselndem
Namen, Ort und Aufbau.

**Ziel:** Als Nutzer möchte ich für jeden Abgleich ein eigenes Protokoll und eine
fortgeführte Liste der Kit-Vorschläge mit festem Namensschema in `private/` haben, damit
ich jede Entscheidung samt Grund je Lauf nachlesen und die Vorschläge dem Kit übergeben
kann.

**Lösungsskizze:**
- Wann: am Ende jedes Laufs, der ein Projekt anfasst (Abgleich, Migration,
  Dokumentmodell, Host-Wechsel, `revise`), auch ohne Änderungen, und bei einem
  abgebrochenen Lauf mit dem Stand bis dahin. `status` schreibt nichts, `global` allein
  hat kein Projekt. Bei `alle` bekommt jedes Projekt seine Dateien.
- Wo, im Ordner `private/template-migration/` mit festem Namensschema:
  - `log-JJJJ-MM-TT-<von>-to-<nach>.md` — ein Protokoll je Lauf, nie überschrieben.
    `<von>` ist der Stempel vor dem Lauf (`none` ohne Stempel), `<nach>` die Version,
    auf die der Lauf hebt. Ein zweiter Lauf mit gleichem Namen bekommt `-2`.
  - `proposals.md` — Kit-Vorschläge, fortgeführt.
  - Den Vergleich mit dem Template legt F-092 in denselben Ordner.
- Vor dem Schreiben prüft `git check-ignore`, dass der Ordner ignoriert ist; sonst nicht
  schreiben und melden. Keine Werte von Secrets, nur Pfade und Namen.
- Jede Datei beginnt mit einem Kopfblock aus `feld: wert`-Zeilen:
  - Protokoll: Datum, Version vorher und nachher (Stempel), Plugin-Version des Laufs,
    Art des Laufs, vollständig oder abgebrochen, Modul, Fragmente, Host, Sichtbarkeit,
    Commit vor dem Lauf, Ergebnis von `just check`, Dateiname des vorigen Protokolls.
  - Vorschläge: Datum der letzten Änderung, Version vorher und nachher des Laufs, der sie
    zuletzt geändert hat, Zahl der Vorschläge.
- **Protokoll:** was der Lauf je Ziel, Zone und Fragment getan hat (Template übernommen,
  Projekt behalten, zusammengeführt, Hunk zurückgestellt, neu, entfernt, übersprungen),
  jede Entscheidung mit Begründung und wer entschieden hat (Nutzer, Default, Skript).
  Getrennt davon, wo das Template für das Projekt konkretisiert wurde
  (`template:adapt`, Platzhalter, optionale Blöcke) und wo ein Override oder eine
  Registry-Zeile entstand. Dazu „nicht diesmal“-Antworten, die Meldungen der Skripte und
  Prüfungen, abgebrochene Schritte und offene Fragen. Nur Protokoll: keine Empfehlungen,
  keine Änderung am Projekt außer den Dateien.
- Der Skill notiert Entscheidungen und Funde fortlaufend während des Laufs, damit sie eine
  Verdichtung des Kontexts in langen Läufen überstehen.
- **Kit-Vorschläge:** Quellen sind Abweichungen, die eine Lücke im Template oder einen
  Fehler im Kit zeigen, und Funde des Laufs, etwa eine Anweisung des Skills, die nicht
  passte, oder ein Skript, das sich falsch verhielt. Je Vorschlag ein Abschnitt mit
  Titel, Kategorie, Fundort, Datum und Kit-Version und einem Text im Format von
  propose-to-template: verallgemeinert, ohne Projektnamen und Personendaten, in der
  Sprache des Kits. Ein Lauf fügt neue Vorschläge an und trägt keinen doppelt ein. Der
  Nutzer übergibt die Datei und entfernt danach die übergebenen Abschnitte. Einen
  Vorschlag, den das Template inzwischen selbst enthält, entfernt der Lauf und nennt ihn
  im Protokoll.
- Sprache des Protokolls: die Antwortsprache des Nutzers.
- Den vollständigen Vergleich mit dem Template und die Frage danach am Ende des Laufs
  bringt F-092.
- Verworfen:
  - Ein einziges Protokoll, das jeder Lauf ersetzt. Die Läufe sollen einzeln nachlesbar
    bleiben; den Gesamtstand zeigt der Vergleich aus F-092.
  - Die Vorschläge im Protokoll. Das Protokoll bleibt frei von Empfehlungen, und die
    Vorschläge überdauern mehrere Läufe.
  - Die Dateien unter `docs/` versionieren. Sie können private Inhalte nennen und sind
    Arbeitslisten für den Nutzer, keine lebende Doku.

**Abhängigkeiten:** keine. Nimmt die Ergebnisse aus F-068 (Nachweis), F-070
(zurückgestellte Hunks) und F-075 (Zonen) auf, sobald es sie gibt.

**Noch zu analysieren:** `private/` ist nicht versioniert, die Dateien liegen also nur
auf dem Rechner des Laufs. Ob das reicht.
