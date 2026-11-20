---
id: F-058
title: Lizenzprüfung für die Module python und ts-node
type: feature
status: IN-PROGRESS
size: L
created: 2026-11-13
done:
depends-on: F-057
superseded-by:
---

# F-058 — Lizenzprüfung für die Module python und ts-node

## Erfassung

**Problem:** Die Regel „Abhängigkeiten nur permissiv lizenziert (kein GPL/AGPL)“ steht
in `CODING-STANDARDS.md` § 8 und der Projekt-CLAUDE.md, automatisch geprüft wird sie nur
im Go-Modul. In Python- und ts-node-Projekten kann eine Copyleft-Abhängigkeit unbemerkt
hineinkommen, auf jedem Host. Dazu ist die Regel nirgends maschinenlesbar und je Projekt
nicht steuerbar: Die Go-Prüfung nutzt fest die Einteilung von `go-licenses` und sperrt
dabei auch LGPL, die Regel in Worten nennt nur GPL und AGPL.

**Ziel:** Als Nutzer möchte ich, dass `just check` in Python- und ts-node-Projekten die
Lizenzen der Abhängigkeiten prüft wie im Go-Modul und dass ein Projekt Ausnahmen
begründet festhalten kann, damit eine verbotene Lizenz nicht unbemerkt hineinkommt und
eine bewusste Abweichung nicht die ganze `justfile` aus dem Template löst.

**Lösungsskizze:**
- Prüfung in `just check` aller drei Module — das Muster aus F-057; das Werkzeug kommt
  über den Paketmanager (uv, pnpm) bzw. über mise (go).
- Eine gemeinsame Lizenzregel je Projekt (erlaubte Lizenzen, Ausnahmen je Paket mit
  Grund), die alle drei Module lesen, auch go.
- Verworfen: je Modul die Einteilung seines Werkzeugs, ohne gemeinsame Regel.
- Verworfen: nur ein Modul als erster Schritt.

**Abhängigkeiten:** F-057 (Muster: Prüfung in `just check`, Werkzeug über mise).

**Noch zu analysieren:**
- Welche Werkzeuge passen (eingebaut in pnpm bzw. über uv?), und wie gehen sie mit
  fehlenden oder frei formulierten Lizenzangaben um — Fehlalarme oder blinde Flecken?
- Zählen nur Laufzeit-Abhängigkeiten oder auch die für Entwicklung und Tests?
- Gemeinsame Lizenzregel: Format, Ort im Projekt, wie die Werkzeuge sie lesen; ob LGPL
  gesperrt bleibt — die Regel in Worten und die Go-Prüfung sollen danach übereinstimmen.
- java und swift-ios bekommen ihre Prüfung beim Bau des Moduls (steht in ihrer
  `MODULE.md`); sie gehören nicht hierher.

## Spezifikation

Grundlage ist der Code-Stand vom 2026-11-20 (nach F-061) und eine Recherche zu den
Werkzeugen. Das Modul go prüft in `just check` mit `go-licenses check
--disallowed_types=forbidden,restricted`: gesperrt sind AGPL, GPL und LGPL, erlaubt ist
MPL (Gruppe „reciprocal“). `go-licenses` kennt statt der Gruppen auch eine
Freigabeliste (`--allowed_licenses`) und übersprungene Pakete (`--ignore`). Für
ts-node listet `pnpm licenses list --prod --json` die Lizenzen ohne zusätzliches
Werkzeug, bricht aber nie ab — die Bewertung braucht einen eigenen kleinen Schritt.
Für python prüft `pip-licenses` (MIT-Lizenz, über `uv run --with`) die installierte
Umgebung und liest auch die Lizenzangabe nach PEP 639; für „nur Laufzeit“ braucht es
eine Umgebung ohne die Dev-Gruppe. Ein Werkzeug für alle Sprachen (`osv-scanner`)
braucht Netz und einen Google-Dienst und scheidet für `just check` aus.

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Projekt aus dem Modul python, dessen Laufzeit-Abhängigkeiten
  nur Lizenzen der Freigabeliste tragen, wenn `just check` läuft, dann ist die
  Lizenzprüfung grün. Kommt eine Laufzeit-Abhängigkeit mit GPL, AGPL, LGPL oder ohne
  erkennbare Lizenz dazu, ohne Ausnahme, dann wird `just check` rot und nennt Paket und
  Lizenz. Negativ: Eine solche Abhängigkeit nur in der Dev-Gruppe lässt die Prüfung grün;
  die `.venv` für Tests und Lint bleibt unverändert.
