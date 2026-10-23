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
| F-020 | `mise.lock` covers every platform: `lockfile_platforms` pins the seven common mise platforms in `core/mise.toml`, `mise lock` named as generator; CI already enforces `--locked` via `jdx/mise-action` (VERSION 0.13.3). Detail in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |
| F-021 | CODING-STANDARDS: readability rules in §1/§6, secure coding beyond secrets in §8 (renamed "Secure coding & secrets"), `api-design` de-duplicated against core §8, *Safe calls* lines in the `python`/`go`/`ts-node` fragments (VERSION 0.14.0). Detail in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |
| F-018 | HOW-TO states where the workflow skills come from: coding-kit plugin, namespaced vs. short call form (short only without a name clash), manual fallback via PROGRESS.md + `just` (VERSION 0.14.1). Detail in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |

---

## Open tasks — work top to bottom

_No prepared tasks. Plan a backlog item via `/prep-step`._

---

## Feature ideas (backlog)

_Intake new ideas via `/add-feature` — they get the next F-number._

**Recommended order:**

1. F-019 — independent, any time.

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
F-018 HOW-TO: state where the workflow skills come from (DONE)
F-019 Standards fragment astro
F-020 mise.lock carries platform URLs for CI (DONE)
F-021 CODING-STANDARDS: readability over cleverness + secure coding beyond secrets (DONE)
-->
