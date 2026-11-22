# coding-kit — repo-level recipes

default:
    @just --list

# Install git hooks
setup:
    lefthook install

# Gate before every commit: repo validation, the feature index, and the plugin script
# tests when a change since the last commit touches them
check: validate features test-changed

# Everything, the script tests always — what CI runs
check-all: validate features test

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

# The script tests only when a change since the last commit touches them; the path list
# lives in scripts/script-tests.sh
test-changed:
    sh scripts/script-tests.sh

# Release notes of a dated version from the CHANGELOG, for gh release create (the
# release flow is in CLAUDE.md)
[positional-arguments]
release-notes *args:
    @sh scripts/release-notes.sh "$@"

# Publish the GitHub release of a pushed tag vX.Y.Z by hand, the same way the release
# workflow does; the tag goes in as an argument, not as text of the command
[positional-arguments]
publish-release tag:
    @sh scripts/publish-release.sh "$1"

# Version rule for plugin content: --staged (pre-commit) or --since <rev> (CI)
[positional-arguments]
version-rule *args:
    uv run python3 scripts/version-rule.py "$@"
