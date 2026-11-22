#!/bin/sh
# Runs the plugin script tests (tests/template-sync/run.sh) when a change touches what
# they test, and says so when it skips them. The path list in affects_tests is the only
# place that decides this: `just check` calls this script for the working tree, the
# pre-commit hook with --staged for the index. `just check-all` and CI run the tests
# unconditionally (`just test`).
#
#   sh scripts/script-tests.sh            changes since the last commit, untracked files included
#   sh scripts/script-tests.sh --staged   staged changes only
#
# A rename counts with its old and its new path. Without a commit to compare with, or
# when git fails, the tests run. Exit code: that of the test run, 0 when they are
# skipped, 2 for an unknown argument.

set -u

# affects_tests PATH — succeeds when a change to PATH can change what the tests see.
affects_tests() {
  case $1 in
    plugins/coding-kit/scripts/* | plugins/coding-kit/global/* | plugins/coding-kit/hooks/*)
      return 0 ;;
    plugins/coding-kit/template/* | tests/template-sync/* | justfile | scripts/script-tests.sh)
      return 0 ;;
    # git quotes paths with unusual characters; such a path cannot be matched reliably.
    '"'*)
      return 0 ;;
  esac
  return 1
}

run_tests() {
  printf 'script tests: %s — running them\n' "$1"
  exec sh tests/template-sync/run.sh
}

usage() {
  printf 'usage: sh scripts/script-tests.sh [--staged]\n' >&2
  exit 2
}

[ $# -le 1 ] || usage
case ${1:-} in
  "")
    scope="no change since the last commit" ;;
  --staged)
    scope="no staged change" ;;
  *)
    usage ;;
esac

cd "$(dirname "$0")/.." || exit 1

git rev-parse --verify --quiet HEAD > /dev/null || run_tests "no commit to compare with"

if [ "${1:-}" = --staged ]; then
  changed=$(git -c core.quotePath=false diff --cached --name-only --no-renames HEAD) ||
    run_tests "git failed"
else
  changed=$(git -c core.quotePath=false diff --name-only --no-renames HEAD &&
    git -c core.quotePath=false ls-files --others --exclude-standard) ||
    run_tests "git failed"
fi

while IFS= read -r path; do
  if [ -n "$path" ] && affects_tests "$path"; then
    run_tests "$path changed"
  fi
done << EOF
$changed
EOF

printf 'script tests skipped: %s touches the plugin scripts, hooks, global rules, template or tests (just check-all runs everything)\n' "$scope"
