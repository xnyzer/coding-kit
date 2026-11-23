---
id: F-095
title: Skript-Tests unter Windows in Git Bash lauffähig machen
type: fix
status: BACKLOG
size:
created: 2026-11-23
done:
depends-on:
superseded-by:
---

# F-095 — Skript-Tests unter Windows in Git Bash lauffähig machen

## Erfassung

**Problem:** Unter Windows scheitern die Skript-Tests (`tests/template-sync`) in Git
Bash mit 202 Fehlern, alle in `install` und `set-global`. Weil die Skript-Pfade, das
`justfile` und `install.sh` in der Pfadliste von `scripts/script-tests.sh` stehen,
scheitert dort jeder Commit an diesen Dateien im Pre-Commit-Hook — er geht nur mit
`--no-verify`.

**Ziel:**
- Ist: `just test` meldet unter Windows 202 Fehler, die mit dem geprüften Code nichts zu
  tun haben; unter Linux (CI) laufen alle Checks grün.
- Soll: die Tests laufen unter Windows so grün wie unter Linux und macOS, oder ein Fall,
  der auf Windows nicht prüfbar ist, wird dort ausdrücklich übersprungen und gemeldet.
- Reproduzieren: Windows mit Git for Windows und mise, im Kit-Repo `just test`.

**Lösungsskizze:**
- Die Installer-Tests verlinken System-Tools per `ln -s` in einen Attrappen-Ordner. Git
  Bash legt dabei Kopien an, und die finden unter `env -i` ihre MSYS-Bibliotheken nicht.
  Statt Links etwa kleine Wrapper-Skripte, die das echte Tool aufrufen.
- Prüfungen auf Dateirechte (`-rw-------`) gelingen auf NTFS nicht, weil `chmod 600`
  dort nicht wirkt — auf Windows anders prüfen oder ausdrücklich überspringen.
- Den Fall „set-global: CRLF file gets CRLF lines“ untersuchen; Verdacht:
  `core.autocrlf=true`, die Systemvorgabe von Git for Windows.
- Einen Fall mit einem Windows-Pfad (`cd` nach `C:\…` scheitert) untersuchen.
- mawk fehlt in Git Bash; prüfen, ob es sich beschaffen lässt oder auf Windows entfällt.

**Abhängigkeiten:** keine. Herkunft: F-094 (Noch zu analysieren).
