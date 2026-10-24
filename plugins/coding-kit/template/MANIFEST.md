# MANIFEST

`manifest-format: 1`

The contract between this template and the coding-kit skills (`/new-project`,
`/update-conventions`, `/choose-stack`). Template and skills ship together in the
coding-kit plugin and share its version (`version` in the plugin's
`.claude-plugin/plugin.json`); the skills check the **manifest format version** above.

## Placeholders

Only these tokens may appear in template content. Placeholders are UPPERCASE with
underscores, wrapped in `{{…}}` (GitHub Actions' `${{ github.* }}` expressions are
lowercase and therefore never collide).

| Token | Meaning | Resolved from |
|-------|---------|---------------|
| `{{PROJECT_NAME}}` | Repository/project name | `/new-project` input (or `/name-it`) |
| `{{PROJECT_NAME_SNAKE}}` | Name with `-` → `_` (Python packages, Go idents) | derived |
| `{{PROJECT_DESCRIPTION}}` | One-line short-info | `/new-project` step 0 |
| `{{OWNER}}` | GitHub login | `gh api user --jq .login` |
| `{{YEAR}}` | Current year | runtime |
| `{{GROUP_ID}}` | Graphiti group id | defaults to project name |
| `{{LANG_LIVING_DOCS}}` | Language of living docs (PROGRESS, REQUIREMENTS, decision logs) | `/new-project` language preset (default: English) |
| `{{LANG_CLAUDE_MD}}` | Language of CLAUDE.md prose | `/new-project` language preset (default: English) |
| `{{LANG_COMMENTS}}` | Language of code comments & docstrings | `/new-project` language preset (default: English) |
| `{{LANG_COMMITS}}` | Language of commit-message prose (Conventional tokens stay English) | `/new-project` language preset (default: English) |
| `{{LANG_README}}` | Language of README & public docs | `/new-project` language preset (default: English) |
| `{{LICENSE_SPDX}}` | Chosen license SPDX id | `/choose-license` ("TBD" allowed) |
| `{{CODEQL_LANGUAGES}}` | CodeQL language for the module | stack module (`javascript-typescript`, `python`, `go`) |
| `{{TEMPLATE_VERSION}}` | Plugin version at instantiation | `version` in the plugin's `.claude-plugin/plugin.json` |

## Answers

`.claude/template-answers` in a project records the values it was instantiated with, so
the template can be rendered again without guessing. `/new-project` writes it; a skill
that changes one of these values updates it in the same step.

Format: one `KEY=value` per line; lines starting with `#` are comments. The value is
everything after the first `=`, trimmed and taken literally (no quoting, no expansion);
it must not contain a tab or `{{`.

| Key | Value |
|-----|-------|
| `PROJECT_NAME`, `PROJECT_DESCRIPTION`, `OWNER`, `YEAR`, `GROUP_ID`, `LANG_LIVING_DOCS`, `LANG_CLAUDE_MD`, `LANG_COMMENTS`, `LANG_COMMITS`, `LANG_README`, `LICENSE_SPDX` | the placeholder of the same name (§ Placeholders); a key no rendered file needs may be left out |
| `MODULE` | the stack module (`docs-only` without a stack) — required |
| `VISIBILITY` | `public` or `private`; decides the public-only targets — required |
| `OPTIONAL` | the `template:optional` blocks the project keeps by choice, comma-separated (e.g. `graphiti`); missing or empty = none; the license blocks are derived, never listed |
| `FRAGMENTS` | standards fragments beyond the module's own and its declared ones (the characteristic fragments the project chose), comma-separated, in slot order |

Derived, never stored: `PROJECT_NAME_SNAKE` (from `PROJECT_NAME`), `CODEQL_LANGUAGES`
(from the module's `MODULE.md`; a module without one gets no target that needs it, so a
docs-only project has no CodeQL workflow), `TEMPLATE_VERSION` (the plugin version) and
the license blocks: `license-tbd` is kept while `LICENSE_SPDX` is `TBD`, `license`
otherwise.

## Markers

| Marker | Meaning |
|--------|---------|
| `<!-- template:adapt: hint -->` | Spot `/new-project` must concretise from the short-info — never raw-copy. |
| `<!-- template:optional:NAME -->` … `<!-- /template:optional:NAME -->` | Block kept or removed at instantiation (used: `graphiti`, `license`, `license-tbd`). |
| `<!-- module:coding-standards -->` … `<!-- /module:coding-standards -->` | Slot in `CODING-STANDARDS.md` §13 where standards fragments are **appended** (each wrapped in `fragment:NAME`), not single-inserted. |
| `<!-- fragment:NAME -->` … `<!-- /fragment:NAME -->` | Wraps one self-contained standards fragment inside the `module:coding-standards` slot. `NAME` = a catalog fragment (`modules/standards/`) or a stack module's own language fragment. See § Standards fragments. |
| `<!-- section:NAME -->` … `<!-- /section:NAME -->` | Marks a template-owned zone inside a **seed** file that `/update-conventions` may diff and offer individually — never the whole file. Names are lowercase-kebab, unique across the template. See § Seed sections. |
| `# module:gitignore` / `# module:ci-jobs` | Append points for module parts in non-HTML files. |
| `<!-- override: reason -->` | Project-local deviation. `/update-conventions` never touches a file/section carrying it. Register in `.claude/convention-overrides.md`. |

