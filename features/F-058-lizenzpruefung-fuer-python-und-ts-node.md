---
id: F-058
title: Lizenzprüfung für die Module python und ts-node
type: feature
status: PLANNED
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
- [ ] AC-4 — Gegeben ein Projekt aus dem Modul go, wenn `just check` läuft, dann liest
  die Lizenzprüfung dieselbe Datei (Freigabeliste und Ausnahmen) statt der festen
  Gruppen. Negativ: Ein Go-Projekt aus der Vorlage bleibt grün; eine Abhängigkeit mit
  GPL, AGPL oder LGPL macht es weiter rot.
- [ ] AC-5 — Gegeben die Regel in Worten (`CODING-STANDARDS.md` § 8, Projekt-CLAUDE.md)
  und das Kit, wenn man sie liest bzw. `just check` des Kits läuft, dann nennen sie
  „keine GPL, AGPL, LGPL; MPL erlaubt; Ausnahmen begründet in der Lizenzregel“; das
  MANIFEST führt die neue Datei; der Validator meldet eine Modul-`justfile` ohne
  Lizenzprüfung in `check`; der CHANGELOG-Eintrag hat `### Template`. Negativ: keine
  Versionsstände im Text.

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
- EC-7 — Projekt mit eigener `justfile` (`keep`) → `/update-conventions` ändert sie
  nicht; der `### Template`-Abschnitt nennt die Zeilen zum Nachtragen.

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

- Berührt: `template/core` (neue Lizenzregel, `CODING-STANDARDS.md` § 8, `CLAUDE.md`),
  die Module go, python und ts-node (`justfile`, `MODULE.md`, ggf. ein kleines Skript
  für die Bewertung), MANIFEST, `scripts/validate.py`, CHANGELOG und Version, README.
- Bestehende Projekte bekommen Datei und Rezepte über `/update-conventions`; die
  Go-Prüfung ändert dort ihr Verfahren, nicht ihr Ergebnis.
- Folge: F-062 frischt danach die Startwerte auf; pnpm 12 muss `pnpm licenses` weiter
  können.
- Kein Widerspruch zu Zielen oder Nicht-Zielen.

### Offene Fragen

- [ ] [CLARIFY] Format und Ort der Lizenzregel (Vorschlag: eine schlichte Textdatei im
  Core, managed, mit Abschnitten für Freigaben und Ausnahmen) — klärt der Spike.
  Nicht blockierend.
- [ ] [CLARIFY] Wie entsteht die Prüfumgebung für python ohne Dev-Gruppe, ohne die
  `.venv` anzufassen? Klärt der Spike. Nicht blockierend.
- [ ] [CLARIFY] Womit bewertet ts-node die Liste von pnpm (Shell und awk oder ein
  kleines Node-Skript), und wie werden `OR`/`AND` sicher ausgewertet? Klärt der Spike.
  Nicht blockierend.

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

## Plan

**Größe:** L. Drei Module, eine neue Datei für alle Projekte, ein Werkzeug, das erst
erprobt werden muss; das Ergebnis erreicht jedes Go-, Python- und ts-node-Projekt.

**Ansatz:** Eine Lizenzregel im Core (Textdatei, managed — eigene Zeilen eines Projekts
bleiben beim Drei-Wege-Abgleich erhalten) mit Freigabeliste und Ausnahmen je Paket mit
Grund. Jedes Modul hat ein Rezept `license-check` in `check`: go übergibt die Liste an
`go-licenses` (`--allowed_licenses`, `--ignore`), python prüft mit `pip-licenses` über
`uv run --with` eine Umgebung ohne Dev-Gruppe, ts-node bewertet
`pnpm licenses list --prod --json`. Verworfen: `osv-scanner` für alle (Netz, Google-
Dienst, Schwachstellen im selben Exit-Code); je Modul eine eigene Regel (drei Stellen,
laufen auseinander).

### F-058a — Spike

- In Projekten aus dem Arbeitsstand ausprobieren: Prüfumgebung für python ohne
  Dev-Gruppe, ohne die `.venv` zu ändern; Form der pnpm-Ausgabe und Auswertung von
  `OR`/`AND`; welche Namen `go-licenses` für `--allowed_licenses` erwartet und wie
  `--ignore` wirkt.
- Daraus Format und Ort der Lizenzregel und die Freigabeliste der Vorlage festlegen.
- Ergebnis im Verlauf; keine Template-Änderung. Klärt die drei offenen Fragen.

### F-058b — Lizenzregel und Go

- Neue Lizenzregel im Core, Zeile im MANIFEST; `CODING-STANDARDS.md` § 8 und
  `core/CLAUDE.md` nennen „keine GPL, AGPL, LGPL; MPL erlaubt; Ausnahmen begründet“.
- Modul go: `license-check` liest die Lizenzregel; `MODULE.md` nachgezogen.
- Durchlauf Go-Projekt: grün, GPL-Paket rot, Ausnahme wirkt.
- Neue Plugin-Version, CHANGELOG mit `### Template`.
- Erfüllt AC-4, AC-3 für go, AC-5 für den Text.

### F-058c — python und ts-node

- `license-check` in beiden `justfile`s und in `check`; für ts-node ggf. ein kleines
  Bewertungsskript in `files/`; `MODULE.md` beider Module.
- Durchlauf beider Module: grün; GPL- bzw. LGPL-Paket als Laufzeit rot, nur Dev grün;
  `OR`-Ausdruck; Ausnahme mit und ohne Grund; `.venv` unverändert.
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
Modulen ist nur `pip-licenses` (MIT), das `uv run --with` für den Lauf holt; es kommt
nicht in die Abhängigkeiten der Projekte.
