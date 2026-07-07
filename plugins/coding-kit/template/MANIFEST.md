# MANIFEST

`manifest-format: 1`

The contract between this template and the coding-kit skills (`/new-project`,
`/update-conventions`, `/choose-stack`). Skills couple to the **manifest format version**
above, not to the template `VERSION`.

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
| `{{LIVING_DOC_LANGUAGE}}` | Language of living docs | German (private) / English (public) |
| `{{LICENSE_SPDX}}` | Chosen license SPDX id | `/choose-license` ("TBD" allowed) |
| `{{CODEQL_LANGUAGES}}` | CodeQL language for the module | stack module (`javascript-typescript`, `python`, `go`) |
| `{{TEMPLATE_VERSION}}` | Template `VERSION` at instantiation | `VERSION` |

## Markers

| Marker | Meaning |
|--------|---------|
| `<!-- template:adapt: hint -->` | Spot `/new-project` must concretise from the short-info — never raw-copy. |
| `<!-- template:optional:NAME -->` … `<!-- /template:optional:NAME -->` | Block kept or removed at instantiation (used: `graphiti`, `security-tool`). |
| `<!-- module:coding-standards -->` | Slot where the module's `CODING-STANDARDS.part.md` is inserted. |
| `# module:gitignore` / `# module:ci-jobs` | Append points for module parts in non-HTML files. |
| `<!-- override: reason -->` | Project-local deviation. `/update-conventions` never touches a file/section carrying it. Register in `.claude/convention-overrides.md`. |

## Policies

- **managed** — owned by the template. `/update-conventions` may propose an overwrite
  (diff shown, confirmed per file; overrides are always respected).
- **seed** — instantiated once, then a living document. Updates never touch it.
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
| `core/AI-DISCLOSURE.md` | `AI-DISCLOSURE.md` | managed (optional block: `security-tool`) |
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
| `core/docs/adr/README.md` | same path | managed |
| `core/docs/adr/0000-template.md` | same path | managed |

## Module contract

Each `modules/<name>/` may provide (all optional except `MODULE.md`):

| Part | Target | Mechanics | Policy |
|------|--------|-----------|--------|
| `MODULE.md` | — (not copied) | documents the module, its tools, per-file policies | — |
| `justfile` | `justfile` | **replaces** the core justfile; must implement the standard recipe set | managed |
| `mise.part.toml` | `mise.toml` | `[tools]` entries merged into the core file | managed |
| `gitignore.part` | `.gitignore` | appended below the `# module:gitignore` marker | managed |
| `CODING-STANDARDS.part.md` | `CODING-STANDARDS.md` | inserted at the `<!-- module:coding-standards -->` slot | managed |
| `ci.part.yml` | `.github/workflows/ci.yml` | jobs appended below the `# module:ci-jobs` marker | managed |
| `files/**` | project root (same relative path) | copied after placeholder substitution | per file, see `MODULE.md` |

**Standard recipe set** every module's justfile must implement (skills call only these):
`setup`, `dev`, `test`, `lint`, `format`, `check`, `build`. `check` is the full gate
(format check + lint + types + tests) and must be green before any commit.

## Version stamp

`/new-project` writes the template `VERSION` into `.claude/template-version`.
`/update-conventions` diffs stamp → current `VERSION` using this manifest; projects without
a stamp get a heuristic comparison with per-file confirmation. `mise.lock` is generated
per project at instantiation (`mise install`), never shipped by the template.
