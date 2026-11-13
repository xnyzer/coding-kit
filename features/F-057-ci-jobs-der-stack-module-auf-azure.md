---
id: F-057
title: Lizenzprüfung des Go-Moduls in just check
type: feature
status: PLANNED
size: M
created: 2026-11-10
done:
depends-on: F-052
superseded-by:
---

# F-057 — Lizenzprüfung des Go-Moduls in just check

## Erfassung

**Problem:** Stack-Module können der GitHub-CI eigene Jobs anhängen (`ci.part.yml` unter
`# module:ci-jobs`); für `azure-pipelines.yml` gibt es keinen solchen Modulteil. Das
Go-Modul prüft so die Lizenzen seiner Abhängigkeiten (`just license-check`), das nicht in
`just check` steckt — auf Azure-Go-Projekten fehlt diese Prüfung in der CI.

**Ziel:** Als Nutzer in der Firma möchte ich, dass ein Projekt auf Azure dieselben
CI-Prüfungen seines Stack-Moduls bekommt wie auf GitHub, damit eine verbotene Lizenz
nicht unbemerkt hineinkommt.

**Lösungsskizze:**
- Die Lizenzprüfung wird Teil von `just check` im Go-Modul; damit prüft jeder Host gleich,
  auch ohne CI, und lokal vor jedem Commit.
- `go-licenses` kommt mit fester Version über mise statt per `go run …@latest`; Renovate
  hält die Version aktuell.
- Der Zusatzjob `ci.part.yml` des Go-Moduls entfällt. Der Mechanismus `ci.part.yml`
  bleibt im Template für künftige Module, die einen eigenen Runner brauchen.
- Verworfen: ein Modulteil je Host (wächst mit jedem Host, lässt Projekte ohne CI
  ungeprüft) und nur dokumentieren (die Lücke bliebe).

**Abhängigkeiten:** F-052 (dort entsteht `azure-pipelines.yml`).

**Noch zu analysieren:** Brauchen weitere Module CI-Jobs außerhalb von `just check`?
Wie verhält sich ein Modulteil, wenn die Pipeline im Projekt angepasst wurde (Pool)?

## Spezifikation

Grundlage ist der Code-Stand vom 2026-11-13: Nur das Go-Modul hat einen CI-Job außerhalb
von `just check`, die Lizenzprüfung. Sie ruft `go-licenses@latest` auf; das löst heute
auf v1.6.0 auf, v2 liegt unter einem eigenen Modulpfad.

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Go-Projekt aus dem Template, wenn `just check` läuft, dann
  läuft die Lizenzprüfung mit; eine Abhängigkeit mit verbotener Lizenz (Typen
  `forbidden`, `restricted`) lässt `just check` scheitern und nennt das Paket. Negativ:
  Mit nur permissiven Abhängigkeiten ist `just check` grün, auch ohne Netz nach
  `just setup`.
- [ ] AC-2 — Gegeben das Go-Modul, wenn man `mise.part.toml` und `justfile` liest, dann
  steht `go-licenses` mit fester Version in `mise.part.toml`, und Renovate erkennt den
  Eintrag als aktualisierbar. Negativ: Im Go-Modul steht kein `@latest`.
- [ ] AC-3 — Gegeben ein gerendertes Go-Projekt auf GitHub, wenn man
  `.github/workflows/ci.yml` liest, dann gibt es keinen eigenen Lizenz-Job mehr; der
  Job `check` deckt die Prüfung ab. Negativ: Der Mechanismus `ci.part.yml` bleibt
  geprüft — ein Test-Modul hängt einen Job unter `# module:ci-jobs` an.
- [ ] AC-4 — Gegeben ein Go-Projekt auf Azure, wenn die Pipeline läuft, dann prüft sie
  die Lizenzen über `just check`, ohne Änderung an `azure-pipelines.yml`. Negativ:
  `azure-pipelines.yml` ist für ein Go- und ein docs-only-Projekt gleich.
