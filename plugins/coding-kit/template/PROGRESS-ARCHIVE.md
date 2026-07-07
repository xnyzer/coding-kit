# project-template — Progress Archive

Finished tasks with their full write-up: what was implemented, which files were touched,
and notable decisions. Newest entries at the top. The living list is `PROGRESS.md`.

---

## F-001 — Initial template build (2026-07-07)

**Problem:** No reusable template existed; every new project re-derived its setup from old
projects.

**What was built (90 files):**

- **Root meta level:** own CLAUDE.md (structure rules + sync invariant: managed-file
  change ⇒ VERSION bump + CHANGELOG entry + MANIFEST update), PROGRESS/-ARCHIVE, README,
  VERSION 0.1.0, CHANGELOG, MANIFEST (manifest-format 1: placeholder registry, marker
  conventions, file policies managed/seed/public-only/module, module contract, standard
  recipe set), governance (CONTRIBUTING, SECURITY, AI-DISCLOSURE, CODE_OF_CONDUCT on
  Contributor Covenant 3.0, Apache-2.0 LICENSE), hardened `.claude/settings.json`,
  `scripts/validate.py` (JSON/YAML/TOML syntax, placeholder registry, privacy lint),
  own CI (`just check` via SHA-pinned checkout v7.0.0 + mise-action v4.2.0), lefthook
  (gitleaks + validator), mise.toml + committed cross-platform mise.lock.
- **core/:** CLAUDE.md template (Graphiti as optional block), CODING-STANDARDS with
  write-then-verify (§10), trunk-based/squash (§11) and module slot (§12), CONTRIBUTING,
  SECURITY (adapt slots), HOW-TO-CODE-WITH-CLAUDE (contributor setup incl. plugin
  install), AI-DISCLOSURE (optional security-tool block), PROGRESS skeletons with
  FEATURE-INDEX (F-NNN), REQUIREMENTS (out-of-scope, dated decision logs, open-question
  checkboxes), M6-hardened settings.json + convention-overrides registry + skills README,
  issue forms + PR template, hardened ci.yml with `# module:ci-jobs` append marker,
  CodeQL toggle workflow (public-only, `{{CODEQL_LANGUAGES}}`), docs-only justfile
  (recipe contract setup/dev/test/lint/format/check/build), mise.toml (just/lefthook/
  gitleaks, lockfile=true), lefthook.yml (gitleaks + `just format` with stage_fixed),
  renovate.json (extends the coding-kit preset), .gitignore with `.env*`/private/
  conventions and module append marker, editorconfig/gitattributes, ADR scaffold.
- **modules/:** docs-only (core defaults), ts-node (pnpm + strict tsconfig per current
  `tsc --init` set + nodenext ESM + Biome + vitest; no Corepack dependency), python
  (uv + src layout + uv_build + ruff + pyright strict + pytest), go (distilled from the
  [redacted-downstream-project] gold standard: gofmt gate, golangci-lint v2 standard set, -race
  tests, go-licenses gate locally + as CI job), swift-ios/java as documented stubs.

**Notable decisions:**

- Template content under `core/` + `modules/`, repo root owns its own docs/CI — resolves
  the dogfooding-vs-template conflict (root CLAUDE.md can't be both).
- Module justfile **replaces** the core justfile (no merge logic); the recipe set is the
  stable contract skills/CI call.
- CodeQL needs a language ⇒ registered placeholder `{{CODEQL_LANGUAGES}}` provided by the
  module; docs-only projects don't get the workflow.
- core/LICENSE ships the real Apache-2.0 text (canonical apache.org copy) as default;
  `/choose-license` replaces it only on deviation/TBD.
- Known caveat documented in `core/.claude/README.md`: deny rules beat allow rules, so
  `.env.example` may be blocked too depending on Claude Code version (fail-safe
  direction; D8 smoke test verifies empirically).

**Verification:** `just check` (validator) green; all four justfiles parse; lefthook
configs valid; `mise install` + `mise lock` work (28 platform entries); gitleaks clean;
personal-data grep zero hits.
