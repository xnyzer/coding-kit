# MANIFEST

`manifest-format: 2`

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
| `{{LANG_LIVING_DOCS}}` | Language of living docs (feature files and their index, § Features) | `/new-project` language preset (default: English) |
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
| `FRAGMENTS` | standards fragments beyond the module's own and its declared ones (characteristic fragments the project chose, fragments from a detection proposal, the language fragment of a tool language), comma-separated, in slot order |

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
| `<!-- fragment:NAME -->` … `<!-- /fragment:NAME -->` | Wraps one self-contained standards fragment inside the `module:coding-standards` slot. `NAME` = a catalog fragment (`modules/standards/`) or a stack module's own module fragment. See § Standards fragments. |
| `<!-- section:NAME -->` … `<!-- /section:NAME -->` | Marks a template-owned zone inside a **seed** file that `/update-conventions` may diff and offer individually — never the whole file. Names are lowercase-kebab, unique across the template. See § Seed sections. |
| `<!-- features-index -->` … `<!-- /features-index -->` | The generated table of all features in `features/INDEX.md`; only `scripts/features-index.sh write` writes between them (§ Features). |
| `# module:gitignore` / `# module:ci-jobs` | Append points for module parts in non-HTML files. |
| `<!-- override: reason -->` | Project-local deviation inside a seed zone or a standards fragment: `/update-conventions` leaves that zone or fragment alone. Whole files are registered in § Deviation registry instead. |

A marker counts only on a line of its own (surrounding whitespace allowed). The same text
inside a line — e.g. in prose that explains a marker — is not a marker.

## Sync direction

Convention flow is **exclusively downward**: template → project, via `/new-project` and
`/update-conventions`. There is no automated upstream path. Conventions always originate
in this template; an improvement discovered in a project reaches the template as a
**manually initiated adoption proposal** (a session in the coding-kit repository, or an
issue there) — never as an automatic write from a project.

## Policies

- **managed** — owned by the template. `/update-conventions` merges template updates
  three-way against the base snapshot (§ Base snapshot): project additions stay, only
  overlapping changes conflict, every result is shown and confirmed per file; registered
  deviations follow their kind (§ Deviation registry).
- **seed** — instantiated once, then a living document. Updates never touch it — except
  zones explicitly marked `section:NAME`, which `/update-conventions` may offer
  individually (diff shown, confirmed per section); the file as a whole is never offered.
- **public-only** — instantiated only for public repositories.
- **module** — provided/replaced by the stack module; synced like managed.

## Base snapshot

`.claude/template-base/` holds, for every managed target a project has, the pure
instantiation of the template at its last sync, as `<target>.base`. The suffix keeps
tools from reading the copies: Biome rejects a second root `biome.json`, Renovate updates
`mise.toml` and workflows in any folder, git applies nested `.gitignore` and
`.gitattributes` files.

- **Content:** what `scripts/template-sync.sh render` in the plugin writes for the
  project's answers (§ Answers) — managed core targets, module parts and managed
  `files/**`; placeholders filled, `template:adapt` markers left raw. Seed files are not
  merged; their zones are synced by marker (§ Seed sections).
- **Seed bases:** for seed files with zones, the seed render at the last sync as
  `<target>.seed` (`template-sync.sh snapshot --seeds`). Only the zone sync reads it — it
  tells a zone the template added since then from one the project opted out of;
  `status`, `merge` and the `/step-done` backstop read `.base` files only.
- **Merge:** `/update-conventions` merges each target three-way (`git merge-file`: base,
  project, current template): project additions stay, template changes arrive, only
  overlapping changes conflict. Line ends, a missing final newline and the content of the
  standards slot do not count as differences — fragments are synced one by one.
- **Deviation:** what a project changed is `diff(base, project)` — computed, never
  described. `/step-done` reports changed managed files that have no registry row.
- **Generated:** written only by the skills, after the user confirmed the result; never
  edited by hand. `.gitattributes` marks the folder `linguist-generated`.

## Deviation registry

`.claude/convention-overrides.md` (seed, zone `overrides-head`) records **why** a project
deviates, in two tables after the zone:

