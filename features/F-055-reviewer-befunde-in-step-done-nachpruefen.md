---
id: F-055
title: Reviewer-Befunde in step-done erst nachprüfen, dann übernehmen
type: fix
status: DONE
size: S
created: 2026-11-03
done: 2026-11-03
depends-on:
superseded-by:
---

# F-055 — Reviewer-Befunde in step-done erst nachprüfen, dann übernehmen

## Erfassung

**Problem:** step-done verlangt nach dem unabhängigen Review nur „Befunde bewerten:
beheben oder mit Begründung verwerfen“, sagt aber nicht, wie bewertet wird. Ein Befund
des Reviewers klingt wie ein Urteil und wird leicht ungeprüft übernommen — obwohl der
Reviewer absichtlich ohne Gesprächskontext arbeitet und deshalb danebenliegen kann. Die
Bewertung durch den Haupt-Agenten ist die Sicherung dagegen; F-037 hat das Verwerfen nie
in einem Lauf erprobt.

**Ziel:**
- Ist: Ein Befund wird übernommen, ohne ihn am Code nachzuprüfen — in F-032a die
  Streichung eines Eintrags aus einer Liste, obwohl zwei andere Einträge in derselben
  Lage waren.
- Soll: Jeder Befund wird zuerst selbst am Code nachgeprüft — trifft er zu, gilt
  dasselbe für vergleichbare Stellen, ist der Maßstab der richtige? Übernommen wird nur,
  was der Prüfung standhält; sonst wird er mit Grund verworfen.
- Reproduzieren: step-done an einem Schritt, dessen Reviewer-Befund an einer Stelle
  zutrifft, an einer vergleichbaren aber nicht.

**Lösungsskizze:**
- step-done, Unabhängiges Review, Punkt „Befunde bewerten“: die Nachprüfung ausdrücklich
  verlangen — am Code, mit Blick auf vergleichbare Stellen; die Befundliste nennt je
  Befund, worauf die Entscheidung beruht.
- Reviewer-Agent: ein Satz, dass ein Befund vergleichbare Stellen gleich behandelt (gilt
  er für eine Stelle, gilt er für alle gleichartigen — oder für keine).
- HOW-TO im Template (Abschnitt zu step-done) prüfen und bei Bedarf nachziehen.

**Abhängigkeiten:** keine (F-037 erledigt).

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben der Reviewer meldet Befunde, wenn step-done sie bewertet, dann
  prüft der Haupt-Agent jeden zuerst selbst am Code nach: Trifft er an der Stelle zu?
  Gilt er für gleichartige Stellen genauso — dann alle beheben —, oder ist eine Stelle
  anders, und warum? Ist die angeführte Grundlage (Kriterium, Regel des Maßstabs,
  Entscheidung) die richtige? Was der Prüfung nicht standhält, wird mit Grund verworfen.
  HOW-TO, README und die Beschreibung von step-done sagen das in einem Halbsatz —
  belegt: step-done § Unabhängiges Review Punkt 3 und Beschreibung im Kopfblock,
  HOW-TO § What `/step-done` does Punkt 1 und README-Zeile zu step-done gelesen;
  `just check` grün.
- [x] AC-2 — Gegeben die Befundliste für die Vorschau, dann nennt sie je Befund Stelle,
  Art, Entscheidung (behoben, teils behoben, verworfen) und worauf die Entscheidung
  beruht — auch bei behobenen, etwa „am Code bestätigt; gleiche Lage in X mitbehoben“ —
  belegt: step-done § Unabhängiges Review Punkt 4 gelesen.
- [x] AC-3 — Gegeben der Reviewer findet einen Fehler an einer Stelle, dann nennt er
  gleichartige Stellen im berührten Code im selben Befund mit, statt eine
  herauszugreifen — ein Befund gilt für alle gleichartigen Stellen oder für keine —
  belegt: `agents/reviewer.md` § Vorgehen gelesen.

### Randfälle

- EC-1 — Ein Befund trifft an einer Stelle zu, an einer scheinbar gleichartigen nicht →
  dort beheben, wo er zutrifft; Entscheidung „teils behoben“, mit dem Unterschied als
  Grund.
