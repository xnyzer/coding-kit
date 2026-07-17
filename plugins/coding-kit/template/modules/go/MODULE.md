# Module: go

Go — distilled from the [redacted-downstream-project] gold standard: **gofmt/goimports** mandatory
(via `golangci-lint fmt`), **go vet + golangci-lint** (v2 config, `standard` linter set),
**tests with `-race`**, and a **license gate** (`go-licenses`, no GPL/AGPL/LGPL) both
locally and as an extra CI job. Go version = current stable via mise + `go.mod` directive.

`{{CODEQL_LANGUAGES}}` → `go`

## Parts

| Part | Notes |
|------|-------|
| `justfile` | replaces core justfile; `check` = fmt-check + vet + golangci-lint + build + test -race |
| `mise.part.toml` | go (current major.minor) + golangci-lint |
| `gitignore.part` | bin, dist, coverage.out |
| `CODING-STANDARDS.part.md` | Go rules for §13 |
| `ci.part.yml` | extra CI job: license gate |
| `files/` | go.mod, main.go + test sample, .golangci.yml |

## File policies (files/)

| File | Policy |
|------|--------|
| `go.mod` | seed (module path + go directive evolve with the project) |
| `.golangci.yml` | managed |
| `main.go`, `main_test.go` | seed (sample code — replace freely) |

## Maintenance notes

- The `go` directive in `go.mod` and the mise pin move together — bump deliberately on new
  Go releases (Renovate proposes both).
- Library projects: replace `main.go` with a package; the recipes are path-agnostic
  (`./...`).
