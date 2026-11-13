---
id: F-057
title: Lizenzprüfung des Go-Moduls in just check
type: feature
status: DONE
size: M
created: 2026-11-10
done: 2026-11-13
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
- `go-licenses` kommt über mise statt per `go run …@latest`: mit Hauptversion wie die
  übrigen Tools, die genaue Version legt `mise.lock` fest.
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

- [x] AC-1 — Gegeben ein Go-Projekt aus dem Template, wenn `just check` läuft, dann
  läuft die Lizenzprüfung mit; eine Abhängigkeit mit verbotener Lizenz (Typen
  `forbidden`, `restricted`) lässt `just check` scheitern und nennt das Paket. Negativ:
  Mit nur permissiven Abhängigkeiten ist `just check` grün, auch ohne Netz nach
  `just setup`. — belegt: Durchlauf F-057c in einem Go-Projekt aus dem Arbeitsstand:
  `just check` grün mit `just license-check` als letztem Schritt; mit einer
  LGPL-Abhängigkeit Exit 1 und Name des Pakets; ohne sie grün bei abgeschalteten
  Downloads.
- [x] AC-2 — Gegeben das Go-Modul und ein daraus gerendertes Projekt, wenn man
  `mise.part.toml` und `justfile` liest und im Projekt `mise lock` und
  `mise install --locked` laufen, dann steht `go-licenses` v2 über das `go:`-Backend mit
  Hauptversion in `mise.part.toml`, `mise.lock` legt die genaue Version fest, und
  `--locked` installiert sie. Negativ: Im Go-Modul steht kein `@latest`. — belegt: Test
  „go: no @latest in the module“; im gerenderten Projekt legt `mise lock` go-licenses
  2.0.1 fest, und `mise install --locked` installiert es nach dem Deinstallieren neu.
- [x] AC-3 — Gegeben ein gerendertes Go-Projekt auf GitHub, wenn man
  `.github/workflows/ci.yml` liest, dann gibt es keinen eigenen Lizenz-Job mehr; der
  Job `check` deckt die Prüfung ab. Negativ: Der Mechanismus `ci.part.yml` bleibt
  geprüft — ein Test-Modul hängt einen Job unter `# module:ci-jobs` an. — belegt:
  Skript-Tests „go: no license job in the CI“ und „ci part: job below its marker“
  (`just check`, 3060 Checks).
- [x] AC-4 — Gegeben ein Go-Projekt auf Azure, wenn die Pipeline läuft, dann prüft sie
  die Lizenzen über `just check`, ohne Änderung an `azure-pipelines.yml`. Negativ:
  `azure-pipelines.yml` ist für ein Go- und ein docs-only-Projekt gleich. — belegt:
  Skript-Tests „host azure: same pipeline for go and docs-only“ und „pipeline is the
  template's“; `check` ruft die Lizenzprüfung (Test „go: check runs the license gate“).
- [x] AC-5 — Gegeben ein bestehendes Go-Projekt, wenn es `/update-conventions` holt,
  dann bekommt es Rezept und mise-Eintrag und verliert den Lizenz-Job in der CI; der
  CHANGELOG-Eintrag hat einen Abschnitt `### Template`, der nennt, was das Projekt tun
  muss (`mise install`, ggf. `mise lock`). Negativ: `just check` des Kits ist grün. —
  belegt: Lauf von `/coding-kit:update-conventions` an einem Go-Projekt vom Stand 3.4.0
  (siehe Verlauf F-057c); CHANGELOG 3.5.0 mit `### Template`; `just check` des Kits
  grün.

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
  tritt über mise nicht auf: mise baut das Tool mit der Go-Version des Projekts.

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
- AC-2: Check — grep auf `@latest` im Go-Modul (F-057b); `mise lock` und
  `mise install --locked` im gerenderten Projekt (F-057c).
- AC-3: Skript-Test — gerendertes Go-`ci.yml` ohne Lizenz-Job; Test-Modul mit
  `ci.part.yml` unter `# module:ci-jobs`.
