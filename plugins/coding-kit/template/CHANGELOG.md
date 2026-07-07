# Changelog

All notable changes to the **template content** (`core/` + `modules/`) are documented here.
Every entry corresponds to a `VERSION` bump. `/update-conventions` reads this file to
explain pending updates to projects.

## [0.1.0] — 2026-07-07

### Added
- Initial `core/`: governance documents (CODING-STANDARDS, CONTRIBUTING, SECURITY,
  HOW-TO-CODE-WITH-CLAUDE, AI-DISCLOSURE, CODE_OF_CONDUCT), PROGRESS/PROGRESS-ARCHIVE
  skeletons with FEATURE-INDEX, REQUIREMENTS template, hardened `.claude/settings.json`,
  convention-overrides registry, issue forms + PR template, hardened CI (`just check`),
  CodeQL toggle workflow, justfile/mise/lefthook/renovate/editorconfig/gitattributes/
  gitignore, `private/` convention, ADR scaffold, README scaffold, LICENSE default.
- Initial modules: `docs-only`, `ts-node`, `python`, `go` (full); `swift-ios`, `java` (stubs).
- `MANIFEST.md` (manifest-format 1) with placeholder/marker conventions and file policies.
