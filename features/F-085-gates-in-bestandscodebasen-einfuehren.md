---
id: F-085
title: Format- und Lint-Gates in Bestandscodebasen einführen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-085 — Format- und Lint-Gates in Bestandscodebasen einführen

## Erfassung

**Problem:** Kommt ein Stack-Modul in ein Bestandsprojekt, macht sein Gate die ganze
Codebasis rot. Das gilt für `biome ci --error-on-warnings` auf nie formatiertem Code,
ebenso für `ruff format --check` und `pyright` im strikten Modus. Einen Weg, die Gates
schrittweise einzuführen, nennen die Module nicht. Behält ein Projekt seine eigene Config
eines Werkzeugs, können die Rezepte des Moduls außerdem wirkungslos werden:
`golangci-lint fmt` mit einer Config ohne `formatters:` endet mit Exit 0 und formatiert
nichts.

**Ziel:** Als Nutzer möchte ich die Gates eines Moduls in einem Bestandsprojekt
schrittweise einführen können, damit sie von Anfang an gelten, ohne dass ich die ganze
Codebasis auf einmal umbauen muss.

**Lösungsskizze:**
- Jede MODULE.md bekommt einen Abschnitt „Einführung in eine Bestandscodebasis“: ein
  reiner Formatierungs-Commit, dessen Hash in `.git-blame-ignore-revs`, dann die Regeln
  schrittweise verschärfen.
- A3 und choose-stack im Modus Bestandsprojekt verweisen darauf, wenn der erste
  `just check` an Format oder Lint scheitert.
- Die Rezepte prüfen, dass sie mit der Config des Projekts wirken. Im Go-Modul prüft
  `format`, dass Formatter konfiguriert sind.
- Verworfen: standardmäßig ohne `--error-on-warnings` zu starten. Das schwächte den Gate
  für alle neuen Projekte.

**Abhängigkeiten:** keine.

**Noch zu analysieren (Websuche):** wie Biome, ruff und golangci-lint die Einführung in
bestehende Codebasen empfehlen.
