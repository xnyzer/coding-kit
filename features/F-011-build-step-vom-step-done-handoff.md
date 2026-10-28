---
id: F-011
title: build-step vom step-done-Handoff entkoppeln
type: feature
status: DONE
size:
created: 2026-07-14
done: 2026-07-14
depends-on:
superseded-by:
---

# F-011 — build-step vom step-done-Handoff entkoppeln

## Verlauf

### F-011 — build-step vom step-done-Handoff entkoppeln (2026-07-14)

**Was entstanden ist (Plugin 0.7.0):**

- **Anlass (Nutzer-Beobachtung, aus einem update-conventions-Lauf in einem Downstream-Projekt):**
  build-step ließ je Substep *immer* step-done laufen. Unerwünscht bei interaktiver
  Einzelarbeit — der Nutzer will vor dem Abschluss selbst prüfen und ggf. anpassen; das
  automatische Durchlaufen soll nur im autonomen `/goal`-Lauf über mehrere Subfeatures
  gelten.
- **Modus-Split in build-step:** Neuer expliziter Erkennungssatz im Kopf von „2.
  Umsetzung" — aktiver `/goal`-Lauf mit erteilter Commit-Freigabe = **autonom**, jede
  andere Nutzung = **interaktiv**. Schritt 5 verzweigt: interaktiv wird step-done nur
  **empfohlen** (nächster Substep erst nach Nutzer-Abschluss bzw. „weiter"), autonom
  läuft step-done je Substep automatisch wie bisher (die `/goal`-Abschlussbedingung
  verlangt es). Description, Loop-Satz und Abschluss-/DONE-Markierung entsprechend
  nachgezogen.
- **Begleitanpassungen:** plugin.json 0.7.0, CHANGELOG-Eintrag, README (build-step-
  Tabellenzeile + Zyklus-Prosa: step-done ist interaktiv ein bewusster eigener Schritt).
- **Entscheidung:** Unterscheidungssignal ist der laufende `/goal`-Kontext + die
  laufbezogene Commit-Freigabe, nicht ein neues Argument — kein Bruch am `/goal`-Flow,
  dessen Abschlussbedingung step-done ohnehin explizit nennt.
- **Nicht hierher (in project-template notiert):** MANIFEST listet `core/private/README.md`
  ohne existierende Datei (Template-Bug); dessen reichere AI-DISCLOSURE ist noch nicht
  als promote/override entschieden.
