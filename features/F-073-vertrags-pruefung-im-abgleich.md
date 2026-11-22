---
id: F-073
title: Abgleich prüft Toolchain, Pflicht-Rezepte und Standards-Slot
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-073 — Abgleich prüft Toolchain, Pflicht-Rezepte und Standards-Slot

## Erfassung

**Problem:** Der Abgleich setzt stillschweigend voraus, dass ein Projekt den Vertrag
erfüllt. Fehlt etwas, meldet er nichts oder bricht ab. So verlor eine `kept`-justfile die
Pflicht-Rezepte, und Skills, die `just features-index` aufrufen, wären gescheitert.

**Ziel:**
- **Ist:**
  - `lock-check` bricht ohne `mise.toml` mit Exit 1 ab und gibt keine Zeile aus, die
    sich auswerten lässt.
  - `detect` meldet ein deklariertes Fragment als `covered`, obwohl der Slot fehlt. Der
    Skill bietet Fragmente ohne Slot an und beschreibt nicht, wie man den Slot repariert.
  - Bei `keep` fehlen `features-index`, `bump-tools`, `license-check` und die
    Index-Prüfung in `check`, ohne dass es gemeldet wird.
  - A2 Schritt 11 verlangt `just check` und nennt keinen Ersatz, wenn es keine justfile
    gibt.
- **Soll:** Der Abgleich prüft den Vertrag ausdrücklich und meldet jede Lücke mit dem
  Weg, sie zu schließen.
- **Reproduzieren:**
  - Projekt ohne `mise.toml` → `lock-check`.
  - Projekt mit `keep`-Zeile für eine alte justfile → `merge` und Schritt 11.

**Lösungsskizze:**
- Eine Vertrags-Prüfung der justfile: Die Rezeptnamen werden gegen den Standard-Satz aus
  MANIFEST § Module contract geprüft, und `check` muss die Index-Prüfung und
  gegebenenfalls `license-check` aufrufen. Gemeldet wird bei `kept`/`keep` und in
  Schritt 11.
- `lock-check` gibt ohne `mise.toml` die Zeile `mise none` aus und endet mit 0.
- `detect` zählt ein Fragment nur mit Slot als `covered`. Der Skill prüft den Slot vor
  dem Angebot und beschreibt die Reparatur: das Markerpaar `module:coding-standards` als
  reinen Wrapper hinter den letzten Abschnitt setzen.
- Ohne justfile nennt Schritt 11 die eigenen Checks des Projekts als Ersatz, wie die
  globale Regel „falls vorhanden“.

**Abhängigkeiten:** keine.
