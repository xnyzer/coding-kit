<!-- fragment:ts-node -->
### TypeScript toolchain (ts-node module)

- **Runtime:** current Node LTS via mise; `engines` in `package.json` enforces the floor.
  **ESM only** (`"type": "module"`); relative imports carry the `.js` extension (nodenext).
- **Package manager: pnpm only** (pinned via `packageManager` + mise). No npm, no yarn.
- **tsconfig is strict** (`strict` plus `noUncheckedIndexedAccess`,
  `exactOptionalPropertyTypes`, `verbatimModuleSyntax`, `noUnusedLocals/Parameters`, …).
  `tsc --noEmit` is part of `just lint`.
- **Biome** is the single formatter + linter (`biome.json`); warnings fail the gate
  (`--error-on-warnings`), and `noExplicitAny` is an error.
- **Tests: vitest**, colocated as `*.test.ts` next to the code; excluded from production
  builds via `tsconfig.build.json`.
- **Lock file:** `pnpm-lock.yaml` (committed) pins exact versions; Renovate keeps the
  dependencies fresh.
<!-- /fragment:ts-node -->
