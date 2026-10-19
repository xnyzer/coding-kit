# project-template — Progress

Living task list. **Done table** at the top, **open tasks in execution order** below,
**feature index** at the very end.

How it works: `/add-feature` intakes new tasks (F-number), `/prep-step` prepares and
decomposes, `/step-done` finishes (review, docs, commit question).

---

## Done

| Step | Description | Completed |
|------|-------------|-----------|
| F-001 | Initial template build → **core/ + modules (docs-only, ts-node, python, go; stubs swift-ios/java), MANIFEST format 1, validator + CI, all checks green.** Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-002a | Composable CODING-STANDARDS: fragment contract + catalog scaffold. Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-17 |
| F-002b | Composable CODING-STANDARDS: migrate existing modules to the fragment scheme. Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-17 |
| F-002c | Composable CODING-STANDARDS: validator support (fragment markers + declarations). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-17 |
| F-003a | Web-standards fragments: react + prisma. Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-17 |
| F-003b | Web-standards fragments: api-design + docker + nginx. Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-17 |
| F-004a | Real-name leak remediation: history rewrite + force-push, residual risk accepted. Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-18 |
| F-004b | Real-name leak prevention: private blocklist check in the validator. Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-18 |
| F-005 | Core concurrency rules: in-flight dedup + completion marker last (§7, VERSION 0.6.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-18 |
| F-006 | Standards fragment `audit-logging` + characteristic triggers in the catalog (VERSION 0.7.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-18 |
| F-007 | Repo docs refreshed for the fragment catalog: root README structure, modules/README pointer (VERSION 0.7.1). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-18 |
| F-008 | Privacy lint + private blocklist shipped to projects: core script + lefthook gate (VERSION 0.8.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-18 |
| F-009 | Docs aligned with the current coding-kit skill set; sync direction made explicitly downward-only (VERSION 0.9.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-010 | Per-dimension language matrix: Languages block in core/CLAUDE.md with five `{{LANG_*}}` placeholders, visibility-coupled default removed (VERSION 0.10.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-011a | Seed section-marker contract: `section:NAME` registered in MANIFEST (§ Markers, seed policy, § Seed sections inventory), validator check generalized (VERSION 0.11.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-20 |
| F-011b | Section markers applied to all six seed skeletons per the MANIFEST inventory (wrappers only, no prose changes; shipped with VERSION 0.11.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-07-20 |
| F-012 | ts-node seed files ship Biome-clean: quotes fixed in `index.test.ts` / `vitest.config.ts`, `$schema` resolved from node_modules, deprecated `rules.recommended` → `rules.preset` (VERSION 0.11.3). Detail in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |
| F-013 | Catalog fragment `nextjs`: App Router boundaries, routing & caching, assets/build, configuration traps; retrofit-only, no module declares it (VERSION 0.12.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |
| F-014 | Permission fix: broad `**/.env.*` deny shadowed the `.env.example` allow entries in both settings files; replaced by the secret-bearing variants (shipped with VERSION 0.12.0). Superseded by F-015. Detail in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |
| F-015 | Env deny set carves the `.env.example` exception via positive character classes — fail-closed again without renaming the placeholder; `agentRules` rule reversed to vendor-aligned (VERSION 0.13.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |
| F-016 | `nextjs` fragment: `agentRules` rule described the greenfield branch; corrected to the routing that actually applies to template projects, plus the `AGENTS.md` requirement and remediation order (VERSION 0.13.1). Detail in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |
| F-017 | HOW-TO rows for `/choose-stack`, `/update-conventions` and `/prep-step` cover fragment companion actions; catalog marker deliberately not introduced (VERSION 0.13.2). Detail in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |

---

## Open tasks — work top to bottom

_No prepared tasks. Plan a backlog item via `/prep-step`._

---

## Feature ideas (backlog)

_Intake new ideas via `/add-feature` — they get the next F-number._

### F-018 — HOW-TO: state where the workflow skills come from

**Status:** BACKLOG

**Problem:** The skill overview in `core/HOW-TO-CODE-WITH-CLAUDE.md` lists the workflow
skills without saying where they live. Only setup step 2 hints at it in passing, so a
reader can look for them in the repository, does not learn the namespaced call form, and
does not see that the workflow also works without the plugin.

**Idea:** Add one short paragraph directly below `## Overview: skills` that states the
origin (coding-kit plugin, set up in the contributor setup), both call forms (short name
and plugin namespace) and the manual fallback (PROGRESS.md workflow + `just` recipes).
Everything else in the file stays as it is.

**Solution sketch:**
- Starting point for the wording (from intake, not binding — `/prep-step` may propose
  better wording after analysis): "None of these skills live in this repository — they
  come from the coding-kit plugin for Claude Code (setup step 2). They can be called by
  their short name (`/add-feature`) or with the plugin's namespace
  (`/coding-kit:add-feature`). Without the plugin, the workflow in PROGRESS.md and the
  `just` recipes still work by hand."
- Sync invariant: patch `VERSION` bump + `CHANGELOG.md` entry in the same commit; no
  `MANIFEST.md` change (no file added, removed or re-policied).

**Dependencies:** none.

**Still to analyse:**
- Verify against the current Claude Code docs when a plugin skill's short name resolves
  (e.g. only without a name collision) — qualify the sentence if needed.
- Numeric reference "setup step 2" vs. a reference to the *Contributor setup* section,
  which survives renumbering.
- Overlap with the step-2 note "(provides the workflow skills used below)" — keep both or
  tighten one.

### F-019 — Standards fragment astro

**Status:** BACKLOG

**Problem:** The catalog has no fragment for Astro. A project that adopts Astro gets no
guidance on the static-first/islands model, Astro's built-in CSP, its asset pipeline or
how `.astro` files enter the quality gate, and nothing records that Astro's bundler
resolution contradicts the `.js`-extension rule of the `ts-node` fragment.

**Idea:** Add a catalog fragment `modules/standards/astro.md` (trigger: `astro`) covering
static-first rendering with islands, a strict CSP, build & dependencies, and imports.
Like `nextjs`, no module declares it; projects retrofit it via `/choose-stack` or
`/prep-step`.

**Solution sketch:**
- New fragment file wrapped in the `fragment:astro` markers, plus a catalog row in
  `modules/standards/README.md`:
  `| astro | Astro static-first sites: islands, strict CSP, build pipeline, images | astro |`
- Cross-reference `nginx` for header-only directives (as `nextjs` references
  `api-design`) and mention that React islands additionally fall under `react`.
- Add an imports section: extensionless relative imports (bundler resolution) as the
  documented exception to the `ts-node` `.js`-extension rule, to be recorded in
  `.claude/convention-overrides.md` (same pattern as `nextjs`).
- Drop the draft's "Text" section (i18n layer, brand names from configuration): not
  Astro-specific, would force an i18n layer on single-language sites (intake decision).
- Sync invariant: minor `VERSION` bump + `CHANGELOG.md` entry in the same commit; no
  `MANIFEST.md` change — fragment files are not listed individually (F-013 precedent).
- Draft body from intake (proposed in another session; not binding, markers and the
  dropped "Text" section omitted):

  ```markdown
  ### Astro

  **Static first, islands only where needed**
  - Pages and layouts are `.astro` components; they render to HTML at build time and ship
    no JavaScript. Content must be readable without JavaScript.
  - Interactivity comes only as an island: a UI-framework component with a `client:*`
    directive. Prefer `client:visible`/`client:idle` over `client:load`; every island has to
    justify its weight against the project's load budget.
  - Islands do not share framework context — share state through a small store library
    (e.g. Nano Stores).
  - Areas with personal data are client-only (`client:only`), never prerendered with user
    data, and marked `noindex`.

  **Strict Content Security Policy**
  - Use Astro's built-in CSP (hashes for its own inline scripts and styles); never add
    `'unsafe-inline'` or `'unsafe-eval'`.
  - No inline event handlers, no `set:html` with untrusted content, no third-party scripts,
    styles or fonts from CDNs.
  - Avoid features the CSP hashes do not cover (check the Astro CSP docs, e.g. view
    transitions via `<ClientRouter/>`, Shiki).
  - Header-only directives (`frame-ancestors`, HSTS, …) come from the server/proxy, not from
    the `<meta>` tag.

  **Build & dependencies**
  - `dependencies` of the site are shipped to browsers (and belong in the project's
    third-party license list); build tools are `devDependencies`.
  - Raster images go through `astro:assets` (`<Image>`/`<Picture>`) and are optimized at
    build time. The default service (sharp) bundles libvips under LGPL: check it against the
    project's license policy; with static output it runs only at build time.
  - If the project needs a service worker, generate it in a post-build step over `dist/`
    when no maintained Astro integration supports the current major version.
  - Type-check `.astro` files with `astro check` in the gate; when linting with Biome, apply
    the reduced rule set Biome documents for Astro files.
  ```

**Dependencies:** none.

**Still to analyse:**
- `dependencies` vs. `devDependencies` rule: the Astro scaffold lists `astro` itself under
  `dependencies`, so "dependencies are shipped to browsers" is not accurate — reword.
- Conditional wording for project-specific notions ("load budget", "third-party license
  list") — e.g. "if the project defines one".
- Verify version-dependent claims against the current Astro/Biome docs at prep time, not
  from memory: built-in CSP stable or experimental and its config key; which features it
  excludes (`<ClientRouter/>`, Shiki); `client:only` needs a framework hint; Biome's
  Astro support and documented overrides; state of service-worker integrations.
- Companion actions (F-017): does adopting Astro need any (e.g. the package behind
  `astro check`, a `tsconfig` extending Astro's preset)? If so, check whether the HOW-TO
  rows need an update.

### F-020 — mise.lock carries platform URLs for CI

**Status:** BACKLOG

**Problem:** `core/mise.toml` says `mise.lock` is generated by `mise install`, which records
only the current platform. A lockfile created on a developer machine therefore lacks the
Linux URLs a CI runner needs, so `mise install --locked` fails there (reported from a
downstream project) — and without `--locked` CI silently resolves outside the lock.

**Idea:** Generate the lockfile explicitly for the platforms a project actually runs on,
and keep that platform set in `[settings]` so every later `mise lock` preserves it.
Align the header comment in `core/mise.toml` and the contract in `MANIFEST.md`
(§ Version stamp) with that command.

**Solution sketch:**
- Starting point from intake (proposed in another session; not binding):
  - `core/mise.toml` header: "generated by `mise lock --platform linux-x64,macos-arm64`,
    committed — CI installs with --locked and needs the platform URLs".
  - `core/mise.toml` `[settings]`: `lockfile_platforms = ["linux-x64", "macos-arm64"]`
    (per `mise lock --help`, the platform default is "the lockfile_platforms setting plus
    the current platform when that setting is configured").
  - `MANIFEST.md` § Version stamp: replace "generated per project at instantiation
    (`mise install`)" with the `mise lock --platform …` command.
- `CHANGELOG.md` migration note for existing projects: `/update-conventions` brings the
  setting, but the existing `mise.lock` stays incomplete — run `mise lock` once and commit.
- Cross-repo note: the lockfile is generated by coding-kit's `/new-project`; the MANIFEST
  change is the contract, the skill may need to follow.
- Sync invariant: patch `VERSION` bump + `CHANGELOG.md` entry in the same commit; no
  `MANIFEST.md` file-list change (no file added, removed or re-policied).

**Dependencies:** none.

**Still to analyse:**
- Verify against the current mise docs at prep time, not from memory: the setting name
  `lockfile_platforms`, the minimum mise version that knows it, and the default of
  `mise lock` without that setting (all platforms? — this repo's own `mise.lock` holds
  all seven). If plain `mise lock` already covers every platform, the fix may reduce to
  the generation command.
- Platform set: the intake proposal pins `linux-x64` + `macos-arm64`. Recommended at intake:
  add `linux-arm64` (ARM runners, containers on Apple Silicon); decide on `macos-x64`.
  Contributors on a platform outside the set add it on every `mise lock` (lockfile churn).
- The template CI (`core/.github/workflows/ci.yml`, same in `modules/go/ci.part.yml`) runs
  `jdx/mise-action` without `install_args`, so it does not enforce `--locked` today.
  Check the action's default; recommended at intake: enforce `--locked` in the template
  CI, otherwise the lockfile has no effect there.
- Renovate: how its mise manager updates `mise.lock` on a version bump — URLs for all
  configured platforms, or only for the runner it executes on?

### F-021 — CODING-STANDARDS: readability over cleverness + secure coding beyond secrets

**Status:** BACKLOG

**Problem:** `core/CODING-STANDARDS.md` sets no explicit bar for readability (simplest
viable solution, code written for the next maintainer), and §8 covers almost only secrets —
input validation, injection, authorization and least privilege are missing from the core.
coding-kit's F-034 makes the build skills apply the standard actively; the content they
apply has to come from this file (what applies lives here, when/how it is checked lives in
the skills).

**Idea:** Close both gaps by extending existing sections — no new section, so §7–§13 keep
their numbers (skills and fragments reference them, e.g. `api-design` → "core §8"). Style
stays terse: one bold rule plus one sentence, stack-neutral. Language-specific safe
variants go into the language fragments; `api-design` is de-duplicated against the new core
rules.

**Solution sketch:**
- Readability, in §1 (Mindset): "simplest viable solution wins — no over-engineering, no
  abstraction on speculation"; "write for the next maintainer", with a checkable yardstick
  ("would a teammate understand it without explanation?").
- Readability, in §6 (Control flow): no nested loops, clever one-liners or long chains
  (comprehensions, streams) that must be decoded before changing them — named intermediate
  steps or helper functions instead. Sharpen alongside the existing nesting-depth rule.
- Secure coding, in §8: validate input at trust boundaries (allowlist, not blocklist);
  injection — parameterised queries, no shell/string assembly with foreign input,
  context-appropriate output encoding; authorize on every access, not only at login;
  least privilege for processes, tokens and file permissions. Secure defaults and "no
  sensitive data in errors or URLs" link to §7 (fail closed, never leak internals) instead
  of restating it; §10 negative tests stay the proof obligation.
- `api-design` fragment (intake decision): keep only the HTTP-specific concretisations
  (schema validation of body/query/params/headers, permission over role strings, rate
  limits, cookies, response shape) and reference core §8 for the principles.
- Language fragments (intake decision): one line each with the safe variant — `python`:
  `subprocess` with an argument list, never `shell=True`; `go`: `exec.Command` with
  separate args, `database/sql` placeholders; `ts-node`: `execFile`/`spawn` over `exec`.
  `prisma` already covers SQL; no shell fragment exists, none needed.
- Sync invariant: minor `VERSION` bump (new binding rules) + `CHANGELOG.md` entry in the
  same commit, flagged so downstream projects pick it up via `/update-conventions`
  (`CODING-STANDARDS.md` is managed, the changes sit outside the module slot); no
  `MANIFEST.md` change (no file added, removed or re-policied). F-019 also plans a minor
  bump — whichever lands first takes the next minor.

**Dependencies:** none. Counterpart in coding-kit: F-034.

---

<!-- FEATURE-INDEX
next-feature: F-022
F-001 Initial template build (DONE)
F-002 Composable CODING-STANDARDS fragments (DONE)
F-003 Web-standards fragments (DONE)
F-004 Remediate already-published real-name leaks (DONE)
F-005 Async in-flight / promise-dedup concurrency standard (DONE)
F-006 Audit / activity-logging standard (DONE)
F-007 Refresh repo docs for the fragment catalog (DONE)
F-008 Ship the privacy lint + private blocklist to projects (DONE)
F-009 Align docs with the current coding-kit skill set (DONE)
F-010 Per-dimension language matrix (DONE)
F-011 Section-marker contract for updatable zones in seed files (DONE)
F-012 ts-node seed files ship Biome-clean (DONE)
F-013 Standards fragment nextjs (App Router) (DONE)
F-014 Fix .env.example shadowed by the broad env deny rule (DONE)
F-015 Fail-closed env deny set + vendor-aligned agentRules rule (DONE)
F-016 Correct the agentRules routing in the nextjs fragment (DONE)
F-017 HOW-TO sync for fragment companion actions (DONE)
F-018 HOW-TO: state where the workflow skills come from
F-019 Standards fragment astro
F-020 mise.lock carries platform URLs for CI
F-021 CODING-STANDARDS: readability over cleverness + secure coding beyond secrets
-->
