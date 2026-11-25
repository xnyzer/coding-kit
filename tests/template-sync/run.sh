#!/bin/sh
# Tests for plugins/coding-kit/scripts/template-sync.sh against the bundled template and
# the kit's global rules (plugins/coding-kit/global/), plus the session-start hook that
# reads them and the template's own scripts/features-index.sh, scripts/license-check.sh
# and scripts/privacy-lint.sh,
# the kit's scripts/release-notes.sh and scripts/publish-release.sh, and the kit's
# install.sh (run with bash, whatever the shell of the pass).
# Every case runs under dash and bash (the shells skills meet on Linux and macOS); the
# script must behave the same in both. Then one more pass under the first shell for each
# of mawk and gawk that is installed but not the default awk: awk implementations differ
# (mawk is the default on Debian and Ubuntu, gawk on Fedora and Arch, and the macOS awk
# accepts more than either). The summary names the shells and awks tested and the checks
# skipped where the file system has no file modes.
#
# The cases come in groups, one file per group (ALL_GROUPS below). Without arguments all
# groups run; with arguments only the named ones, in the order of ALL_GROUPS.
# scripts/script-tests.sh picks the groups a change touches.
#
# A job is one group under one shell (or under the extra awk). The jobs run in parallel,
# as many at once as the machine has cores minus one (at least one); TEST_JOBS sets
# another number. Each finished job prints a progress line; failures follow at the end,
# ordered by group and shell, then the summary.
#
#   sh tests/template-sync/run.sh                 all groups
#   sh tests/template-sync/run.sh install hook    only these groups
#   sh tests/template-sync/run.sh --plan [GROUP…] print the jobs and how many run at once
#   TEST_JOBS=1 sh tests/template-sync/run.sh     one job at a time

set -u

# The groups in the order their jobs start, the longest first, so that no lane runs alone
# at the end: tests/template-sync/NAME.sh defines run_NAME_cases, with - in NAME as _.
ALL_GROUPS='install sync zones render detect global host mise features privacy hook
settings migrate lock selection runner synced publish-release license release-notes'

plan=no
if [ "${1:-}" = --plan ]; then
  plan=yes
  shift
fi

# The groups to run, in the order of ALL_GROUPS: all of them, or those named as arguments.
# An argument that names no group stops the run before any test.
selected=
for group in $ALL_GROUPS; do
  if [ $# -eq 0 ]; then
    selected="$selected $group"
    continue
  fi
  for arg in "$@"; do
    if [ "$arg" = "$group" ]; then
      selected="$selected $group"
      break
    fi
  done
done
for arg in "$@"; do
  known=no
  for group in $ALL_GROUPS; do
    if [ "$arg" = "$group" ]; then known=yes; fi
  done
  if [ "$known" = no ]; then
    printf 'unknown group: %s\n' "$arg" >&2
    printf 'usage: sh tests/template-sync/run.sh [--plan] [GROUP…]\n' >&2
    # $ALL_GROUPS unquoted: one line, the names separated by spaces.
    printf 'groups: %s\n' "$(echo $ALL_GROUPS)" >&2
    exit 2
  fi
done
partial=$#

# The number of cores, 1 when neither getconf nor nproc can tell.
count_cores() {
  cc_n=$(getconf _NPROCESSORS_ONLN 2> /dev/null) || cc_n=
  case $cc_n in
    '' | *[!0-9]*) cc_n=$(nproc 2> /dev/null) || cc_n= ;;
  esac
  case $cc_n in
    '' | *[!0-9]* | 0) cc_n=1 ;;
  esac
  echo "$cc_n"
}

# How many jobs may run at once: TEST_JOBS when set, else the cores minus one. Any other
# value than a number from 1 to 9999 written without leading zero stops the run before
# any test; the limit keeps the arithmetic far from overflow.
if [ -n "${TEST_JOBS:-}" ]; then
  case $TEST_JOBS in
    *[!0-9]* | 0* | ?????*)
      printf 'TEST_JOBS must be a number from 1 to 9999 without leading zero, not: %s\n' \
        "$TEST_JOBS" >&2
      exit 2 ;;
  esac
  slots=$TEST_JOBS