## Sync direction

Convention flow is **exclusively downward**: template → project, via `/new-project` and
`/update-conventions`. There is no automated upstream path. Conventions always originate
in this template; an improvement discovered in a project reaches the template as a
**manually initiated adoption proposal** (a session in the coding-kit repository, or an
issue there) — never as an automatic write from a project.

## Policies

- **managed** — owned by the template. `/update-conventions` may propose an overwrite
  (diff shown, confirmed per file; overrides are always respected).
- **seed** — instantiated once, then a living document. Updates never touch it — except
  zones explicitly marked `section:NAME`, which `/update-conventions` may offer
  individually (diff shown, confirmed per section); the file as a whole is never offered.
- **public-only** — instantiated only for public repositories.
- **module** — provided/replaced by the stack module.

## Core-managed files

| Source | Target in project | Policy |
|--------|-------------------|--------|
| `core/CLAUDE.md` | `CLAUDE.md` | seed |
| `core/PROGRESS.md` | `PROGRESS.md` | seed |
| `core/PROGRESS-ARCHIVE.md` | `PROGRESS-ARCHIVE.md` | seed |
| `core/REQUIREMENTS.md` | `REQUIREMENTS.md` | seed (transitional artifact) |
| `core/README.md` | `README.md` | seed |
| `core/LICENSE` | `LICENSE` | seed (default Apache-2.0; `/choose-license` may replace) |
| `core/CODE_OF_CONDUCT.md` | `CODE_OF_CONDUCT.md` | managed, public-only |
| `core/CODING-STANDARDS.md` | `CODING-STANDARDS.md` | managed (contains module slot) |
| `core/CONTRIBUTING.md` | `CONTRIBUTING.md` | managed |
| `core/SECURITY.md` | `SECURITY.md` | managed (contains adapt slots) |
| `core/HOW-TO-CODE-WITH-CLAUDE.md` | `HOW-TO-CODE-WITH-CLAUDE.md` | managed |
| `core/AI-DISCLOSURE.md` | `AI-DISCLOSURE.md` | managed (identical in every project) |
| `core/.claude/settings.json` | `.claude/settings.json` | managed |
| `core/.claude/README.md` | `.claude/README.md` | managed |
| `core/.claude/convention-overrides.md` | `.claude/convention-overrides.md` | seed |
| `core/.claude/skills/README.md` | `.claude/skills/README.md` | managed |
| `core/.github/ISSUE_TEMPLATE/bug_report.yml` | same path | managed |
| `core/.github/ISSUE_TEMPLATE/feature_request.yml` | same path | managed |
| `core/.github/ISSUE_TEMPLATE/config.yml` | same path | managed |
| `core/.github/PULL_REQUEST_TEMPLATE.md` | same path | managed |
| `core/.github/workflows/ci.yml` | same path | managed (module may append jobs) |
| `core/.github/workflows/codeql.yml` | same path | managed, public-only |
| `core/justfile` | `justfile` | module (core ships the docs-only default) |
| `core/mise.toml` | `mise.toml` | managed (module merges `[tools]`) |
| `core/lefthook.yml` | `lefthook.yml` | managed |
| `core/renovate.json` | `renovate.json` | managed |
| `core/.editorconfig` | `.editorconfig` | managed |
| `core/.gitattributes` | `.gitattributes` | managed |
| `core/.gitignore` | `.gitignore` | managed (module appends below marker) |
| `core/private/README.md` | `private/README.md` | managed |
| `core/scripts/privacy-lint.sh` | `scripts/privacy-lint.sh` | managed |
| `core/docs/adr/README.md` | same path | managed |
| `core/docs/adr/0000-template.md` | same path | managed |

## Removed and renamed targets

Declared history of targets that left the core-managed table, so `/update-conventions`
can offer moving or removing them in projects without reading git history. One row per
target: `Version` is the release that removed or renamed it, `New target` is the new path
or `removed`, `Policy` is the target's policy before the change. A change that drops a
target from the core-managed table adds its row in the same commit (`just version-rule`
enforces it).

| Version | Old target | New target | Policy |
|---------|------------|------------|--------|

No target has been removed or renamed so far (checked back to template 0.1.0).

## Module contract

Each `modules/<name>/` may provide (all optional except `MODULE.md`):

