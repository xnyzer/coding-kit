# {{PROJECT_NAME}} — Claude Instructions

<!-- template:optional:graphiti -->
## Graphiti Memory (Knowledge Graph)
**group_id**: `{{GROUP_ID}}`

- **Query the graph first** before searching files:
  `search_memory_facts(query="…", group_ids=["{{GROUP_ID}}"])`,
  `search_nodes(query="…", group_ids=["{{GROUP_ID}}"])`.
- **After significant changes**, update via `add_memory` (`group_id: "{{GROUP_ID}}"`,
  `source: "text"`, descriptive `name`). Split dense content into multiple episodes.
- Requires a running Graphiti MCP server — skip silently if none is available.
<!-- /template:optional:graphiti -->

## Overview

{{PROJECT_DESCRIPTION}}

<!-- template:adapt: expand purpose, scope, and target users from the short-info; one
paragraph, written so a fresh session understands what this project is. Full context:
README.md -->

## Status & where to start

<!-- template:adapt: current state in one or two sentences; keep updated as the project
evolves (the /step-done skill maintains this) -->

Read in order: `README.md`, `REQUIREMENTS.md` (while it exists), `PROGRESS.md`
(+ `PROGRESS-ARCHIVE.md` for past decisions). **To continue: open `PROGRESS.md`, take the
first open task, run `/prep-step` to plan, then `/step-done` to finish.** Work the open
tasks top to bottom.

## Conventions

- **Code, commits, governance docs: English.** Living docs (PROGRESS, REQUIREMENTS,
  project parts of this file): **{{LIVING_DOC_LANGUAGE}}**.
- Git: **Conventional Commits**, English, imperative mood; body ends with
  `Co-Authored-By: Claude <noreply@anthropic.com>`. Commit email = **GitHub noreply**
  (verify `git config user.email`; fix via `gh api user`). **Never auto-commit — ask first.**
- License: **{{LICENSE_SPDX}}**; dependencies must be permissive-licensed (no GPL/AGPL) —
  deviations only as a conscious, documented decision.
- Toolchain: **mise + just + lefthook** are mandatory; all checks run via **`just check`**
  and it must be green before any commit.
- Secrets and private material never enter the tree; operational internals go to
  `private/` (gitignored). Living docs stay free of private info (names, customers, local
  paths, IPs) — the project must remain publishable at any time.

## Workflow & skills

Tasks are F-numbers in `PROGRESS.md` (+ `FEATURE-INDEX` block); finished work is archived
in `PROGRESS-ARCHIVE.md`. Skills come from the **coding-kit plugin**: `/add-feature`
(intake), `/prep-step` (plan + decompose), `/step-done` (review, secrets scan, docs,
commit question), `/audit-code` (full audit). Details: `HOW-TO-CODE-WITH-CLAUDE.md`.
Coding rules: `CODING-STANDARDS.md`. Project-local deviations from template conventions
are registered in `.claude/convention-overrides.md`.
