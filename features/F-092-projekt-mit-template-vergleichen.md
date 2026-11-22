---
id: F-092
title: Projekt jederzeit vollständig mit dem aktuellen Template vergleichen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on: F-091
superseded-by:
---

# F-092 — Projekt jederzeit vollständig mit dem aktuellen Template vergleichen

## Erfassung

**Problem:** Den ganzen Abstand eines Projekts zum aktuellen Template zeigt kein Bericht.
`status` vergleicht mit dem Snapshot, also dem Template des letzten Laufs (bei „diesmal
nicht“ einem noch älteren), und der Merge meldet nur, was das Template seit der Basis
geändert hat. Was frühere Läufe behalten haben, was aus alten Template-Versionen stammt
und was in Projekten liegt, die nie auf dem Template gestartet sind, bleibt unsichtbar.
Wer ein Projekt ganz angleichen will, findet diese Abweichungen nicht.

**Ziel:** Als Nutzer möchte ich ein Projekt jederzeit vollständig mit dem aktuellen
Template vergleichen lassen, unabhängig von seiner Vorgeschichte, damit ich es gezielt
ans Template angleichen und in Sonderfällen das Template anpassen lassen kann. Der
neueste Vergleich genügt, ohne ältere nachzupflegen.

**Lösungsskizze:**
- Ein eigener Plugin-Skill (Arbeitsname `compare-template`), nur lesend. Er schreibt nur
  `private/template-migration/comparison.md`, die jeder Vergleich ersetzt, und neue
  Einträge in die Vorschlagsdatei aus F-091. Aufrufbar jederzeit, auch ohne Migration.
- **Frage am Ende von update-conventions:** Nach jedem Lauf fragt der Skill, ob der
  Vergleich laufen soll. Die Frage hat keine Vorauswahl, ohne ausdrückliches Ja läuft er
  nicht. Bei `alle` kommt eine Frage am Ende, in der der Nutzer die Projekte wählt.
- **Mechanik im Skript, Beschreibung durch einen Agenten:**
  - Das Skript erzeugt den mechanischen Teil: einen frischen Render des aktuellen
    Templates mit den Antworten des Projekts und den direkten Vergleich damit
    (`status --base <soll>`), ohne Snapshot, Basis oder Merge-Klassen. Dazu Zonen,
    Fragmente, Registry, Erkennung, Lock-Prüfung, Altlasten und projekteigene Dateien in
    Template-Bereichen. Fehlen die Antworten, werden sie wie in der Vorschau von `status`
    abgeleitet und als abgeleitet markiert.
  - Ein Plugin-Agent mit frischem Kontext, wie der Reviewer von step-done und nur mit
    lesenden Werkzeugen, liest diese Ausgaben, die betroffenen Projektdateien, den
    vorigen Vergleich und die Protokolle der Läufe. Er schreibt Beschreibung, Grund,
    Kategorie und Verlust je Abweichung. Der Skill schreibt die Datei. So bleibt der
    Kontext des Migrationslaufs klein, und der Vergleich hängt nicht an dessen
    Entscheidungen.
  - Unveränderte Abweichungen übernehmen Beschreibung und Grund aus dem vorigen
    Vergleich. Neu beschrieben werden nur neue oder geänderte, deshalb ist der erste
    Vergleich eines alten Projekts der teure.
