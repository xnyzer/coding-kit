# Changelog

Versioniert wird das Plugin (`plugins/coding-kit/.claude-plugin/plugin.json`, semver).
Jede inhaltliche Plugin-Änderung bumpt die Version und bekommt hier einen Eintrag —
im selben Commit.

## 0.1.0 — 2026-07-07

Erstes Grundgerüst:

- Vier Core-Skills: `add-feature`, `prep-step`, `step-done` (mit Privacy-Scan der
  lebenden Doku), `audit-code` — stack-agnostisch, personendatenfrei, F-NNN-tolerant.
- Projekterkennender Stop-Hook (PROGRESS.md mit FEATURE-INDEX oder
  `.claude/template-version`; blockt höchstens einmal pro Stopp).
- Marketplace `xnyzer` mit Plugin-Quelle im selben Repo.
- Renovate-Shareable-Preset (`default.json`): `config:recommended` + Action-Digest-
  Pinning + Label `dependencies`.
- Idempotenter Installer (`install.sh`) inkl. Personal-Config `~/.claude/coding-kit.env`.
