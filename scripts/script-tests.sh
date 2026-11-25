#!/bin/sh
# Runs the plugin script tests (tests/template-sync/run.sh) for the groups a change
# touches, and says so when it skips them. The table in groups_for is the only place that
# decides this: `just check` calls this script for the working tree, the pre-commit hook
# with --staged for the index. `just check-all` and CI run all groups unconditionally
# (`just test`).
#
#   sh scripts/script-tests.sh            changes since the last commit, untracked files included
#   sh scripts/script-tests.sh --staged   staged changes only
#   … --list                              print the choice instead of running it: all, none
#                                         or the groups, one line
#
# A rename counts with its old and its new path. Without a commit to compare with, or
# when git fails, all groups run. Exit code: that of the test run, 0 when they are
# skipped or listed, 2 for an unknown argument.

set -u

# groups_for PATH — the test groups a change to PATH can affect: their names, "all", or
# nothing when the tests do not see PATH. Whatever many groups use, or whose reach is
# unclear, runs all of them. A test file whose helpers other groups call runs those
# groups too (the head comment of a test file names the files it uses).
groups_for() {
  case $1 in
    install.sh) echo install ;;
    # publish-release.sh calls the real release-notes.sh next to it.
    scripts/release-notes.sh) echo release-notes publish-release ;;
    scripts/publish-release.sh) echo publish-release ;;
    # A privacy case scans the kit's own mise.lock.
    mise.lock) echo privacy ;;
    plugins/coding-kit/hooks/*) echo hook ;;
    # Most groups build their fixtures with the helpers of sync.sh.
    tests/template-sync/run.sh | tests/template-sync/sync.sh) echo all ;;
    tests/template-sync/zones.sh) echo zones global ;;
    tests/template-sync/global.sh) echo global hook ;;
    tests/template-sync/mise.sh) echo mise install ;;
    tests/template-sync/*.sh)
      gf_name=${1#tests/template-sync/}
      echo "${gf_name%.sh}" ;;
    plugins/coding-kit/scripts/* | plugins/coding-kit/global/*) echo all ;;
    plugins/coding-kit/template/*) echo all ;;
    tests/template-sync/* | justfile | scripts/script-tests.sh)
      echo all ;;
    # git quotes paths with unusual characters; such a path cannot be matched reliably.
    '"'*) echo all ;;
  esac
}

# finish CHOICE [REASON] — runs the choice (none, all or the groups), or prints it with
# --list. REASON says why all groups run.
finish() {
  if [ "$list" = yes ]; then
    printf '%s\n' "$1"
    exit 0
  fi
  case $1 in
    none)
      printf 'script tests skipped: %s touches what they test (the table is in scripts/script-tests.sh; just check-all runs everything)\n' "$scope"
      exit 0 ;;
    all)
      printf 'script tests: %s — running all groups\n' "$2"
      exec sh tests/template-sync/run.sh ;;
    *)
      printf 'script tests: the changes touch the groups %s — running them\n' "$1"
      # Unquoted: the groups are words without spaces, one argument each.
      exec sh tests/template-sync/run.sh $1 ;;
  esac
}

usage() {
  printf 'usage: sh scripts/script-tests.sh [--staged] [--list]\n' >&2
  exit 2
}

staged=no
list=no
for arg in "$@"; do
  case $arg in
    --staged) staged=yes ;;
    --list) list=yes ;;
    *) usage ;;
  esac
done
if [ "$staged" = yes ]; then
  scope="no staged change"
else
  scope="no change since the last commit"
fi

cd "$(dirname "$0")/.." || exit 1

git rev-parse --verify --quiet HEAD > /dev/null || finish all "no commit to compare with"

if [ "$staged" = yes ]; then
  changed=$(git -c core.quotePath=false diff --cached --name-only --no-renames HEAD) ||
    finish all "git failed"
else
  changed=$(git -c core.quotePath=false diff --name-only --no-renames HEAD &&
    git -c core.quotePath=false ls-files --others --exclude-standard) ||
    finish all "git failed"
fi

# The groups of all changed paths, each once; the first path that needs all ends the
# search.
groups=
while IFS= read -r path; do
  [ -n "$path" ] || continue
  for group in $(groups_for "$path"); do
    [ "$group" != all ] || finish all "$path changed"
    case " $groups " in
      *" $group "*) ;;
      *) groups="$groups $group" ;;
    esac
  done
done << EOF
$changed
EOF

if [ -z "$groups" ]; then
  finish none
fi
finish "${groups# }"