else
  slots=$(($(count_cores) - 1))
  [ "$slots" -ge 1 ] || slots=1
fi

# The cases build git repositories of their own. In a pre-commit hook git exports the
# index and directory of the kit repo, which would point their git calls there.
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_PREFIX GIT_OBJECT_DIRECTORY \
  GIT_ALTERNATE_OBJECT_DIRECTORIES
# Nor does the system git config of the machine take part: Git for Windows sets
# core.autocrlf=true there, which warns in every case repo and changes what git writes.
GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_NOSYSTEM

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SCRIPT=$ROOT/plugins/coding-kit/scripts/template-sync.sh
TEMPLATE=$ROOT/plugins/coding-kit/template
BASE_TMP=$(mktemp -d "${TMPDIR:-/tmp}/template-sync-test.XXXXXX")
trap 'rm -rf "$BASE_TMP"' EXIT

checks=0
failures=0
skipped=0
SH=
TMP=
# Job name in failure lines: group/shell, plus /awk when it is not the default one.
LABEL=

# --- harness --------------------------------------------------------------------

fail() {
  failures=$((failures + 1))
  printf 'FAIL [%s] %s\n' "$LABEL" "$*"
}

# check DESCRIPTION COMMAND… — passes when COMMAND succeeds.
check() {
  c_desc=$1
  shift
  checks=$((checks + 1))
  "$@" > /dev/null 2>&1 || fail "$c_desc"
}

# refute DESCRIPTION COMMAND… — passes when COMMAND fails.
refute() {
  c_desc=$1
  shift
  checks=$((checks + 1))
  if "$@" > /dev/null 2>&1; then fail "$c_desc"; fi
}

# Whether chmod sets file modes here. Git Bash on Windows mounts with noacl: chmod has no
# effect there, and every file shows the same mode.
: > "$BASE_TMP/mode-probe"
chmod 600 "$BASE_TMP/mode-probe"
if [ "$(ls -l "$BASE_TMP/mode-probe" | cut -c1-10)" = '-rw-------' ]; then
  FILE_MODES=yes
else
  FILE_MODES=no
fi

# check_owner_only DESCRIPTION FILE — passes when only the owner may read and write FILE
# (mode 600). Without file modes the check is skipped and counted for the summary.
check_owner_only() {
  if [ "$FILE_MODES" = no ]; then
    skipped=$((skipped + 1))
    return
  fi
  check "$1" test "$(ls -l "$2" | cut -c1-10)" = '-rw-------'
}

# wrap_tool TOOL FILE — FILE becomes a script that runs TOOL (a path) with its arguments.
# Not a link: Git Bash on Windows copies the tool for ln -s, and the copy does not find
# its libraries.
wrap_tool() {
  wt_quoted=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  printf "#!/bin/sh\nexec '%s' \"\$@\"\n" "$wt_quoted" > "$2"
  chmod +x "$2"
}

# Answers for a demo project. Extra arguments: KEY=value adds a line, -KEY drops the key
# from the base set.
answers() {  # FILE MODULE VISIBILITY [KEY=value | -KEY]…
  a_file=$1
  printf '%s\n' '# test answers' 'PROJECT_NAME=demo-app' \
    'PROJECT_DESCRIPTION=Demo & tools / a\b | c' 'OWNER=octo' 'GROUP_ID=demo-app' \
    'LANG_LIVING_DOCS=German' 'LANG_CLAUDE_MD=German' 'LANG_COMMENTS=English' \
    'LANG_COMMITS=English' 'LANG_README=English' 'LICENSE_SPDX=Apache-2.0' \
    "MODULE=$2" "VISIBILITY=$3" > "$a_file"
  shift 3
  for a_arg in "$@"; do
    case $a_arg in
      -*)
        grep -v "^${a_arg#-}=" "$a_file" > "$a_file.tmp"
        mv "$a_file.tmp" "$a_file"
        ;;
      *) printf '%s\n' "$a_arg" >> "$a_file" ;;
    esac
  done
}

