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

---

## Open tasks — work top to bottom

_No prepared tasks. Plan a backlog item via `/prep-step`._

---

## Feature ideas (backlog)

### F-005 — Async in-flight / promise-dedup concurrency standard

**Status:** BACKLOG

**Problem:** When several independent triggers can start the same expensive or side-effectful
async operation (a migration, an external call, a cache populate, a token refresh), running each
independently causes duplicate work, wasted load, or corruption from a half-done shared state.
This is a general senior pattern surfaced while sourcing the web fragments (F-003) but it is not
web-framework-specific, so it belongs in the core standard or a backend fragment, not in F-003.

**Idea:** Capture the in-flight-map / promise-dedup pattern as a language-agnostic standard:
when to apply (shared mutable state + multiple async triggers + expensive/side-effectful work),
when not to (cheap idempotent reads), and the correctness rule (never set the "done" marker
before the awaited work completes, or concurrent readers see a half-finished state).

**Solution sketch:**
- Decide the home: a new core subsection (near error handling / resilience) vs. a `backend`
  standards fragment in the catalog. Language-agnostic wording; illustrative, name-free example.

**Dependencies:** none. (Related: informed by F-003 source analysis.)

### F-006 — Audit / activity-logging standard

**Status:** BACKLOG

**Problem:** Mutating and administrative actions should leave an audit trail, but this is neither
a web framework nor one of the F-003 fragments — it went uncaptured. A downstream project
inheriting the template's standards would otherwise lose this rule.

**Idea:** Capture audit/activity logging as a standard: which actions must be logged (mutations,
admin/security-relevant operations), what a log entry carries (actor, action, target, time —
no secrets), and how it differs from application logging.

**Solution sketch:**
- Decide the home: a core observability subsection vs. an `observability`/`audit-logging`
  standards fragment. Framework-general, name-free.

**Dependencies:** none. (Related: informed by F-003 source analysis.)

---

<!-- FEATURE-INDEX
next-feature: F-007
F-001 Initial template build (DONE)
F-002 Composable CODING-STANDARDS fragments (DONE)
F-003 Web-standards fragments (DONE)
F-004 Remediate already-published real-name leaks (DONE)
F-005 Async in-flight / promise-dedup concurrency standard (BACKLOG)
F-006 Audit / activity-logging standard (BACKLOG)
-->