- [ ] AC-2 — Gegeben ein Projekt aus dem Modul ts-node, dasselbe wie AC-1 für
  `dependencies` gegenüber `devDependencies`. Ein Lizenzausdruck mit `OR` ist erlaubt,
  wenn eine Alternative erlaubt ist; mit `AND` nur, wenn alle erlaubt sind.
- [ ] AC-3 — Gegeben die gemeinsame Lizenzregel des Projekts (eine Datei: erlaubte
  Lizenzen, Ausnahmen je Paket mit Grund), wenn ein Projekt eine Ausnahme mit Grund
  einträgt, dann lässt die Prüfung jedes Moduls genau dieses Paket durch. Negativ: Eine
  Ausnahme ohne Grund ist ein Fehler; LGPL steht nicht in der Freigabeliste der
  Vorlage, MPL-2.0 schon.
- [x] AC-4 — Gegeben ein Projekt aus dem Modul go, wenn `just check` läuft, dann liest
  die Lizenzprüfung dieselbe Datei (Freigabeliste und Ausnahmen) statt der festen
  Gruppen. Negativ: Ein Go-Projekt aus der Vorlage bleibt grün; eine Abhängigkeit mit
  GPL, AGPL oder LGPL macht es weiter rot. — belegt: Durchlauf F-058b: Go-Projekt aus
  dem Arbeitsstand mit `just check` grün; LGPL-Paket (juju/errors) und lokales Modul mit
  GPL-3-Text rot; die Prüfung liest `license-policy.txt`, eine Ausnahme mit Grund wirkt.
- [ ] AC-5 — Gegeben die Regel in Worten (`CODING-STANDARDS.md` § 8, Projekt-CLAUDE.md,
  die Skills add-feature, prep-step und audit-code) und das Kit, wenn man sie liest bzw.
  `just check` des Kits läuft, dann nennen sie „keine GPL, AGPL, LGPL; MPL erlaubt;
  Ausnahmen begründet in der Lizenzregel“; das MANIFEST führt die neuen Dateien; der
  Validator meldet eine Modul-`justfile` ohne Lizenzprüfung in `check`; der
  CHANGELOG-Eintrag hat `### Template`. Negativ: keine Versionsstände im Text.

### Randfälle

- EC-1 — Projekt ohne Laufzeit-Abhängigkeiten (Zustand der Vorlage) → Prüfung grün,
  kein Fehler wegen leerer Liste.
- EC-2 — Lizenz fehlt oder ist frei formuliert → rot; das Projekt trägt eine Ausnahme
  mit Grund ein, oder die Schreibweise kommt in die Freigabeliste.
- EC-3 — Übliche Schreibweisen derselben Lizenz („MIT“, „MIT License“) → die
  Freigabeliste der Vorlage enthält die gängigen Varianten der erlaubten Lizenzen.
- EC-4 — Lizenzausdruck mit `WITH` (etwa eine Ausnahme-Klausel zu GPL) → nicht
  freigegeben; bei Bedarf Ausnahme je Paket.
- EC-5 — Erster Lauf ohne Netz → pnpm und go prüfen offline; python braucht für die
  Prüfumgebung den uv-Cache und meldet sonst einen klaren Fehler.
- EC-6 — Frontend mit Bundler, das `devDependencies` mit ausliefert → nicht erkannt;
  die Doku sagt, gebündelte Pakete gehören in `dependencies`.
- EC-7 — Projekt mit eigener `justfile` (`keep`) → `/update-conventions` mergt das neue
  Rezept ein; bei einem Konflikt gewinnt die Projektseite, dann nennt der
  `### Template`-Abschnitt die Zeilen zum Nachtragen.
