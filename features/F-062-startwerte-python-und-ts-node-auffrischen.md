---
id: F-062
title: Startwerte der Module und Core-Workflows im Template auffrischen
type: change
status: PLANNED
size: L
created: 2026-11-20
done:
depends-on: F-058
superseded-by:
---

# F-062 — Startwerte der Module und Core-Workflows im Template auffrischen

## Erfassung

**Problem:** Die Startwerte der Module python und ts-node sind veraltet; das Dependency
Dashboard führt seit F-061 neuere Versionen zur Freigabe, darunter große Sprünge
(python, node, TypeScript, vitest, pnpm). Neue Projekte starten mit den alten Werten,
und ihr eigenes Renovate schlägt gleich zu Beginn eine Reihe großer Updates vor.

**Ziel:** Die Startwerte im Template — die Module python, ts-node und go und die
Actions und mise in den Core-Workflows — stehen auf aktuellen Versionen, jedes Modul
ist mit ihnen geprüft. Gleich bleiben: Rezepte und Verhalten der Module, die
Lizenzprüfung aus F-058.

**Lösungsskizze:**
- Direkt auf main, je Teil ein Substep mit Prüfung und Commit; Renovate räumt die
  Einträge im Dashboard danach selbst ab. Der Weg über Dashboard-PRs bleibt für
  einzelne Werte.
- Mindestversionen folgen der mise-Version (`requires-python`, `engines`), die
  Untergrenzen der Dev-Abhängigkeiten dem aktuellen Stand.

**Abhängigkeiten:** F-058 — beide ändern die Module; F-058 zuerst.

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Projekt mit Modul python, aus dem Arbeitsstand gerendert,
  wenn `mise install` und `just check` laufen (mit Lizenzprüfung), dann ist alles grün
  mit python 3.15, `requires-python >=3.15`, uv_build 0.13 und den angehobenen
  Untergrenzen von pytest, pyright, ruff und pip-licenses.
- [ ] AC-2 — Gegeben ein Projekt mit Modul ts-node, aus dem Arbeitsstand gerendert,
  wenn `mise install`, `pnpm install` und `just check` laufen, dann ist alles grün mit
  node 26, `engines >=26`, pnpm 12, TypeScript 7, vitest 5 und aktuellem Biome; die
  Lizenzprüfung liest die Ausgabe von pnpm 12 wie bisher, auch ohne
  Laufzeit-Abhängigkeiten.
- [ ] AC-3 — Gegeben ein Projekt mit Modul go, aus dem Arbeitsstand gerendert, wenn
  `just check` läuft, dann ist es grün mit go 1.27 in `mise.toml` und `go.mod`, mit
  golangci-lint und Lizenzprüfung.
- [ ] AC-4 — Gegeben die Core-Workflows, dann stehen checkout, mise-action und
  codeql-action auf der neuen Version, jeweils als Commit-SHA mit passendem
  Versionskommentar, und `azure-pipelines.yml` nennt die neue mise-Version, deren
  install.sh es gibt. Negativfall: Ein SHA, der nicht zum Tag im Kommentar gehört, gilt
  als Fehler.
- [ ] AC-5 — Gegeben der Abschluss jedes Substeps, wenn `just check` läuft, dann ist es
  grün (Skript-Tests eingeschlossen), und Version 3.7.0 hat einen CHANGELOG-Eintrag mit
  Abschnitt `### Template`, der die neuen Startwerte nennt.
- [ ] AC-6 — Gegeben ein Bestandsprojekt, das über `/update-conventions` nur die
  managed `mise.toml` übernimmt (pnpm 12, node 26 bzw. python 3.15), während seine
  Seeds die alten Werte behalten (`packageManager pnpm@11…`, `engines >=24`,
  `requires-python >=3.13`), wenn `just check` läuft, dann bleibt es grün.
- [ ] AC-7 — Gegeben der Push der Änderungen, wenn Renovate das Dashboard neu aufbaut,
  dann stehen die Template-Updates nicht mehr unter „Pending Approval“ — außer „lock
  file maintenance in the template“.

### Randfälle

- EC-1 — Eine neue Hauptversion läuft im Modul nicht ohne Anpassung (TypeScript 7,
  vitest 5, pnpm 12, mise-action v5) → die Anpassung gehört in denselben Substep, wenn
  sie sauber ins Modul passt; sonst bleibt der alte Startwert, der Grund steht als
  Entscheidung in der Datei und im CHANGELOG — kein Workaround.
- EC-2 — Ein Werkzeug kennt die neue Sprachversion noch nicht (ruff- oder
  pyright-Ziel py315, golangci-lint mit go 1.27) → wie EC-1.
- EC-3 — Bestandsprojekt mit `packageManager pnpm@11…` und mise pnpm 12 → pnpm nimmt
  die Version aus `packageManager` oder meldet sich klar; geprüft in AC-6.
- EC-4 — Renovate schlägt nach dem Push für einen Wert sofort wieder etwas vor (neues
  Patch-Release dazwischen) → kein Fehler; der Eintrag bleibt im Dashboard für später.
- EC-5 — `lock file maintenance in the template` → bleibt unangetastet, das Template
  hat keine `mise.lock`.

### Nicht-Ziele

- Neue Werkzeuge, Rezepte oder Regeln in den Modulen — nur Versionen und was sie
  zwingend verlangen.
- Das Modul swift-ios (Xcode liegt außerhalb von mise).
- Die Kit-eigenen Workflows und `mise.lock` im Repo-Root — dafür öffnet Renovate
  normale PRs.
- Änderungen in Downstream-Projekten; sie holen die managed Dateien selbst über
  `/update-conventions`.

