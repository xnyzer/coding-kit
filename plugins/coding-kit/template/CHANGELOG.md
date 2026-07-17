# Changelog

All notable changes to the **template content** (`core/` + `modules/`) are documented here.
Every entry corresponds to a `VERSION` bump. `/update-conventions` reads this file to
explain pending updates to projects.

## [0.3.1] — 2026-07-17

### Changed
- Migrated the existing stack modules to the fragment scheme: each module's
  `CODING-STANDARDS.part.md` (go/python/ts-node) is now wrapped in `<!-- fragment:<module> -->`
  … `<!-- /fragment:<module> -->` markers (content otherwise unchanged), and each `MODULE.md`
  declares its (empty) `Standards fragments` set. Makes the parts conform to the append
  contract without changing any rule text.

## [0.3.0] — 2026-07-17

### Added
- Composable CODING-STANDARDS fragments — contract + scaffold. The §13 stack slot is now
  append-capable: standards fragments are each wrapped in `<!-- fragment:NAME -->` …
  `<!-- /fragment:NAME -->` and appended inside `<!-- module:coding-standards -->`, so a project
  composes several language/framework fragments instead of a single inserted block. Adds the
  `modules/standards/` catalog (`README.md` with the framework→fragment mapping; the fragments
  themselves are authored next) and documents the marker, the module `Standards fragments:`
  declaration, and the catalog in `MANIFEST.md`. Migrating the existing go/python/ts-node parts
  and validator support follow separately.

## [0.2.0] — 2026-07-17

Refinements surfaced by running `/update-conventions` against an instantiated project, and
one template bug it exposed. Project-specific divergences there (a pnpm toolchain, filled
`template:adapt` slots, a fuller stack-specific CODING-STANDARDS, a bilingual HOW-TO) stay as
registered overrides in that project and were not promoted.

### Added
- `core/AI-DISCLOSURE.md`: a general "Why this matters" section (human/AI collaboration
  model), present for every project.
- `core/CODING-STANDARDS.md`: new language-agnostic section 5 "Comments & documentation"
  (comment the *why*; document the public surface; English identifiers) — sections 6–13
  renumbered accordingly.
- `core/CODING-STANDARDS.md` §8: the "never commit" list now names real identifiers
  (people, customers, concrete projects) alongside secrets and deployment internals.

### Changed
- `core/CLAUDE.md`: add `/build-step` to the build chain in both "Status & where to start"
  (`prep-step → build-step → step-done`) and the "Workflow & skills" skill list.
- `core/CLAUDE.md`: scale the startup reading guidance — read `README`/`REQUIREMENTS` and
  `PROGRESS.md`'s open tasks + `FEATURE-INDEX`; scan (don't fully read) a large Done
  table/backlog; consult `PROGRESS-ARCHIVE.md` on demand, not at startup. Saves context.
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: refresh the skill overview to match the current
  coding-kit — add `/build-step`, `/teach-step` and a grouped "project maintenance" table
  (`/choose-stack`, `/choose-license`, `/update-conventions`, define/refine-requirements);
  note `/audit-code`'s optional scope; rewrite Workflow 2 as the `prep-step → build-step →
  step-done` loop with the `BACKLOG → PLANNED → done` status markers.
- `modules/{go,python,ts-node}`: section cross-references follow the renumbering above —
  `CODING-STANDARDS.part.md` (§6→§7 errors, §9→§10 tests, §7→§8 licenses) and `MODULE.md`
  (§12→§13, the stack slot). References to §1–§4 are unaffected.

### Removed
- `core/AI-DISCLOSURE.md`: the optional `security-tool` block. Its content was
  engineering-practice claims (vetted libraries, fail-closed, mandatory security review),
  not AI disclosure, and it duplicated `CODING-STANDARDS.md` §7/§8; the security policy
  belongs in `SECURITY.md`. The file is now identical in every project — `MANIFEST.md`
  updated accordingly (the `template:optional` mechanism remains, used by `graphiti`).

### Fixed
- `core/private/README.md` now exists. `MANIFEST.md` listed it as a managed source and
  `.gitignore` whitelists it (`!private/README.md`), but the file was missing — every
  instantiation lacked the `private/` convention marker.

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