- EC-8 — Das Projekt steht selbst unter GPL, AGPL oder „TBD“ → das eigene Projekt wird
  nicht geprüft (python `--no-emit-project`, go ohne das eigene Modul, pnpm listet es
  nicht); die Prüfung bleibt grün, wenn die Abhängigkeiten erlaubt sind.
- EC-9 — Bestehendes Python-Projekt ohne die Gruppe `licenses` in `pyproject.toml`
  (Seed) → `license-check` bricht mit klarer Meldung ab; der `### Template`-Abschnitt
  nennt die Zeilen zum Nachtragen.

### Nicht-Ziele

- Keine Prüfung der Entwicklungs-Abhängigkeiten.
- Keine Prüfung für java und swift-ios; sie bekommen sie beim Bau des Moduls.
- Kein `osv-scanner`, kein CI-Job, keine Prüfung auf Schwachstellen.
- Kein Auffrischen der Startwerte (→ F-062).
- Keine Rechtsberatung und keine erzeugten Hinweis-Dateien (NOTICE).

### Tests

- AC-1: manuell — Projekt aus dem Arbeitsstand (python): grün; GPL- bzw. LGPL-Paket als
  Laufzeit-Abhängigkeit: rot mit Paket und Lizenz; dasselbe Paket nur in der
  Dev-Gruppe: grün; `.venv` danach unverändert (pytest läuft).
- AC-2: manuell — wie AC-1 für ts-node, dazu ein Paket mit `OR`-Ausdruck.
- AC-3: manuell — Ausnahme mit Grund: grün; ohne Grund: Fehler; in allen drei Modulen.
- AC-4: manuell — Go-Projekt aus der Vorlage grün; Paket mit GPL rot; Ausnahme wirkt.
- AC-5: Check — Validator mit Gegenprobe (Lizenzprüfung aus einer Modul-`justfile`
  entfernt → Meldung); `just check`, `just version-rule`; Doku lesen.

### Einbettung

- Berührt: `template/core` (Lizenzregel, Prüfskript, `CODING-STANDARDS.md` § 8,
  `CLAUDE.md`), die Module go, python und ts-node (`justfile`, `MODULE.md`, python dazu
  `pyproject.toml`), die Skills add-feature, prep-step und audit-code, MANIFEST,
  `scripts/validate.py`, Kit-Tests, CHANGELOG und Version, README.
- Bestehende Projekte bekommen Datei und Rezepte über `/update-conventions`; die
  Go-Prüfung ändert dort ihr Verfahren, nicht ihr Ergebnis.
- Folge: F-062 frischt danach die Startwerte auf; pnpm 12 muss `pnpm licenses` weiter
  können.
- Kein Widerspruch zu Zielen oder Nicht-Zielen.

### Offene Fragen

- [x] [CLARIFY] Format und Ort der Lizenzregel (Vorschlag: eine schlichte Textdatei im
  Core, managed, mit Abschnitten für Freigaben und Ausnahmen) — klärt der Spike.
  Nicht blockierend. — geklärt 2026-11-20: `license-policy.txt` im Projekt-Root (Core,
  managed) mit Zeilen `allow` und `except` (F-058a).
- [x] [CLARIFY] Wie entsteht die Prüfumgebung für python ohne Dev-Gruppe, ohne die
  `.venv` anzufassen? Klärt der Spike. Nicht blockierend. — geklärt 2026-11-20:
  `uv export --no-dev --no-emit-project` und `uv run --isolated --no-project
  --with-requirements …` (F-058a).
- [x] [CLARIFY] Womit bewertet ts-node die Liste von pnpm (Shell und awk oder ein
  kleines Node-Skript), und wie werden `OR`/`AND` sicher ausgewertet? Klärt der Spike.
  Nicht blockierend. — geklärt 2026-11-20: ein gemeinsames Prüfskript für alle Module
  (Shell und awk), Regeln unter Entscheidungen in F-058a.

### Entscheidungen

- 2026-11-20 — Gesperrt sind GPL, AGPL und LGPL, MPL ist erlaubt — wie die Go-Prüfung
  heute; die Regel in Worten wird angepasst. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-20 — Geprüft werden nur Laufzeit-Abhängigkeiten, wie bei Go. Entscheidung
  des Nutzers nach Empfehlung.
