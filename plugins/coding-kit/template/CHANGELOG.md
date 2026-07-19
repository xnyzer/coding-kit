# Changelog

All notable changes to the **template content** (`core/` + `modules/`) are documented here.
Every entry corresponds to a `VERSION` bump. `/update-conventions` reads this file to
explain pending updates to projects.

## [0.9.0] — 2026-07-19

Docs alignment with the current coding-kit skill set; no rule text or file set changed.

### Changed
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: refresh the skill overview for the current coding-kit —
  `/prep-step` additionally checks standards coverage when a task introduces new
  frameworks/dependencies (matching the catalog's dependency signals **and** characteristic
  triggers; proposes appending missing catalog fragments, or authoring a project-local
  fragment with a manual adoption proposal for the template); `/step-done` gains a
  non-blocking, diff-based standards-coverage backstop (new manifest dependencies or signal
  files without a fragment are reported with an append proposal); `/choose-stack` composes
  the module's declared catalog fragments (append, idempotent per `fragment:NAME` marker)
  and retrofits characteristic fragments after confirmation; `/update-conventions` syncs
  fragment-granular and downward only, never touching project-local fragments;
  `/define-requirements` asks the catalog's characteristic triggers in the interview.
- `modules/standards/README.md`: describe trigger evaluation as implemented — `/prep-step`
  matches both signal types; characteristic triggers are asked in the requirements
  interview, at feature planning, and retrofittable via `/choose-stack`.
- Sync direction made explicit across the docs (`MANIFEST.md` § Sync direction, root
  `README.md`, root `CONTRIBUTING.md`): convention flow is exclusively downward
  (template → project); the former upstream/promote path is gone — contributions from
  projects arrive as manually initiated adoption proposals (template session or GitHub
  issue), never as automatic writes.

## [0.8.0] — 2026-07-18

### Added
- `core/scripts/privacy-lint.sh` plus a `privacy-lint` pre-commit job in
  `core/lefthook.yml`: every project now blocks commits that would leak private
  identifiers. Generic patterns (absolute local paths, IPs and email addresses outside
  the documentation allowlists) always apply; an optional gitignored
  `private/blocklist.txt` adds project-private terms and is silently skipped where
  absent (e.g. in CI). POSIX sh + grep only — no new toolchain dependency. Convention
  documented in `core/private/README.md`; the secrets-policy section in
  `core/CONTRIBUTING.md` now names the full pre-commit gate; registered as a managed
  file in `MANIFEST.md`.

## [0.7.1] — 2026-07-18

### Changed
- `modules/README.md`: clarify that `standards/` is not a stack module but the
  cross-cutting catalog of reusable CODING-STANDARDS fragments, with a pointer to its
  own README.

## [0.7.0] — 2026-07-18

### Added
- Standards fragment `audit-logging` in the `modules/standards/` catalog: accountability
  trail for services with user/admin mutations — what must be logged (domain mutations,
  permission/role changes, auth and admin operations, including denied attempts), what an
  entry carries (actor, action, target, timestamp, outcome — never secrets or full
  payloads), properties (append-only, coupled to the mutation, queryable, deliberate
  retention), and the separation from application logging.

### Changed
- `modules/standards/README.md`: the catalog mapping now supports **project-characteristic
  triggers** alongside dependency signals — for fragments (like `audit-logging`) that no
  package manifest can reveal; evaluating those triggers stays coding-kit logic.

## [0.6.0] — 2026-07-18

### Added
- `core/CODING-STANDARDS.md` §7 (heading extended to "Error handling, resilience &
  concurrency"): two language-agnostic concurrency rules — deduplicate concurrent async
  work via an in-flight promise/future that every concurrent caller awaits (applies where
  shared mutable state, several independent async triggers, and expensive or side-effectful
  work meet; cheap idempotent reads need no guard), and set the completion marker only
  after the awaited work finishes, so concurrent readers never observe a half-finished
  state as done. No section renumbering.

## [0.5.0] — 2026-07-17

### Added
- Standards fragments `api-design`, `docker`, and `nginx` in the `modules/standards/` catalog,
  completing the initial web set. `api-design` covers thin-routes/fat-services, URL/method/
  status conventions, schema-validated request/response, and the web security boundary
  (explicit authorization, rate limiting, forbidden patterns, credentials & data protection,
  security headers); `docker` covers multi-stage images, non-root runtime, layer caching,
  healthchecks, PID-1 signal handling, compose and entrypoint/startup; `nginx` covers the
  reverse-proxy hardening (per-location header re-declaration, WebSocket, compression, SPA
  cache strategy, HSTS placement). Generalized and senior-hardened; registered in the mapping.

## [0.4.0] — 2026-07-17

### Added
- Standards fragments `react` and `prisma` in the `modules/standards/` catalog (the first
  entries), generalized from real full-stack sources and senior-hardened: `react` covers
  function-component/hooks discipline, component size, design-token/slot-based styling,
  accessibility, i18n and performance; `prisma` covers deliberate querying (no N+1,
  paginate, transactions, one client, explicit constraint handling) and immutable
  migrations with DB-enforced integrity. Registered in the framework→fragment mapping.

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
