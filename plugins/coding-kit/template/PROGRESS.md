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

---

## Open tasks — work top to bottom

_No prepared tasks. Plan a backlog item via `/prep-step`._

---

## Feature ideas (backlog)

_Intake new ideas via `/add-feature` — they get the next F-number._

### F-011 — Section-marker contract for updatable zones in seed files

**Status:** BACKLOG

**Problem:** `/update-conventions` never touches seed files (CLAUDE.md, PROGRESS.md,
REQUIREMENTS.md, README.md, …) — by design, since they carry project-specific prose.
But these skeletons also carry **template-owned structure** (CLAUDE.md's Graphiti/
Languages/convention blocks, the PROGRESS skeleton head, the REQUIREMENTS head note)
that evolves with the template and currently never reaches existing projects.

**Idea:** Mark updatable zones inside the seed skeletons with explicit section
markers (modeled on `fragment:NAME`), so the sync can diff and offer those sections
individually while everything unmarked stays untouchable. This repo defines the
contract and the data; the evaluation/sync logic is coding-kit work (tracked there
as F-021).

**Sketch:**
- Define a marker scheme for seed sections (e.g. `<!-- section:NAME -->` …
  `<!-- /section:NAME -->`), collision-free with the existing `override:`,
  `fragment:`, and `template:` markers; register it in `MANIFEST.md` (§ Markers).
- Wrap the template-owned zones in the seed skeletons: `core/CLAUDE.md` (Graphiti
  block, Languages block, convention bullets), `core/PROGRESS.md` skeleton head,
  `core/REQUIREMENTS.md` head note; decide per file whether `core/README.md` has any
  template zone at all.
- MANIFEST policy wording: seed files stay seed; marked sections are individually
  offerable by `/update-conventions`, never the whole file.

**Open questions:** exact zone inventory per seed file; behavior of projects
instantiated before the markers existed (migration itself is kit-side).

**Dependencies:** none here; consumed by coding-kit F-021.

---

<!-- FEATURE-INDEX
next-feature: F-012
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
F-011 Section-marker contract for updatable zones in seed files
-->