- EC-2 — Ein Befund widerspricht einer Entscheidung aus dem Gespräch, die nicht in der
  Feature-Datei steht (der Reviewer kann sie nicht kennen) → verworfen mit Verweis auf
  die Entscheidung; sie kommt mit der Verbuchung in die Feature-Datei.

### Nicht-Ziele

- Kein zweiter Reviewer-Lauf und kein eigener Prüf-Agent für die Befunde — die
  Nachprüfung macht der Haupt-Agent (F-037: ein Lauf je Schritt).
- Das Antwortformat des Reviewers bleibt gleich.

### Tests

- AC-1 bis AC-3: manuell — die geänderten Stellen gelesen: step-done § Unabhängiges
  Review Punkt 3 und 4 samt Beschreibung, `agents/reviewer.md` § Vorgehen, HOW-TO
  § What `/step-done` does, README-Zeile zu step-done.
- Praxis: Der nächste step-done-Lauf mit Befunden (voraussichtlich F-032b) zeigt die
  Grundlage je Befund — Bewährung, keine Bedingung für `DONE`.
- Dazu `just check` und die Versionsregel.

### Einbettung

Den Reviewer nutzt nur step-done. Berührt: step-done (Punkt 3 und 4, Beschreibung im
Kopfblock), der Agent, die HOW-TO im Template (deshalb `### Template` im CHANGELOG), die
README-Skilltabelle. Version 3.3.0 ist noch nicht gepusht — der Eintrag dort wird
ergänzt, kein neuer Bump. Keine Datei neu oder umgewidmet, das MANIFEST bleibt. Kein ADR.

## Plan

**Größe:** S — fünf Dateien mit je ein bis drei Sätzen, die Lösung liegt auf der Hand.
Formal reicht es als Vorlage in alle Projekte (L-Signal), es ist aber nur eine
Klarstellung im Text ohne geänderten Ablauf.

- Umsetzung über `/add-skill` (Plugin-Skill und Agent ändern sich).
- step-done § Unabhängiges Review, Punkt 3 wird „Befunde nachprüfen und bewerten“: die
  drei Prüffragen aus AC-1, dazu EC-1 und EC-2. Punkt 4: Grundlage je Befund,
  Entscheidung um „teils behoben“ erweitert.
- `agents/reviewer.md` § Vorgehen, beim Satz „Nur Befunde mit Grundlage melden“: der
  Satz zu gleichartigen Stellen (AC-3).
- HOW-TO § What `/step-done` does, Punkt 1: Jeder Befund wird zuerst am Code
  nachgeprüft — auch an gleichartigen Stellen —, dann behoben oder mit Grund verworfen.
- README-Zeile und Beschreibung von step-done: „Befunde am Code nachgeprüft, behoben
  oder mit Grund verworfen“.
- CHANGELOG 3.3.0: ein Punkt zu F-055 und ein Abschnitt `### Template` für die HOW-TO;
  `plugin.json` bleibt 3.3.0.

## Verlauf

### F-055 — fertig 2026-11-03

**Umgesetzt:**

- step-done, Unabhängiges Review: Punkt 3 heißt „Befunde nachprüfen und bewerten“. Jeder
  Befund wird am Code nachgeprüft — trifft er zu, gilt er für gleichartige Stellen
  genauso, trägt seine Grundlage? —, dann behoben, teils behoben oder verworfen. Ein
  Befund gegen eine Entscheidung, die nur im Gespräch fiel, wird verworfen, die
  Entscheidung kommt in den Verlauf. Punkt 4 nennt je Befund, worauf die Entscheidung
  beruht.
- Reviewer-Agent: gleichartige Stellen kommen in denselben Befund.
- HOW-TO, README und die Beschreibung von step-done sagen das in einem Halbsatz;
  CHANGELOG 3.3.0 mit Abschnitt `### Template`.

**Entscheidungen:** keine über die Spezifikation hinaus.

**Abweichung vom Plan:** Der Reviewer sagt zusätzlich in einem Halbsatz, warum eine
scheinbar gleichartige Stelle anders ist.

**Funde:** Unabhängiges Review ohne Befunde; keine neuen Aufgaben. Der Abschluss lief noch
mit dem installierten step-done; den neuen Punkt 3 erprobt erst ein Lauf mit dem neuen
Stand.