- **`## Files`** — machine-read: `| Path | Kind | Reason | Since |`, one row per path or
  glob (several comma-separated paths allowed; `*` also matches `/`, as in `.github/**`).
- **`## Rules`** — `| Rule | Deviation | Reason | Since |`, for deviations that are not
  about one file (e.g. a different rule for living docs); read by people — except a row
  whose Rule cell is `module:NAME`, `fragment:NAME` or `tool:NAME` (backticks allowed):
  it declines that detection proposal for good (§ Detection), and its Deviation cell says
  what the project does instead.

In both tables **Since** is the date the row was added, `YYYY-MM-DD`; a row that is
changed later keeps it.

The kind decides how updates treat a file:

| Kind | Effect |
|------|--------|
| `skip` | never created, changed or offered (e.g. no CI in a local-only project) |
| `keep` | template changes still merge in; on a conflict the project side wins |
| `adapt` | carries spots concretised for this project (`template:adapt`); merged normally |
| *(empty)* | merged normally; the row documents the reason |

A deviation without a row is merged like any other and reported as unregistered until it
has one. A row whose file no longer deviates, or whose deviation the template now
contains itself, is offered for removal.

## Core-managed files

| Source | Target in project | Policy |
|--------|-------------------|--------|
| `core/CLAUDE.md` | `CLAUDE.md` | seed |
| `core/features/INDEX.md` | same path | seed |
| `core/features/F-000-template.md` | same path | managed |
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
| `core/scripts/features-index.sh` | same path | managed |
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
| 2.0.0 | `PROGRESS.md` | removed | seed |
| 2.0.0 | `PROGRESS-ARCHIVE.md` | removed | seed |
| 2.0.0 | `REQUIREMENTS.md` | removed | seed |

The three files of the old document model are replaced by `features/` (§ Features).
Their content is not moved by this table: `/update-conventions` migrates it into feature
files and the overview of `CLAUDE.md`, and deletes the old files only after that.

## Module contract

Each `modules/<name>/` may provide (all optional except `MODULE.md`):

| Part | Target | Mechanics | Policy |
|------|--------|-----------|--------|
| `MODULE.md` | — (not copied) | documents the module, its tools, per-file policies and the signals that point to it (§ Detection) | — |
| `justfile` | `justfile` | **replaces** the core justfile; must implement the standard recipe set | managed |
| `mise.part.toml` | `mise.toml` | `[tools]` entries merged into the core file | managed |
| `gitignore.part` | `.gitignore` | appended below the `# module:gitignore` marker | managed |
| `CODING-STANDARDS.part.md` | `CODING-STANDARDS.md` | the module's own module fragment (the rules of its toolchain) — appended in the `module:coding-standards` slot, wrapped as `fragment:<module>`; a module may also declare catalog fragments, its language fragment first (§ Standards fragments) | managed |
| `ci.part.yml` | `.github/workflows/ci.yml` | jobs appended below the `# module:ci-jobs` marker | managed |
| `files/**` | project root (same relative path) | copied after placeholder substitution | per file, see `MODULE.md` |

**Composition rules.** Rendering must be reproducible byte for byte, so the mechanics
above are exact. The plugin's `scripts/template-sync.sh render` implements them:

- `mise.part.toml` holds a `[tools]` table only; its entries follow the last entry of the
  core `[tools]` table, in file order.
- `gitignore.part` and `ci.part.yml` are inserted directly below their marker line.
- The fragments replace the placeholder text of the slot, in this order: the module
  fragment, its declared catalog fragments, the project's `FRAGMENTS` (§ Answers). Each
  comes without surrounding blank lines, one blank line between two.
- A kept `template:optional` block loses only its two marker lines; a dropped one goes
  with its content.
- `files/**`: the table `## File policies (files/)` in `MODULE.md` names every file by its
  full path below `files/`; the first word of its policy cell (`managed` or `seed`) is
  machine-read.

**Standard recipe set** every module's justfile must implement (skills call only these):
`setup`, `dev`, `test`, `lint`, `format`, `check`, `build`, `features-index`. `check` is
the full gate (format check + lint + types + tests) and must be green before any commit;
it also runs `sh scripts/features-index.sh check`, and `features-index` runs
`sh scripts/features-index.sh write` (§ Features).

## Standards fragments