# render NAME MODULE VISIBILITY [--seeds] [KEY=value | -KEY]… — output in $TMP/NAME,
# listing in $TMP/NAME.tsv, stderr in $TMP/NAME.err.
render() {
  r_name=$1 r_module=$2 r_vis=$3
  shift 3
  r_flag=
  if [ "${1:-}" = --seeds ]; then
    r_flag=--seeds
    shift
  fi
  answers "$TMP/$r_name.answers" "$r_module" "$r_vis" "$@"
  # $r_flag is empty or one word, so it stays unquoted.
  $SH "$SCRIPT" render $r_flag "$TEMPLATE" "$TMP/$r_name.answers" "$TMP/$r_name" \
    > "$TMP/$r_name.tsv" 2> "$TMP/$r_name.err"
}

has() { [ -f "$TMP/$1" ]; }
contains() { grep -qF -- "$2" "$TMP/$1"; }
err_mentions() { grep -qF -- "$2" "$TMP/$1.err"; }
# Some file below DIR still ends in .tmpl, a suffix the render strips.
tmpl_left() { find "$TMP/$1" -name '*.tmpl' | grep -q .; }

# No registered-style placeholder token left anywhere below DIR.
no_placeholders() {
  ! grep -rqE '[{][{][A-Z][A-Z0-9_]*[}][}]' "$TMP/$1"
}

# The listing names exactly the files on disk.
listing_matches() {
  cut -f1 "$TMP/$1.tsv" | LC_ALL=C sort > "$TMP/$1.listed"
  (cd "$TMP/$1" && find . -type f | sed 's|^\./||' | LC_ALL=C sort) > "$TMP/$1.found"
  cmp -s "$TMP/$1.listed" "$TMP/$1.found"
}

# Every section/fragment/module marker below DIR is opened as often as it is closed. A
# marker counts only on a line of its own (MANIFEST § Markers), not quoted inside code.
markers_paired() {
  for mp_kind in section fragment module; do
    mp_open=$(grep -rhxE "[[:space:]]*<!-- $mp_kind:[a-z0-9-]+ -->[[:space:]]*" "$TMP/$1" | wc -l)
    mp_close=$(grep -rhxE "[[:space:]]*<!-- /$mp_kind:[a-z0-9-]+ -->[[:space:]]*" "$TMP/$1" | wc -l)
    [ "$mp_open" -eq "$mp_close" ] || return 1
  done
}

no_seed_rows() { ! cut -f2 "$TMP/$1.tsv" | grep -qx seed; }
has_seed_rows() { cut -f2 "$TMP/$1.tsv" | grep -qx seed; }

