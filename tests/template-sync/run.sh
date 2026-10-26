#!/bin/sh
# Tests for plugins/coding-kit/scripts/template-sync.sh against the bundled template and
# the kit's global rules (plugins/coding-kit/global/), plus the session-start hook that
# reads them.
# Every case runs under dash and bash (the shells skills meet on Linux and macOS); the
# script must behave the same in both. Then one more pass under the first shell for each
# of mawk and gawk that is installed but not the default awk: awk implementations differ
# (mawk is the default on Debian and Ubuntu, gawk on Fedora and Arch, and the macOS awk
# accepts more than either). Prints failures only, then a summary that names the shells
# and awks tested.
#
#   sh tests/template-sync/run.sh

set -u

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SCRIPT=$ROOT/plugins/coding-kit/scripts/template-sync.sh
TEMPLATE=$ROOT/plugins/coding-kit/template
BASE_TMP=$(mktemp -d "${TMPDIR:-/tmp}/template-sync-test.XXXXXX")
trap 'rm -rf "$BASE_TMP"' EXIT

checks=0
failures=0
SH=
TMP=
# Pass name in failure lines: the shell, plus the awk when it is not the default one.
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

# Every section/fragment/module marker below DIR is opened as often as it is closed.
markers_paired() {
  for mp_kind in section fragment module; do
    mp_open=$(grep -rhoE "<!-- $mp_kind:[a-z0-9-]+ -->" "$TMP/$1" | wc -l)
    mp_close=$(grep -rhoE "<!-- /$mp_kind:[a-z0-9-]+ -->" "$TMP/$1" | wc -l)
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

# Managed core targets per MANIFEST for a visibility — parsed here independently of the
# script, so a parsing slip in either shows up.
expected_core() {  # VISIBILITY
  awk -F'|' -v vis="$1" '
    /^## Core-managed files/ { f = 1; next }
    /^## / { f = 0 }
    f && $2 ~ /`core\// {
      src = $2; gsub(/[ `]/, "", src)
      tgt = $3; gsub(/^ +| +$/, "", tgt); gsub(/`/, "", tgt)
      if (tgt == "same path") tgt = substr(src, 6)
      if ($4 ~ /^ *seed/) next
      if ($4 ~ /public-only/ && vis != "public") next
      print tgt
    }' "$TEMPLATE/MANIFEST.md"
}

all_core_present() {  # NAME VISIBILITY [EXCEPT]
  for p_t in $(expected_core "$2"); do
    [ "$p_t" = "${3:-}" ] && continue
    [ -f "$TMP/$1/$p_t" ] || return 1
  done
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

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/render.sh"
. "$HERE/sync.sh"
. "$HERE/zones.sh"
. "$HERE/global.sh"
. "$HERE/hook.sh"
. "$HERE/lock.sh"
. "$HERE/detect.sh"

# --- main -----------------------------------------------------------------------

shells=
for s in dash bash; do
  if command -v "$s" > /dev/null 2>&1; then shells="$shells $s"; fi
done
if [ -z "$shells" ]; then
  echo "template-sync tests: neither dash nor bash found" >&2
  exit 1
fi

# All cases with $SH, their files below DIR.
run_cases() {  # DIR
  TMP=$1
  mkdir -p "$TMP"
  run_render_cases
  run_sync_cases
  run_zones_cases
  run_global_cases
  run_hook_cases
  run_lock_cases
  run_detect_cases
}

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

for SH in $shells; do
  LABEL=$SH
  run_cases "$BASE_TMP/$SH"
done

# One more pass under the first shell for each extra awk, found as `awk` through a link
# at the front of PATH, so the script and the test helpers both use it.
default_awk=$(awk_kind awk)
if [ "$default_awk" = other ]; then awks='system awk'; else awks=$default_awk; fi
not_installed=
first_shell=${shells# }
first_shell=${first_shell%% *}
for extra in mawk gawk; do
  [ "$extra" != "$default_awk" ] || continue
  if ! command -v "$extra" > /dev/null 2>&1; then
    not_installed="$not_installed $extra"
    continue
  fi
  mkdir -p "$BASE_TMP/bin-$extra"
  ln -s "$(command -v "$extra")" "$BASE_TMP/bin-$extra/awk"
  saved_path=$PATH
  PATH=$BASE_TMP/bin-$extra:$PATH
  export PATH
  SH=$first_shell
  LABEL=$first_shell/$extra
  run_cases "$BASE_TMP/$extra"
  PATH=$saved_path
  export PATH
  awks="$awks, $extra"
done

summary="shells:$shells; awk: $awks"
if [ -n "$not_installed" ]; then summary="$summary; not installed:$not_installed"; fi
printf 'template-sync tests: %d checks, %d failed (%s)\n' "$checks" "$failures" "$summary"
[ "$failures" -eq 0 ]
