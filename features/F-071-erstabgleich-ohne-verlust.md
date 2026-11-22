---
id: F-071
title: Erstabgleich von Bestandsprojekten ohne Verlust führen
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-071 — Erstabgleich von Bestandsprojekten ohne Verlust führen

## Erfassung

**Problem:** Beim ersten Abgleich eines Projekts ohne Basis (A3, zweiwegig) gibt es je
Datei nur „ganz Template“ oder „ganz Projekt“. Hätte man in einem Projekt übernommen,
wären CI-Jobs, Linter-Regeln, `*.pem` und `*.key` in `.gitignore` und die
Bedrohungsszenarien in `SECURITY.md` verloren gegangen. Außerdem läuft der erste Merge,
bevor die alte Registry überführt ist, sodass `keep` dort noch nicht greift.

**Ziel:**
- **Ist:**
  - `two-way` wird wie `template-only` behandelt (übernehmen, diesmal nicht, dauerhaft
    ablehnen). Abgelehnte Dateien kommen in jedem Lauf wieder.
  - In A3 wird die Registry erst in Schritt 3 überführt. Das Skript liest die
    Alt-Tabelle nicht und meldet das auch nicht.
- **Soll:** Ein Erstabgleich bringt jede Datei auf den Stand des Templates und behält die
  Inhalte, die nur das Projekt hat. Die Registry gilt ab dem ersten Merge.
- **Reproduzieren:**
  - Projekt ohne Stempel mit eigener CI und erweiterter `.gitignore` → A3, Variante (b).
  - Projekt mit Alt-Registry und einer `keep`-Zeile für die justfile → Der erste Merge
    meldet `conflict` statt `kept`.

**Lösungsskizze:**
- Für `two-way` eine Wahl „auf das Template umziehen“:
  - Der Skill listet auf, was nur das Projekt hat, schlägt für jeden Zusatz einen eigenen
    Block vor, registriert die Abweichung und setzt den Snapshot. Danach mergt das Skript
    dreiwegig.
  - Bei „übernehmen“ zeigt der Skill ausdrücklich, was verloren geht.
  - Ein Projekt ist genau diesen Weg schon erfolgreich von Hand gegangen.
- Für Dateien, die nur eine Menge von Zeilen sind (`.gitignore`), eine Merge-Art
  „Vereinigung“, die das MANIFEST je Ziel festlegt.
- A3 überführt die Registry vor dem ersten Merge. `merge`, `status` und `zones` melden
  ein altes Registry-Format.
- A3 Schritt 2:
  - Variante (b) samt ihren Folgen erklären und (a) empfehlen, sobald ein Stempel da ist.
  - Dokumentieren, was heute nur im Skript steht: Stempel unter 1.0.0 laufen über die
    importierte Historie, `manifest-format: 1` rendert, und es braucht einen vollen Klon
    statt des Plugin-Caches.
  - Fehlt der Checkout, nennt `base-from-history` den Klonbefehl. Es warnt außerdem, wenn
    sich gerenderte Ziele zwischen Commits derselben Version unterscheiden.
- Dateien, die das Projekt nie hatte, heißen `never-had` statt `missing`. A3 Schritt 1
  sagt, woher `YEAR` kommt.
- Verworfen: `conflict` mit leerer Basis. diff3 macht daraus einen einzigen Block über die
  ganze Datei.

**Abhängigkeiten:** keine. Nah an F-070.

**Noch zu analysieren:**
- Wie der Skill Stellen für Zusätze vorschlägt, ohne Dateien selbst zusammenzuführen.
  Das verbietet der Grundsatz des Skills.
- Welche Ziele die Merge-Art „Vereinigung“ bekommen.
