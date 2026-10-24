# Sync cases (status, changed, merge, snapshot, base-from-history) for
# tests/template-sync/run.sh — sourced, uses its helpers. Fixtures are small synthetic
# files: base = .claude/template-base/<target>.base, ours = the project, theirs = SOLL.

# put PATH FORMAT — printf FORMAT into $TMP/PATH, creating directories.
put() {
  mkdir -p "$(dirname "$TMP/$1")"
  # The format is the fixture itself: escapes like \n and \r are intended.
  printf "$2" > "$TMP/$1"
}

# fixture PROJECT TARGET BASE OURS THEIRS — "-" leaves that side out.
fixture() {
  if [ "$3" != - ]; then put "$1/.claude/template-base/$2.base" "$3"; fi
  if [ "$4" != - ]; then put "$1/$2" "$4"; fi
  if [ "$5" != - ]; then put "$1.soll/$2" "$5"; fi
}

registry() {  # PROJECT ROWS… — writes a Files table, one "| path | kind | reason | since |" per row
  mkdir -p "$TMP/$1/.claude"
  {
    printf '# Convention Overrides\n\n## Files\n\n| Path | Kind | Reason | Since |\n'
    printf '|------|------|--------|-------|\n'
    for r_row in "$@"; do printf '%s\n' "$r_row"; done
    printf '\n## Rules\n\n| Rule | Deviation | Reason | Since |\n|---|---|---|---|\n'
  } > "$TMP/$1/.claude/convention-overrides.md"
}

# Field check on a result line: TSV NAME, TARGET, then the expected fields 2… (empty =
# any value).
row_is() {  # NAME TARGET F2 [F3 [F4]]
  awk -F'\t' -v t="$2" -v a="$3" -v b="${4:-}" -v c="${5:-}" '
    $1 == t { found = 1; ok = ($2 == a) && (b == "" || $3 == b) && (c == "" || $4 == c) }
    END { exit !(found && ok) }' "$TMP/$1.tsv"
}

no_row() {  # NAME TARGET
  ! cut -f1 "$TMP/$1.tsv" | grep -qxF -- "$2"
}

# $TMP/PATH holds exactly what printf FORMAT produces.
file_is() {  # PATH FORMAT
  printf "$2" > "$TMP/expected"
  cmp -s "$TMP/$1" "$TMP/expected"
}

ts() {  # COMMAND ARGS… — the script under test with the current shell
  $SH "$SCRIPT" "$@"
}

# git without the user's hooks, signing or identity
tgit() {  # DIR ARGS…
  t_dir=$1
  shift
  git -C "$t_dir" -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false \
    -c core.hooksPath=/dev/null "$@"
}