| Part | Target | Mechanics | Policy |
|------|--------|-----------|--------|
| `MODULE.md` | — (not copied) | documents the module, its tools, per-file policies | — |
| `justfile` | `justfile` | **replaces** the core justfile; must implement the standard recipe set | managed |
| `mise.part.toml` | `mise.toml` | `[tools]` entries merged into the core file | managed |
| `gitignore.part` | `.gitignore` | appended below the `# module:gitignore` marker | managed |
| `CODING-STANDARDS.part.md` | `CODING-STANDARDS.md` | the module's own language fragment — appended in the `module:coding-standards` slot, wrapped as `fragment:<module>`; a module may also declare catalog fragments (§ Standards fragments) | managed |
| `ci.part.yml` | `.github/workflows/ci.yml` | jobs appended below the `# module:ci-jobs` marker | managed |
| `files/**` | project root (same relative path) | copied after placeholder substitution | per file, see `MODULE.md` |

**Composition rules.** Rendering must be reproducible byte for byte, so the mechanics
above are exact. The plugin's `scripts/template-sync.sh render` implements them:

- `mise.part.toml` holds a `[tools]` table only; its entries follow the last entry of the
  core `[tools]` table, in file order.
- `gitignore.part` and `ci.part.yml` are inserted directly below their marker line.
- The fragments replace the placeholder text of the slot, in this order: the module's
  language fragment, its declared catalog fragments, the project's `FRAGMENTS`
  (§ Answers). Each comes without surrounding blank lines, one blank line between two.
- A kept `template:optional` block loses only its two marker lines; a dropped one goes
  with its content.
- `files/**`: the table `## File policies (files/)` in `MODULE.md` names every file by its
  full path below `files/`; the first word of its policy cell (`managed` or `seed`) is
  machine-read.

**Standard recipe set** every module's justfile must implement (skills call only these):
`setup`, `dev`, `test`, `lint`, `format`, `check`, `build`. `check` is the full gate
(format check + lint + types + tests) and must be green before any commit.

## Standards fragments

`modules/standards/` is a catalog of reusable, framework-granular `CODING-STANDARDS` fragments
(e.g. `react`, `prisma`, `docker`), separate from the per-language stack modules — a fragment
can be pulled by any module that needs it. Each fragment is a self-contained file
`modules/standards/<name>.md` whose body is wrapped in `<!-- fragment:<name> -->` …
`<!-- /fragment:<name> -->` and **appended** inside the `<!-- module:coding-standards -->` slot
of a project's `CODING-STANDARDS.md`.

- **Catalog** — `modules/standards/README.md` lists every fragment and the trigger→fragment
  mapping (dependency/framework signals and project-characteristic triggers). `/prep-step`
  matches both trigger types to detect a newly introduced framework or characteristic whose
  fragment is not yet present.
- **Declaration** — a stack module contributes its own language fragment (its
  `CODING-STANDARDS.part.md`, wrapped as `fragment:<module>`) implicitly, and declares any
  additional catalog fragments — in order — via a `Standards fragments:` line in its `MODULE.md`
  (omit the line, or leave it empty, to pull none).
- **Policy** — managed. `/update-conventions` refreshes each fragment by its `fragment:NAME`
  marker — fragment-granular and downward only (template → project), respecting overrides.
  A project-added fragment not in the catalog is never written to; it is reported as a
  manually triggerable adoption proposal for the template (see § Sync direction).
- **Assembly** — appending the fragments at instantiation / `/choose-stack` is coding-kit logic;
  this manifest defines only the contract and the data.

## Seed sections

Seed files are living documents and never updated as a whole — but some carry
**template-owned zones** (structure and guidance that evolve with the template). Those
zones are wrapped in `<!-- section:NAME -->` … `<!-- /section:NAME -->` markers so
`/update-conventions` can diff and offer each section individually; everything unmarked
stays untouchable. A project that deletes a marker pair permanently opts that zone out
of updates. Evaluating the markers is coding-kit logic; this manifest defines the
contract and the inventory:

| Seed file | Sections |
|-----------|----------|
| `core/CLAUDE.md` | `claude-graphiti` (inside the `template:optional:graphiti` block), `claude-startup`, `claude-conventions`, `claude-workflow` |
| `core/PROGRESS.md` | `progress-head` |
| `core/PROGRESS-ARCHIVE.md` | `archive-head` |
| `core/REQUIREMENTS.md` | `requirements-head` |
| `core/README.md` | `readme-getting-started` |
| `core/.claude/convention-overrides.md` | `overrides-head` |

## Version stamp

`/new-project` writes the plugin version into `.claude/template-version`.
`/update-conventions` takes the update window from the plugin `CHANGELOG.md` — the
`### Template` sections of the releases above the stamp; stamps below 1.0.0 belong to the
former project-template series and also read its frozen section — and diffs using this
manifest; projects without a stamp get a heuristic comparison with per-file
confirmation. `mise.lock` is generated
per project at instantiation with `mise lock` — the platform set comes from
`lockfile_platforms` in `core/mise.toml` — and never shipped by the template.
