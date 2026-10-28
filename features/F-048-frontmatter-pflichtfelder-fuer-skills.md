---
id: F-048
title: Frontmatter-Pflichtfelder und erlaubte Felder für Skills
type: feature
status: DONE
size:
created: 2026-10-26
done: 2026-10-26
depends-on:
superseded-by:
---

# F-048 — Frontmatter-Pflichtfelder und erlaubte Felder für Skills

## Verlauf

### F-048 — Frontmatter-Pflichtfelder für Skills und Übersicht der erlaubten Felder (2026-10-26)

**Problem:** Ob ein Skill nur vom Nutzer oder auch von Claude gestartet wird und ob er
einen Slash-Command hat, stand nicht überall ausdrücklich im Frontmatter: 18 von 19
Plugin-Skills setzten `disable-model-invocation`, `user-invocable` nur
`propose-to-template`. Weder die Authoring-Doku noch `/add-skill` noch der Validator
verlangten die Felder — `explain-level` (F-040b) entstand zunächst ohne die Zeile. Welche
weiteren Felder Claude Code für Skills kennt, war im Kit nirgends geprüft festgehalten.

**Planungsentscheidungen** (aus dem Eintrag, nach Prüfung der Claude-Code-Doku):
- Pflicht in jedem Skill (Plugin und `.claude/skills/`): `name`, `description`,
  `disable-model-invocation` und `user-invocable` — die beiden Flags ausdrücklich und
  wörtlich `true` oder `false`; `user-invocable: false` nie zusammen mit
  `disable-model-invocation: true`.
- Der Validator lässt nur die 20 Felder zu, die die Claude-Code-Doku für Skills nennt, und
  prüft die Grenze von 1536 Zeichen für `description` plus `when_to_use`.
- `argument-hint` für jeden Skill, der ein Argument nimmt.
- `default-enabled` gibt es für Skills nicht (nur `defaultEnabled` im Plugin-Manifest).
- Nicht jetzt: `when_to_use`, `allowed-tools`, `hooks`, `paths`, `arguments`, `metadata`,
  `license`, `compatibility`. Über `model` und `effort` entscheidet F-046; `context: fork`
  geht als Hinweis an F-037, `shell` an F-027.

**Was entstanden ist (1.6.0, unveröffentlicht):**

- **Alle 20 Skills** (19 im Plugin, `add-skill` repo-lokal): beide Flags ausdrücklich —
  19-mal `user-invocable` ergänzt, bei `propose-to-template`
  `disable-model-invocation: false`. Zwölf Skills mit Argument bekommen ein
  `argument-hint` in Anführungszeichen (add-feature, audit-code, build-step,
  check-upstreams, define-requirements, handoff, name-it, new-project, prep-step,
  refine-prompt, teach-step, update-conventions). Reihenfolge der Felder: `name`,
  `description`, `argument-hint`, `disable-model-invocation`, `user-invocable`,
  `disallowed-tools`.
- **`scripts/validate.py`:** `check_skill_frontmatter` und `check_skills_dir` für Plugin-
  und repo-lokale Skills — Pflichtfelder, beide Flags wörtlich `true` oder `false` (die
  Doku nähme auch `yes` oder `on`), die verbotene Kombination, die Feldliste
  `SKILL_FIELDS` (20 Felder laut Claude-Code-Doku) und die Grenze `SKILL_LISTING_CAP`.
  Bisher prüfte er nur `name` und `description` der Plugin-Skills.
- **`docs/skill-authoring.md` § Frontmatter:** Pflichtfelder mit einer Tabelle, was `true`
  und `false` bewirken — samt Kontextkosten: Die Beschreibung eines Skills mit
  `disable-model-invocation: true` steht nicht im Kontext —, die Längengrenze, eine
  Feldübersicht mit der Nutzung im Kit; `default-enabled` gestrichen.
- **`/add-skill`:** Interviewfrage 5 fragt beide Flags und `argument-hint`; neuer
  Checklistenpunkt „Beide Arten: Frontmatter".
- **PROGRESS:** Hinweise unter „Noch zu analysieren" in F-027 (auch der Session-Hinweis
  startet über `bash`; Feld `shell`) und F-037 (`context: fork`).
- **CHANGELOG** unter 1.6.0.

**Verifikation:** Die Startwerte aller 20 Skills vorher und nachher per Skript verglichen
— gleich; der Diff fügt in den Plugin-Skills nur Frontmatter-Zeilen hinzu. Vor dem
Nachziehen meldete der Validator genau die 20 Lücken. Fehlerprobe an Kopien: `yes` statt
`true`, die verbotene Kombination, das unbekannte Feld `disable-model-invokation` und eine
Beschreibung mit 1950 Zeichen werden gemeldet, der unveränderte Skill nicht. `just check`
grün (1590 Checks). Secrets- und Privacy-Scan ohne Fund.

**Notable decisions:**
- Wörtliches `true`/`false` statt der Varianten, die Claude Code auch akzeptiert: So
  versteht ein Leser den Wert ohne YAML-Wissen.
- Die Feldliste steht im Validator, nicht nur in der Doku, weil Claude Code ein
  unbekanntes Feld still ignoriert. Bringt Claude Code ein neues Feld, meldet der
  Validator es, bis es in `SKILL_FIELDS` steht.
- `argument-hint` ist Konvention, aber nicht geprüft: Ob ein Skill ein Argument nimmt,
  kann der Validator nicht wissen.
- Beim Eintragen fiel auf, dass auch der Session-Hinweis aus F-040d über `bash` startet —
  in F-027 vermerkt.
- Für F-046: Die Beschreibungen der zehn von Claude startbaren Skills stehen in jeder
  Runde im Kontext (rund 4250 Zeichen); `update-conventions` liegt mit 1383 Zeichen nahe
  an der Grenze.

**Geänderte Dateien:** `plugins/coding-kit/skills/*/SKILL.md` (alle 19),
`.claude/skills/add-skill/SKILL.md`, `scripts/validate.py`, `docs/skill-authoring.md`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`.
