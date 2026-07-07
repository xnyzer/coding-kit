# Security Policy

coding-kit ships behaviour into development environments: Claude Code plugin skills, a
Stop hook that runs shell commands, a Renovate preset consumed by downstream projects,
and an installer script. A malicious or careless change here propagates — reports are
taken seriously.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Use GitHub's private reporting instead:

1. Go to the **Security tab** of this repository
2. Click **"Report a vulnerability"**
3. Fill in the form and submit

## What is in scope

- The hook scripts (`plugins/coding-kit/hooks/`) — they execute on every Claude Code
  stop event in matching projects.
- The installer (`install.sh`) — it writes to `~/.claude/` and installs tooling.
- The shareable Renovate preset (`default.json`) — e.g. a change that would unpin
  actions or widen automerge behaviour downstream.
- The skill instructions (`plugins/coding-kit/skills/`) — e.g. prompt-injection vectors
  or instructions that would exfiltrate secrets.

Out of scope: vulnerabilities in the referenced third-party tools themselves (Claude
Code, mise, just, lefthook, gitleaks, Renovate) — report those upstream, but do tell us
so pins and instructions can be updated.

## What happens next

This project is maintained by a single person in their spare time — initial response
within a few days where possible, but it can take two to three weeks. Confirmed issues in
shipped behaviour are treated with priority because of their downstream blast radius.

## Safe harbor

No legal action against researchers who report in good faith, give reasonable time to fix,
and limit testing to their own machines and repositories.
