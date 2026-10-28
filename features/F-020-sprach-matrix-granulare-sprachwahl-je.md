---
id: F-020
title: Sprach-Matrix — granulare Sprachwahl je Projekt
type: feature
status: DONE
size:
created: 2026-07-19
done: 2026-07-19
depends-on:
superseded-by:
---

# F-020 — Sprach-Matrix — granulare Sprachwahl je Projekt

## Verlauf

### F-020 — Sprach-Matrix: granulare Sprachwahl je Projekt (2026-07-19)

**Aufgabe:** Die Projektsprache war eine einzige Dimension („Sprache der lebenden
Doku") mit sichtbarkeitsgekoppeltem Default (Deutsch privat / Englisch public).
Sprache hängt aber am Thema/Publikum, nicht an der Sichtbarkeit — ein privates
Projekt kann public werden (F-019), ohne dass die Sprache wechseln soll.
Template-Gegenstück: project-template TPL-010 (Languages-Block, fünf
`LANG_*`-Platzhalter, VERSION 0.10.0) — im Pairing direkt miterledigt.

**Was entstanden ist (Plugin 0.14.0; 2 Substeps, ein Release):**

- **F-020a — Erhebung & Instanziierung:** new-project Schritt 5 ist die
  Preset-Frage (A Arbeitssprache + Englisch nach außen [Default] / B alles Englisch /
  C alles Arbeitssprache / D individuell je Dimension, freie Sprachwahl), Vorschlag
  aus der Short-Info — die Sichtbarkeits-Frage sagt explizit, dass sie die
  Sprachwahl nicht beeinflusst. §4b füllt die fünf `LANG_*`-Platzhalter. Globale
  CLAUDE.md-Vorlage: Haus-Default Englisch bleibt, ein Projekt-Languages-Block
  gewinnt je Dimension; Alt-Konvention wird weiter gelesen. Immer englisch:
  Identifier, Conventional-Tokens, Status-Tokens, Governance-Doku.
- **F-020b — Betrieb & Migration:** step-done liest den Languages-Block (§0), prüft
  die Kommentar-/Docstring-Sprache im Review (§1) und schlägt Commit-Prosa in der
  Commit-Sprache vor (§6; ohne Block englisch, Tokens immer englisch); build-step
  schreibt Kommentare in der Kommentar-Sprache (§2); update-conventions löst die
  fünf Werte rück (A2.2, mit Alt-Projekt-Fallback) und bietet die
  Languages-Block-Migration als bestätigten Schritt an (neuer A3-Schritt 6 +
  Hinweis in A2.7) — nötig, weil CLAUDE.md `seed` ist und nie automatisch
  angefasst wird.
- **Entscheidung (Nutzer) — prospektive Migration:** Beim Sprachwechsel wird nichts
  rückwirkend übersetzt; neue Einträge folgen ab sofort den gewählten Sprachen,
  Struktur-Überschriften (z. B. PROGRESS-Skelett) dürfen übersetzt werden, die
  Historie bleibt unverändert. Gemischte Tabellen sind akzeptiert — sie
  dokumentieren den Wechselzeitpunkt.
- **Bewusst nicht angefasst:** die generische Phrase „Sprache der lebenden Doku" in
  ~10 Skills — sie bleibt gültig und zeigt auf die Block-Zeile (Diff-Minimierung).
- **Begleitanpassungen:** plugin.json 0.14.0, CHANGELOG, new-project-description;
  README-new-project-Zeile brauchte keine Änderung.
- **Geänderte Dateien:** `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/skills/build-step/SKILL.md`,
  `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `templates/global-CLAUDE.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
  `CHANGELOG.md`.