- AC-4: Skript-Test — Render von Go und docs-only auf Azure, `azure-pipelines.yml`
  gleich.
- AC-5: Check — `just check`, CHANGELOG mit `### Template`.

### Einbettung

- Berührt im Go-Modul: `justfile`, `mise.part.toml`, `ci.part.yml` (fällt weg),
  `MODULE.md`, `CODING-STANDARDS.part.md`; dazu `tests/template-sync/render.sh` mit einem
  Test-Modul für `ci.part.yml`.
- MANIFEST: Der Module contract bleibt; `ci.part.yml` ist kein Core-Ziel, also keine
  Zeile unter „Removed and renamed targets“.
- Version 3.5.0, CHANGELOG mit `### Template`.
- Folgen: F-053 (GitLab) und F-054 (Forgejo) brauchen für Go keinen Modulteil mehr.
- Kein Widerspruch zu Zielen oder Nicht-Zielen.

### Offene Fragen

- [x] [CLARIFY] v1.6.0 oder v2 von `go-licenses` — v2, siehe Verlauf F-057a.
- [x] [CLARIFY] Installiert mise das Tool über das `go:`-Backend und schreibt es in
  `mise.lock`? — ja, auch `--locked` geht, siehe Verlauf F-057a.
- [x] [CLARIFY] Aktualisiert Renovate `go:`-Einträge in `mise.toml`, oder braucht das
  Preset eine Regel? — keine Regel nötig; die Sperrdatei hebt Renovate aber nicht an
  (→ F-059).

### Entscheidungen

- 2026-11-13 — Lizenzprüfung in `just check` statt Modulteil je Host oder nur Doku.
  Grund: ein Weg für alle Hosts, auch ohne CI; F-053 und F-054 brauchen nichts Eigenes.
  Preis: `just check` in Go-Projekten etwas langsamer. Entscheidung des Nutzers nach
  Empfehlung.
- 2026-11-13 — AC-2 geändert: Hauptversion in `mise.part.toml` statt fester Version,
  genau in `mise.lock`, wie bei allen Tools des Templates; der Teil „Renovate erkennt
  den Eintrag als aktualisierbar“ entfällt, das regelt F-059. Der Beleg über
  `mise lock` und `--locked` kommt aus dem Durchlauf F-057c. Entscheidung des Nutzers
  nach Empfehlung.

## Plan

**Größe:** M. Wenige Dateien im Go-Modul und in den Tests, einzelne offene Fragen, die ein
kurzer Spike klärt. Formal reicht es in alle Go-Projekte, ändert dort aber nur, wo die
bestehende Prüfung läuft.

**Ansatz:** Die Lizenzprüfung wird ein Teil von `just check` im Go-Modul; `go-licenses`
kommt über mise, mit Hauptversion wie die übrigen Tools. Der Zusatzjob `ci.part.yml` des Go-Moduls entfällt,
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

- `mise.part.toml`: `"go:github.com/google/go-licenses/v2" = "2"`.
- `justfile`: `check` ruft die Lizenzprüfung; das Rezept `license-check` bleibt einzeln
  aufrufbar, ohne `@latest`.
- `ci.part.yml` des Go-Moduls entfernen; `MODULE.md` und `CODING-STANDARDS.part.md`
  nennen die Prüfung in `just check` statt des CI-Jobs.
- Tests in `tests/template-sync/render.sh`: Go-`ci.yml` ohne Lizenz-Job; Test-Modul mit
  `ci.part.yml` für den Mechanismus; `azure-pipelines.yml` gleich für go und docs-only.
- Version 3.5.0, CHANGELOG mit `### Template`: was ein Go-Projekt tun muss
  (`mise install`, ggf. `mise lock`; bei eigener `justfile` die Zeile zum Nachtragen).
- Erfüllt AC-3 und AC-4; AC-2 und AC-5 bis auf den Durchlauf.

### F-057c — Durchlauf mit echtem Go-Projekt

- Go-Projekt aus dem Arbeitsstand rendern: mit einer GPL-Abhängigkeit ist `just check`
  rot und nennt das Paket, ohne sie grün, auch ohne Netz.
