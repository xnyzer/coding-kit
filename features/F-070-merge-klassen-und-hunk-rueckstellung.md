---
id: F-070
title: Merge-Klassen korrigieren und einzelne Hunks zurückstellen
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-070 — Merge-Klassen korrigieren und einzelne Hunks zurückstellen

## Erfassung

**Problem:** `merge` nennt einen sauberen Dreiwege-Merge `caught-up`, sobald das
Ergebnis dem Template gleicht, auch wenn die Projektdatei davon abweicht. Der Skill
übernimmt `caught-up` ohne Diff und trägt die Registry-Zeile aus. So kam eine
zurückgestellte Template-Zeile ungesehen ins Projekt. Ausgelöst wurde das, weil sich
nur ganze Dateien zurückstellen lassen, keine einzelnen Hunks.

**Ziel:**
- **Ist:**
  - `caught-up` wird nach `git merge-file` vergeben, ohne Vergleich mit dem Projekt.
  - Zurückstellen geht nur je Datei. Der Ausweg „Basis der Datei alt halten“ verfälscht
    `status` (+32/−6 statt einer Zeile). Außerdem meldet dann kein Lauf mehr Änderungen an
    Fragmenten ohne alte Basis.
  - `deviates` trennt Ergänzung nicht von Ersetzung. In einem Projekt enthielten fünf
    von sechs abweichenden Dateien das ganze Template und dazu eigene Zeilen, und für
    jede wurde eine Registry-Zeile angeboten.
- **Soll:** `caught-up` gibt es nur, wenn Projekt und Template gleich sind. Einzelne
  Hunks lassen sich zurückstellen und kommen im nächsten Lauf wieder. Reine Ergänzungen
  sind als solche erkennbar.
- **Reproduzieren:** ein Projekt, das einen Teil einer Template-Änderung schon hat →
  `merge` meldet `caught-up`, das Ergebnis enthält aber auch den Rest.

**Lösungsskizze:**
- `caught-up` nur bei Projekt = Template, sonst `merged` mit dem Hinweis, dass die
  Abweichung jetzt im Template steckt. Der Skill bekommt die Regel: Wo Projekt und
  Ergebnis verschieden sind, wird nie ohne Diff übernommen.
- Zurückstellen je Hunk: Die Datei wird auf den neuen Stand gesnapshottet, die
  zurückgestellten Hunks liegen mit Datum und Grund in einer eigenen Datei unter
  `.claude/template-base/`. Der nächste Merge bietet sie wieder an.
- Die Basis des Fragment-Slots hängt nicht mehr an der Basis der Datei.
- Eine Klasse `extends`, wenn der Diff Basis → Projekt nur aus hinzugefügten Zeilen
  besteht. Eine Registry-Zeile ist dafür freiwillig. Der Skill sagt klar, dass eine
  Registry-Zeile keine Datei ändert, sondern nur dokumentiert.
- Verworfen: eine Registry-Art `defer`. Die Registry hält dauerhafte Entscheidungen,
  eine Rückstellung ist vorübergehend.

**Abhängigkeiten:** keine. Nah an F-071, denn der Umzug auf das Template erzeugt genau den
Zustand `extends`. Baut auf dem erledigten F-041 auf.

**Noch zu analysieren:**
- Das Format der Datei mit den zurückgestellten Hunks.
- Wie `status` und der Backstop von step-done zurückgestellte Hunks zählen.
- Ob `extends` eine eigene Klasse wird oder ein Merkmal von `deviates`.
