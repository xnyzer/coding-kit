# Module: java (stub — documented, not implemented)

Planned scope for a future Java module. Nothing here is instantiated yet;
`/choose-stack` lists it as "planned".

## Intended shape

- **Toolchain:** current LTS JDK via mise; build tool decision pending (Gradle with
  version catalog vs. Maven — verify current best practice when building the module).
- **Recipes:** `setup` (dependency resolution, lefthook install), `test` (JUnit),
  `lint` (Checkstyle/Error Prone — verify current state), `format`
  (google-java-format or Spotless), `check` (features index + format-check + lint + test +
  license gate), `build` (jar/native), `dev` (run main class), `features-index` and
  `bump-tools` (as in core).
- **License gate:** inside `just check`, like the go module, so every host runs it and no
  `ci.part.yml` is needed; candidate: Gradle/Maven license plugins.
- **CodeQL:** `{{CODEQL_LANGUAGES}}` → `java-kotlin`.

## Open questions (resolve when building the module)

- [ ] Gradle vs. Maven default for solo projects.
- [ ] Formatter choice (Spotless wrapping google-java-format is the likely default).
- [ ] Dependency lock strategy (Gradle lockfiles) + Renovate manager coverage.
