---
id: F-076
title: Monorepos mit mehreren Paketen und Sprachen unterstützen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on: F-072
superseded-by:
---

# F-076 — Monorepos mit mehreren Paketen und Sprachen unterstützen

## Erfassung

**Problem:** Der Vertrag kennt genau ein Modul je Projekt, und jedes Modul liefert
Rezepte und Configs für ein einzelnes Paket im Root. Monorepos kommen in allen Formen
vor: mehrere Pakete in einer Sprache, mehrere Sprachen oder beides. Heute enden sie mit
vier bis fünf `keep`/`skip`-Zeilen und eigenen Rezepten neben dem Vertrag.

**Ziel:** Als Nutzer möchte ich Monorepos jeder Art mit dem Kit aufsetzen und abgleichen,
damit Rezepte, Configs, CI und Standards zu jedem Paket passen, ohne dass ich den Vertrag
umgehen muss.

**Lösungsskizze:**
- Ein Vertrag für den allgemeinen Fall: eine Zuordnung „Paketordner → Modul“, in der
  jedes Modul auch einen Workspace mit mehreren Paketen abdecken kann. Das
  Einzelpaket-Repo ist darin der Sonderfall „Root → ein Modul“, alte Antworten bleiben
  gültig.
- Einmal spezifizieren, in Stufen bauen:
  1. eine Sprache mit Workspace (ts-node mit pnpm, der belegte Fall)
  2. mehrere Module in einem Repo
  3. die übrigen Ökosysteme (uv, Go, Maven, Gradle)
- Die Rezepte laufen über alle Pakete (`pnpm -r` oder das Gegenstück des Ökosystems).
  Configs für ein einzelnes Paket werden übersprungen, jedes Paket behält seine eigenen.
- Tests im Workspace (aus F-089): eine Root-Config des Testrunners mit einem Projekt je
  Paket, die Dependency nicht je Paket. Ein Paket mit eigener Bundler-Config bindet sie
  per `extends` ein, `root` allein verliert Plugins und Pfad-Aliase. Ein neues Paket
  bekommt seinen Build-Ausschluss für Tests im selben Schritt.
- render und merge kombinieren justfile, `mise.toml`, CI und Standards-Fragmente mehrerer
  Module. choose-stack und new-project fragen je Paketordner.

**Abhängigkeiten:** F-072 (Workspaces erkennen).

**Noch zu analysieren (Websuche):**
- just-Muster für pnpm-Workspaces und die Gegenstücke der anderen Ökosysteme.
- Ob mehrere Module in einem Repo ein eigenes Feature werden.
- Wie bestehende Workspace-Projekte mit ihren `keep`-Zeilen migrieren.
- Ob das Fragment `docker` für Workspaces `pnpm deploy --prod` nennt (ein flaches
  `node_modules` fürs Produktions-Image).
