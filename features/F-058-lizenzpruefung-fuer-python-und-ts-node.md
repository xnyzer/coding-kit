---
id: F-058
title: Lizenzprüfung für die Module python und ts-node
type: feature
status: BACKLOG
size:
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
- Prüfung in `just check` beider Module, Werkzeug über mise mit Hauptversion, genau in
  `mise.lock` — das Muster aus F-057.
- Option: eine gemeinsame Lizenzregel je Projekt (gesperrte Lizenzen, Ausnahmen je
  Paket mit Grund), die alle Prüfungen lesen, auch die von Go.
- Option: je Modul die Einteilung seines Werkzeugs, ohne gemeinsame Regel.
- Kleinerer erster Schritt möglich: nur ein Modul.

**Abhängigkeiten:** F-057 (Muster: Prüfung in `just check`, Werkzeug über mise).

**Noch zu analysieren:**
- Welche Werkzeuge passen (eingebaut in pnpm bzw. über uv?), und wie gehen sie mit
  fehlenden oder frei formulierten Lizenzangaben um — Fehlalarme oder blinde Flecken?
- Zählen nur Laufzeit-Abhängigkeiten oder auch die für Entwicklung und Tests?
- Gemeinsame Lizenzregel: Format, Ort im Projekt, wie die Werkzeuge sie lesen; ob LGPL
  gesperrt bleibt — die Regel in Worten und die Go-Prüfung sollen danach übereinstimmen.
- java und swift-ios bekommen ihre Prüfung beim Bau des Moduls (steht in ihrer
  `MODULE.md`); sie gehören nicht hierher.