### Tests

- AC-1 bis AC-3 → manuell: je Modul ein Projekt aus dem Arbeitsstand rendern
  (`template-sync.sh render --seeds`), `git init`, `mise trust`, `mise install`,
  `just setup`, `just check`.
- AC-2, Lizenzfall ohne Abhängigkeiten → manuell im gerenderten Projekt
  `just license-check` vor dem ersten `pnpm add`.
- AC-4 → `gh api repos/<action>/git/ref/tags/<tag>` gegen den SHA in der Datei;
  install.sh der mise-Version per HTTP-Abruf.
- AC-5 → `just check`; `just version-rule --staged` im Pre-Commit-Hook.
- AC-6 → manuell: ein Projekt mit den Seeds aus 3.6.0 rendern (`base-from-history`),
  die neue `mise.toml` einsetzen, `mise install`, `just check`.
- AC-7 → nach dem Push das Dashboard (#3) lesen.

### Einbettung

- Berührt: `modules/python` (mise.part.toml, pyproject.toml), `modules/ts-node`
  (mise.part.toml, package.json, ggf. tsconfig, vitest.config, justfile bei
  pnpm-Änderungen), `modules/go` (mise.part.toml, go.mod.tmpl), `core/.github/
  workflows` (ci.yml, codeql.yml), `core/azure-pipelines.yml`; die MODULE.md-Texte nur,
  wo sie Versionen nennen.
- Managed Dateien (mise.toml der Module, Workflows, azure-pipelines.yml) erreichen
  Bestandsprojekte als Angebot von `/update-conventions`; Seeds (pyproject.toml,
  package.json, go.mod) nur neue Projekte — deshalb AC-6.
- Versionsregel: Template-Inhalt → Version 3.7.0, CHANGELOG mit `### Template`; alle
  Substeps teilen sich die unveröffentlichte Version.
- Doku: `docs/renovate-preset.md` (Dogfooding) bekommt den Weg „direkt auf main“ für
  mehrere Werte.
- Widerspricht keinem Ziel oder Nicht-Ziel; folgt F-061 (Startwerte bewusst anheben).

### Offene Fragen

keine

### Entscheidungen

- 2026-11-22 — Umfang: alle Template-Startwerte aus dem Dashboard (python, ts-node,
  go, Core-Workflows) statt nur python und ts-node. Empfehlung war nur python und
  ts-node; entschieden alles, ein Durchgang für alle Startwerte.
- 2026-11-22 — Weg: direkt auf main in Substeps statt über einzelne Dashboard-PRs —
  weniger Git-Handarbeit, geprüft wird je Modul.
- 2026-11-22 — Mindestversionen (`requires-python`, `engines`) und Untergrenzen der
  Dev-Abhängigkeiten werden mit angehoben — die Regel „Mindestversion = mise-Version“
  bleibt.
- 2026-11-22 — mise-action auf v5 (nicht nur v4.3.0): das Kit-Repo läuft schon mit v5.
- 2026-11-22 — Geht eine neue Hauptversion nicht sauber, bleibt der alte Startwert mit
  Grund (EC-1) — die Aktualität ist kein Grund für einen Workaround.

## Plan

**Größe:** L — rund 15 Dateien in den drei Modulen und den Core-Workflows, offene
Fragen bei vier Hauptversionen, und es ist die Vorlage für jedes neue Projekt; die
managed Dateien erreichen Bestandsprojekte als Angebot.

**Ansatz:** Je Teil ein Substep direkt auf main, jeder mit einem aus dem Arbeitsstand
gerenderten Projekt geprüft. Die Versionen werden beim Bau zur Laufzeit aus Registry
und GitHub bestimmt, die Action-SHAs per `gh api` aufgelöst. Erst die kleinen Sprünge
(Core-Workflows, go), die auch Version 3.7.0 und den CHANGELOG-Eintrag anlegen, dann
python, zuletzt ts-node mit den meisten Hauptversionen. Verworfen: je Update ein
Dashboard-PR (Entscheidung oben). Die Erkennung (prep-step 2a) entfällt — es kommen
keine neuen Werkzeuge oder Abhängigkeiten dazu, nur neue Versionen.

### F-062a — Core-Workflows und Modul go

checkout v7.0.1, mise-action v5, codeql-action auf das neueste v4, `MISE_VERSION` in
`azure-pipelines.yml` auf das neueste mise-Release; go 1.27 in `mise.part.toml` und
`go.mod.tmpl`. Version 3.7.0 mit CHANGELOG-Eintrag (`### Template`), in
`docs/renovate-preset.md` der Weg „direkt auf main“. Erfüllt AC-3, AC-4, AC-5.

### F-062b — Modul python

python 3.15 in `mise.part.toml`, `requires-python >=3.15`, `uv_build >=0.13,<0.14`,
Untergrenzen von pytest, pyright, ruff und pip-licenses auf den aktuellen Stand;
Bestandsprojekt-Fall mit alter `pyproject.toml`. Erfüllt AC-1, AC-5, AC-6 (python).

### F-062c — Modul ts-node

node 26 und pnpm 12 in `mise.part.toml`, `engines >=26`, `packageManager` auf pnpm 12,
TypeScript 7, vitest 5, Biome und `@types/node` auf den aktuellen Stand; nötige
Anpassungen an tsconfig, vitest-Konfiguration oder Rezepten im selben Schritt (EC-1);
Bestandsprojekt-Fall mit `pnpm@11` und `engines >=24`. Nach dem Push das Dashboard
prüfen. Erfüllt AC-2, AC-5, AC-6 (ts-node), AC-7.
