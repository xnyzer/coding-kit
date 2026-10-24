# coding-kit — repo-level recipes

default:
    @just --list

# Install git hooks
setup:
    lefthook install

# Full repo validation: JSON/YAML/TOML syntax, plugin/marketplace/skill contracts,
# privacy lint + blocklist, bundled template (placeholders, markers, fragment catalog),
# then the plugin script tests
check:
    uv run --with pyyaml python3 scripts/validate.py
    sh tests/template-sync/run.sh

# Version rule for plugin content: --staged (pre-commit) or --since <rev> (CI)
version-rule *args:
    uv run python3 scripts/version-rule.py {{args}}