- Im gerenderten Projekt `mise lock` und `mise install --locked`: `mise.lock` legt die
  genaue Version von `go-licenses` fest, und `--locked` installiert sie.
- Ein Go-Projekt vom Stand 3.4.0 per `/update-conventions` holen lassen: Rezept und
  mise-Eintrag kommen, der Lizenz-Job in `ci.yml` geht.
- Erfüllt AC-1, AC-2 und AC-5.

**Erkennung (Schritt 2a):** entfällt fürs Kit selbst; das neue Tool kommt nur ins
Go-Modul des Templates. Neue Endpunkte oder Config gibt es nicht.

## Verlauf

### F-057a — fertig 2026-11-13

**Umgesetzt:** Spike in einem Wegwerf-Projekt aus dem Template (Modul go, Host azure):

- Beide Versionen von `go-licenses` laufen mit Go 1.26; mise baut das Tool mit der
  Go-Version des Projekts, Fehler bei Standard-Paketen gab es nicht. Beide kennen
  `--disallowed_types=forbidden,restricted`.
- Eine LGPL-Abhängigkeit lässt die Prüfung mit Exit 1 scheitern und nennt das Paket;
  eine permissive besteht. Die Prüfung dauert unter einer Sekunde und läuft mit
  abgeschalteten Downloads (Go-Proxy und mise offline) gleich.
- Das `go:`-Backend von mise installiert das Tool aus dem Quellcode; `mise.lock` hält
  nur die Version fest, ohne Download-Adresse, und `mise install --locked` installiert
  sie trotzdem.
- Renovate erkennt `go:`-Einträge über die Go-Datenquelle; ein Eintrag mit genauer
  Version bekommt Update-Vorschläge, das Preset braucht keine Regel.

**Entscheidungen:**

- `go-licenses` v2 über das `go:`-Backend von mise, als Eintrag
  `"go:github.com/google/go-licenses/v2" = "2"`, statt v1.6.0, auf das `@latest` heute
  auflöst. Grund: v2 ist die aktuelle Reihe, meldet Funde klarer und bringt `--ignore`
  und `--allowed_licenses` mit, die F-058 braucht. Bei v1 schlägt Renovate die Version
  2.0.1 auf dem Pfad ohne `/v2` vor, wo es sie nicht gibt.
- In `mise.part.toml` steht die Hauptversion, die genaue Version in `mise.lock`, wie bei
  allen Tools des Templates (AC-2 geändert, siehe Spezifikation).

**Abweichung vom Plan:**

- Ohne Netz wurde nur nachgestellt: Downloads über Go und mise abgeschaltet, das Netz
  selbst nicht getrennt.
- Der Beleg für AC-2 über `mise lock` und `--locked` wandert in den Durchlauf F-057c;
  Plan und Zuordnung der Abnahmekriterien sind angepasst.

**Funde:**

- Renovate hebt Tools mit Hauptversion in `mise.lock` nicht an: In einem
  Downstream-Projekt bleiben just und lefthook stehen, und ein lokaler Renovate-Lauf
  findet für `go-licenses` mit gesperrter älterer Version kein Update. Das betrifft alle
  Tools des Templates → F-059 aufgenommen.

### F-057b — fertig 2026-11-13

**Umgesetzt:**

- Go-Modul: `check` ruft am Ende `just license-check`; das Rezept nutzt `go-licenses`
  aus mise (`mise.part.toml`: `"go:github.com/google/go-licenses/v2" = "2"`), ohne
  `@latest`. `ci.part.yml` ist entfernt; `MODULE.md` und das Fragment `go` nennen die
  Prüfung in `just check`.
- Tests in `tests/template-sync/render.sh`: Go-`ci.yml` ohne Lizenz-Job, `check` ruft
  die Prüfung, kein `@latest` im Modul; ein Test-Modul (Kopie des Templates mit
  `ci.part.yml` in docs-only) hält den Mechanismus geprüft; die Azure-Pipeline ist für
  go und docs-only gleich.
