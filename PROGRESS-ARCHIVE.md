# coding-kit — Progress-Archiv

Abgeschlossene Aufgaben mit Detail und Begründung. Neueste oben.

---

## F-001 — Kit-Grundgerüst (2026-07-07)

**Was entstanden ist:**

- **Marketplace** `.claude-plugin/marketplace.json` — Name `xnyzer`, Plugin per relativem
  `source: "./plugins/coding-kit"` → `/plugin marketplace add xnyzer/coding-kit` und
  `/plugin install coding-kit@xnyzer` funktionieren direkt.
- **Plugin** `plugins/coding-kit/` — `plugin.json` (Version 0.1.0), vier Core-Skills,
  Stop-Hook.
- **Skills** (generalisiert aus erprobten projektlokalen Vorlagen, personendatenfrei,
  stack-agnostisch): `add-feature`, `prep-step`, `step-done`, `audit-code`. Gemeinsame
  Bausteine: Projektkontext aus der Projekt-CLAUDE.md (group_id, Doku-Sprache,
  Sicherheits-Postur), Checks nur über just-Standardrezepte, F-Nummern-Toleranz (alt
  lesen, F-NNN schreiben), Kontext-Recovery-Block (M4), Write-then-Verify (M3) in
  step-done, Privacy-Scan der lebenden Doku in step-done, Commit-E-Mail-Check zur
  Laufzeit via `gh api` (kein Hardcode).
- **Stop-Hook** `hooks/stop-reminder.sh` — projekterkennend (PROGRESS.md mit
  FEATURE-INDEX oder `.claude/template-version`), blockt einen Stopp höchstens einmal
  (`stop_hook_active`-Schutz) und verweist auf `/coding-kit:step-done`; in fremden Repos
  vollständig still.
- **Renovate-Preset** `default.json` (Root): `config:recommended` +
  `helpers:pinGitHubActionDigests` + Label `dependencies`; Doku in
  `docs/renovate-preset.md`. Kit und project-template extenden es selbst (Dogfooding).
- **Installer** `install.sh` — idempotent: prüft gh/claude, richtet Marketplace + Plugin
  ein, legt `~/.claude/coding-kit.env` an (via `gh api` vorbefüllt, chmod 600), bietet
  Toolchain-Installation an; globale CLAUDE.md-Einrichtung folgt mit F-004.
- **Doku:** deutsches `README.md`, `docs/skill-authoring.md` (verbindliche
  Authoring-Konvention), `CLAUDE.md` (Dogfooding), Governance auf Englisch
  (LICENSE Apache-2.0, CODE_OF_CONDUCT CC 3.0, SECURITY, CONTRIBUTING, AI-DISCLOSURE).
- **Qualität:** `scripts/validate.py` (JSON/YAML/TOML-Syntax, Plugin-/Marketplace-/
  Skill-Frontmatter-Checks, Privacy-Lint) via `just check`, lefthook (gitleaks +
  Validator), gehärtete CI (permissions minimal, Actions SHA-gepinnt, Concurrency).

**Entscheidungen:**

- Stop-Hook blockt (JSON `decision: block`) statt nur zu echoen — die Erinnerung erreicht
  das Modell zuverlässig; der `stop_hook_active`-Schutz verhindert Schleifen.
  Hook-Ausgabe auf Englisch, weil sie in beliebigen (oft öffentlichen) Projekten wirkt.
- Kit versioniert über `plugin.json` + `CHANGELOG.md` (keine separate VERSION-Datei wie
  im Template — die Skills koppeln an die MANIFEST-Formatversion des Templates, nicht an
  Kit-Versionen).
- `project-template/renovate.json` (Root) im Zuge dessen aufs Preset umgestellt
  (TODO(D3) dort erledigt; Root-Datei ist nicht manifest-verwaltet → kein VERSION-Bump).
