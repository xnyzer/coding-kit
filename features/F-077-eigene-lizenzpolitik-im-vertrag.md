---
id: F-077
title: Eigene Lizenzpolitik eines Projekts im Vertrag vorsehen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-077 — Eigene Lizenzpolitik eines Projekts im Vertrag vorsehen

## Erfassung

**Problem:** Das Lizenz-Gate des Templates hat enge Grenzen:
- Es prüft nur Laufzeit-Abhängigkeiten und erlaubt MPL.
- Es kennt weder eine Liste der Namensnennungen noch Schriftlizenzen.
- Ausnahmen gelten je Paket, nicht je Version.

Ein Projekt mit strengerem eigenem Gate bekommt beim Abgleich Konflikte: zwei Rezepte
`license-check`, und die Template-Dateien kommen als `new`. Außerdem schreiben Skills und
Standards die Regel des Templates fest.

**Ziel:** Als Nutzer möchte ich für ein Projekt eine eigene Lizenzpolitik festlegen
können, damit Gate, Standards und Skills ihr folgen und der Abgleich sie nicht jedes Mal
überschreiben will.

**Lösungsskizze:**
- Die Skills add-feature, prep-step und audit-code, CODING-STANDARDS § 8 und die
  Lizenz-Zone verweisen auf „die Lizenzpolitik des Projekts“, mit `license-policy.txt` als
  Standard.
- Ein Vertrag für ein eigenes Gate:
  - Der Rezeptname bleibt `license-check`.
  - Eine Registry-Zeile hält die Entscheidung fest.
  - Der Abgleich bietet die Template-Dateien danach nicht mehr an.
- Die Allow-Liste kennt auch Lizenzen, die Werkzeuge unter anderen Namen melden, etwa
  `GNU-All-permissive-Copying-License` aus `go-licenses`. Die SPDX-ID ist vermutlich
  `FSFAP`.
- Steigt ein Projekt von einer Prüfung nach Kategorie um, nennt der Skill den Wechsel zur
  Allow-Liste.

**Abhängigkeiten:** keine. Die Lizenz-Zone kommt aus F-075.

**Noch zu analysieren:** Zum Lizenz-Gate liegt ein eigener ausführlicher Prompt vor, der
vor prep-step eingearbeitet wird.
