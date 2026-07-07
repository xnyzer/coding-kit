# .claude/

Claude Code project configuration.

## settings.json (managed by the template)

Hardened permissions: a tight allow-list (`just`, `mise`, read-only git, hooks/scanner)
plus a deny-list for secret material (`.env*`, key files, `.ssh/`, `.aws/`, `secrets/`,
`credentials/`) and for `git push --force`.

**Known caveat:** deny rules take precedence over allow rules, so depending on the Claude
Code version the `.env.example` allow entries may not carve out an exception — worst case
Claude asks for permission on `.env.example` too. That is the intended failure direction.

## settings.local.json (never committed)

Machine-local settings and permission grants accumulate here; it is gitignored and must
never be committed or copied between machines — it tends to collect local paths and
project internals.

## convention-overrides.md

The registry of deliberate project-local deviations from template conventions.
`/update-conventions` reads it and leaves registered files/sections untouched.

## template-version

Stamped by `/new-project`; records which template `VERSION` this project was instantiated
from. `/update-conventions` uses it to compute pending updates. Do not edit by hand.

## skills/

**Project-specific skills only.** The generic workflow skills (`/add-feature`,
`/prep-step`, `/step-done`, `/audit-code`, …) come from the coding-kit plugin — do not
copy them here, or you'll shadow updates.
