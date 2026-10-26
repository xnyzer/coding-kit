#!/bin/sh
# Tests for plugins/coding-kit/scripts/template-sync.sh against the bundled template.
# Every case runs under dash and bash (the shells skills meet on Linux and macOS); the
# script must behave the same in both. Prints failures only, then a summary.
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

# --- harness --------------------------------------------------------------------

fail() {
  failures=$((failures + 1))
  printf 'FAIL [%s] %s\n' "$SH" "$*"
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

for SH in $shells; do
  TMP=$BASE_TMP/$SH
  mkdir -p "$TMP"
  run_render_cases
  run_sync_cases
  run_zones_cases
  run_lock_cases
  run_detect_cases
done

printf 'template-sync tests: %d checks, %d failed (shells:%s)\n' "$checks" "$failures" "$shells"
[ "$failures" -eq 0 ]
