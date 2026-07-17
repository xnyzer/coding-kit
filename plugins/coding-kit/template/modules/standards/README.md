# modules/standards/

Reusable, framework-granular `CODING-STANDARDS` fragments, composed into a project's
`CODING-STANDARDS.md` §13 slot. Unlike the per-language stack `modules/`, these are
cross-cutting: a `react` or `docker` fragment can be pulled by any module that needs it. The
contract is defined in [`MANIFEST.md`](../../MANIFEST.md) (§ Standards fragments).

Each fragment is a self-contained file `<name>.md` whose body is wrapped in
`<!-- fragment:<name> -->` … `<!-- /fragment:<name> -->`. Skills append it inside the
`<!-- module:coding-standards -->` slot; nothing else in `CODING-STANDARDS.md` changes.

## Catalog

Every fragment plus the framework→fragment mapping — the dependency/framework signals that
`/prep-step` matches to detect a newly introduced framework whose fragment is not yet present.

| Fragment | Covers | Frameworks / dependency signals |
|----------|--------|---------------------------------|
| _(none yet — fragments are authored in a follow-up)_ | — | — |

## How a module pulls fragments

A stack module contributes its own language fragment (its `CODING-STANDARDS.part.md`, wrapped
as `fragment:<module>`) implicitly. To also pull catalog fragments, it lists them — in order —
on a `Standards fragments:` line in its `MODULE.md`, e.g.:

```
Standards fragments: react, prisma, api-design, docker, nginx
```

Omit the line (or leave it empty) to pull no catalog fragments.