`modules/standards/` is a catalog of reusable `CODING-STANDARDS` fragments for languages and
frameworks (e.g. `python-lang`, `react`, `docker`), separate from the per-language stack
modules — a fragment can be pulled by any module or project that needs it. Each fragment is
a self-contained file `modules/standards/<name>.md` whose body is wrapped in
`<!-- fragment:<name> -->` … `<!-- /fragment:<name> -->` and **appended** inside the
`<!-- module:coding-standards -->` slot of a project's `CODING-STANDARDS.md`.

- **Catalog** — `modules/standards/README.md` lists every fragment and its triggers: typed
  signals (§ Detection) or a project characteristic. Signals are found by script;
  characteristics no file shows, so `/prep-step` and `/define-requirements` ask for them.
- **Declaration** — a stack module contributes its own module fragment (its
  `CODING-STANDARDS.part.md`, wrapped as `fragment:<module>`, with the rules that hold only
  with its toolchain) implicitly, and declares any additional catalog fragments — in order —
  via a `Standards fragments:` line in its `MODULE.md` (omit the line, or leave it empty, to
  pull none).
- **Language fragments** — the catalog fragment `<language>-lang` (`python-lang`,
  `typescript-lang`, `go-lang`) holds the rules of a language that hold whatever toolchain
  runs the code. The module of a language declares it first, so a project with the module
  gets both; a project that uses the language as a tool language (§ Detection) gets the
  language fragment alone. Module and catalog fragments share the `fragment:` names, hence
  the suffix.
- **Policy** — managed. `/update-conventions` refreshes each fragment by its `fragment:NAME`
  marker — fragment-granular and downward only (template → project), respecting override
  lines (§ Markers). `scripts/template-sync.sh zones` in the plugin compares the fragments
  with the render and puts a new one behind its nearest predecessor of the render order
  that the slot holds (without one at the start of the slot).
  A project-added fragment not in the catalog is never written to; it is reported as a
  manually triggerable adoption proposal for the template (see § Sync direction).
- **Assembly** — appending the fragments at instantiation / `/choose-stack` is coding-kit logic;
  this manifest defines only the contract and the data.

## Detection

`scripts/template-sync.sh detect` in the plugin compares what a project uses with what the
template has conventions for — the stack modules and the catalog fragments. Skills only
propose what it finds; nothing is applied without confirmation. `/prep-step` checks the
signals a task plans, `/step-done` the signals a step adds, `/update-conventions` the
whole project.

A **signal** is written `type:value`:

| Signal | Matches | Read from |
|--------|---------|-----------|
| `npm:NAME` | dependency `NAME` | `package.json`: `dependencies`, `devDependencies`, `peerDependencies`, `optionalDependencies` |
| `pypi:NAME` | dependency `NAME`, compared normalized (lowercase, each run of `-`, `_`, `.` as one `-`) | `pyproject.toml`: `dependencies` of `[project]`, `[project.optional-dependencies]`, `[dependency-groups]`, `[tool.poetry.dependencies]`, `[tool.poetry.group.*.dependencies]`; `requirements*.txt` |
| `go:PATH` | required module `PATH`, also with a major-version suffix (`PATH/v2` …) | `go.mod`: `require`, except lines marked `// indirect` |
| `tool:NAME` | tool `NAME` | `[tools]` of `mise.toml` and `.mise.toml` |
| `file:GLOB` | a file whose name matches `GLOB` (sh pattern); a `GLOB` with `/` matches the path from the project root, and its `*` also matches `/` | the file list |

The **file list** is what git lists for the project — tracked files plus untracked ones
that are not ignored — without `.claude/template-base/`. Manifests count wherever they
appear in it, by file name. Detection only reads; nothing in a project file is executed.

**Declared in:**

- **Modules** — the `Signals:` line of `MODULE.md`: the signals comma-separated in
  backticks, all on that one line; `(none)` for a module nothing points to (`docs-only`).
  Stub modules carry no line and are never proposed — a module gets its line when it is
  built out.
- **Fragments** — the trigger column of the catalog (`modules/standards/README.md`), as
  signals in backticks. A *characteristic:* trigger has none.

**Evaluation.** A module or fragment with at least one matching signal is a hit, in one of
three states:

