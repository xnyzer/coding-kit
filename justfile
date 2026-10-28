# coding-kit — repo-level recipes

default:
    @just --list

# Install git hooks
setup:
    lefthook install

# Full gate: repo validation, the feature index, then the plugin script tests
check: validate features test

# Check the feature files and the generated table in features/INDEX.md
features:
    sh plugins/coding-kit/template/core/scripts/features-index.sh check features

# Regenerate the table in features/INDEX.md from the feature files
features-index:
    sh plugins/coding-kit/template/core/scripts/features-index.sh write features

# Repo validation: syntax, plugin and template contracts, privacy lint and blocklist
validate:
    uv run --with pyyaml python3 scripts/validate.py

# Tests of the plugin scripts under dash and bash, plus mawk and gawk when installed
test:
    sh tests/template-sync/run.sh

# Version rule for plugin content: --staged (pre-commit) or --since <rev> (CI)
version-rule *args:
    uv run python3 scripts/version-rule.py {{args}}
