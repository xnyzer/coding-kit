---
id: F-004
title: Globale CLAUDE.md-Vorlage
type: feature
status: DONE
size:
created: 2026-07-07
done: 2026-07-07
depends-on:
superseded-by:
---

# F-004 — Globale CLAUDE.md-Vorlage

## Verlauf

### F-004 — Globale CLAUDE.md-Vorlage (2026-07-07)

**Was entstanden ist:** `templates/global-CLAUDE.md` — die schlanke Vorlage der globalen
House-Defaults (Sprache & Stil, Git-/Commit-Regeln inkl. Laufzeit-Auflösung der
Noreply-E-Mail, Graphiti-Regeln mit group_id-Quelle Root-CLAUDE.md + `main` für
Übergreifendes, Arbeitsweise mit Write-then-Verify, F-Nummern-Workflow, private/-
Konvention, Verweis auf die Plugin-Skills). Die Datei ist bewusst schlank (lädt in jede
Session) und identisch mit `~/.claude/CLAUDE.md` auf dem Rechner — dadurch funktioniert
der bestehende Installer-Schritt (cp bei Neueinrichtung, diff-Hinweis bei Abgleich) ohne
Code-Änderung; er war ab F-001 vorbereitet und ist jetzt aktiv.

**Migration (einmalige Nutzeraktion, erledigt):** Inhalte der Legacy-Datei
`~/.claude/instructions.md` überführt und modernisiert — group_id-Quelle ist jetzt die
Root-CLAUDE.md des Projekts (nicht mehr `.claude/instructions.md`); hartkodierte
E-Mail-Adressen durch Laufzeit-Auflösung via `gh api` ersetzt (die Vorlage ist public —
keine Identität im Text). Die Legacy-Datei wurde nach Backup in `private/` gelöscht
(sie wurde von Claude Code ohnehin nicht geladen).

**Entscheidungen:**

- Vorlage und lokale Datei bleiben byte-identisch und generisch (keine persönlichen
  Werte nötig — alles Persönliche kommt zur Laufzeit oder aus der Personal-Config).
- Kein plugin.json-Bump: `templates/` und Installer sind Repo-, nicht Plugin-Inhalt;
  die Sync-Invariante (Version + CHANGELOG) gilt nur für Skills/Hooks.