- 2026-11-20 — Eine gemeinsame Lizenzregel je Projekt (Freigabeliste und Ausnahmen mit
  Grund), die alle drei Module lesen, auch go. Grund: eine Stelle, Freigabeliste nach
  § 8, Ausnahmen ohne eigene `justfile`. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-20 — Kein Auffrischen der Startwerte in F-058; dafür F-062. Entscheidung des
  Nutzers nach Empfehlung.
- 2026-11-20 — `pip-licenses` steht in einer eigenen Gruppe `licenses` der
  `pyproject.toml`; die genaue Version liegt in `uv.lock`, das Renovate des Projekts
  hält sie aktuell. Grund: § 8 verlangt feste Versionen; die Gruppe ist nicht Teil der
  `.venv` (uv installiert nur `dev` als Standard). Entscheidung des Nutzers nach
  Empfehlung.

## Plan

**Größe:** L. Drei Module, eine neue Datei für alle Projekte, ein Werkzeug, das erst
erprobt werden muss; das Ergebnis erreicht jedes Go-, Python- und ts-node-Projekt.

**Ansatz:** Eine Lizenzregel `license-policy.txt` im Core (managed — eigene Zeilen eines
Projekts bleiben beim Drei-Wege-Abgleich erhalten) mit Zeilen `allow <Lizenz>` und
`except <Paket> <Grund…>`. Ein gemeinsames Prüfskript `scripts/license-check.sh`
(POSIX-Shell und awk) bewertet Zeilen „Paket ⇥ Lizenz“ dagegen und meldet alle Verstöße
auf einmal. Jedes Modul hat ein Rezept `license-check` in `check`, das nur die Liste
liefert: go über `go-licenses report` ohne das eigene Modul, python über `pip-licenses`
in einer abgeschotteten Umgebung aus `uv export --no-dev`, ts-node über
`pnpm licenses list --prod --json`. Verworfen: die Sperrfunktion der Werkzeuge
(`pip-licenses` meldet nur den ersten Verstoß und wertet Ausdrücke nicht aus, pnpm
sperrt gar nicht — F-058a); `osv-scanner` für alle (Netz, Google-Dienst, Schwachstellen
im selben Exit-Code); je Modul eine eigene Regel (drei Stellen, laufen auseinander).

### F-058a — Spike

- In Projekten aus dem Arbeitsstand ausprobieren: Prüfumgebung für python ohne
  Dev-Gruppe, ohne die `.venv` zu ändern; Form der pnpm-Ausgabe und Auswertung von
  `OR`/`AND`; welche Namen `go-licenses` für `--allowed_licenses` erwartet und wie
  `--ignore` wirkt.
- Daraus Format und Ort der Lizenzregel und die Freigabeliste der Vorlage festlegen.
- Ergebnis im Verlauf; keine Template-Änderung. Klärt die drei offenen Fragen.

### F-058b — Lizenzregel, Prüfskript und Go

- `license-policy.txt` und `scripts/license-check.sh` im Core, Zeilen im MANIFEST;
  Tests des Skripts in den Kit-Tests (`OR`, `AND`, „; “, `WITH`, Klammern, Ausnahme mit
  und ohne Grund, leere Liste) unter dash, bash und mawk.
- `CODING-STANDARDS.md` § 8, `core/CLAUDE.md` und die Skills add-feature, prep-step und
  audit-code nennen „keine GPL, AGPL, LGPL; MPL erlaubt; Ausnahmen begründet in
  `license-policy.txt`“.
- CHANGELOG 3.5.0: die beiden Hinweise zu `keep` richtigstellen (das Update mergt ein,
  bei Konflikt gewinnt die Projektseite).
- Modul go: `license-check` gibt `go-licenses report` ohne das eigene Modul an das
  Prüfskript; `MODULE.md` nachgezogen.
- Durchlauf Go-Projekt: grün, LGPL- bzw. GPL-Paket rot, Ausnahme wirkt.
- Neue Plugin-Version, CHANGELOG mit `### Template`.
- Erfüllt AC-4, AC-3 für go, AC-5 für den Text.

### F-058c — python und ts-node

