---
id: F-066
title: Releases per GitHub-Workflow beim Tag-Push anlegen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on: F-065
superseded-by:
---

# F-066 — Releases per GitHub-Workflow beim Tag-Push anlegen

## Erfassung

**Problem:** Seit F-065 bekommt jede Version ab 1.0.0 einen Tag `vX.Y.Z` und ein
GitHub-Release. Das Release legt ein eigener Schritt nach dem Push des Tags von Hand an;
wird er vergessen oder bricht er ab, fehlt das Release, und niemand merkt es.

**Ziel:** Als Pfleger des Kits möchte ich, dass ein gepushter Tag `vX.Y.Z` sein
GitHub-Release selbst bekommt, damit kein Release fehlt und sein Text immer aus dem
CHANGELOG des getaggten Stands stammt.

**Lösungsskizze:**
- Ein Workflow, ausgelöst vom Push eines Tags `v*`: Er liest den Abschnitt der Version
  mit `scripts/release-notes.sh` aus dem CHANGELOG des getaggten Commits und legt das
  Release mit `gh release create` an, ohne eigenen Titel.
- Gibt es das Release schon, überspringt er es; ist die Version nicht datiert oder fehlt
  sie, schlägt er fehl.
- Schreibrecht (`contents: write`) nur für diesen Job; die CI behält `contents: read`.
  Die Action ist per SHA gepinnt, Renovate hält sie aktuell.
- Der Release-Ablauf in der Kit-CLAUDE.md verkürzt sich entsprechend.
- Alternative: nur eine Prüfung in der CI, die eine datierte Version ohne Tag oder
  Release meldet — ohne Schreibrecht, aber nur als Erinnerung.

**Abhängigkeiten:** F-065.

**Noch zu analysieren:**
- Entfällt Schritt 4 in der CLAUDE.md ganz, oder bleibt er als Rückweg, wenn der
  Workflow scheitert?
- Wie eng lässt sich das Schreibrecht fassen?
- Wie lässt sich der Workflow prüfen, ohne ein echtes Release zu erzeugen?
- Ein Release für eine ältere Version (etwa ein Patch auf einem alten Stand) darf nicht
  „Latest“ werden.