# The line right after the first line containing MARK (fixed string) in FILE is EXPECTED;
# fails when MARK is missing or ends the file.
line_after() {  # FILE MARK EXPECTED
  la_got=$(awk -v m="$2" '
    hit { print; done = 1; exit }
    index($0, m) { hit = 1 }
    END { exit !done }' "$TMP/$1") || return 1
  [ "$la_got" = "$3" ]
}

# The line right before the first line containing MARK in FILE is EXPECTED; fails when
# MARK is missing or starts the file.
line_before() {  # FILE MARK EXPECTED
  lb_got=$(awk -v m="$2" '
    NR > 1 && index($0, m) { print prev; done = 1; exit }
    { prev = $0 }
    END { exit !done }' "$TMP/$1") || return 1
  [ "$lb_got" = "$3" ]
}

# The fragments of FILE open in this order: NAMES, space-separated (marker lines only).
slot_order() {  # FILE NAMES
  so_got=$(sed -n 's/^<!-- fragment:\([a-z0-9-]*\) -->$/\1/p' "$TMP/$1" | tr '\n' ' ')
  [ "$so_got" = "$2 " ]
}

has_module_rows() { cut -f3 "$TMP/$1.tsv" | grep -qx module; }

# Managed core targets per MANIFEST for a visibility and a host (default github) — parsed
# here independently of the script, so a parsing slip in either shows up.
expected_core() {  # VISIBILITY [HOST]
  awk -F'|' -v vis="$1" -v host="${2:-github}" '
    /^## Core-managed files/ { f = 1; next }
    /^## / { f = 0 }
    f && $2 ~ /`core\// {
      src = $2; gsub(/[ `]/, "", src)
      tgt = $3; gsub(/^ +| +$/, "", tgt); gsub(/`/, "", tgt)
      if (tgt == "same path") tgt = substr(src, 6)
      if ($4 ~ /^ *seed/) next
      if ($4 ~ /public-only/ && vis != "public") next
      if (match($4, /host:[a-z]+(\/[a-z]+)*/) \
        && index("/" substr($4, RSTART + 5, RLENGTH - 5) "/", "/" host "/") == 0) next
      print tgt
    }' "$TEMPLATE/MANIFEST.md"
}

all_core_present() {  # NAME VISIBILITY [EXCEPT]
  for p_t in $(expected_core "$2"); do
    [ "$p_t" = "${3:-}" ] && continue
    [ -f "$TMP/$1/$p_t" ] || return 1
  done
}

# The managed core targets of NAME are exactly those of VISIBILITY on HOST.
core_exactly() {  # NAME VISIBILITY HOST
  expected_core "$2" "$3" | LC_ALL=C sort > "$TMP/$1.core-want"
  awk -F '\t' '$2 == "managed" && $3 == "core" { print $1 }' "$TMP/$1.tsv" \
    | LC_ALL=C sort > "$TMP/$1.core-got"
  cmp -s "$TMP/$1.core-want" "$TMP/$1.core-got"
}

# SOURCE with its host blocks resolved for HOST: the block of HOST loses its marker
# lines, the blocks of other hosts go with their content. Written to $TMP/NAME.
for_host() {  # SOURCE HOST NAME
  awk -v host="$2" '
    /^<!-- template:optional:host-[a-z]+ -->$/ {
      name = $0
      sub(/^<!-- template:optional:host-/, "", name); sub(/ -->$/, "", name)
      in_block = 1
      next
    }
    /^<!-- \/template:optional:host-[a-z]+ -->$/ { in_block = 0; next }
    in_block && name != host { next }
    { print }' "$1" > "$TMP/$3"
}

# The module's [tools] entries follow the last core [tools] entry as one block.
tools_follow() {  # NAME MODULE
  awk '/^\[tools\]/ { f = 1; next } /^\[/ { f = 0 } f && NF { l = $0 } END { print l }' \
    "$TEMPLATE/core/mise.toml" > "$TMP/tools.expected"
  grep -v -e '^\[' -e '^[[:space:]]*$' "$TEMPLATE/modules/$2/mise.part.toml" >> "$TMP/tools.expected"
  awk 'NR == FNR { want[++n] = $0; next }
       { got[++m] = $0 }
       END {
         for (i = 1; i + n - 1 <= m; i++) {
           ok = 1
           for (j = 1; j <= n; j++) if (got[i + j - 1] != want[j]) { ok = 0; break }
           if (ok) exit 0
         }
         exit 1
       }' "$TMP/tools.expected" "$TMP/$1/mise.toml"
}

first_line() { sed -n 1p "$1"; }

same_but_first_line() {  # RENDERED SOURCE
  [ "$(sed 1d "$TMP/$1")" = "$(sed 1d "$2")" ]
}

# --- cases (one file per command group, sourced) --------------------------------

# All group files, also those not selected: groups share helpers (most use the fixture
# helpers of sync.sh; global those of zones.sh, hook those of global.sh, install the
# stand-ins of mise.sh). scripts/script-tests.sh runs these groups along.
HERE=$(cd "$(dirname "$0")" && pwd)
for group in $ALL_GROUPS; do
  . "$HERE/$group.sh"
done

# --- main -----------------------------------------------------------------------

shells=
for s in dash bash; do
  if command -v "$s" > /dev/null 2>&1; then shells="$shells $s"; fi
done
if [ -z "$shells" ]; then
  echo "template-sync tests: neither dash nor bash found" >&2
  exit 1
fi

# The awk implementation behind COMMAND: mawk or gawk by their -W version line, "other"
# for anything else (the macOS awk prints no version there).
awk_kind() {  # COMMAND
  ak_line=$("$1" -W version < /dev/null 2> /dev/null | sed -n 1p)
  case $ak_line in
    mawk*) echo mawk ;;
    'GNU Awk'*) echo gawk ;;
    *) echo other ;;
  esac
}

# Each extra awk, installed but not the default one, gets jobs under the first shell.
default_awk=$(awk_kind awk)
if [ "$default_awk" = other ]; then awks='system awk'; else awks=$default_awk; fi
extras=
not_installed=
for extra in mawk gawk; do
  [ "$extra" != "$default_awk" ] || continue
  if command -v "$extra" > /dev/null 2>&1; then
    extras="$extras $extra"
    awks="$awks, $extra"
  else
    not_installed="$not_installed $extra"
  fi
done
first_shell=${shells# }
first_shell=${first_shell%% *}

# The jobs, one per line in $BASE_TMP/jobs: GROUP SHELL AWK, with - for the default awk.
: > "$BASE_TMP/jobs"
n_jobs=0
for group in $selected; do
  for s in $shells; do
    echo "$group $s -" >> "$BASE_TMP/jobs"
    n_jobs=$((n_jobs + 1))
  done
  for extra in $extras; do
    echo "$group $first_shell $extra" >> "$BASE_TMP/jobs"
    n_jobs=$((n_jobs + 1))
  done
done
lanes=$slots
[ "$lanes" -le "$n_jobs" ] || lanes=$n_jobs

job_label() {  # GROUP SHELL AWK
  if [ "$3" = - ]; then echo "$1/$2"; else echo "$1/$2/$3"; fi
}

if [ "$plan" = yes ]; then
  printf 'jobs: %d, at once: %d\n' "$n_jobs" "$lanes"
  while read -r p_group p_shell p_awk; do
    job_label "$p_group" "$p_shell" "$p_awk"
  done < "$BASE_TMP/jobs"
  exit 0
fi

# An extra awk is found as `awk` through a wrapper at the front of PATH, so the script and
# the test helpers both use it.
for extra in $extras; do
  mkdir -p "$BASE_TMP/bin-$extra"
  wrap_tool "$(command -v "$extra")" "$BASE_TMP/bin-$extra/awk"
done

# Per job NUMBER: claim/NUMBER (taken by one lane), out/NUMBER (its output), result/NUMBER
# ("checks failures skipped", written only when the job got to the end), done/NUMBER;
# pid/LANE is the job a lane runs right now.
mkdir "$BASE_TMP/claim" "$BASE_TMP/out" "$BASE_TMP/result" "$BASE_TMP/done" \
  "$BASE_TMP/pid"

# The cases of GROUP with SHELL (and AWK), files below their own folder. Runs in a
# subshell: the counters, PATH and TMP stay the job's own. Stopped (SIGTERM), it ends after
# the command it runs, so nothing is left running.
run_job() {  # NUMBER GROUP SHELL AWK
  trap 'exit 143' TERM
  SH=$3
  LABEL=$(job_label "$2" "$3" "$4")
  if [ "$4" != - ]; then
    PATH=$BASE_TMP/bin-$4:$PATH
    export PATH
  fi
  TMP=$BASE_TMP/job-$1
  mkdir -p "$TMP"
  "run_$(printf '%s' "$2" | tr - _)_cases"
  printf '%d %d %d\n' "$checks" "$failures" "$skipped" > "$BASE_TMP/result/$1"
}

# A lane takes the next job nobody claimed (mkdir succeeds once), runs it, prints a
# progress line, and goes on until no job is left or the run is stopped.
run_lane() {  # LANE
  rl_lane=$1
  rl_i=0
  while [ "$rl_i" -lt "$n_jobs" ]; do
    rl_i=$((rl_i + 1))
    [ ! -f "$BASE_TMP/stop" ] || return 0
    mkdir "$BASE_TMP/claim/$rl_i" 2> /dev/null || continue
    rl_spec=$(sed -n "${rl_i}p" "$BASE_TMP/jobs")
    # $rl_spec unquoted: three words without spaces or patterns.
    (run_job "$rl_i" $rl_spec) > "$BASE_TMP/out/$rl_i" 2>&1 &
    rl_pid=$!
    echo "$rl_pid" > "$BASE_TMP/pid/$rl_lane"
    # A stop that came after the check above but before the pid file: stop the job here.
    [ ! -f "$BASE_TMP/stop" ] || kill "$rl_pid" 2> /dev/null
    wait "$rl_pid"
    # The job is gone; a stop must not kill its pid, which the system may give away again.
    rm -f "$BASE_TMP/pid/$rl_lane"
    [ ! -f "$BASE_TMP/stop" ] || return 0
    : > "$BASE_TMP/done/$rl_i"
    if [ -f "$BASE_TMP/result/$rl_i" ]; then
      read -r rl_checks rl_failures rl_skipped < "$BASE_TMP/result/$rl_i"
      if [ "$rl_failures" -eq 0 ]; then rl_state=ok; else rl_state="$rl_failures failed"; fi
    else
      rl_state="ended without a result"
    fi
    rl_done=$(ls "$BASE_TMP/done" | wc -l)
    # $rl_spec unquoted again; $rl_done may carry the blanks of wc.
    printf '%s %s — %d of %d\n' "$(job_label $rl_spec)" "$rl_state" $rl_done "$n_jobs"
  done
}

# Ctrl+C or a stop. Background jobs ignore SIGINT in a script, so they are told by hand:
# the stop file keeps the lanes from starting another job, SIGTERM ends each running job
# after its current command. Then the run waits for all of them, and the EXIT trap clears
# the temp folder with nothing left writing to it.
stop_lanes() {
  trap '' INT TERM HUP
  printf 'template-sync tests: stopping after the commands running now\n' >&2
  : > "$BASE_TMP/stop"
  for sl_file in "$BASE_TMP"/pid/*; do
    [ -f "$sl_file" ] && kill "$(cat "$sl_file")" 2> /dev/null
  done
  wait
  exit 130
}

trap stop_lanes INT TERM HUP
lane=0
while [ "$lane" -lt "$lanes" ]; do
  lane=$((lane + 1))
  run_lane "$lane" &
done
wait
trap - INT TERM HUP

# The output of each job in the order of the jobs, then the totals. A job without a
# result line ended early (it crashed or exited) and counts as a failure.
checks=0
failures=0
skipped=0
n=0
while read -r t_group t_shell t_awk; do
  n=$((n + 1))
  cat "$BASE_TMP/out/$n"
  if [ -f "$BASE_TMP/result/$n" ]; then
    read -r t_checks t_failures t_skipped < "$BASE_TMP/result/$n"
    checks=$((checks + t_checks))
    failures=$((failures + t_failures))
    skipped=$((skipped + t_skipped))
  else
    failures=$((failures + 1))
    printf 'FAIL [%s] the job ended without a result\n' \
      "$(job_label "$t_group" "$t_shell" "$t_awk")"
  fi
done < "$BASE_TMP/jobs"

summary="shells:$shells; awk: $awks; $n_jobs jobs, $lanes at once"
if [ "$partial" -gt 0 ]; then summary="groups:$selected; $summary"; fi
if [ -n "$not_installed" ]; then summary="$summary; not installed:$not_installed"; fi
if [ "$skipped" -gt 0 ]; then summary="$summary; $skipped skipped (no file modes)"; fi
printf 'template-sync tests: %d checks, %d failed (%s)\n' "$checks" "$failures" "$summary"
[ "$failures" -eq 0 ]