- `license-check` in beiden `justfile`s und in `check`: python mit
  `uv export --no-dev --no-emit-project` und `uv run --isolated …` mit `pip-licenses`
  aus der Gruppe `licenses` (Version in `uv.lock`), ts-node mit
  `pnpm licenses list --prod --json`; die Umwandlung in „Paket ⇥ Lizenz“ übernimmt die
  Sprache des Moduls; `pyproject.toml` (Gruppe `licenses`) und `MODULE.md` beider
  Module.
- Durchlauf beider Module: grün; GPL- bzw. LGPL-Paket als Laufzeit rot, nur Dev grün;
  `OR`-Ausdruck; Ausnahme mit und ohne Grund; `.venv` unverändert. Für ts-node ein
  kleines lokales Testpaket mit GPL.
- CHANGELOG ergänzt (bei eigener `justfile` die Zeilen zum Nachtragen).
- Erfüllt AC-1, AC-2, AC-3.

### F-058d — Validator und Abgleich

- `scripts/validate.py`: jede Modul-`justfile` von go, python und ts-node hat
  `license-check` in `check`; Gegenprobe von Hand.
- `/update-conventions` an einem bestehenden Go- und Python-Projekt vom Stand davor:
  Lizenzregel kommt an, `justfile` wird gemergt.
- README nachgezogen; `just check`, `just version-rule`.
- Erfüllt AC-5.

**Erkennung (Schritt 2a):** Im Kit entfällt sie (kein gerendertes Projekt). Neu in den
Modulen ist nur `pip-licenses` (MIT) in der eigenen Gruppe `licenses` der
`pyproject.toml` (Version in `uv.lock`); es gehört nicht zur `.venv` und nicht zu den
Laufzeit-Abhängigkeiten.

## Verlauf

### F-058a — fertig 2026-11-20

**Umgesetzt:**

- Spike in Projekten aus dem Arbeitsstand (python, ts-node, go), ohne Änderung am
  Template.
- python: `uv export --no-dev --no-emit-project` und `uv run --isolated --no-project
  --with-requirements … --with pip-licenses` listen nur die Laufzeit-Pakete; die
  `.venv` bleibt unverändert, ein GPL-Paket nur in der Dev-Gruppe erscheint nicht.
  `pip-licenses` liefert SPDX-Kürzel (auch Ausdrücke nach PEP 639) oder alte
  Klassennamen wie „Apache Software License“, mehrere Klassen durch „; “ getrennt.
- ts-node: `pnpm licenses list --prod --json` trennt Laufzeit und Dev und gruppiert nach
  Lizenztext; Ausdrücke kommen mit oder ohne Klammern, fehlende Lizenzen als „Unknown“.
- go: `go-licenses report ./...` liefert Paket und SPDX-Kürzel, ohne Test-Importe, aber
  mit dem eigenen Modul.
- Muster eines gemeinsamen Prüfskripts (awk) gegen eine Lizenzregel mit `allow`- und
  `except`-Zeilen: rot für GPL, LGPL, „Unknown“, `… WITH …`, `(A OR B) AND GPL-3.0` und
  „MIT; GPL“; grün für `Apache-2.0 OR BSD-3-Clause`, `(MIT OR GPL-3.0-or-later)`,
  `(MIT AND Zlib)`, MPL-2.0 und eine begründete Ausnahme. Eine leere Liste ist grün,
  eine Ausnahme ohne Grund ein Fehler; mawk verhält sich gleich.

**Entscheidungen:**

- 2026-11-20 — Ein gemeinsames Prüfskript `scripts/license-check.sh` im Core
  (POSIX-Shell und awk) bewertet für alle drei Module Zeilen „Paket ⇥ Lizenz“; jedes
  Modul liefert nur die Liste. Grund: `pip-licenses --allow-only` meldet nur den ersten
  Verstoß und vergleicht Ausdrücke als ganzen Text, pnpm sperrt gar nicht; so gelten
  in allen Modulen dieselben Regeln und Meldungen. Entscheidung des Nutzers nach
  Empfehlung.
