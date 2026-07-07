# How to Code with Claude

Guide for working with Claude Code in the {{PROJECT_NAME}} project.

---

## Contributor setup

1. **Install Claude Code** — see the [official docs](https://code.claude.com/docs).
2. **Install the coding-kit plugin** (provides the workflow skills used below):
   ```
   /plugin marketplace add xnyzer/coding-kit
   /plugin install coding-kit@xnyzer
   ```
3. **Install the toolchain** — [mise](https://mise.jdx.dev) provides everything pinned in
   `mise.toml` (including `just`, `lefthook`, `gitleaks` and the stack toolchain):
   ```
   mise install
   just setup     # dependencies + git hooks
   just check     # must be green
   ```
4. *(Optional)* **Graphiti memory** — if a Graphiti MCP server is configured, the project
   uses the group id documented in `CLAUDE.md`. Without one, the skills skip it silently.

---

## Overview: skills

| Skill | When to use | What happens |
|-------|-------------|--------------|
| `/add-feature` | Put a new task on the roadmap | Analysis → write-up → entry in PROGRESS.md |
| `/prep-step` | Before implementing a task | Analysis → decomposition → plan in PROGRESS.md → ask whether to start |
| `/step-done` | After finishing a task/substep | Code review → secrets & privacy scan → docs → commit question |
| `/audit-code` | One-off check of the whole project | Check → results in AUDIT-RESULTS.md (gitignored) |

---

## Workflow 1: Intake a new task

```
You:    /add-feature <idea>
Claude: Analysis… recommendation… open questions…
You:    yes, do that
Claude: Writes it out, shows you the text
You:    looks good
Claude: Records the F-number in PROGRESS.md, updates the feature index
```

**Important:** Everything gets an F-number. No distinction between "feature" and "task".

---

## Workflow 2: Prepare & implement a task

```
You:    /prep-step F-002
Claude: Analysis… size assessment… substeps if needed (F-002a, F-002b, …)
You:    yes, write that in
Claude: Records the plan in PROGRESS.md — should I start with F-002a?
You:    yes
Claude: Implements F-002a…
You:    /step-done
Claude: Review, checks, PROGRESS-ARCHIVE, commit question
You:    yes, commit
Claude: Committed. Continue with F-002b?
```

**Size assessment:** Small (<200 lines, <5 files) → direct. Medium → 2–3 substeps.
Large → 3–5 substeps. `/prep-step` without an argument takes the next open task.

---

## What `/step-done` does in detail

1. **Code review & checks** — changed files against `CODING-STANDARDS.md`; `just check`
   must be green.
2. **Secrets & privacy scan** — working tree + commit draft for secrets/keys/IPs/private
   emails; living docs for private info (names, customers, local paths). Findings are
   fixed or moved to `private/` before any commit is proposed.
3. **PROGRESS.md / PROGRESS-ARCHIVE.md** — Done table updated, detail section archived.
4. **Graphiti** — knowledge-graph update (if configured).
5. **Commit** — asks whether to commit; proposes a Conventional Commits message and
   verifies the commit email is a GitHub noreply address.

---

## Important files

| File | Purpose |
|------|---------|
| `PROGRESS.md` | Open tasks + Done table + feature index |
| `PROGRESS-ARCHIVE.md` | Full documentation of all finished tasks |
| `REQUIREMENTS.md` | Transitional spec — dissolved once fully transferred to PROGRESS.md |
| `CODING-STANDARDS.md` | Binding coding rules (incl. stack section) |
| `CLAUDE.md` | Project-specific Claude instructions (auto-loaded) |
| `.claude/convention-overrides.md` | Registered deviations from template conventions |
| `.claude/skills/` | Project-specific skills only (workflow skills come from the plugin) |

---

## Tips

- **Not everything at once.** Decompose large tasks via `/prep-step`.
- **`/step-done` after each substep** — otherwise details get lost in the docs.
- **Claude never commits automatically.** You are always asked.
- **Language:** living docs are written in {{LIVING_DOC_LANGUAGE}}; code, comments,
  commits, and governance docs are always English.
- **Secrets/private info** belong in `private/` (gitignored), never in the tree.
- **On errors:** fix diagnostics immediately — no workarounds, always the root cause.
