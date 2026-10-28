---
id: F-002
title: Begleit-Skills
type: feature
status: DONE
size:
created: 2026-07-07
done: 2026-07-07
depends-on:
superseded-by:
---

# F-002 — Begleit-Skills

## Verlauf

### F-002 — Begleit-Skills (2026-07-07)

**Was entstanden ist:** Fünf Skills unter `plugins/coding-kit/skills/` (Plugin 0.2.0) —
einzeln nutzbar und von `/new-project` (F-003) aufrufbar; jede SKILL.md definiert dafür
explizit ihre „Rückgabe an den Aufrufer":

- **name-it** — Kandidaten nach Kriterien (kurz, sprechend, kollisionsarm,
  lowercase-kebab-tauglich), Verfügbarkeits-Checks zur Laufzeit (GitHub via gh,
  npm-Registry, PyPI-JSON-API; Domain nur auf Wunsch via RDAP), Websuche gegen
  Namensvettern. Rückgabe: gewählter Name.
- **choose-license** — M1-Kurzinterview (Sichtbarkeit, kommerzielle Nutzung, Copyleft,
  Dependency-Lage), Empfehlung Default Apache-2.0, Alternativen MIT/MPL-2.0, GPL/AGPL
  nur als bewusste Entscheidung, „TBD" gültig (nur privat). Standalone schreibt es
  LICENSE + Paket-Metadaten nach Bestätigung. Rückgabe: SPDX-Id oder TBD.
- **choose-stack** — Modus A Neuanlage (Bedarf aus Short-Info, aktuelle Framework-Lage
  per Websuche verifiziert, Stubs klar ausgewiesen, „offen" → docs-only); Modus B
  Bestandsprojekt (EIN Modul nachrüsten/wechseln nach MANIFEST-Modul-Kontrakt, Diff +
  Bestätigung je Datei, Override-Schutz, Verifikation via mise install + just setup +
  just check). Template-Repo wird zur Laufzeit aufgelöst (lokaler Checkout, sonst
  gh clone von `<login>/project-template`; Override `CODING_KIT_TEMPLATE_REPO`).
  Grenze dokumentiert: laufende Modul-Updates = `/update-conventions`. Rückgabe:
  Modulname (+ CODEQL-Sprache, geschriebene Dateien).
- **define-requirements** — M1-Interview aus der Short-Info (Ziele, Kern-Features,
  Nicht-Ziele, Constraints; Vorschläge bestätigen lassen statt offen fragen) →
  REQUIREMENTS.md in M5-Struktur (= Template-Skelett `core/REQUIREMENTS.md`) → initiale
  PROGRESS.md mit einer F-Nummer je Anforderung + FEATURE-INDEX. Verwaltet den
  Auflöse-Trigger (vollständig überführt + Nutzer bestätigt → Kurzfassung in CLAUDE.md,
  Entscheidungen als ADR sichern, Datei löschen).
- **refine-requirements** — M2-Diagnose „Was führt dich zurück zur Spec?" mit drei
  Pfaden (Änderung von außen / Implementierungs-Lücke / Grundsatz-Challenge); darf
  Features splitten (neue Nummern via FEATURE-INDEX); immer datierte Decision-Log-
  Einträge (Product/Technical getrennt, Historie supersedieren statt umschreiben);
  arbeitet nach Auflösung der REQUIREMENTS.md auf PROGRESS + ADRs weiter.

**Entscheidungen:**

- Alle fünf mit `disable-model-invocation: false`, damit der `/new-project`-Orchestrator
  (F-003) sie als Sub-Skills aufrufen kann; präzise descriptions verhindern Spontanfeuer.
- Neuer optionaler Personal-Config-Schlüssel `CODING_KIT_TEMPLATE_REPO` (Default bleibt
  Laufzeit-Auflösung `<github-login>/project-template` — kein Hardcode).