run_sync_cases() {
  S='<!-- module:coding-standards -->'
  E='<!-- /module:coding-standards -->'

  # --- merge: one target per edge case --------------------------------------------
  fixture mp eol.txt 'a\nb\nc\n' 'a\nb\nc\nP\n' 'A\nb\nc'
  fixture mp crlf.txt 'a\nb\nc\n' 'a\r\nb\r\nc\r\nP\r\n' 'A\nb\nc\n'
  fixture mp append.txt 'a\nb\n' 'a\nb\nP\n' 'a\nb\nT\n'
  fixture mp same.txt 'a\nb\n' 'a\nX\n' 'a\nX\n'
  fixture mp ident.txt 'a\n' 'a\n' 'a\n'
  fixture mp tonly.txt 'a\nb\n' 'a\nb\n' 'a\nB\n'
  fixture mp ponly.txt 'a\nb\n' 'a\nB\n' 'a\nb\n'
  fixture mp nobase.txt - 'x\n' 'y\n'
  fixture mp nobase-same.txt - 'x\n' 'x\n'
  fixture mp emptybase.txt '' 'a\nP\n' 'a\nT\n'
  fixture mp newfile.txt - - 'n\n'
  fixture mp gone.txt 'g\n' 'g\n' -
  fixture mp deleted.txt 'd\n' - 'd\n'
  fixture mp kept.txt 'a\nb\n' 'a\nP\n' 'a\nT\n'
  fixture mp .github/workflows/ci.yml 'c\n' 'C\n' 'c2\n'
  fixture mp STD.md "head\n$S\nOLD\n$E\ntail\n" "head\n$S\nFRAG-A\n\nFRAG-B\n$E\ntail\nproj\n" \
    "HEAD\n$S\nNEW\n$E\ntail\n"
  registry mp '| `kept.txt` | keep | project wins | 2026-10-24 |' \
    '| `.github/**`, `none.txt` | skip | no CI | 2026-10-24 |' \
    '| `same.txt` | | now in the template | 2026-10-24 |'
  check "merge runs" eval 'ts merge "$TMP/mp" "$TMP/mp.soll" "$TMP/mo" > "$TMP/m.tsv" 2> "$TMP/m.err"'
  check "missing final newline merges cleanly" row_is m eol.txt merged 0
  check "missing final newline: result" file_is mo/eol.txt 'A\nb\nc\nP\n'
  check "CRLF project merges cleanly" row_is m crlf.txt merged 0
  check "CRLF project: result has LF ends" file_is mo/crlf.txt 'A\nb\nc\nP\n'
  check "both append at the end: conflict" row_is m append.txt conflict 1
  check "conflict result carries diff3 markers" grep -q '^<<<<<<< project' "$TMP/mo/append.txt"
  check "same change on both sides: caught-up" row_is m same.txt caught-up 0 registered
  check "no change: identical" row_is m ident.txt identical
  check "template-only change" row_is m tonly.txt template-only
  check "template-only: result is the template" file_is mo/tonly.txt 'a\nB\n'
  check "project-only change" row_is m ponly.txt project-only 0 none
  check "project-only: result is the project" file_is mo/ponly.txt 'a\nB\n'
  check "no base, different: two-way" row_is m nobase.txt two-way
  check "two-way: result is the template" file_is mo/nobase.txt 'y\n'
  check "no base, equal: identical" row_is m nobase-same.txt identical
  check "empty base: both added → conflict" row_is m emptybase.txt conflict
  check "project lacks a new target: new" row_is m newfile.txt new
  check "new: result is the template" file_is mo/newfile.txt 'n\n'
  check "no longer rendered: removed" row_is m gone.txt removed
  refute "removed: no result" test -e "$TMP/mo/gone.txt"
  check "project deleted it: missing" row_is m deleted.txt missing
  check "keep row: conflict resolved to the project" row_is m kept.txt kept 1 keep
  check "keep row: project side wins" file_is mo/kept.txt 'a\nP\n'
  check "glob skip row covers nested paths" row_is m .github/workflows/ci.yml skipped 0 skip
  refute "skipped: no result" test -e "$TMP/mo/.github/workflows/ci.yml"
  check "slot: merged outside the slot" row_is m STD.md merged 0
  check "slot: project fragments kept, template text merged" \
    file_is mo/STD.md "HEAD\n$S\nFRAG-A\n\nFRAG-B\n$E\ntail\nproj\n"
  refute "merge into a non-empty dir refused" ts merge "$TMP/mp" "$TMP/mp.soll" "$TMP/mo"

  # --- status --------------------------------------------------------------------
  fixture sp same.txt 'a\nb\n' 'a\nb\n' -
  fixture sp crlf.txt 'a\nb\n' 'a\r\nb' -
  fixture sp dev.txt 'a\n' 'a\nb\n' -
  fixture sp gone.txt 'g\n' - -
  fixture sp STD.md "x\n$S\nOLD\n$E\n" "x\n$S\nNEW-FRAGMENT\n$E\n" -
  registry sp '| `dev.txt` | | reason | 2026-10-24 |'
  check "status runs" eval 'ts status "$TMP/sp" > "$TMP/s.tsv"'
  check "status: unchanged" row_is s same.txt unchanged none
  check "status: line ends and final newline ignored" row_is s crlf.txt unchanged
  check "status: deviation with diffstat" row_is s dev.txt deviates registered "+1 -0"
  check "status: missing" row_is s gone.txt missing
  check "status: slot content ignored" row_is s STD.md unchanged
  mkdir -p "$TMP/nosnap"
  ts status "$TMP/nosnap" > /dev/null 2>&1
  check "status without snapshot: exit 3" test $? -eq 3
  registry sp '| `x` | sometimes | reason | 2026-10-24 |'
  refute "unknown kind in the registry refused" ts status "$TMP/sp"

  # --- changed -------------------------------------------------------------------
  fixture cp dev.txt 'a\n' 'a\n' -
  fixture cp calm.txt 'c\n' 'c\n' -
  fixture cp fresh.txt 'f\n' - -
  put cp/other.txt 'o\n'
  tgit "$TMP/cp" init -q
  tgit "$TMP/cp" add -A
  tgit "$TMP/cp" commit -q -m base
  put cp/dev.txt 'a\nb\n'
  put cp/other.txt 'o2\n'
  put cp/fresh.txt 'F\n'
  put cp/.claude/template-base/calm.txt.base 'hand-edited\n'
  check "changed runs" eval 'ts changed "$TMP/cp" > "$TMP/c.tsv"'
  check "changed: touched managed file deviates" row_is c dev.txt deviates none
  check "changed: untracked managed file listed" row_is c fresh.txt deviates
  check "changed: hand edit of the snapshot" row_is c .claude/template-base/calm.txt.base snapshot-edited
  check "changed: file without base not listed" no_row c other.txt
  check "changed: untouched managed file not listed" no_row c calm.txt

  # --- snapshot ------------------------------------------------------------------
  fixture np keep.txt 'old\n' 'x\n' 'new\n'
  fixture np drop.txt 'old\n' 'x\n' -
  check "snapshot runs" eval 'ts snapshot "$TMP/np" "$TMP/np.soll" keep.txt drop.txt > "$TMP/n.tsv"'
  check "snapshot: base set to the rendered version" file_is np/.claude/template-base/keep.txt.base 'new\n'
  check "snapshot: target without rendered version loses its base" \
    test ! -e "$TMP/np/.claude/template-base/drop.txt.base"
  check "snapshot: listing" row_is n drop.txt removed
  refute "snapshot: path outside the project refused" ts snapshot "$TMP/np" "$TMP/np.soll" ../x

  # --- base-from-history (needs the full history of this checkout) ---------------
  if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2> /dev/null)" = false ]; then
    for b_v in 0.11.2 0.13.2 1.0.0; do
      check "base-from-history $b_v" eval 'ts base-from-history "$ROOT" "$b_v" "$TMP/h-$b_v" > /dev/null'
      check "base-from-history $b_v: MANIFEST exported" test -f "$TMP/h-$b_v/template/MANIFEST.md"
    done
    check "base-from-history 0.13.2: version file" file_is h-0.13.2/template/VERSION '0.13.2\n'
    check "base-from-history 1.0.0: plugin.json" grep -q '"version": "1.0.0"' "$TMP/h-1.0.0/.claude-plugin/plugin.json"
    refute "base-from-history: unknown version refused" ts base-from-history "$ROOT" 0.0.1 "$TMP/h-x"
  fi
  refute "base-from-history: invalid version refused" ts base-from-history "$ROOT" 1.x "$TMP/h-y"
  refute "base-from-history: not a git checkout refused" ts base-from-history "$TMP/nosnap" 1.0.0 "$TMP/h-z"
}
