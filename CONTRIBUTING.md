# Contributing to coding-kit

Thanks for your interest! This is a personal toolkit first — its conventions are opinionated
and documented; contributions that fit them are welcome.

## What this repo is

A Claude Code plugin (`plugins/coding-kit/`) with its skills, a stop hook and the project
template (`plugins/coding-kit/template/`), the marketplace that serves it
(`.claude-plugin/marketplace.json`), a shareable Renovate preset (`default.json`), and a
new-machine installer (`install.sh`). Kit documentation and skill texts are **German** by
design; template content, governance docs, commit messages, and anything that acts inside
downstream projects are English.

## The versioning rule (binding)

Skills, hooks and template share one version. Every content change to any of them
requires:

1. a version in `plugins/coding-kit/.claude-plugin/plugin.json` above the pushed state
   (semver; several commits may share one unreleased version),
2. an entry for that version in `plugins/coding-kit/CHANGELOG.md` — with a
   `### Template` section when template content changed, because `/update-conventions`
   shows exactly that section to downstream projects,
3. a `MANIFEST.md` update in the same commit if template files were added, removed, or
   re-policied; a target that leaves the core-managed table gets a row in
   `## Removed and renamed targets`.

`just version-rule` checks this before every commit and in CI.

## Where conventions originate

Conventions always originate **here in the template** and flow exclusively downward
(template → project) via `/new-project` and `/update-conventions`. Improvements discovered
in an instantiated project are contributed as a manually initiated adoption proposal — a
session in this repository, or an issue — never as an automatic write from a project.

## Proposing a module or fragment

The kit's skills notice what the template lacks: a tool in a project's `mise.toml` with no
module or fragment, a project-local standards fragment, a change to a template file that
would help every project. They then offer an adoption proposal — generalized and free of
personal data — in one of two forms; nothing is sent automatically:

- **An issue** (the default, no checkout needed). Title by kind — `template: add a <language>
  module`, `standards: add a <name> fragment`, `template: <file> — <change>` — and a body
  with *Summary*, *Today* (what the project does instead), *Proposal* (module or fragment,
  its signals, a matching stub), *Material* and *Kit rules*. Material is split into
  *From the project* (in use there) and *Suggested, not from the project* (unverified
  ideas), so whoever builds the addition can weigh them.
- **A prompt** for a session in this repository or a fork, asking it to design the
  addition: research the current state of the toolchain first, weigh both parts of the
  material, show the draft with what it kept or dropped and why, and build only after
  approval — under the rules above. In a fork it ends with a pull request listing the
  changed files.

A new language usually becomes a stack module plus its language fragment
(`<language>-lang`); a tool without a language of its own becomes a catalog fragment.
Read `plugins/coding-kit/template/MANIFEST.md` and an existing full module before
building one.

## Rules for template content

Read `plugins/coding-kit/template/MANIFEST.md` before changing template content — it is
the contract with the skills, and `just check` verifies it mechanically.

- English only, free of personal data: no real names (people, customers, or concrete
  downstream projects), private emails, absolute local paths, IPs, hostnames. Identity is
  parameterised (`{{OWNER}}`, …) or resolved at runtime.
- Only registered placeholders (MANIFEST § Placeholders); `just check` enforces the
  registry.
- No static tool-version claims in prose — write "current LTS", not a number. Technical
  pins (action SHAs, mise tools) are exact; Renovate keeps them fresh, and a pin change
  under `template/` is a content change like any other (see the versioning rule).

## Rules for skills and hooks

Read `docs/skill-authoring.md` before changing anything under `plugins/`. In short:

- No personal data, no absolute local paths, no hardcoded identity — resolve at runtime
  (`git config`, `gh api`) or via the personal config the installer creates.
- No static tool-version claims in prose; technical pins are kept fresh by Renovate.
- Skills must stay stack-agnostic (standard `just` recipes only) and must not hardcode
  any project's state.
- Skills read the template only via `${CLAUDE_PLUGIN_ROOT}/template`. A session in this
  repository runs the installed plugin; test changes with
  `claude --plugin-dir plugins/coding-kit`.

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
internals. `lefthook` runs gitleaks, the validator and the versioning rule before every
commit, and the plugin script tests when a script, the template or the tests change
(`just setup` installs the hooks).

## Pull requests

Target `main`; CI must be green; keep changes focused — one concern per PR. Squash-merge
is the default.
