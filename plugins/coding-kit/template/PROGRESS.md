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

---

## Open tasks — work top to bottom

### F-002 — Composable CODING-STANDARDS fragments

**Status:** PLANNED

**Problem:** The template assembles CODING-STANDARDS from one language-agnostic core plus a
single stack-module part inserted at the §13 slot. A project using several frameworks (e.g.
React + Prisma + Docker) cannot compose their standards, and standards cannot grow as new
frameworks are adopted mid-project — so such projects keep a full CODING-STANDARDS override
instead of inheriting the template.

**Idea:** Break stack-specific standards into framework-granular fragments and make the §13
slot append-capable, so a project inherits core + exactly the fragments for the frameworks it
uses, and can add more later.

**Solution sketch (decided at prep-step):**
- §13 becomes append-capable: fragments are appended inside the existing
  `<!-- module:coding-standards -->` slot, each **self-wrapped** in `<!-- fragment:NAME -->`
  … `<!-- /fragment:NAME -->` (model: the `# module:gitignore` append marker). Skills
  concatenate; no wrapping at runtime.
- Fragments live in a central, reusable catalog `modules/standards/` (react/prisma/docker/…),
  authored in F-003; F-002 only scaffolds the catalog + a framework→fragment mapping.
- A stack module pulls its own `CODING-STANDARDS.part.md` (its language-core fragment)
  implicitly, and declares any **additional** catalog fragments via a "Standards fragments"
  line in its `MODULE.md` (empty for go/python/ts-node).
- Runtime assembly (appending fragments on new-project / choose-stack) is coding-kit logic,
  tracked separately; F-002 defines the contract + data + validator only. Sync-invariant
  (VERSION + CHANGELOG + MANIFEST) applies to the template-content substeps.

**Dependencies:** none in project-template (F-001 done). Co-dependent with the coding-kit side
(choose-stack multi-fragment, prep-step/step-done detection) for a full end-to-end assembly —
that side is tracked separately in the coding-kit repo.

**Substeps:** _(F-002a done — see the Done table and `PROGRESS-ARCHIVE.md`.)_

#### F-002b — Migrate existing modules
- **What:** wrap each existing `CODING-STANDARDS.part.md` (go/python/ts-node) in
  `<!-- fragment:<module> -->` markers **without changing its content**; add the (empty)
  "Standards fragments" declaration to each `MODULE.md`.
- **Files:** `modules/{go,python,ts-node}/CODING-STANDARDS.part.md` + `MODULE.md`, `VERSION`,
  `CHANGELOG.md`.
- **Dependencies:** F-002a.
- **Acceptance:**
  - [ ] All three modules conform; part content unchanged (marker-only diff).
  - [ ] A hand-simulated assembly (core §13 + a module fragment) is valid Markdown.
  - [ ] `just check` green; sync-invariant satisfied.

#### F-002c — Validator support
- **What:** extend `scripts/validate.py` to (a) check `<!-- fragment:NAME -->` markers are
  balanced/well-formed and (b) check every "Standards fragments" name declared in a `MODULE.md`
  resolves to a catalog fragment (no dangling declarations).
- **Files:** `scripts/validate.py` (repo tooling — no VERSION bump).
- **Dependencies:** F-002a, F-002b.
- **Acceptance:**
  - [ ] Validator flags a malformed fragment marker and a dangling declaration (verified).
  - [ ] `just check` green.

---

## Feature ideas (backlog)

### F-003 — Web-standards fragments (react / prisma / api-design / docker / nginx)

**Status:** BACKLOG

**Problem:** F-002 delivers the composable-fragment infrastructure but no web/full-stack
content to compose. Without authored fragments for the common full-stack building blocks, a
downstream full-stack project still cannot inherit its standards from the template and keeps a
full CODING-STANDARDS override.

**Idea:** Author framework-specific standards fragments for the common full-stack building
blocks — React, Prisma, API design, Docker, Nginx — generalized from proven project standards
(project-specific detail and names removed), so a full-stack project inherits core + these
fragments.

**Solution sketch:**
- One fragment per building block in the F-002 catalog: `react`, `prisma`, `api-design`,
  `docker`, `nginx` (extend later as needed).
- Generalize from a real project's standards: keep the framework-specific rules, strip
  project-specific detail and any names.
- Register each in the framework→fragment mapping and wire them into the relevant stack
  module's declared fragments.
- Sync-invariant applies (VERSION + CHANGELOG + MANIFEST), `just check` stays green.

**Dependencies:** F-002 (fragment infrastructure + catalog + markers) must be done first.

**Still to analyze:**
- Which stack module(s) pull these — the existing `ts-node` vs. a new full-stack module.
- Where the line sits vs. core §1–§13: is `api-design` general enough to be near-core, or
  strictly web-specific?
- How opinionated to make each fragment (generalize vs. keep sharp).

---

<!-- FEATURE-INDEX
next-feature: F-004
F-001 Initial template build (DONE)
F-002 Composable CODING-STANDARDS fragments (PLANNED)
F-003 Web-standards fragments (BACKLOG)
-->
