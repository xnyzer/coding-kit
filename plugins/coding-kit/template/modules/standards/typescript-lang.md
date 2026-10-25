<!-- fragment:typescript-lang -->
### TypeScript

Rules for all TypeScript code in the project, whatever toolchain runs it.

- **Strict types:** the compiler runs strict; never weaken it per file — fix the types.
- **No `any`** — use `unknown` and narrow.
- **Safe calls (core §8):** `execFile`/`spawn` with an argument array, never `exec` with a
  string built from foreign input; no `eval`/`new Function`.
- **Naming:** camelCase for values/functions, PascalCase for types/classes,
  kebab-case file names.
- **Dependencies:** pinned in a committed lock file; permissive licenses only (§8).
<!-- /fragment:typescript-lang -->
