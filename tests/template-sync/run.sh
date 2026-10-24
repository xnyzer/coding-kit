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

# --- cases ----------------------------------------------------------------------

run_cases() {
  M=$TEMPLATE/modules

  # docs-only, private, managed targets only
  check "docs-only renders" render docs docs-only private
  check "docs-only: listing matches the files" listing_matches docs
  check "docs-only: no placeholder left" no_placeholders docs
  check "docs-only: every managed core target" all_core_present docs private
  check "docs-only: managed only, no seed row" no_seed_rows docs
  refute "docs-only: no seed file" has docs/CLAUDE.md
  refute "private: no public-only file" has docs/CODE_OF_CONDUCT.md
  refute "docs-only: no CodeQL workflow" has docs/.github/workflows/codeql.yml
  check "docs-only: core justfile" same_but_first_line docs/justfile "$TEMPLATE/core/justfile"
  check "docs-only: slot keeps its placeholder text" same_but_first_line docs/CODING-STANDARDS.md "$TEMPLATE/core/CODING-STANDARDS.md"

  # docs-only, public: public-only files, still no CodeQL (no language)
  check "docs-only public renders" render docs-pub docs-only public
  check "public: public-only file" has docs-pub/CODE_OF_CONDUCT.md
  check "docs-only public: every core target but CodeQL" all_core_present docs-pub public .github/workflows/codeql.yml
  refute "docs-only public: no CodeQL workflow" has docs-pub/.github/workflows/codeql.yml

  # ts-node, public
  check "ts-node renders" render ts ts-node public
  check "ts-node: listing matches the files" listing_matches ts
  check "ts-node: no placeholder left" no_placeholders ts
  check "ts-node: markers paired" markers_paired ts
  check "ts-node: every managed core target" all_core_present ts public
  check "ts-node: CodeQL language" contains ts/.github/workflows/codeql.yml "'javascript-typescript'"
  for t_f in biome.json tsconfig.json tsconfig.build.json vitest.config.ts; do
    check "ts-node: managed module file $t_f" has "ts/$t_f"
  done
  refute "ts-node: seed module file left out" has ts/package.json
  check "ts-node: module justfile replaces the core one" same_but_first_line ts/justfile "$M/ts-node/justfile"
  check "ts-node: project name in the justfile head" contains ts/justfile demo-app
  check "ts-node: tools follow the core tools" tools_follow ts ts-node
  check "ts-node: gitignore part below its marker" line_after ts/.gitignore "# module:gitignore" "$(first_line "$M/ts-node/gitignore.part")"
  check "ts-node: language fragment opens the slot" line_after ts/CODING-STANDARDS.md "<!-- module:coding-standards -->" "<!-- fragment:ts-node -->"
  check "ts-node: language fragment closes the slot" line_before ts/CODING-STANDARDS.md "<!-- /module:coding-standards -->" "<!-- /fragment:ts-node -->"

  # go, public: CI part
  check "go renders" render go go public
  check "go: no placeholder left" no_placeholders go
  check "go: CI part below its marker" line_after go/.github/workflows/ci.yml "# module:ci-jobs" "$(first_line "$M/go/ci.part.yml")"
  check "go: CodeQL language" contains go/.github/workflows/codeql.yml "'go'"
  check "go: managed module file" has go/.golangci.yml
  refute "go: seed module file left out" has go/go.mod
  check "go: tools follow the core tools" tools_follow go go

  # python with seeds, graphiti kept, a characteristic fragment
  check "python with seeds renders" render py python private --seeds OPTIONAL=graphiti FRAGMENTS=audit-logging
  check "python: listing matches the files" listing_matches py
  check "python: no placeholder left" no_placeholders py
  check "python: markers paired" markers_paired py
  check "python: seed rows listed" has_seed_rows py
  check "python: package dir renamed" has py/src/demo_app/__init__.py
  check "python: empty marker file kept" has py/src/demo_app/py.typed
  refute "python: marker file stays empty" test -s "$TMP/py/src/demo_app/py.typed"
  check "python: seed file" has py/pyproject.toml
  check "python: graphiti zone kept" contains py/CLAUDE.md "<!-- section:claude-graphiti -->"
  refute "python: optional markers removed" grep -rq "template:optional" "$TMP/py"
  check "python: description taken literally" contains py/README.md 'Demo & tools / a\b | c'
  check "python: blank line between fragments" line_after py/CODING-STANDARDS.md "<!-- /fragment:python -->" ""
  check "python: characteristic fragment follows" line_before py/CODING-STANDARDS.md "<!-- fragment:audit-logging -->" ""
  check "python: characteristic fragment closes the slot" line_before py/CODING-STANDARDS.md "<!-- /module:coding-standards -->" "<!-- /fragment:audit-logging -->"

  # determinism
  check "same answers render again" render py2 python private --seeds OPTIONAL=graphiti FRAGMENTS=audit-logging
  check "rendering is deterministic (files)" diff -r "$TMP/py" "$TMP/py2"
  check "rendering is deterministic (listing)" cmp -s "$TMP/py.tsv" "$TMP/py2.tsv"

  # graphiti dropped: its zone goes, GROUP_ID is no longer needed
  check "without graphiti renders (no GROUP_ID)" render nog docs-only private --seeds -GROUP_ID
  refute "without graphiti: zone dropped" contains nog/CLAUDE.md "section:claude-graphiti"
  check "without graphiti: no placeholder left" no_placeholders nog

  # license blocks follow LICENSE_SPDX
  check "license chosen: license sentence" contains docs/CONTRIBUTING.md 'licensed under **Apache-2.0** (see `LICENSE`)'
  refute "license chosen: no TBD sentence" contains docs/CONTRIBUTING.md "No license has been chosen"
  check "TBD license renders" render tbd docs-only private -LICENSE_SPDX LICENSE_SPDX=TBD
  check "TBD license: TBD sentence" contains tbd/CONTRIBUTING.md "No license has been chosen yet (TBD)"
  refute "TBD license: no pointer to a LICENSE file" contains tbd/CONTRIBUTING.md '(see `LICENSE`)'
  refute "license blocks in OPTIONAL refused" render e9 docs-only private OPTIONAL=license

  # a stub module renders on docs-only level
  check "stub module renders" render java java private
  refute "stub module: no module files" has_module_rows java

  # warnings and refusals
  check "unknown key renders" render typo docs-only private LANG_COMENTS=x
  check "unknown key: warning" err_mentions typo LANG_COMENTS
  refute "missing MODULE refused" render e1 docs-only private -MODULE
  check "missing MODULE: message" err_mentions e1 MODULE
  refute "unknown module refused" render e2 nope private
  refute "invalid visibility refused" render e3 docs-only internal
  refute "duplicate key refused" render e4 docs-only private OWNER=other
  refute "braces in a value refused" render e5 docs-only private -PROJECT_DESCRIPTION "PROJECT_DESCRIPTION=bad {{ x"
  refute "missing value refused" render e6 docs-only private -OWNER
  check "missing value: names the placeholder" err_mentions e6 OWNER
  refute "unknown fragment refused" render e7 docs-only private FRAGMENTS=nope
  refute "invalid optional name refused" render e8 docs-only private OPTIONAL=Bad_Name
  mkdir -p "$TMP/full" && : > "$TMP/full/x"
  answers "$TMP/full.answers" docs-only private
  refute "non-empty output dir refused" $SH "$SCRIPT" render "$TEMPLATE" "$TMP/full.answers" "$TMP/full"
  $SH "$SCRIPT" > /dev/null 2>&1
  check "no command: usage exit 2" test $? -eq 2
  $SH "$SCRIPT" render "$TEMPLATE" "$TMP/full.answers" > /dev/null 2>&1
  check "missing argument: usage exit 2" test $? -eq 2
}

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
  run_cases
done

printf 'template-sync tests: %d checks, %d failed (shells:%s)\n' "$checks" "$failures" "$shells"
[ "$failures" -eq 0 ]
