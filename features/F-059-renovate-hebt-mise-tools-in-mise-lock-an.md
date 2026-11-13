---
id: F-059
title: Renovate hebt die mise-Tools in mise.lock an
type: fix
status: BACKLOG
size:
created: 2026-11-13
done:
depends-on:
superseded-by:
---

# F-059 — Renovate hebt die mise-Tools in mise.lock an

## Erfassung

**Problem:** Das Template trägt die Tools in `mise.toml` mit Hauptversion ein, die genaue
Version steht in `mise.lock`. Renovate hebt diese genaue Version nicht an: Die Tools
bleiben auf dem Stand, mit dem das Projekt angelegt wurde, bis jemand von Hand
`mise lock --bump` ausführt — auch gitleaks mit seinen Sicherheitsupdates. Das
widerspricht der Rahmenbedingung, dass Renovate die mise-Pins aktuell hält; F-031 ist
davon ausgegangen, dass Renovate `mise lock` ausführt.

**Ziel:**
- Ist: In einem Downstream-Projekt stehen just und lefthook Monate hinter der neuesten
  Version ihrer Hauptversion, Renovate schlägt nichts vor und hat `mise.lock` nie
  geändert. Ein lokaler Renovate-Lauf (lookup) erkennt bei `"go:…/v2" = "2"` mit
  gesperrtem 2.0.0 „nur Sperrdatei“, findet aber kein Update, obwohl 2.0.1 existiert.
- Soll: Neue Versionen innerhalb der Hauptversion kommen ohne Handarbeit an — gebündelt,
  höchstens wöchentlich, bei grüner CI automatisch gemergt. `mise.toml` behält die
  Hauptversionen.
- Reproduzieren: Projekt aus dem Template mit Renovate; ein Tool, dessen gesperrte
  Version älter ist als die neueste derselben Hauptversion → kein PR, kein Eintrag im
  Dashboard.

**Lösungsskizze:**
- Ziel: Renovates Lock File Maintenance im Preset (`mise lock --bump`, wöchentlich, ein
  PR für alle Tools, Automerge bei grüner CI). Gilt über das Preset auf jedem Host mit
  Renovate; Renovate muss dafür `mise` ausführen dürfen — auf GitHub entscheidet das der
  gehostete Dienst, auf anderen Hosts der Betreiber des Renovate-Laufs.
- Ohne Renovate (Host `git`): ein Rezept, etwa `just bump-tools`, das die Sperrdatei
  von Hand auffrischt.
- Ausweich, falls Renovate `mise` nicht ausführen darf: ein eigener wöchentlicher
  CI-Job — je Host verschieden, daher nur Notlösung.
- Verworfen: genaue Versionen in `mise.toml` für alle Tools — ein PR je Tool und
  Version, die Sperrdatei muss trotzdem mitgehen, und das Muster aller Projekte ändert
  sich.

**Abhängigkeiten:** keine.

**Noch zu analysieren (Spike zuerst):**
- Darf der gehostete Renovate-Dienst auf GitHub `mise` ausführen (Lock File
  Maintenance)? Was muss der Betreiber auf anderen Hosts erlauben?
- Ist das fehlende Update ein Fehler in Renovate (etwa der Vergleich von „v2.0.1“ mit
  einem Filter auf „2…“)? Dann gehört ein Bericht an Renovate dazu.
- Warum bekommt ein Tool aus dem mise-Kern (node) Vorschläge für die Sperrdatei, Tools
  aus anderen Quellen (aqua, go) nicht?
- Freigabe über das Dashboard (`:dependencyDashboardApproval`) hält Updates zurück; ob
  das für Tool-Updates entfallen soll, entscheidet jedes Projekt selbst.
