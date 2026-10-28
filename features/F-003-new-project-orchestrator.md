---
id: F-003
title: /new-project-Orchestrator
type: feature
status: DONE
size:
created: 2026-07-07
done: 2026-07-07
depends-on:
superseded-by:
---

# F-003 — /new-project-Orchestrator

## Verlauf

### F-003 — /new-project-Orchestrator (2026-07-07)

**Was entstanden ist:** `plugins/coding-kit/skills/new-project/SKILL.md` (Plugin 0.3.0) —
der Orchestrator über dem project-template, nach dem Muster des bewährten
Maschinen-Anlage-Skills (Inputs sammeln statt raten, nichts ungefragt, Templates aus
der Quelle statt inline):

- **Schritt 0 (M1):** „Was soll das Projekt können?" → Short-Info (ein Satz, publishbar),
  mehrfach wiederverwendet (Repo-Beschreibung, CLAUDE.md, README, Graphiti, Namensfindung);
  bei Projekten aus einem Quelldokument (z. B. STARTPROMPT-Datei) wird die Short-Info
  daraus vorgeschlagen.
- **Abfragen** mit Defaults, Sub-Skills aufrufbar, Aufschieben erlaubt: Name (/name-it),
  Sichtbarkeit (privat), Lizenz (/choose-license; TBD nur bei privat), Modul
  (/choose-stack; offen → docs-only), Doku-Sprache (Deutsch bei privat, Englisch bei
  public), group_id (= Name; „kein Graphiti" möglich), Anforderungen jetzt
  (/define-requirements) oder später.
- **Plan → Bestätigung → Ausführung**, jeder außenwirksame Schritt einzeln bestätigt:
  `gh repo create --template --clone` (kein git init) + lokale Autor-Config via gh api;
  Instanziierung streng nach den MANIFEST-Tabellen (Platzhalter-Registry,
  template:adapt konkretisieren, template:optional graphiti/security-tool,
  public-only-Dateien, LICENSE-Handling inkl. TBD); Modul-Einbau nach Modul-Kontrakt;
  Aufräumen aller Template-eigenen Dateien mit git-status-Gegenprüfung;
  `.claude/template-version`-Stempel; Repo-Settings (Beschreibung = Short-Info, Topics
  mit Marker `coding-kit`, Squash-Merge, Push-Protection mit Feature-Detection);
  Verifikation `mise trust && mise install && just setup && just check`;
  Personendaten-grep + Verschieben von Quelldokumenten nach `private/`;
  Erst-Commit nur nach OK; Graphiti-Seeding falls MCP läuft.
- **Robustheit:** Trockenlauf via Argument `dry-run` (zeigt Fragen, Plan und
  Ziel-Dateiliste, führt nichts aus), Kontext-Recovery-Block, `manifest-format`-Check
  (kann Format 1, bricht sonst mit Hinweis auf Kit-Update ab), Fehlerpfad bei belegtem
  Repo-Namen.

**Entscheidungen:**

- `disable-model-invocation: true` — Repo-Anlage darf nie spontan vom Modell ausgelöst
  werden; nur der Nutzer startet den Orchestrator.
- Instanziierung koppelt an die MANIFEST-Tabellen zur Laufzeit statt an einkopierte
  Dateilisten — Template-Änderungen brechen den Skill nicht (Kopplung nur über die
  `manifest-format`-Version).
- Quell-STARTPROMPTs wandern nach `private/` des neuen Projekts (gitignored) — die
  publishbare Essenz steckt bereits in Short-Info/REQUIREMENTS.
