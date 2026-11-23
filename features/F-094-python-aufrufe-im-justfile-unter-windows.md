---
id: F-094
title: Python-Aufrufe im justfile unter Windows lauffähig machen
type: fix
status: PLANNED
size: S
created: 2026-11-23
done:
depends-on:
superseded-by:
---

# F-094 — Python-Aufrufe im justfile unter Windows lauffähig machen

## Erfassung

**Problem:** Die Rezepte `validate` und `version-rule` im `justfile` rufen
`uv run … python3` auf. Unter Windows legt uv in seiner Umgebung nur `python.exe` an;
`python3` trifft den Store-Platzhalter von Windows und endet mit Exit 49. Damit scheitern
dort `just check`, `just check-all` und der Pre-Commit-Hook — im Kit-Repo ist unter
Windows kein Commit ohne `--no-verify` möglich.

**Ziel:**
- Ist: unter Windows bricht `just validate` mit „Python was not found …“ und Exit 49 ab,
  `git commit` scheitert im Hook an `validate` und `version-rule`.
- Soll: beide Rezepte laufen unter Windows, macOS und Linux gleich; der Pre-Commit-Hook
  lässt einen Commit mit grünen Prüfungen durch.
- Reproduzieren: Windows mit Git for Windows und mise, im Kit-Repo `just validate`.

**Lösungsskizze:**
- In beiden Rezepten `python` statt `python3` — `uv run python` liefert auf allen
  Plattformen den Interpreter der uv-Umgebung.
- Kein Plugin-Inhalt: keine neue Version, kein CHANGELOG-Eintrag.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Die Skript-Tests laufen unter Windows teils nicht: `ln -s` legt in Git Bash Kopien an,
  die unter `env -i` ihre MSYS-Bibliotheken nicht finden; `chmod 600` wirkt auf NTFS
  nicht; ein CRLF-Fall von `set-global` ist ungeklärt — eigene Nummer, wenn unter
  Windows an Skripten gearbeitet wird.

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben Windows mit Git for Windows und den Tools aus mise, wenn
  `just validate` und `just version-rule --staged` laufen, dann nutzen sie den
  Interpreter von uv und melden OK statt Exit 49.
- [ ] AC-2 — Gegeben eine bereitgestellte Änderung mit grünen Prüfungen unter Windows,
  wenn `git commit` läuft, dann lässt der Pre-Commit-Hook den Commit ohne `--no-verify`
  durch.
- [ ] AC-3 — Gegeben die CI unter Linux, wenn `just check-all` läuft, dann bleibt sie
  grün.

### Randfälle

- EC-1 — macOS ohne `python` im PATH (dort gibt es oft nur `python3`) → uv startet für
  das Ziel `python` den eigenen Interpreter, unabhängig vom PATH (Quelltext von uv,
  `run.rs`) → läuft.

### Tests

- AC-1 → manuell auf Windows: beide Rezepte aufrufen.
- AC-2 → der Commit dieses Features samt der Planung von F-027 läuft durch den Hook.
- AC-3 → CI-Lauf nach dem Push.

### Einbettung

- Nur das `justfile` (Rezepte `validate`, `version-rule`); der Pre-Commit-Hook und die
  CI rufen diese Rezepte und sind damit mit behoben.
- Kein Plugin-Inhalt — keine neue Version, kein CHANGELOG-Eintrag. Die Shebangs der
  beiden Skripte bleiben.
- Die Skript-Tests unter Windows bleiben eine spätere eigene Nummer (Erfassung).

### Entscheidungen

- 2026-11-23 — `uv run python …` statt des direkten Skriptaufrufs `uv run scripts/….py`:
  beide laufen auf allen Plattformen; `python` bleibt ausdrücklich und ändert nur ein
  Wort je Rezept.

## Plan

**Größe:** S — zwei Wörter in einer Datei, die Lösung ist unter Windows schon erprobt.

**Ansatz:**
- In beiden Rezepten `python3` durch `python` ersetzen.
- `just validate`, `just version-rule --staged` und `just check` auf Windows laufen
  lassen.
- Commit über den Hook (AC-2), danach die CI prüfen (AC-3).
