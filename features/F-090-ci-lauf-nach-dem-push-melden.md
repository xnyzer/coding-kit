---
id: F-090
title: Nach jedem Push den CI-Lauf abwarten und das Ergebnis melden
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-090 — Nach jedem Push den CI-Lauf abwarten und das Ergebnis melden

## Erfassung

**Problem:** Ein grünes `just check` vor dem Commit sagt nichts über die CI, die auf einem
frischen Checkout läuft. In einem Downstream-Projekt war `main` acht Tage rot: Lokal lag
ein altes Build-Ergebnis im Arbeitsbaum, die CI hatte es nicht, und nach dem Push sah
niemand in den Lauf.

**Ziel:** Als Nutzer möchte ich nach jedem Push erfahren, ob die CI grün ist, damit ein
roter `main` sofort auffällt und nicht erst beim nächsten Push.

**Lösungsskizze:**
- Eine globale Regel im Abschnitt Git der Kit-Regeln: Nach jedem Push den Lauf abwarten
  oder im Hintergrund beobachten und das Ergebnis melden. Bei Rot ins Log sehen und die
  Ursache nennen, nicht nur die Farbe.
- Das gilt nur, wenn der Host eine CI hat und sie per CLI erreichbar ist: GitHub über
  `gh`, Azure DevOps über `az`. Bei Host `git` entfällt die Regel. Für die Releases des
  Kits steht der Schritt schon im Release-Ablauf der CLAUDE.md.
- Verworfen: ein Schritt am Ende von step-done, wie vorgeschlagen. step-done pusht nie;
  gepusht wird nur auf Bitte des Nutzers und damit außerhalb der Skills.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Ob ein Hook nach `git push` die Regel absichert, statt nur auf sie zu vertrauen.
- Wie lange die Session wartet und was bei einem sehr langen Lauf passiert.