- [ ] AC-5 — Gegeben ein bestehendes Go-Projekt, wenn es `/update-conventions` holt,
  dann bekommt es Rezept und mise-Eintrag und verliert den Lizenz-Job in der CI; der
  CHANGELOG-Eintrag hat einen Abschnitt `### Template`, der nennt, was das Projekt tun
  muss (`mise install`, ggf. `mise lock`). Negativ: `just check` des Kits ist grün.

### Randfälle

- EC-1 — Kein Netz, Modul-Cache nach `just setup` gefüllt → Prüfung läuft offline.
  Fehlt der Cache, scheitert sie mit der Meldung von Go, wie `go build`.
- EC-2 — Das Projekt hat eine eigene justfile (`keep`) → `/update-conventions` ändert
  sie nicht; der `### Template`-Abschnitt nennt die Zeile zum Nachtragen.
- EC-3 — `go-licenses` kann eine Lizenz nicht einordnen (`unknown`) → wie bisher kein
  Fehler; die Regel (`forbidden`, `restricted`) ändert sich nicht.
- EC-4 — Das Projekt hat `mise.lock`, und die CI installiert mit `--locked` → Ohne
  Eintrag für das neue Tool scheitert die Installation; `/update-conventions` bzw. der
  `### Template`-Abschnitt sagt, dass `mise lock` nötig ist.
- EC-5 — `go-licenses` ist mit einer anderen Go-Version gebaut als das Projekt nutzt →
  Spike klärt, ob das Fehler bei Standard-Paketen erzeugt; die Installation über mise
  muss die Go-Version des Projekts nutzen.

### Nicht-Ziele

- Keine Lizenzprüfung für Python oder ts-node; das ist eine eigene Frage.
- Keine Änderung der Lizenzregel (`forbidden`, `restricted`).
- Kein Modulteil für `azure-pipelines.yml` oder andere Hosts; `azure-pipelines.yml`
  bleibt unverändert.
- Der Mechanismus `ci.part.yml` wird nicht entfernt.

### Tests

- AC-1: Skript-Test (Render: `check` im Go-justfile ruft die Lizenzprüfung) und
  manuell im Spike: Go-Projekt aus dem Template mit einer GPL-Abhängigkeit, `just check`
  rot; ohne sie grün, auch mit abgeschaltetem Netz (`GOFLAGS=-mod=mod`, `GOPROXY=off`).
- AC-2: Check — grep auf `@latest` im Go-Modul; Spike: Renovate-Lauf bzw. Doku des
  mise-Managers für `go:`-Einträge.
- AC-3: Skript-Test — gerendertes Go-`ci.yml` ohne Lizenz-Job; Test-Modul mit
  `ci.part.yml` unter `# module:ci-jobs`.
- AC-4: Skript-Test — Render von Go und docs-only auf Azure, `azure-pipelines.yml`
  gleich.
- AC-5: Check — `just check`, CHANGELOG mit `### Template`.

### Einbettung

- Berührt im Go-Modul: `justfile`, `mise.part.toml`, `ci.part.yml` (fällt weg),
  `MODULE.md`, `CODING-STANDARDS.part.md`; dazu `tests/template-sync/render.sh` mit einem
  Test-Modul für `ci.part.yml`; ggf. das Renovate-Preset `default.json`.
- MANIFEST: Der Module contract bleibt; `ci.part.yml` ist kein Core-Ziel, also keine
  Zeile unter „Removed and renamed targets“.
- Version 3.5.0, CHANGELOG mit `### Template`.
- Folgen: F-053 (GitLab) und F-054 (Forgejo) brauchen für Go keinen Modulteil mehr.
- Kein Widerspruch zu Zielen oder Nicht-Zielen.

### Offene Fragen

- [ ] [CLARIFY] v1.6.0 oder v2 von `go-licenses` — gleiche Flags, läuft mit Go 1.26?
  (Spike, nicht blockierend)
