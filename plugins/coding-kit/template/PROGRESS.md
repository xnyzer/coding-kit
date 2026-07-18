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

---

## Open tasks — work top to bottom

### F-006 — Audit / activity-logging standard

**Status:** PLANNED

**Problem:** Mutating and administrative actions should leave an audit trail, but this is neither
a web framework nor one of the F-003 fragments — it went uncaptured. A downstream project
inheriting the template's standards would otherwise lose this rule.

**Plan (from prep, 2026-07-18):**

- Home decided with the owner: **catalog fragment `audit-logging`**, not a core section — an
  audit trail is real architecture and would be wrong to impose on libraries, CLIs, or local
  tools. Its trigger is a **project characteristic** ("service with user/admin mutations"),
  not a dependency signal.
- New `modules/standards/audit-logging.md`, self-wrapped as `fragment:audit-logging`, in the
  style of the F-003 fragments (framework-general, name-free): which actions must be logged
  (domain mutations, permission/role changes, auth events, admin/config operations — including
  denied attempts); what an entry carries (actor id, action, target type + id, timestamp,
  outcome — never secrets, tokens, or full payloads); properties (append-only, queryable,
  reliably coupled to the mutation; retention is a conscious project decision); and the
  difference from application logging (accountability vs. debugging).
- `modules/standards/README.md`: register the fragment; extend the catalog semantics so a
  mapping row may carry a characteristic-based trigger instead of dependency signals —
  evaluating the trigger (requirements interview at instantiation, `/prep-step` suggestion on
  matching features) stays coding-kit logic.
- Sync invariant: `VERSION` 0.6.0 → 0.7.0 (own commit after F-005; new fragment = minor,
  F-003 precedent) + `CHANGELOG.md` entry; no MANIFEST change (catalog fragments are covered
  generically, as in F-003).

**Files:** `modules/standards/audit-logging.md` (new), `modules/standards/README.md`,
`VERSION`, `CHANGELOG.md` (~50–60 lines).

**Dependencies:** none (ordered after F-005).

---

## Feature ideas (backlog)

_Empty. Intake new ideas via `/add-feature`._

---

<!-- FEATURE-INDEX
next-feature: F-007
F-001 Initial template build (DONE)
F-002 Composable CODING-STANDARDS fragments (DONE)
F-003 Web-standards fragments (DONE)
F-004 Remediate already-published real-name leaks (DONE)
F-005 Async in-flight / promise-dedup concurrency standard (DONE)
F-006 Audit / activity-logging standard (PLANNED)
-->
