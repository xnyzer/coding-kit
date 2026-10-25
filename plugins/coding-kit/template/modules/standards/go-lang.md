<!-- fragment:go-lang -->
### Go

Rules for all Go code in the project, whatever toolchain runs it.

- **Formatting:** gofmt/goimports are mandatory. Imports grouped stdlib → third-party →
  local (§4).
- **Linting:** `go vet` clean. Warnings are errors (§1).
- **Naming:** Go conventions — `MixedCaps`, exported identifiers documented; package
  names short, lower-case, no underscores. The verb-first/`is`/`has` intent rules (§3)
  still apply.
- **Errors:** return `error`, never panic on a production path (§7). Wrap with
  `fmt.Errorf("…: %w", err)`; define sentinel/typed errors for domain failures. Check
  every returned error — no `_ =` discards on meaningful paths.
- **Context:** thread `context.Context` as the first parameter through request/IO paths;
  honour cancellation.
- **Concurrency:** no shared state without synchronisation; no goroutine leaks (bounded
  lifetimes, respect `ctx`). Tests run with `-race`.
- **Safe calls (core §8):** `exec.Command(name, args...)` with separate arguments, never
  `sh -c` with foreign input; `database/sql` placeholders, never `fmt.Sprintf` into a query.
- **Tests:** standard `testing` package, table-driven where it helps; `_test.go` next to
  the code. Negative tests for every boundary (§10).
- **Dependencies:** `go.mod`/`go.sum` pinned; `go mod tidy` clean; permissive licenses
  only (§8).
<!-- /fragment:go-lang -->