| State | Module | Fragment |
|-------|--------|----------|
| `covered` | it is `MODULE` in the answers (§ Answers) | its `fragment:NAME` marker is in the standards slot of `CODING-STANDARDS.md`, or the module of the answers declares it (the render brings it) |
| `declined` | the Rules table of the registry has the row `module:NAME` | the Rules table has the row `fragment:NAME` |
| `missing` | otherwise | otherwise |

Without an answers file the module check is skipped, and fragments count by the slot
alone. A missing module is proposed via `/choose-stack`; a missing fragment is appended
like any other (§ Standards fragments) and goes into `FRAGMENTS`. A permanent "no" is a
Rules row (§ Deviation registry); "not this time" is not recorded. A project keeps one
stack module: a language whose module the project does not have — next to another module,
or in a `docs-only` project — is a tool language. Its module is declined with a reason,
and the hand-built toolchain is registered as `keep`. Its language fragment (§ Standards
fragments) still applies: it carries the language's signals and is proposed like any other
fragment.

**Tools without a convention.** A tool in `[tools]` of a project's `mise.toml` is
**known** when the template names it: in `[tools]` of the core `mise.toml` or of a
module's `mise.part.toml`, or as a declared `tool:` signal. A tool name with a backend
prefix (`npm:…`, `pipx:…`, `cargo:…`, `aqua:…` — any name with `:`) installs a package,
not a language, and is never reported. Every other tool gets a line of its own, after the
modules and fragments, in one of two states:

| State | Tool |
|-------|------|
| `declined` | the Rules table of the registry has the row `tool:NAME` |
| `unknown` | otherwise — the template has no module or fragment for it |

Only tools can be `unknown`; dependencies and files without a convention are not
reported. An `unknown` tool is proposed to the template — as a module or a fragment, the
kit decides — never added to the project. Stub modules (`modules/README.md`) declare no
signals, so their languages count as `unknown` too. A tool that needs no convention (an
infra CLI, a linter) is declined with a Rules row.

## Features

Every task of a project is a **feature**: an F-number with one file
`features/F-NNN-short-name.md` that grows over its whole life — intake, specification, plan,
history — and is never moved or renamed. The short name comes from the title (lowercase
ASCII letters, digits, hyphens; about 40 characters) and stays when the title changes.
`features/F-000-template.md` (managed) is the template; `features/INDEX.md` (seed) is the
overview. A project's goals, non-goals and constraints live in the overview of `CLAUDE.md`.

**Header block.** A feature file starts with a block between two `---` lines of plain
`key: value` lines — no quotes, no multi-line values, lists comma-separated:

| Field | Value | Required |
|-------|-------|----------|
| `id` | `F-NNN`, the number of the file name | yes |
| `title` | at most 70 characters; says what changes — not how, not why | yes |
| `type` | `feature` (new behaviour), `fix` (wrong behaviour), `change` (rework, docs, upkeep, audit) | yes |
| `status` | see below | yes |
| `size` | `S`, `M`, `L`; empty until `/prep-step` sets it | — |
| `created` | `YYYY-MM-DD` | yes |
| `done` | `YYYY-MM-DD`; required for `DONE`, allowed for `DROPPED` and `SUPERSEDED`, empty while open | — |
| `depends-on` | F-numbers | — |
| `superseded-by` | F-numbers; required for `SUPERSEDED`, empty otherwise | — |

**Status.** Open: `BACKLOG` (captured), `PLANNED` (specification and plan approved),
`IN-PROGRESS` (first substep booked). Closed: `DONE` (final; follow-up work gets a new
number), `DROPPED` (not, or no further, implemented; the reason is in the file),
`SUPERSEDED` (merged into or split across the features in `superseded-by`). The way
through and who sets what: the zone `index-head` of `features/INDEX.md`.

**Sections** of a feature file, headed in the language of the living docs: intake,
specification, plan, history — the template carries them with their hints.

**Index.** `features/INDEX.md` has the zone `index-head`, then the recommended order
(written by hand; only open features), then the table of all features between the marker
lines `<!-- features-index -->` and `<!-- /features-index -->`, then the line
`next-feature: F-NNN`. The table is generated, never edited by hand: one row per feature,
sorted by number — ID linked to the file, title, status (`SUPERSEDED → F-NNN`), done date.

