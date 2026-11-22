---
id: F-081
title: Index-Prüfung genauer machen und die H1 am Titel ausrichten
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-081 — Index-Prüfung genauer machen und die H1 am Titel ausrichten

## Erfassung

**Problem:** `features-index.sh check` lehnt gültige Indizes ab und lässt gleichzeitig
Regelverstöße durch.

**Ziel:**
- **Ist:**
  - Jede geschlossene F-Nummer im Text der empfohlenen Reihenfolge gilt als Fehler, auch
    in einer Begründung („Fund aus F-…“) und in einem Projektabschnitt zwischen der
    Reihenfolge und den Tabellen.
  - `created` nach `done` und ein Status-Wort am Ende des Titels fallen nicht auf.
  - Ändert sich der Titel, bleibt die H1 alt, und niemand bemerkt es.
  - Von Hand umbrochene Punkte der Reihenfolge werden nach dem Verlinken ungleichmäßig.
- **Soll:** Geprüft wird, was die Regeln sagen, nicht mehr und nicht weniger.

**Lösungsskizze:**
- Geprüft werden nur die Nummern am Anfang eines Punkts oder Strangs, also vor der
  Begründung. Die Reihenfolge endet an der nächsten `##`-Überschrift. MANIFEST
  § Features sagt, wo Projekttext im Index stehen darf.
- Neue Prüfungen:
  - `created` ≤ `done`
  - kein Status-Wort am Ende des Titels
  - die H1 lautet `# <id> — <title>`. `write` gleicht sie an, denn sie ist abgeleitet wie
    die Tabelle.
- Der `index-head` empfiehlt einen Punkt je Zeile. `write` bricht keinen Text des
  Nutzers um.
- Optional: Abschnitte einer Feature-Datei melden, die `F-000` nicht kennt.

**Abhängigkeiten:** keine. Das Kit nutzt das Skript selbst.
