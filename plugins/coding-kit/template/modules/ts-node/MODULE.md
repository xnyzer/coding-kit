# Module: ts-node

TypeScript on Node — senior defaults: **pnpm** (pinned via `packageManager` + mise, no
Corepack dependency), **strict tsconfig** (the `tsc --init` strict set + `nodenext` for
bundler-free Node ESM), **Biome** as formatter + linter (warnings fail the gate),
**vitest** for tests (colocated `*.test.ts`, excluded from builds via
`tsconfig.build.json`). Node = current LTS via mise; `engines` enforces the floor.

`{{CODEQL_LANGUAGES}}` → `javascript-typescript`

## Parts

| Part | Notes |
|------|-------|
| `justfile` | replaces core justfile; `check` = Biome CI (format+lint) + `tsc --noEmit` + vitest |
| `mise.part.toml` | node (LTS major) + pnpm |
| `gitignore.part` | node_modules, dist, coverage |
| `CODING-STANDARDS.part.md` | TypeScript rules for §13 |
| `files/` | package.json, tsconfig(.build).json, biome.json, vitest.config.ts, src sample |

**Standards fragments:** (none) — this module contributes only its own `fragment:ts-node`
language fragment; it pulls no catalog fragments from `modules/standards/`.

## File policies (files/)

| File | Policy |
|------|--------|
| `package.json` | seed (scripts/deps evolve with the project; Renovate updates versions) |
| `tsconfig.json`, `tsconfig.build.json` | managed |
| `biome.json` | managed |
| `vitest.config.ts` | managed |
| `src/index.ts`, `src/index.test.ts` | seed (sample code — replace freely) |

## Maintenance notes

- Exact dependency versions in `package.json` and the `packageManager` pin are refreshed
  by Renovate; the mise majors track the current LTS (bump deliberately on LTS change).
- `biome ci --error-on-warnings` enforces zero-warning policy; if a Biome major changes
  flags, `/update-conventions` carries the fix.
- The `dev` recipe is a documented placeholder — projects wire their own entrypoint.