**Script.** `scripts/features-index.sh` (managed, POSIX sh + awk) is the only writer of the
table: `write` regenerates it, `check` reports broken header blocks, duplicate numbers, a
stale table, a missing or too low `next-feature` and recommended-order entries that are not
open. Every justfile runs `check` in `just check` and `write` as `just features-index`
(§ Module contract); the pre-commit hook runs `check` when files in `features/` are staged
and never writes.

**Migration from the model before 2.0.0.** A project with `PROGRESS.md` (and its
`FEATURE-INDEX` block), `PROGRESS-ARCHIVE.md` and possibly `REQUIREMENTS.md` moves once,
through `/update-conventions`. The mechanical part is `scripts/template-sync.sh migrate`
in the plugin: every F-number becomes a feature file, word for word — the open entry
under intake (its open substeps under plan), the archive sections and Done rows of the
number as history, oldest first; number, title and status from the `FEATURE-INDEX`
(`→ aufgegangen in …` becomes `SUPERSEDED`), dates from the history and, where none is
written, from git; `type` is always `feature`. Whatever stands outside an F-entry (an old
"Schritt 1.2", the recommended order) is listed, never guessed. The skill does what
needs judgment: it places the order text in the index, shortens titles over 70
characters, distributes `REQUIREMENTS.md` (goals, non-goals and constraints into the
overview of `CLAUDE.md`, decisions into an ADR or a feature file, core features without a
number into new files), and deletes the old files only after the new ones are confirmed.

## Seed sections

Seed files are living documents and never updated as a whole — but some carry
**template-owned zones** (structure and guidance that evolve with the template). Those
zones are wrapped in `<!-- section:NAME -->` … `<!-- /section:NAME -->` markers so
`/update-conventions` can diff and offer each section individually; everything unmarked
stays untouchable. A project that deletes a marker pair permanently opts that zone out
of updates; an override line inside a zone protects it (§ Markers). The plugin's
`scripts/template-sync.sh zones` compares each zone with the render and the seed base
(§ Base snapshot):

- **New zone** — in the render, neither in the file nor in its seed base (added by the
  template, or by an optional block the answers switched on since): offered and inserted
  behind its nearest predecessor of the render order that the file has, without one
  before its nearest successor, without both at the end of the file.
- **Opted-out zone** — in the seed base, not in the file (also when the file lost all its
  markers): listed only; taken back only on request. Without a seed base (projects
  synced before seed bases existed) a missing zone is asked about once.
- **Zone text without markers** — the base lacks the zone, but its content stands
  verbatim in the file outside every zone (a marker pair deleted, the text kept): on
  request only its markers are put around that text instead of inserting it a second
  time; the same holds for an opted-out zone taken back.
- **Removed zone** — in the file and its seed base, no longer in the render: removing it
  with its content is offered; with an override line it stays as project text. A
  renamed zone shows as one removed and one new zone.

This manifest defines the contract and the inventory:

| Seed file | Sections |
|-----------|----------|
| `core/CLAUDE.md` | `claude-graphiti` (inside the `template:optional:graphiti` block), `claude-startup`, `claude-conventions`, `claude-workflow` |
| `core/features/INDEX.md` | `index-head` |
| `core/README.md` | `readme-getting-started` |
| `core/.claude/convention-overrides.md` | `overrides-head` |

## Version stamp

`/new-project` writes the plugin version into `.claude/template-version`, next to
`.claude/template-answers` (§ Answers) and the base snapshot (§ Base snapshot).
`/update-conventions` shows the update window from the plugin `CHANGELOG.md` — the
`### Template` sections of the releases above the stamp; stamps below 1.0.0 belong to the
former project-template series and also read its frozen section — then renders the
template from the answers and merges against the snapshot, also when the stamp is
current (answers can change). A project without snapshot or answers is migrated first:
the answers are recovered from the project, the base comes from the template of the stamp
version (or an older one) in the coding-kit history, or the first sync compares two-way.
`mise.lock` is generated per project at instantiation with `mise lock` — the platform set
comes from `lockfile_platforms` in `core/mise.toml` — and never shipped by the template.
