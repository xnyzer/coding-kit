---
id: F-064
title: Skript-Tests in just check nur bei passenden Änderungen ausführen
type: change
status: PLANNED
size: S
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-064 — Skript-Tests in just check nur bei passenden Änderungen ausführen

## Erfassung

**Problem:** `just check` führt im Kit-Repo immer die Skript-Tests aus (rund drei
Minuten), auch vor Commits, die nur Feature-Dateien, INDEX oder CHANGELOG ändern. Der
Pre-Commit-Hook überspringt sie in diesem Fall schon über eine Pfadliste, `just check`
nicht — die Regel „`just check` vor jedem Commit“ kostet so bei jedem Doku-Commit
unnötig Zeit.

**Ziel:** `just check` lässt die Skript-Tests weg, wenn sich seit dem letzten Commit
keine Datei geändert hat, die sie betreffen. Gleich bleiben: die CI prüft immer alles;
Validator und Feature-Tabelle laufen in `just check` immer; die Regel „`just check` vor
jedem Commit“; die Projekte aus dem Template.

**Lösungsskizze:**
- `just check` prüft die geänderten Dateien (bereitgestellt, nicht bereitgestellt,
  neu) gegen die Pfadliste der Skript-Tests und meldet, wenn es sie überspringt und
  warum.
- Ein Rezept wie `just check-all` prüft alles; die CI nutzt es.
- Ein Skript `scripts/script-tests.sh` hält die Pfadliste und entscheidet; Hook und
  `just check` rufen es auf.
- Option verworfen: nur die Regel ändern (Hook statt `just check` vor Doku-Commits) —
  Claude müsste je Commit selbst entscheiden, statt dass es mechanisch geprüft wird.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Kann lefthook die Pfadliste aus einer gemeinsamen Quelle beziehen, oder prüft der
  Hook stattdessen über dasselbe Skript wie `just check`?
- Gehören weitere Pfade in die Liste, die die Tests heute schon betreffen (z. B. das
  justfile, `scripts/`)?
- Verhalten ohne Commit-Historie oder mitten in einem Merge oder Rebase: im Zweifel
  alles prüfen.
- Muss die Kit-CLAUDE.md oder `docs/` den Unterschied von `check` und `check-all`
  erklären?

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben nur Änderungen außerhalb der Pfadliste (z. B. in `features/` oder
  am CHANGELOG), wenn `just check` läuft, dann laufen Validator und Feature-Tabelle,
  die Skript-Tests nicht, und die Ausgabe sagt, dass und warum sie übersprungen wurden.
- [ ] AC-2 — Gegeben eine Änderung unter einem Pfad der Liste — bereitgestellt, nicht
  bereitgestellt, neu oder gelöscht —, wenn `just check` oder der Pre-Commit-Hook
  läuft, dann laufen die Skript-Tests.
- [ ] AC-3 — Gegeben die CI, wenn sie läuft, dann prüft sie über `just check-all`
  immer alles, auch bei sauberem Arbeitsbaum.

### Randfälle

- EC-1 — Repo ohne Commit oder ein Fehler von git → die Skript-Tests laufen.
- EC-2 — Datei aus der Liste heraus umbenannt → alter und neuer Pfad zählen, die
  Skript-Tests laufen.

### Nicht-Ziele

- Validator und Feature-Tabelle filtern — beide sind schnell und laufen immer.
- Die Projekte aus dem Template — ihr `just check` bleibt, wie es ist.

### Tests

- AC-1 → manuell: nur eine Doku-Datei ändern, `just check` → Meldung „übersprungen“.
- AC-2 → manuell: eine Template-Datei ändern (einmal nicht bereitgestellt, einmal als
  neue Datei), `just check` → Tests laufen; ein Commit mit dieser Änderung → der Hook
  lässt die Tests laufen.
- AC-3 → CI-Lauf nach dem Push: die Zusammenfassung der Skript-Tests steht im Log.
- EC-1, EC-2 → manuell in einem Wegwerf-Repo im Scratchpad.

### Einbettung

- `justfile`: `check` nutzt das Skript, neu `check-all` (alles) für die CI.
- `lefthook.yml`: der Job `script-tests` ruft das Skript für bereitgestellte Dateien
  auf, die Glob-Liste dort entfällt; der Kommentar wird angepasst.
- `.github/workflows/ci.yml`: `just check-all` statt `just check`.
- Doku: Kit-CLAUDE.md (Konventionen), README (Abschnitt zur Mitarbeit),
  `docs/skill-authoring.md` (Tests) — der Unterschied von `check` und `check-all`.
- Versionsregel: nichts davon ist Plugin-Inhalt — keine neue Version, kein CHANGELOG.
- Die globale Regel „`just check` vor jedem Commit“ bleibt gültig und wird nur
  schneller erfüllt.

### Offene Fragen

keine

### Entscheidungen

- 2026-11-22 — Ein Shell-Skript hält die Pfadliste, statt sie in `lefthook.yml` und
  `justfile` doppelt zu führen: lefthook kann Globs nicht aus einer Datei lesen, ein
  Skript bedienen beide.
- 2026-11-22 — Die CI ruft ein eigenes Rezept `check-all` auf, statt dass das Skript
  die CI-Umgebung erkennt: ein Mechanismus, sichtbar in der Workflow-Datei.
- 2026-11-22 — Zur Pfadliste kommen das `justfile` und das neue Skript selbst hinzu:
  beide bestimmen, wie die Tests laufen.

## Plan

**Größe:** S — etwa sechs Dateien und unter 150 Zeilen, die Lösung liegt auf der Hand,
und es betrifft nur das Werkzeug des Kit-Repos.

**Ansatz:**
- `scripts/script-tests.sh` (POSIX-Shell): ermittelt die geänderten Dateien — ohne
  Option Arbeitsbaum und neue Dateien gegenüber dem letzten Commit, mit `--staged` nur
  die bereitgestellten —, Umbenennungen als zwei Pfade. Trifft eine Datei die
  Pfadliste (heutige Liste aus `lefthook.yml` plus `justfile` und das Skript), laufen
  die Tests; sonst eine Zeile, dass sie übersprungen wurden. Ohne Commit oder bei einem
  git-Fehler laufen sie immer.
- `justfile`: `check: validate features test-changed`, neu `check-all: validate
  features test` und `test-changed` als Aufruf des Skripts; `test` bleibt.
- `lefthook.yml`: Job `script-tests` ruft `sh scripts/script-tests.sh --staged`,
  ohne Glob.
- CI auf `just check-all`; Doku an den drei Stellen nachziehen.
- Prüfen nach den Tests oben, dann `just check-all` einmal komplett.
