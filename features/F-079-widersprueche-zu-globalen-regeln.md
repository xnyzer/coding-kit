---
id: F-079
title: Widersprüche zu den globalen Kit-Regeln erkennen
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-079 — Widersprüche zu den globalen Kit-Regeln erkennen

## Erfassung

**Problem:** Projekt-Zonen, Auto-Memory-Notizen und die Harness können den globalen
Kit-Regeln widersprechen, ohne dass es auffällt. A5 hat so eine widersprüchliche Notiz in
den Graph übertragen. Commits tragen mal die Kit-Zeile, mal die modellspezifische Zeile
der Harness, auch im Kit selbst.

**Ziel:**
- **Ist:**
  - G5 prüft Widersprüche nur in der persönlichen `CLAUDE.md`. Eine Projektfassung von
    `claude-graphiti` mit „Graph-Eintrag nach jeder größeren Änderung“ fiel deshalb
    nicht auf.
  - A5 überträgt Einträge ungeprüft.
  - step-done § 5b nennt die Commit-Zeile, sagt aber nicht, dass sie die Zeile der
    Harness ersetzt.
- **Soll:** Widersprüche werden genannt, bevor etwas übernommen oder übertragen wird, und
  jeder Commit trägt die Kit-Zeile.

**Lösungsskizze:**
- Globale Regeln und step-done sagen ausdrücklich, dass die Kit-Zeile
  `Co-Authored-By: Claude <noreply@anthropic.com>` die Attribution der Harness ersetzt.
  Das gilt für jeden Commit, auch für Doku-Commits außerhalb von step-done.
- A2 Schritt 7: Meldet eine Projekt-Zone `differs` und berührt sie ein Thema der globalen
  Regeln (Graphiti, Commits, Sprache), weist der Skill auf mögliche Widersprüche zur
  gerenderten Kit-Datei hin.
- A5 Schritt 3 prüft jeden Eintrag gegen die gerenderten globalen Regeln. Bei einem
  Widerspruch fragt der Skill nach, statt zu übertragen.

**Abhängigkeiten:** keine. Der Doku-Commit aus F-080 folgt derselben Regel.