- Inhalt:
  - Managed Dateien: die ganze Datei gegen den Render, mit Umfang und kurzer
    Beschreibung jeder Abweichung.
  - Seed-Dateien: jede Zone (gleich, weicht ab, `override`, `unmarked`, fehlt). Inhalt
    außerhalb der Zonen gehört dem Projekt und wird nur mit seinem Umfang genannt.
  - Standards-Slot: je Fragment gleich, abweichend, projektlokal oder laut Erkennung
    fehlend.
  - Ziele, die das Template rendert und das Projekt nicht hat, auch über `skip`.
  - Altlasten: Ziele aus MANIFEST § Removed and renamed targets, alte Formate
    (`PROGRESS.md`, `instructions.md`) und projekteigene Dateien in Bereichen, die das
    Template verwaltet (`.github/`, `.claude/`, `scripts/`, Werkzeug-Configs), etwa eine
    zweite CI. Die Tabelle beginnt erst mit 2.0.0, ältere Reste findet nur dieser Blick.
  - Vertrag: Pflicht-Rezepte des justfile, Toolchain in `mise.toml` und `mise.lock`,
    Hooks. Stempel und Antworten gegen die Erkennung (Modul, Fragmente, Host).
  - Registry: Zeilen ohne Abweichung, Abweichungen ohne Zeile, die Rules-Zeilen.
  - Konkretisierungen (`template:adapt`, Platzhalter, optionale Blöcke) stehen getrennt
    von den Abweichungen.
  - Jede Abweichung mit Ort (Datei, Zone, Abschnitt oder Hunk), Art (Override, `keep`,
    `skip`, `adapt`, unregistriert, Altlast, projekteigen), Grund mit seiner Herkunft
    (Registry, Protokoll eines Laufs, voriger Vergleich, unbekannt) und einer Kategorie:
    Projekt-Besonderheit, Lücke im Template, aus Zeit- oder Risikogründen
    zurückgestellt, Fehler im Kit (mit F-Nummer, wenn bekannt). Dazu, was das Template
    dort hätte und was beim Übernehmen verloren ginge.
  - Abweichungen der Kategorien „Lücke im Template“ und „Fehler im Kit“ trägt der Skill
    als Vorschläge in die Datei aus F-091 ein.
- Kopfblock aus `feld: wert`-Zeilen: Datum, Template-Version, gegen die verglichen wurde,
  Plugin-Version des Vergleichs, Stempel des Projekts, Antworten vorhanden oder
  abgeleitet, Modul, Fragmente, Host, Sichtbarkeit, Commit, auf dem verglichen wurde,
  Protokoll des Laufs, aus dem er gestartet wurde (oder ohne Lauf), Zahl der
  Abweichungen je Art, Datum des vorigen Vergleichs.
- Vor dem Schreiben prüft `git check-ignore`, dass die Datei ignoriert ist. Keine Werte
  von Secrets. Nur feststellen: keine Empfehlungen, keine Änderung am Projekt.
- Sprache: die Antwortsprache des Nutzers.
- Verworfen:
  - Eine Option in update-conventions oder ein Ausbau von `status`. Die beiden fragen,
    was der nächste Lauf ändert; der Vergleich fragt, wie weit das Projekt vom Template
    entfernt ist. In einem eigenen Skill ist „nur lesend“ Teil der Struktur, und
    update-conventions wird nicht noch größer (vgl. F-082).
  - Den Vergleich nach jedem Lauf von selbst starten. Er kostet beim ersten Mal viel,
    deshalb entscheidet der Nutzer je Lauf.
  - Den Vergleich aus den Merge-Ergebnissen oder dem Snapshot ableiten. Beide kennen nur
    den Abstand zur Basis, nicht zum aktuellen Template.
  - Den Skill mit `context: fork` statt eines Agenten. Das Kit nutzt das Feld nicht, weil
    offen ist, ob ein solcher Skill aus einem laufenden Skill heraus startet
    (`docs/skill-authoring.md`).
  - Protokoll und Vergleich in einer Datei. Der Vergleich ist die Arbeitsliste fürs
    Angleichen und soll nicht in den Einzelheiten eines Laufs untergehen.

**Abhängigkeiten:** F-091 (Vorschlagsdatei und Protokoll als Quelle der Gründe). Nimmt
die Prüfungen aus F-073 (Vertrag) und F-075 (Zonen) auf, sobald es sie gibt; in
Monorepos je Paket, sobald F-076 steht.

**Noch zu analysieren:**
- Ob update-conventions den Vergleich als Arbeitsliste nutzt und zurückgestellte
  Abweichungen von sich aus wieder anbietet, oder ob `revise` dafür eine Angleich-Runde
  bekommt.
- Wie der erste Vergleich Gründe aus Protokollen übernimmt, die vorher von Hand
  entstanden sind, mit wechselnden Namen und Aufbau.
- Welche Werkzeuge der Agent braucht, wenn er Diffs selbst bilden muss, und ob das Skript
  ihm dafür fertige Diffs liefert.
- Name des Skills.
