<!-- fragment:astro -->
### Astro

**Adopting Astro changes managed files — do it in the adoption step.** On the `ts-node`
module, an Astro project deviates from three managed files: `tsconfig.json` extends
`astro/tsconfigs/strict`, `biome.json` carries the `.astro` override (see *Build & quality
gate*), and the `justfile` gate runs `astro check` (devDependencies `@astrojs/check` and
`typescript`). Register each of the three as `keep` in the Files table of
`.claude/convention-overrides.md` in the same step: template updates then still merge in,
and where they collide with the Astro changes the project side wins — otherwise a
conflict resolved the wrong way drops `.astro` files out of the gate. Add `.astro/`
(generated types) to `.gitignore`.

**Static first, islands only where needed**
- Pages and layouts are `.astro` components; they render to HTML at build time and ship no
  JavaScript. Content must be readable without JavaScript.
- Interactivity comes only as an island: a UI-framework component with a `client:*`
  directive. Prefer `client:visible` / `client:idle` over `client:load`; if the project
  defines a load budget, every island justifies its weight against it.
- `client:only` always names its framework (`client:only="react"`) — Astro cannot infer it,
  because the component never renders on the server.
- Islands do not share framework context — share state through a small store library
  (e.g. Nano Stores). React islands additionally follow the `react` fragment.
- Personal data is never prerendered: render it client-side (`client:only`) or on demand
  (`export const prerender = false`), and mark such pages `noindex`.

**Strict Content Security Policy**
- Enable Astro's built-in CSP (`security.csp`); it hashes Astro's own scripts and styles.
  Never add `'unsafe-inline'` or `'unsafe-eval'` — `'unsafe-inline'` in a directive also
  stops Astro from emitting hashes for it.
- The CSP is not active under `astro dev`; verify it with `build` + `preview`.
- Some features are not covered by the hashes — check the Astro CSP docs for the installed
  version. Known cases: view transitions via `<ClientRouter />` (use the native View
  Transition API) and Shiki (use `<Prism />`). External scripts and styles need their own
  hashes.
- No inline event handlers. `set:html` is not escaped — trusted content only; use
  `set:text` for anything else. No third-party scripts, styles or fonts from CDNs.
- Astro delivers the policy as a `<meta>` tag, which cannot carry header-only directives
  (`frame-ancestors`, reporting) or HSTS — those come from the server/proxy (see the `nginx`
  fragment).

**Build & quality gate**
- What ships to visitors is what islands and `<script>` tags import — not the
  `dependencies` list (the scaffold lists `astro` itself there). If the project keeps a
  third-party notice list, it covers exactly those client-side packages.
- Raster images go through `astro:assets` (`<Image>` / `<Picture>`), optimised at build
  time. The default service (sharp, Apache-2.0) ships prebuilt libvips binaries under
  LGPL-3.0-or-later: check them against the project's license policy. With static output
  they run only at build time; with on-demand rendering on a Node adapter they ship in the
  deployed image.
- Fonts are self-hosted — through Astro's `fonts` configuration or local files.
- If the project needs a service worker and no maintained Astro integration supports the
  installed major, generate it in a post-build step over `dist/`.
- `astro check` type-checks `.astro` files in the gate. Biome's Astro support is
  experimental: apply the override Biome documents for `.astro` files (currently `useConst`,
  `useImportType`, `noUnusedVariables` and `noUnusedImports` off while full HTML support is
  disabled) — check the Biome docs for the installed version.

**Imports**
- Extensionless relative imports (bundler resolution). This is the documented exception to
  the `.js`-extension rule of the `ts-node` fragment; a project adopting Astro records it in
  the Rules table of `.claude/convention-overrides.md`.
<!-- /fragment:astro -->
