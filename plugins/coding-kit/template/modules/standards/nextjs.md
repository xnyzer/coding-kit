<!-- fragment:nextjs -->
### Next.js (App Router)

**Check the shipped docs before writing App Router code.** Recent majors changed APIs,
conventions and file structure against what most training data contains; the authoritative
reference for the installed version ships inside the package, at `node_modules/next/dist/docs/`
(in a monorepo, resolve it from the workspace that depends on `next`, not from the repo root).
Do not write App Router code from memory, and heed deprecation notices.

**Server / client boundary**
- Server Components are the default. `"use client"` marks a leaf, never a layout or a page
  that only wraps interactive parts.
- Modules touching credentials, the database, or an upstream API client import `server-only`,
  so an accidental client import fails the build instead of shipping secrets.
- `NEXT_PUBLIC_*` is a publication decision, not a convenience prefix — never for tokens,
  secrets, or internal hostnames.
- Server Actions are public endpoints. Every action validates its input and authorises the
  caller itself; being reachable only from the app's own UI is not access control.

**Routing & data**
- Route Handlers follow the `api-design` fragment (thin route to service, explicit response
  shape, whitelist validation).
- Caching is explicit. User-specific data declares its caching behaviour deliberately — never
  let a personalised route be statically prerendered by accident.
- File conventions carry the structure: `layout` / `page` / `loading` / `error` / `not-found`.
  Route segments are kebab-case.
- Metadata comes from the Metadata API, not hand-written `<head>` tags.
- Request-scoped middleware lives in `proxy.ts` and exports `proxy`; `middleware.ts` is the
  deprecated predecessor — migrate with the official codemod and never keep both in a tree.

**Assets & build**
- `next/image` for images and `next/font` with self-hosted files — no third-party CDN on a
  user-facing page.
- `output: "standalone"` is what a container image ships; keep it working. In the Dockerfile
  set `ENV HOSTNAME=0.0.0.0`: the standalone server reads `HOSTNAME` verbatim and container
  runtimes set it to the container id.
- Next's agent-rules generator writes a managed block into `AGENTS.md` / `CLAUDE.md` on a
  `next dev` run. Disable it (`agentRules: false` in the Next config) — those files are
  governance, not framework output, and this fragment already carries the read-the-shipped-docs
  rule the generated block would add.
- Biome owns linting and formatting; `next lint` is not used.

**Configuration**
- Next overwrites `NODE_ENV` and `PORT` before application code runs (in `standalone/server.js`
  and `server/lib/start-server.js`). Environment validation must therefore target variables the
  framework does not manage.
- The `instrumentation.ts` hook runs lazily around the first request, not at boot, and Next
  swallows a rejected `register()` and reports "Ready" anyway. Refusing to serve on bad
  configuration has to be an explicit `process.exit`.

**Imports**
- Extensionless relative imports (bundler resolution). This is the documented exception to the
  `.js`-extension rule of the `ts-node` fragment; a project adopting Next records it in
  `.claude/convention-overrides.md`.
<!-- /fragment:nextjs -->
