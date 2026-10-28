---
id: F-047
title: Skript-Tests zusätzlich mit mawk
type: feature
status: DONE
size:
created: 2026-10-26
done: 2026-10-26
depends-on:
superseded-by:
---

# F-047 — Skript-Tests zusätzlich mit mawk

## Verlauf

### F-047 — Skript-Tests zusätzlich mit mawk (2026-10-26)

**Problem:** `just check` testete `template-sync.sh` nur mit dem awk des Rechners. Auf
macOS nimmt das mehr hin als mawk, das Standard-awk auf Debian und Ubuntu. In F-045a fiel
ein awk-Array namens `NF` deshalb erst unter mawk auf — lokal grün, und die CI läuft erst
beim Push.

**Was entstanden ist:**

- **`tests/template-sync/run.sh`:** Nach den Durchgängen unter dash und bash folgt je ein
  Durchgang unter der ersten Shell mit mawk und mit gawk, wenn installiert und nicht das
  Standard-awk — über einen Link `awk → <awk>` in einem Temp-Ordner vorn im `PATH`, so
  dass Skript und Test-Helfer dasselbe awk nutzen. Das Standard-awk erkennt
  `awk -W version` (mawk, GNU Awk; alles andere, etwa das macOS-awk, gilt als
  „system awk"). Fehlschläge tragen den Durchgang im Namen (`[dash/mawk]`); die
  Zusammenfassung nennt Shells, geprüfte und nicht installierte awks
  (`awk: system awk, mawk; not installed: gawk`). `just check`, Pre-Commit-Hook und CI
  bekommen das ohne eigene Änderung.
- **Doku:** `docs/skill-authoring.md` § Hilfsskripte (automatischer Durchgang statt
  Handtest); README (Repo-Struktur und ein Pflege-Punkt: mawk für die Arbeit an
  `template-sync.sh`, gawk optional, beide GPL und außerhalb der Toolchain); der
  Kommentar des `test`-Rezepts im justfile.

**Verifikation:** `just check` grün mit 1170 Checks (780 unter dash und bash, 390 im
Durchgang dash/mawk); Versionsregel grün (kein Plugin-Inhalt). Ein eingeschleustes
awk-Array `NF` scheitert in 49 Checks, alle im Durchgang `dash/mawk`; ohne mawk im `PATH`
laufen 780 Checks wie bisher, mit „not installed: mawk gawk".

**CI:** Das CI-Log nach dem Push (Lauf 40359892425) zeigt `awk: gawk, mawk`: Der
Ubuntu-Runner hat gawk als Standard-awk und mawk zusätzlich installiert. Die CI prüft
damit beide; mawk war dort vor F-047 nicht abgedeckt. Eine Installation in der CI ist
nicht nötig.

**Notable decisions:**
- Die Durchgänge stehen in `run.sh`, nicht im justfile — eine Stelle für `just check`,
  Pre-Commit-Hook und CI.
- gawk zusätzlich zu mawk: Es ist Standard auf Fedora und Arch, wie mawk auf Debian und
  Ubuntu.
- Je zusätzlichem awk nur eine Shell: Die Unterschiede liegen im awk, die Shells decken
  die ersten beiden Durchgänge ab.
- Kosten: gut 30 Sekunden je zusätzlichem awk statt der geschätzten 20; `just check`
  dauert damit rund 75 statt 42 Sekunden.
- Die Frage zur CI klärte das Log nach dem Push: gawk ist dort Standard, mawk läuft als
  zusätzlicher Durchgang.
- Der justfile-Kommentar ist einzeilig, weil `just --list` nur die letzte Kommentarzeile
  zeigt.

**Geänderte Dateien:** `tests/template-sync/run.sh`, `justfile`,
`docs/skill-authoring.md`, `README.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.