- 2026-11-20 — Die Lizenzregel ist `license-policy.txt` im Projekt-Root (Core,
  managed): `allow <Lizenz>` in der Schreibweise der Werkzeuge, `except <Paket>
  <Grund…>` mit Pflicht-Grund. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-20 — Auswertung: bei `OR` reicht eine erlaubte Alternative; bei `AND` und „; “
  (Klassenlisten aus Python) müssen alle erlaubt sein; `WITH` und verschachtelte
  Klammern nur, wenn der ganze Text freigegeben ist; das eigene Projekt wird nicht
  geprüft. Entscheidung des Nutzers nach Empfehlung.

**Abweichung vom Plan:** Ansatz, F-058b und F-058c nach den Entscheidungen oben
angepasst; neu sind Tests des Prüfskripts in den Kit-Tests, die Gruppe `licenses` für
python und die Korrektur der Skills.

**Funde:**

- CHANGELOG 3.5.0 sagt zweimal, `/update-conventions` ändere eine `justfile` mit `keep`
  nicht; laut MANIFEST mergt es ein, nur bei Konflikt gewinnt das Projekt. Korrektur in
  F-058b.
- Unabhängiges Review mit fünf Befunden zu Spezifikation und Plan: EC-7 (`keep`) —
  bestätigt, korrigiert; das eigene Projekt in der Prüfung — durch den Spike gelöst,
  EC-8 ergänzt; `OR`/`AND` auch für python — durch das gemeinsame Prüfskript erledigt;
  `pip-licenses` ohne feste Version — bestätigt, Gruppe `licenses` (EC-9); die Skills
  add-feature, prep-step und audit-code nennen die alte Regel — bestätigt, AC-5 und
  F-058b erweitert.

### F-058b — fertig 2026-11-20

**Umgesetzt:**

- `license-policy.txt` (Core, managed): Zeilen `allow` und `except`; die Vorlage gibt
  gängige freie Lizenzen frei (SPDX-Kürzel und ältere Python-Namen) und MPL-2.0, ohne
  Ausnahmen.
- `scripts/license-check.sh` (Core, managed, POSIX-Shell und awk): bewertet
  „Paket ⇥ Lizenz“ — „; “-Listen Name für Name (Namen dürfen Klammern enthalten),
  SPDX-Ausdrücke mit `OR`/`AND`, `WITH` und verschachtelte Klammern im Zweifel rot;
  meldet alle Verstöße und eine Zusammenfassung.
- Modul go: `license-check` listet mit `go-licenses report` ohne das eigene Modul und
  übergibt die Liste dem Prüfskript; `MODULE.md` nachgezogen.
- Regel in Worten: `CODING-STANDARDS.md` § 8, `core/CLAUDE.md` (Zone
  `claude-conventions`), Skills add-feature, prep-step und audit-code. MANIFEST: zwei
  Zeilen und ein Absatz zu `license-check` im Rezeptsatz.
- Kit-Tests `tests/template-sync/license.sh` unter dash, bash und mawk; Version 3.6.0,
  CHANGELOG mit `### Template`; die beiden `keep`-Hinweise in 3.5.0 korrigiert.
- Durchlauf Go-Projekt aus dem Arbeitsstand: `just check` grün; juju/errors (LGPL) und
  ein lokales Modul mit GPL-3-Text rot, auch im vollen `just check`; Ausnahme mit Grund
  grün.

**Entscheidungen:**

- 2026-11-20 — Die Go-Liste geht über eine Datei statt einer Pipe an das Prüfskript.
  Grund: Bei einer Pipe sähe die Shell nur den Exit-Code des Prüfskripts; bräche awk ab,
  ginge eine halbe Liste als grün durch.

**Abweichung vom Plan:** Der Rezeptsatz im MANIFEST nennt `license-check` für Module
mit Abhängigkeiten; die Skill-Änderungen liefen über `/add-skill`.

**Funde:** Unabhängiges Review mit zwei Befunden, beide bestätigt und behoben: Eine
„; “-Liste mit Klammern im Namen (etwa `MIT License; Mozilla Public License 2.0
(MPL 2.0)`) fiel durch — Auswertung angepasst, Tests ergänzt, der Klammer-Test prüft
jetzt die Regel selbst; ein zusammengepresster `eval`-Einzeiler im Test ist in einzelne
Prüfungen aufgeteilt.
