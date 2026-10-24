# coding-kit — repo-level recipes

default:
    @just --list

# Install git hooks
setup:
    lefthook install

# Full gate: repo validation, then the plugin script tests
check: validate test

# Repo validation: syntax, plugin and template contracts, privacy lint and blocklist
validate:
    uv run --with pyyaml python3 scripts/validate.py

# Tests of the plugin scripts (template-sync.sh) under dash and bash
test:
    sh tests/template-sync/run.sh

# Version rule for plugin content: --staged (pre-commit) or --since <rev> (CI)
version-rule *args:
    uv run python3 scripts/version-rule.py {{args}}