- Version 3.5.0, CHANGELOG mit `### Template`: was ein Go-Projekt nach dem Update tun
  muss, auch mit eigener `justfile`.

**Entscheidungen:**

- `check` ruft die Prüfung als letzten Schritt per `just license-check`: Der Befehl
  steht nur im Rezept, und die schnellen Prüfungen laufen zuerst.

**Abweichung vom Plan:**

- Der Entwurf des Moduls java plant die Lizenzprüfung jetzt ebenfalls in `just check`
  statt über `ci.part.yml` — auf Wunsch des Nutzers mitgenommen.

**Funde:** keine.

### F-057c — fertig 2026-11-13

**Umgesetzt:**

- Durchlauf in Wegwerf-Projekten aus dem Template (Modul go):
  - AC-1: `just check` grün, mit LGPL-Abhängigkeit rot und mit Paketname, ohne sie grün
    bei abgeschalteten Downloads.
  - AC-2: `mise lock` schreibt go-licenses 2.0.1 in `mise.lock`, `--locked` installiert
    es.
  - AC-5: Der Nutzer hat `/coding-kit:update-conventions` mit dem Plugin aus dem
    Arbeitsstand in einem Projekt vom Stand 3.4.0 ausgeführt. `ci.yml` verliert den
    Lizenz-Job, `justfile` und `mise.toml` kommen aus dem Template, das Fragment `go`
    wird einzeln angeboten; `lock-check` meldet go-licenses als fehlend, der Skill
    trägt es mit `mise install && mise lock` ein; Stempel 3.5.0, `just check` grün.
- Vorhandener Fehler im Go-Modul behoben: `go build ./...` legte bei einem einzigen
  Hauptpaket eine Programmdatei mit dem Projektnamen ins Hauptverzeichnis, die
  `.gitignore` nicht ausschloss. `check` baut jetzt mit `-o /dev/null`; `build`
  installiert Programme per `GOBIN="$PWD/bin" go install ./...` nach `bin/` und
  kompiliert Bibliotheken nur. Drei Tests in `tests/template-sync/render.sh`, ein Punkt
  im `### Template` von 3.5.0 (mit `git rm --cached` für schon eingecheckte Dateien),
  dazu die Zeilen zum Nachtragen für Projekte mit eigener `justfile`.

**Entscheidungen:**

- Den Fehler mit der Programmdatei in F-057 beheben statt unter eigener Nummer, weil
  das Rezept hier schon angefasst war. Entscheidung des Nutzers nach Empfehlung.
- AC-5 mit einem echten Lauf des Skills durch den Nutzer belegen statt nur mit den
  Skript-Befehlen oder einem Lauf ohne Eingabe. Entscheidung des Nutzers.

**Abweichung vom Plan:**

- Die verbotene Lizenz im Gegentest ist LGPL statt GPL; go-licenses ordnet beide als
  `restricted` ein.
- Ohne Netz wurde nachgestellt: Downloads über Go und mise abgeschaltet.
- Der Update-Lauf lag vor dem Fix der Programmdatei; den Fix belegt ein frisches
  Projekt (`just check` ohne Programmdatei im Hauptverzeichnis, `just build` nach
  `bin/`) und ein Test mit einer Bibliothek und mit zwei Programmen.
- `build` erst mit `go build -o bin/ ./...` gebaut; das bricht in Bibliotheken ab („no
  main packages to build“) — Befund aus dem unabhängigen Review, durch `go install`
  ersetzt.
- Die Frage nach dem Host im Lauf kam vom Testaufbau (`HOST=github` ohne Remote), nicht
  von F-057.

**Funde:**

- Auf dem Entwicklungsrechner war mise nicht aktiviert: Tools, die nur über mise kommen,
  fehlten, und Homebrew-Versionen liefen statt der festgelegten → F-060 aufgenommen. Auf
  dem Rechner sind die Shims auf Wunsch des Nutzers aktiviert.
- `mise lock` in einem frischen Projekt legte für just die lokal installierte Version
  fest statt der neuesten derselben Hauptversion → als Punkt in F-059 aufgenommen.
