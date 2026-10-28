---
id: F-019
title: Pflege-Skill go-public (Projekt nachträglich public-ready)
type: feature
status: DONE
size:
created: 2026-07-19
done: 2026-07-20
depends-on:
superseded-by:
---

# F-019 — Pflege-Skill go-public (Projekt nachträglich public-ready)

## Verlauf

### F-019 — Pflege-Skill go-public: Projekt nachträglich public-ready machen (2026-07-20)

**Aufgabe:** public-only-Dateien werden bei privaten Projekten bewusst nicht
instanziiert; für den späteren Weg an die Öffentlichkeit gab es keinen geführten
Prozess — und niemand prüfte systematisch das eigentliche Risiko: Secrets/
Personendaten in der gesamten Git-Historie, TBD-Lizenz, fehlende Repo-Settings.

**Was entstanden ist (Plugin 0.17.0; 2 Substeps, ein Release):**

- **F-019a — Skill-Kern:** Neuer Pflege-Skill
  `plugins/coding-kit/skills/go-public/SKILL.md` (`disable-model-invocation`).
  Fallerkennung zur Laufzeit (`gh repo view`): A privat → Umstellung, B nur lokal
  → Anlage + initialer Push, C schon public → Preflight trotzdem vollständig
  (nachträgliche Funde sind dort bereits öffentlich), dann nur Nachzug-/
  Abschluss-Check. Preflight blockierend, fail-closed, vier Gates:
  Historien-Secrets-Scan (Scanner zur Laufzeit aus lefthook/mise aufgelöst,
  gitleaks nur Fallback, fehlender Scanner = rot), Privacy-Scan des committeten
  Baums **inkl. Commit-Metadaten** (Autor-/Committer-E-Mails der Historie —
  Ergänzung während der Umsetzung, kein Datei-Scan findet das), LICENSE nicht
  TBD, private/-Hygiene über die Historie (Ausnahme: managed
  `private/README.md`). Befund-Optionen: bereinigen / History-Rewrite **nur als
  Anleitung** (`git filter-repo` + Force-Push, nie automatisch) / begründete
  False-Positive-Einstufung (protokolliert) / Abbruch.
- **F-019b — Nachzug, Übergang, Abschluss-Check:** Verbindliche Reihenfolge
  **Nachzug vor Übergang** (Nutzer-Entscheidung: nie unvollständig online) —
  update-conventions läuft mit neuer **Sichtbarkeits-Prämisse** („behandle als
  public"), public-only-Dateien und Template-Updates entstehen und werden
  committet, bevor irgendetwas öffentlich wird; hartes Gate im Skill. Übergang je
  Fall nach Klartext-Bestätigung: `gh repo edit --visibility public`
  (`--accept-visibility-change-consequences` per Feature-Detection) bzw.
  `gh repo create` + Push nur mit ausdrücklicher laufbezogener Freigabe aus
  demselben Lauf. Repo-Settings wie new-project § 4c (Topics inkl. Marker
  `coding-kit`, Push-Protection). Der Languages-Block bleibt unangetastet
  (F-020: Sprache sichtbarkeitsentkoppelt). Abschluss-Check: CodeQL läuft an,
  Vollständigkeit, Settings, `just check`, Graphiti-Update.
- **update-conventions-Erweiterung:** Sichtbarkeits-Prämisse in Intro + A2.3
  dokumentiert (gilt auch für die A3-Heuristik); Default bleibt die tatsächliche
  Sichtbarkeit via `gh repo view`.
- **Begleitanpassungen:** plugin.json 0.17.0 (+ go-public in der
  Description-Aufzählung), CHANGELOG, README-Zeile; project-template 0.11.2
  (HOW-TO-Pflegezeile für `/go-public`, VERSION + CHANGELOG dort).
- **Geänderte Dateien:** `plugins/coding-kit/skills/go-public/SKILL.md` (neu),
  `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`;
  im project-template: `core/HOW-TO-CODE-WITH-CLAUDE.md`, `VERSION`,
  `CHANGELOG.md`.
