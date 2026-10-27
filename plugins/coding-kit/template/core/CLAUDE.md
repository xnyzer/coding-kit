# {{PROJECT_NAME}} — Claude Instructions

<!-- template:optional:graphiti -->
<!-- section:claude-graphiti -->
## Graphiti Memory (Knowledge Graph)
**group_id**: `{{GROUP_ID}}`

- **Query the graph first** before searching files:
  `search_memory_facts(query="…", group_ids=["{{GROUP_ID}}"])`,
  `search_nodes(query="…", group_ids=["{{GROUP_ID}}"])`.
- **After significant changes**, update via `add_memory` (`group_id: "{{GROUP_ID}}"`,
  `source: "text"`, descriptive `name`). Split dense content into multiple episodes.
- Requires a running Graphiti MCP server — skip silently if none is available.
<!-- /section:claude-graphiti -->
<!-- /template:optional:graphiti -->

## Overview

{{PROJECT_DESCRIPTION}}

<!-- template:adapt: expand purpose, scope, and target users from the short-info; one
paragraph, written so a fresh session understands what this project is. Full context:
README.md -->

### Goals

<!-- template:adapt: what the project must achieve — a few bullets. This file is loaded
in every session: keep each section short; if it grows a lot, move it into its own file
and import it with @ -->

### Non-goals

<!-- template:adapt: what the project deliberately does not do — as binding as the goals -->

### Constraints

<!-- template:adapt: technical, legal, platform and budget constraints -->

## Status & where to start

<!-- template:adapt: current state in one or two sentences; keep updated as the project
evolves (the /step-done skill maintains this) -->

<!-- section:claude-startup -->
Read `README.md`, then `features/INDEX.md`: its recommended order and the table of all
features are the working context. Open a feature file (`features/F-NNN-*.md`) when you
work on that feature or need the reasons behind a finished one — not all of them at
startup. **To continue: take the first feature of the recommended order, run `/prep-step`
to specify and plan it, `/build-step` to implement it, then `/step-done` to finish each
substep.**
<!-- /section:claude-startup -->

<!-- section:claude-conventions -->
## Conventions

- **Languages** (chosen at instantiation, independent of repo visibility — identifiers,
  Conventional-Commit tokens, status tokens, and governance docs are always English):
  - Living docs (feature files and their index): **{{LANG_LIVING_DOCS}}**
  - CLAUDE.md prose (project parts of this file): **{{LANG_CLAUDE_MD}}**
  - Code comments & docstrings: **{{LANG_COMMENTS}}**
  - Commit-message prose: **{{LANG_COMMITS}}**
  - README & public docs: **{{LANG_README}}**
- Git: **Conventional Commits** (tokens English), prose in {{LANG_COMMITS}},
  imperative mood; body ends with
  `Co-Authored-By: Claude <noreply@anthropic.com>`. Commit email = **GitHub noreply**
  (verify `git config user.email`; fix via `gh api user`). **Never auto-commit — ask first.**
- License: **{{LICENSE_SPDX}}**; dependencies must be permissive-licensed (no GPL/AGPL) —
  deviations only as a conscious, documented decision.
- Toolchain: **mise + just + lefthook** are mandatory; all checks run via **`just check`**
  and it must be green before any commit.
- Secrets and private material never enter the tree; operational internals go to
  `private/` (gitignored). Living docs stay free of private info (names, customers, local
  paths, IPs) — the project must remain publishable at any time.
<!-- /section:claude-conventions -->

<!-- section:claude-workflow -->
## Workflow & skills

Every task is an F-number with its own file in `features/` (`F-NNN-short-name.md`, from
`F-000-template.md`): intake, specification, plan and history in one place.
`features/INDEX.md` holds the recommended order and the table of all features, which
`just features-index` generates from the files. Skills come from the **coding-kit
plugin**: `/add-feature` (intake and advice), `/prep-step` (specify, size and plan),
`/build-step` (implement the plan), `/step-done` (review, secrets scan, history and
booking, commit question), `/audit-code` (full audit). Details:
`HOW-TO-CODE-WITH-CLAUDE.md`.
Decisions about one feature are recorded in its file; a decision that shapes the project
beyond one feature becomes an ADR in `docs/adr/`. Coding rules: `CODING-STANDARDS.md`.
Project-local deviations from template conventions are registered in
`.claude/convention-overrides.md`.
<!-- /section:claude-workflow -->
