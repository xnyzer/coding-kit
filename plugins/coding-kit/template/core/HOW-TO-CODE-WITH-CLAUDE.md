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

None of these skills live in this repository — they come from the coding-kit plugin for
Claude Code (see *Contributor setup*). Each can be called with the plugin's namespace,
e.g. `/coding-kit:add-feature`; the short form `/add-feature` used below works as long as
no other command or skill has the same name. The skills automate a workflow you can also
follow by hand: PROGRESS.md and the `just` recipes (`just check` above all) work without
the plugin.

**Daily development loop** — a task moves `BACKLOG → PLANNED → implemented → done`:

| Skill | When to use | What happens |
|-------|-------------|--------------|
| `/add-feature` | Put a new task on the roadmap — you start it, or Claude does when a new task comes up while building | Analysis → write-up → your OK → entry in PROGRESS.md (status **BACKLOG**) |
| `/prep-step` | Plan a task before building it | Questions the sketch against the code, sizes it, decomposes into substeps → plan in PROGRESS.md (status **PLANNED**). If the task introduces a new framework/dependency, checks standards coverage against the fragment catalog — matching dependency signals **and** characteristic triggers — and proposes appending missing catalog fragments, or authoring a project-local fragment (with a manual adoption proposal for the template). A fragment that also requires a change in the project itself brings that change into the plan |
| `/build-step` | Implement a planned task | Works the plan substep by substep, verifying each; ends every substep with a `/step-done` recommendation |
| `/step-done` | After finishing a task/substep | Code review → `just check` → secrets & privacy scan → standards-coverage backstop → preview of the PROGRESS booking with the commit message → one approval → booking + commit |
| `/teach-step` | Implement it yourself, guided | Socratic guidance — you write all the code; Claude reads it, gives graded hints, runs tests, writes nothing itself |
| `/audit-code` | One-off audit of existing code | Check (optionally scoped to an area or path) → results in AUDIT-RESULTS.md (gitignored) |

**Occasional project maintenance:**

| Skill | When to use |
|-------|-------------|
| `/choose-stack` | Add a stack module later, or switch modules. Composes the module's declared catalog fragments (append, idempotent per `fragment:NAME` marker) and can retrofit characteristic fragments after confirmation. Some fragments require more than the text in the slot — a file that has to exist before a framework first runs, say; that change is made in the same step and confirmed with it |
| `/choose-license` | Pick or change the project license |
| `/update-conventions` | Pull template updates into this project — downward only (template → project). Managed files are merged three-way against the base snapshot in `.claude/template-base/`: your additions stay, template changes arrive, only overlapping changes need a decision, and every result is confirmed per file; registered deviations follow their kind. Standards fragments and marked seed sections (`section:NAME`) are synced one by one; seed files are never replaced as a whole; project-local fragments are never touched, only reported with a manually triggerable adoption proposal for the template. Fragment requirements of that kind are re-checked even when the fragment text itself is unchanged — this is the only route that reaches a project which adopted a fragment before it carried the requirement. Without an argument it syncs this project; `status` only reports, `revise` reviews the deviation registry |
| `/go-public` | Take a private or local-only project public, guided and fail-closed: blocking preflight audit (secrets across the full git history, privacy incl. commit metadata, license, `private/` hygiene), file catch-up **before** the switch (public-only files arrive while still private), then visibility change or repo creation + initial push only after explicit per-run approval |
| `/define-requirements` | Elicit requirements (M1 interview → `REQUIREMENTS.md`). The interview also asks the fragment catalog's characteristic triggers (e.g. audit-logging: "Are there user/admin actions that mutate data?") |
| `/refine-requirements` | Go back to the spec when something fundamental changed |

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
Claude may also start `/add-feature` itself — for an idea that comes up during
`/build-step`, say — but the entry is still written only after your OK.

---

## Workflow 2: Prepare, implement & finish a task

```
You:    /prep-step F-002
Claude: Analysis… size assessment… substeps if needed (F-002a, F-002b, …)
You:    yes, write that in
Claude: Records the plan in PROGRESS.md (status PLANNED)
You:    /build-step F-002
Claude: Implements F-002a, verifies it, recommends /step-done
You:    /step-done
Claude: Review, checks, scans — then the PROGRESS booking and commit message as a preview
You:    book and commit
Claude: Booked and committed. Continue with F-002b?
```

Three skills, one per phase: `/prep-step` plans (→ `PLANNED`), `/build-step` implements the
plan substep by substep, `/step-done` reviews and finishes each substep. Prefer to write the
code yourself? Use `/teach-step` instead of `/build-step` — it guides you and writes nothing.

**Size assessment:** Small (<200 lines, <5 files) → direct. Medium → 2–3 substeps.
Large → 3–5 substeps. `/prep-step` without an argument takes the next open task.

---

## What `/step-done` does in detail

1. **Code review & checks** — changed files against `CODING-STANDARDS.md`; `just check`
   must be green.
2. **Secrets & privacy scan** — working tree + commit draft for secrets/keys/IPs/private
   emails; living docs for private info (names, customers, local paths). Findings are
   fixed or moved to `private/` before any commit is proposed.
3. **Standards-coverage backstop** — diff-based: new manifest dependencies or signal files
   without a matching standards fragment are reported as a gap, with a proposal to append
   the fragment. Non-blocking — it never stops the finish.
4. **PROGRESS booking, as a preview** — done row, archive entry and `(DONE)` marker are
   prepared, not yet written.
5. **One approval for booking and commit** — the preview comes with a proposed
   Conventional Commits message; you choose *book and commit*, *book only*, or *change
   the text*. Only then are `PROGRESS.md` / `PROGRESS-ARCHIVE.md` written, `just check`
   re-run and the commit made (commit email verified as a GitHub noreply address).
6. **Graphiti** — knowledge-graph update after the booking (if configured).

---

## Important files

| File | Purpose |
|------|---------|
| `PROGRESS.md` | Open tasks + Done table + feature index |
| `PROGRESS-ARCHIVE.md` | Full documentation of all finished tasks |
| `REQUIREMENTS.md` | Transitional spec — dissolved once fully transferred to PROGRESS.md |
| `CODING-STANDARDS.md` | Binding coding rules (incl. stack section) |
| `CLAUDE.md` | Project-specific Claude instructions (auto-loaded) |
| `.claude/convention-overrides.md` | Registered deviations from template conventions — why a managed file deviates and how updates treat it |
| `.claude/template-answers` | Values the template is rendered with for this project |
| `.claude/template-base/` | Base snapshot for template updates (generated — never edit) |
| `.claude/skills/` | Project-specific skills only (workflow skills come from the plugin) |

---

## Tips

- **Not everything at once.** Decompose large tasks via `/prep-step`.
- **`/step-done` after each substep** — otherwise details get lost in the docs.
- **Claude never commits automatically.** You are always asked — and no PROGRESS entry is
  written without your OK either.
- **Languages:** see the Languages block in `CLAUDE.md` — living docs in
  {{LANG_LIVING_DOCS}}, code comments in {{LANG_COMMENTS}}, commit prose in
  {{LANG_COMMITS}} (Conventional-Commit tokens stay English); identifiers and
  governance docs are always English.
- **Secrets/private info** belong in `private/` (gitignored), never in the tree.
- **On errors:** fix diagnostics immediately — no workarounds, always the root cause.
