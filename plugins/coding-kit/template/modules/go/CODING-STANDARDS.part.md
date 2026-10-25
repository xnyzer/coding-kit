<!-- fragment:go -->
### Go toolchain (go module)

- **Go version:** pinned via mise + the `go.mod` directive (they move together). No `latest`.
- **Formatting:** `just format` runs gofmt/goimports; `just check` fails on a diff.
- **Linting:** `golangci-lint` clean (v2, `standard` set — errcheck, govet, ineffassign,
  staticcheck, unused).
- **License gate:** `just license-check` and the CI license job enforce the permissive
  licenses (§8).
<!-- /fragment:go -->
