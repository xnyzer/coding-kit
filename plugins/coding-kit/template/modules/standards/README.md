# modules/standards/

Reusable, framework-granular `CODING-STANDARDS` fragments, composed into a project's
`CODING-STANDARDS.md` §13 slot. Unlike the per-language stack `modules/`, these are
cross-cutting: a `react` or `docker` fragment can be pulled by any module that needs it. The
contract is defined in [`MANIFEST.md`](../../MANIFEST.md) (§ Standards fragments).

Each fragment is a self-contained file `<name>.md` whose body is wrapped in
`<!-- fragment:<name> -->` … `<!-- /fragment:<name> -->`. Skills append it inside the
`<!-- module:coding-standards -->` slot; nothing else in `CODING-STANDARDS.md` changes.

## Catalog

Every fragment plus the trigger→fragment mapping. Most triggers are **signals**, typed as
`npm:`, `pypi:`, `go:`, `tool:` or `file:` ([MANIFEST § Detection](../../MANIFEST.md)), which
the plugin's `template-sync.sh detect` finds in a project. A fragment without any signal
declares a **project characteristic** instead (marked *characteristic:*), which no file
shows: `/prep-step` asks it for a planned task, the requirements interview
(`/define-requirements`) asks it up front, and `/choose-stack` can retrofit it (confirmed
before appending). Evaluating triggers is coding-kit logic; this catalog defines only the
mapping.

| Fragment | Covers | Trigger — signals / project characteristic |
|----------|--------|------------------------------------------------------|
| `python-lang` | Python language rules, whatever the toolchain: type hints, safe calls, naming, dependencies | `tool:python`, `file:pyproject.toml`, `file:requirements*.txt` |
| `typescript-lang` | TypeScript language rules, whatever the toolchain: strict types, no `any`, safe calls, naming, dependencies | `npm:typescript`, `file:tsconfig.json` |
| `go-lang` | Go language rules, whatever the toolchain: formatting, vet, naming, errors, context, concurrency, safe calls, tests, dependencies | `tool:go`, `file:go.mod` |
| `react` | React components, styling/theming, i18n, a11y, performance | `npm:react`, `npm:react-dom` |
| `nextjs` | App Router boundaries, routing & caching, assets, build, configuration | `npm:next` |
| `astro` | Static-first sites: islands, strict CSP, build & quality gate, images | `npm:astro` |
| `prisma` | Prisma data access, schema & migrations | `npm:prisma`, `npm:@prisma/client` |
| `api-design` | REST API design, request/response validation, web security boundary | `npm:express`, `npm:fastify`, `npm:koa`, `npm:hono`, `npm:@nestjs/core`, `pypi:fastapi`, `pypi:flask`, `pypi:django`, `pypi:litestar`, `go:github.com/gin-gonic/gin`, `go:github.com/labstack/echo`, `go:github.com/go-chi/chi`, `go:github.com/gofiber/fiber` |
| `docker` | Container images, compose, entrypoint & startup | `file:Dockerfile*`, `file:*.Dockerfile`, `file:docker-compose*.y*ml`, `file:compose.y*ml`, `file:compose.*.y*ml` |
| `nginx` | Reverse proxy: headers, caching, SPA serving, WebSocket | `file:nginx*.conf`, `file:*nginx/*` |
| `audit-logging` | Accountability trail for mutating/admin actions: scope, entry contents, properties, retention | *characteristic:* service with user/admin mutations |

## How a module pulls fragments

A stack module contributes its own **module fragment** (its `CODING-STANDARDS.part.md`,
wrapped as `fragment:<module>`) implicitly — the rules that hold only with the module's
toolchain. To also pull catalog fragments, it lists them — in order — on a
`Standards fragments:` line in its `MODULE.md`, e.g.:

```
Standards fragments: react, prisma, api-design, docker, nginx
```

Omit the line (or leave it empty) to pull no catalog fragments.

**Language fragments** are the catalog fragments named `<language>-lang` (`python-lang`,
`typescript-lang`, `go-lang`): the rules of a language that hold whatever toolchain runs the
code. The module of a language declares its language fragment first. A project that uses the
language without its module — a tool language (MANIFEST § Detection) — pulls the language
fragment alone, proposed through its signals. Module and catalog fragments share the
`fragment:` names, hence the suffix.
