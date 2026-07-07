# coding-kit — repo-level recipes

default:
    @just --list

# Install git hooks
setup:
    lefthook install

# Full kit validation: JSON/YAML/TOML syntax, plugin/marketplace/skill contracts, privacy lint
check:
    uv run --with pyyaml python3 scripts/validate.py
