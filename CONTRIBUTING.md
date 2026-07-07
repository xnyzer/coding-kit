# Contributing to coding-kit

Thanks for your interest! This is a personal toolkit first — its conventions are opinionated
and documented; contributions that fit them are welcome.

## What this repo is

A Claude Code plugin (`plugins/coding-kit/`), the marketplace that serves it
(`.claude-plugin/marketplace.json`), a shareable Renovate preset (`default.json`), and a
new-machine installer (`install.sh`). Kit documentation and skill texts are **German** by
design; governance docs, commit messages, and anything that acts inside downstream
projects are English.

## The versioning invariant (binding)

Every content change to the plugin (skills, hooks) requires, in the same commit:

1. a version bump in `plugins/coding-kit/.claude-plugin/plugin.json` (semver),
2. a `CHANGELOG.md` entry.

## Rules for skills and hooks

Read `docs/skill-authoring.md` before changing anything under `plugins/`. In short:

- No personal data, no absolute local paths, no hardcoded identity — resolve at runtime
  (`git config`, `gh api`) or via the personal config the installer creates.
- No static tool-version claims in prose; technical pins are kept fresh by Renovate.
- Skills must stay stack-agnostic (standard `just` recipes only) and must not hardcode
  any project's state.

## License of contributions

This project is licensed under **Apache-2.0** (see `LICENSE`). By submitting a
contribution you agree that it is licensed under the same terms (inbound = outbound).

## Commits

- **Conventional Commits**, English, imperative mood; explain trade-offs in the body
  (`Decision: X over Y because …`).
- End the body with `Co-Authored-By: Claude <noreply@anthropic.com>` when applicable.
- Commit emails must be GitHub noreply addresses
  (`<numeric-id>+<username>@users.noreply.github.com`) — this history is public.

## Secrets policy

Never commit secrets, tokens, private keys, private email addresses, or deployment
internals. `lefthook` runs gitleaks plus the kit validator before every commit
(`just setup` installs the hooks).

## Pull requests

Target `main`; CI must be green; keep changes focused — one concern per PR. Squash-merge
is the default.