- [ ] [CLARIFY] Installiert mise das Tool über das `go:`-Backend und schreibt es in
  `mise.lock`? (Spike, nicht blockierend)
- [ ] [CLARIFY] Aktualisiert Renovate `go:`-Einträge in `mise.toml`, oder braucht das
  Preset eine Regel? (Spike, nicht blockierend)

### Entscheidungen

- 2026-11-13 — Lizenzprüfung in `just check` statt Modulteil je Host oder nur Doku.
  Grund: ein Weg für alle Hosts, auch ohne CI; F-053 und F-054 brauchen nichts Eigenes.
  Preis: `just check` in Go-Projekten etwas langsamer. Entscheidung des Nutzers nach
  Empfehlung.

## Plan

**Größe:** M. Wenige Dateien im Go-Modul und in den Tests, einzelne offene Fragen, die ein
kurzer Spike klärt. Formal reicht es in alle Go-Projekte, ändert dort aber nur, wo die
bestehende Prüfung läuft.

**Ansatz:** Die Lizenzprüfung wird ein Teil von `just check` im Go-Modul; `go-licenses`
kommt mit fester Version über mise. Der Zusatzjob `ci.part.yml` des Go-Moduls entfällt,
`azure-pipelines.yml` bleibt unverändert. Verworfen: ein Modulteil je Host (wächst mit
jedem Host, lässt Projekte ohne CI ungeprüft).

### F-057a — Spike: go-licenses über mise

- In einem Wegwerf-Projekt aus dem Template (Modul go) prüfen:
  - v1.6.0 oder v2: gleiche Flags, läuft mit der Go-Version des Moduls, keine Fehler bei
    Standard-Paketen;
  - Installation über das `go:`-Backend von mise, Eintrag in `mise.lock`, Installation
    mit `--locked`;
  - ob Renovate `go:`-Einträge in `mise.toml` aktualisiert oder das Preset eine Regel
    braucht;
  - Lauf ohne Netz nach `just setup` und die Laufzeit der Prüfung.
- Ergebnis: Version und Backend als Entscheidung in der Feature-Datei.
- Ändert keine Kit-Dateien außer der Feature-Datei, also keine neue Version.
- Klärt die drei offenen Fragen.

### F-057b — Go-Modul und Tests umstellen

- `mise.part.toml`: `go-licenses` mit fester Version.
- `justfile`: `check` ruft die Lizenzprüfung; das Rezept `license-check` bleibt einzeln
  aufrufbar, ohne `@latest`.
- `ci.part.yml` des Go-Moduls entfernen; `MODULE.md` und `CODING-STANDARDS.part.md`
  nennen die Prüfung in `just check` statt des CI-Jobs.
- Ggf. eine Regel im Renovate-Preset `default.json` (Ergebnis F-057a).
- Tests in `tests/template-sync/render.sh`: Go-`ci.yml` ohne Lizenz-Job; Test-Modul mit
  `ci.part.yml` für den Mechanismus; `azure-pipelines.yml` gleich für go und docs-only.
- Version 3.5.0, CHANGELOG mit `### Template`: was ein Go-Projekt tun muss
  (`mise install`, ggf. `mise lock`; bei eigener `justfile` die Zeile zum Nachtragen).
- Erfüllt AC-2, AC-3 und AC-4, AC-5 bis auf den Durchlauf.

### F-057c — Durchlauf mit echtem Go-Projekt

- Go-Projekt aus dem Arbeitsstand rendern: mit einer GPL-Abhängigkeit ist `just check`
  rot und nennt das Paket, ohne sie grün, auch ohne Netz.
- Ein Go-Projekt vom Stand 3.4.0 per `/update-conventions` holen lassen: Rezept und
  mise-Eintrag kommen, der Lizenz-Job in `ci.yml` geht.
- Erfüllt AC-1 und AC-5.

**Erkennung (Schritt 2a):** entfällt fürs Kit selbst; das neue Tool kommt nur ins
Go-Modul des Templates. Neue Endpunkte oder Config gibt es nicht.
