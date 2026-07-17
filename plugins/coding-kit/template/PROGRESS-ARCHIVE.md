# project-template — Progress Archive

Finished tasks with their full write-up: what was implemented, which files were touched,
and notable decisions. Newest entries at the top. The living list is `PROGRESS.md`.

---

## F-003a — Web-standards fragments: react + prisma (2026-07-17)

**Problem:** The composable-standards catalog (`modules/standards/`) existed but held no
fragments — a full-stack project had nothing to compose for its frontend/data layer.

**What was built (5 files; VERSION 0.3.1 → 0.4.0):**

- `modules/standards/react.md` (new): React standard — function components + hooks, typed props,
  custom hooks, local/server-state discipline, component size, design-token/slot-based styling,
  accessibility, i18n, performance.
- `modules/standards/prisma.md` (new): Prisma standard — deliberate querying (no N+1, paginate,
  transactions, one shared client, explicit constraint handling) and immutable migrations with
  DB-enforced integrity.
- `modules/standards/README.md`: registered both in the framework→fragment mapping.
- `VERSION`, `CHANGELOG.md`.

**Notable decisions:**

- Generalized from real full-stack sources and **senior-hardened** (not a copy): added
  server-state-via-cache-layer, stable list keys, controlled inputs, accessibility and a lazy-UI
  error boundary to `react`; deliberate `select`, one shared client, explicit constraint-violation
  handling and indexing to `prisma`.
- **Name-free**, no version pins; project-specific rules (domain abstractions, project theme
  specifics) deliberately left out. A coverage check against the sources confirmed no
  framework-general rule was dropped.

**Verification:** `just check` green (markers balanced, no dangling declarations, privacy lint);
both fragments self-wrapped and mapped. (Same commit also lands the F-003 plan and the F-005/F-006
intake.)

---

## F-002c — Composable CODING-STANDARDS: validator support (2026-07-17)

**Problem:** Nothing enforced the new fragment contract, so a malformed fragment marker or a
`MODULE.md` declaring a non-existent catalog fragment would pass silently.

**What was built (1 file — repo tooling, no VERSION bump):**

- `scripts/validate.py`: two new checks — (a) `check_fragment_markers` scans every file for
  `<!-- fragment:NAME -->` markers and stack-verifies they are balanced and well-nested; (b)
  `check_fragment_declarations` parses each `modules/*/MODULE.md` "Standards fragments"
  declaration and flags any fragment name absent from the `modules/standards/` catalog.

**Notable decisions:**

- The marker regex matches lowercase-kebab names only (`[a-z0-9][a-z0-9-]*`), so documentation
  placeholders (`fragment:NAME` uppercase, `fragment:<name>` bracketed) never false-positive —
  keeping the MANIFEST / README / §13 example markers clean.
- No VERSION bump: `validate.py` is repo tooling, not shipped template content.

**Verification:** `just check` green on the real repo; temporary fixtures confirmed both checks
fire (unclosed `fragment:zzz`; dangling declaration `nope`), then removed and re-verified green.

**This completes F-002** (composable CODING-STANDARDS fragments): contract + catalog scaffold
(F-002a), module migration (F-002b), validator (F-002c). Web fragments follow in F-003; the
coding-kit-side assembly is tracked separately.

---

## F-002b — Composable CODING-STANDARDS: migrate existing modules (2026-07-17)

**Problem:** After F-002a defined the fragment contract, the existing stack modules still shipped
their `CODING-STANDARDS.part.md` as unwrapped blocks — not conforming to the new append/marker
scheme.

**What was built (8 files):**

- `modules/{go,python,ts-node}/CODING-STANDARDS.part.md`: each wrapped in
  `<!-- fragment:<module> -->` … `<!-- /fragment:<module> -->` markers; rule text unchanged
  (marker-only diff — exactly 6 insertions total, markers balanced open=close per module).
- `modules/{go,python,ts-node}/MODULE.md`: added a `Standards fragments: (none)` declaration —
  these single-package language modules pull no catalog fragments.
- `VERSION` 0.3.0 → 0.3.1; `CHANGELOG.md` entry.

**Also in this commit (privacy scrub, not F-002b scope):** replaced a concrete downstream project
name with a neutral wording in `modules/go/MODULE.md` and the F-001 archive entry, per the
repo-wide no-real-names rule. Remediating the already-published git history is tracked as F-004.

**Notable decisions:**

- Fragments self-wrap (the marker lives in the fragment file), so the coding-kit assembly just
  concatenates — no wrapping at runtime.
- A module's own language part is `fragment:<module>`; catalog fragments are declared separately
  and are none for these three.

**Verification:** `just check` green; marker-only diff confirmed; markers balanced; declarations
present in all three `MODULE.md`; working-tree name scan clean.

---

## F-002a — Composable CODING-STANDARDS: fragment contract + catalog scaffold (2026-07-17)

**Problem:** The §13 stack slot took a single inserted module part, so a project could not
compose standards for several frameworks or grow them over time. F-002a lays the contract for
composable fragments; migration (F-002b) and validator support (F-002c) follow.

**What was built (5 files):**

- `MANIFEST.md`: registered the `<!-- fragment:NAME -->` … `<!-- /fragment:NAME -->` marker;
  updated the `module:coding-standards` marker and the `CODING-STANDARDS.part.md`
  module-contract row to append/wrap semantics; new "## Standards fragments" section (catalog,
  the `MODULE.md` `Standards fragments:` declaration, policy, assembly boundary).
- `core/CODING-STANDARDS.md`: §13 slot now documents append + per-fragment markers.
- `modules/standards/README.md` (new): catalog scaffold — framework→fragment mapping table
  (empty until fragments are authored) + how a module declares fragments.
- `VERSION` 0.2.0 → 0.3.0; `CHANGELOG.md` entry.

**Notable decisions:**

- Central reusable catalog `modules/standards/` (not fragments buried per stack module) — a
  fragment like `react`/`docker` can be pulled by any module that needs it.
- Fragments are self-wrapping (each file carries its own `fragment:NAME` markers); skills
  concatenate, no wrapping at runtime.
- A module pulls its own language fragment implicitly and declares additional catalog fragments
  via a `Standards fragments:` line in its `MODULE.md`.
- Runtime assembly stays coding-kit logic; F-002 defines only the contract + data + validator.
  Full end-to-end composition needs the coding-kit `choose-stack` change (tracked separately).

**Verification:** `just check` (validator) green; §13 slot and MANIFEST section reviewed;
internal link `../../MANIFEST.md` resolves; secrets/privacy scan clean.

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
  (uv + src layout + uv_build + ruff + pyright strict + pytest), go (distilled from a
  production Go service gold standard: gofmt gate, golangci-lint v2 standard set, -race
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
