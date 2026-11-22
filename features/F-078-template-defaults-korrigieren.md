---
id: F-078
title: Template-Defaults aus den Migrationsläufen korrigieren
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-078 — Template-Defaults aus den Migrationsläufen korrigieren

## Erfassung

**Problem:** Einige Voreinstellungen des Templates passen in Bestandsprojekten nicht oder
sind unsicher. Jedes Projekt muss sie einzeln umgehen.

**Ziel:**
- **Ist:**
  - `just setup` im Python-Modul (`uv sync`) gleicht die Umgebung exakt ab und entfernt
    dabei optionale Extras, die die Tests brauchen. Die CI ruft `just setup` auf und hat
    sie deshalb auch nicht.
  - `license-check.sh` versteht `AND` und `OR` nur in Großschreibung. „MIT and ISC“ aus
    npm-Metadaten fällt deshalb durch.
  - `core/.gitignore` hat keine Muster für Schlüsselmaterial (`*.pem`, `*.key`).
  - `bug_report.yml` schlägt „Node 24“ auch in Go- und Python-Projekten vor.
  - Die Tabelle „Supported versions“ in `SECURITY.md` muss jedes Projekt mit Releases
    ändern, sie ist aber kein `template:adapt`-Punkt.
  - §13 der `CODING-STANDARDS.md` verweist auf `MANIFEST.md` § Standards fragments. Die
    Datei liegt im Kit-Template, nicht im Projekt, und eine Link-Prüfung meldet den
    Verweis als kaputt.
- **Soll:** sichere, modulneutrale Defaults, die ohne Abweichung passen.

**Lösungsskizze:**
- `setup` nutzt `uv sync --all-extras`, und MODULE.md sagt das. Das passt zu
  `license-check`, das Extras schon mitzählt. Verworfen: `--all-groups`, das die Gruppe
  `licenses` in `.venv` holen würde, und `--inexact`, das veraltete Pakete liegen ließe.
- `license-check.sh` liest die Operatoren ohne Beachtung der Groß-/Kleinschreibung.
- `*.pem` und `*.key` kommen in `core/.gitignore`. Der Platzhalter im Bug-Report wird
  modulneutral, die Tabelle in `SECURITY.md` ein `template:adapt`-Punkt.
- §13 nennt die Herkunft des Verweises: das `MANIFEST.md` des coding-kit-Templates.
- Größer, als eigener Teilschritt: actionlint in der Core-CI und ein Smoke-Test für den
  Image-Build über das Fragment `docker`. Fragmente sind heute Textbausteine für
  CODING-STANDARDS, ein CI-Teil erweitert also den Vertrag (vgl. F-022).

**Abhängigkeiten:** keine.

**Noch zu analysieren (Websuche):** wie sich `uv sync` aktuell verhält und ob uv eine
Einstellung für Standard-Extras kennt.
