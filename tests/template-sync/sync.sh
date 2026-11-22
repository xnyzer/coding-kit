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

# The TSV NAME has exactly this line, its fields given one by one — for a path that has
# several lines.
line_in() {  # NAME FIELD…
  li_file=$TMP/$1.tsv
  li_line=$2
  shift 2
  for li_f in "$@"; do li_line=$li_line$(printf '\t')$li_f; done
  grep -qxF -- "$li_line" "$li_file"
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

  # --- merge: files git ignores (ignored, unignored) -------------------------------
  # ig-p is a git repository that ignores all of private/, *.pem and skipme.txt; the
  # template versions private/README.md and drops *.pem and skipme.txt.
  put ig-p/.gitignore 'private/\n*.pem\nbuild/\nskipme.txt\n'
  put ig-p.soll/.gitignore 'private/*\n!private/README.md\nbuild/\n'
  fixture ig-p private/README.md - 'my notes\n' 'template readme\n'
  fixture ig-p private/same.txt - 's\n' 's\n'
  fixture ig-p build/tracked.txt - 'p\n' 't\n'
  fixture ig-p skipme.txt - 'mine\n' 'theirs\n'
  put ig-p/private/notes.md 'n\n'
  put ig-p/keys/server.pem 'k\n'
  put 'ig-p/my keys/schlüssel.pem' 'k\n'
  put ig-p/sub/.gitignore 'local.cfg\n'
  put ig-p/sub/local.cfg 'c\n'
  put ig-p/build/out.o 'o\n'
  put ig-p/notes.local 'x\n'
  registry ig-p '| `skipme.txt` | skip | the project keeps its own | 2026-11-22 |'
  tgit "$TMP/ig-p" init -q
  mkdir -p "$TMP/ig-p/.git/info"
  printf 'notes.local\n' >> "$TMP/ig-p/.git/info/exclude"
  printf 'cache.tmp\n' > "$TMP/ig-excludes"
  tgit "$TMP/ig-p" config core.excludesFile "$TMP/ig-excludes"
  put ig-p/cache.tmp 'c\n'
  tgit "$TMP/ig-p" add -A
  tgit "$TMP/ig-p" add -f build/tracked.txt
  tgit "$TMP/ig-p" commit -q -m base
  check "merge in a git project runs" eval 'ts merge "$TMP/ig-p" "$TMP/ig-p.soll" "$TMP/ig-go" > "$TMP/ig-g.tsv"'
  check "ignored copy that differs: ignored" line_in ig-g private/README.md ignored 0 none
  refute "ignored: no result" test -e "$TMP/ig-go/private/README.md"
  check "ignored copy equal to the template: identical" line_in ig-g private/same.txt identical 0 none
  check "tracked copy under an ignore rule: two-way" line_in ig-g build/tracked.txt two-way 0 none
  check "skip row wins over ignored" line_in ig-g skipme.txt skipped 0 skip
  check "file the merged .gitignore exposes: unignored" line_in ig-g keys/server.pem unignored 0 none
  check "unignored: name with a space and an umlaut" line_in ig-g 'my keys/schlüssel.pem' unignored 0 none
  check "unignored: an ignored target too" line_in ig-g private/README.md unignored 0 none
  check "unignored: registry kind of the path" line_in ig-g skipme.txt unignored 0 skip
  check "still ignored by the result: not listed" no_row ig-g build/out.o
  check "still ignored by private/*: not listed" no_row ig-g private/notes.md
  check "ignored by a nested .gitignore: not listed" no_row ig-g sub/local.cfg
  check "ignored by .git/info/exclude: not listed" no_row ig-g notes.local
  check "ignored by core.excludesFile: not listed" no_row ig-g cache.tmp

  # A project without a .gitignore: .git/info/exclude ignores today, and a negation in
  # the new root .gitignore overrides it.
  put ig-e.soll/.gitignore '*.log\n!secret.txt\n'
  put ig-e/secret.txt 's\n'
  put ig-e/other.txt 'o\n'
  tgit "$TMP/ig-e" init -q
  mkdir -p "$TMP/ig-e/.git/info"
  printf 'secret.txt\nother.txt\n' >> "$TMP/ig-e/.git/info/exclude"
  check "merge without a project .gitignore runs" eval 'ts merge "$TMP/ig-e" "$TMP/ig-e.soll" "$TMP/ig-eo" > "$TMP/ig-e.tsv"'
  check "no project .gitignore: new" line_in ig-e .gitignore new 0 none
  check "a negation in the new .gitignore exposes an excluded file" line_in ig-e secret.txt unignored 0 none
  check "still excluded by .git/info/exclude: not listed" no_row ig-e other.txt

  # The project deleted its .gitignore: restoring brings the template's version back.
  fixture ig-m .gitignore '*.log\n' - '*.log\n!secret.txt\n'
  put ig-m/secret.txt 's\n'
  tgit "$TMP/ig-m" init -q
  mkdir -p "$TMP/ig-m/.git/info"
  printf 'secret.txt\n' >> "$TMP/ig-m/.git/info/exclude"
  check "merge with a deleted .gitignore runs" eval 'ts merge "$TMP/ig-m" "$TMP/ig-m.soll" "$TMP/ig-mo" > "$TMP/ig-m.tsv"'
  check "deleted .gitignore: missing" line_in ig-m .gitignore missing 0 none
  check "deleted .gitignore: the restored version would expose a file" line_in ig-m secret.txt unignored 0 none

  # The same layout outside git: no ignore rules apply.
  put ig-n/.gitignore 'private/\n'
  put ig-n.soll/.gitignore 'private/*\n!private/README.md\n'
  fixture ig-n private/README.md - 'my notes\n' 'template readme\n'
  check "merge outside git runs" eval 'ts merge "$TMP/ig-n" "$TMP/ig-n.soll" "$TMP/ig-no" > "$TMP/ig-n.tsv"'
  check "outside git: never ignored" line_in ig-n private/README.md two-way 0 none
  refute "outside git: no unignored lines" grep -q unignored "$TMP/ig-n.tsv"

  # The merged .gitignore equals the project's: nothing changes for ignored files.
  put ig-u/.gitignore '*.pem\n'
  put ig-u.soll/.gitignore '*.pem\n'
  put ig-u/k.pem 'k\n'
  tgit "$TMP/ig-u" init -q
  tgit "$TMP/ig-u" add -A
  tgit "$TMP/ig-u" commit -q -m base
  check "merge with an unchanged .gitignore runs" eval 'ts merge "$TMP/ig-u" "$TMP/ig-u.soll" "$TMP/ig-uo" > "$TMP/ig-u.tsv"'
  refute "unchanged .gitignore: no unignored lines" grep -q unignored "$TMP/ig-u.tsv"

  # An unresolved conflict in .gitignore counts with the template side winning.
  fixture ig-c .gitignore 'build/\n' 'build/\n*.pem\n' 'build/\n*.log\n'
  put ig-c/k.pem 'k\n'
  tgit "$TMP/ig-c" init -q
  tgit "$TMP/ig-c" add -A
  tgit "$TMP/ig-c" commit -q -m base
  check "merge with a .gitignore conflict runs" eval 'ts merge "$TMP/ig-c" "$TMP/ig-c.soll" "$TMP/ig-co" > "$TMP/ig-c.tsv"'
  check ".gitignore conflict" line_in ig-c .gitignore conflict 1 none
  check "conflict: the template side would expose the key" line_in ig-c k.pem unignored 0 none

  # A project below the top level of its work tree: ignored works, unignored warns.
  put ig-sr/proj/.gitignore 'private/\n'
  put ig-sr/proj.soll/.gitignore 'private/*\n!private/README.md\n'
  fixture ig-sr/proj private/README.md - 'my notes\n' 'template readme\n'
  tgit "$TMP/ig-sr" init -q
  tgit "$TMP/ig-sr" add -A
  tgit "$TMP/ig-sr" commit -q -m base
  check "merge below the top level runs" \
    eval 'ts merge "$TMP/ig-sr/proj" "$TMP/ig-sr/proj.soll" "$TMP/ig-so" > "$TMP/ig-s.tsv" 2> "$TMP/ig-s.err"'
  check "below the top level: ignored" line_in ig-s private/README.md ignored 0 none
  refute "below the top level: no unignored lines" grep -q unignored "$TMP/ig-s.tsv"
  check "below the top level: warning" grep -q 'below the top level' "$TMP/ig-s.err"

  # A .git that git cannot read stops the merge instead of skipping the checks.
  put ig-b/.git 'gitdir: nowhere\n'
  fixture ig-b a.txt - 'a\n' 'b\n'
  refute "unreadable .git: merge refused" ts merge "$TMP/ig-b" "$TMP/ig-b.soll" "$TMP/ig-bo"

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

  # --- --base: a rendered base instead of the snapshot ----------------------------
  put bp.base/a.txt 'a\nb\n'
  put bp.soll/a.txt 'A\nb\n'
  put bp/a.txt 'a\nb\nP\n'
  check "status --base without snapshot" eval 'ts status --base "$TMP/bp.base" "$TMP/bp" > "$TMP/b.tsv"'
  check "status --base: deviation" row_is b a.txt deviates none "+1 -0"
  check "merge --base" eval 'ts merge --base "$TMP/bp.base" "$TMP/bp" "$TMP/bp.soll" "$TMP/bo" > "$TMP/bm.tsv"'
  check "merge --base: merged" row_is bm a.txt merged 0
  check "merge --base: result" file_is bo/a.txt 'A\nb\nP\n'
  refute "merge --base: snapshot left alone" test -e "$TMP/bp/.claude/template-base"
  refute "--base needs a directory" ts status --base "$TMP/nope" "$TMP/bp"

  # --- snapshot ------------------------------------------------------------------
  fixture np keep.txt 'old\n' 'x\n' 'new\n'
  fixture np drop.txt 'old\n' 'x\n' -
  check "snapshot runs" eval 'ts snapshot "$TMP/np" "$TMP/np.soll" keep.txt drop.txt > "$TMP/n.tsv"'
  check "snapshot: base set to the rendered version" file_is np/.claude/template-base/keep.txt.base 'new\n'
  check "snapshot: target without rendered version loses its base" \
    test ! -e "$TMP/np/.claude/template-base/drop.txt.base"
  check "snapshot: listing" row_is n drop.txt removed
  refute "snapshot: path outside the project refused" ts snapshot "$TMP/np" "$TMP/np.soll" ../x
  fixture nz keep.txt 'old\n' 'x\n' 'new\n'
  refute "snapshot: targets in one argument refused" ts snapshot "$TMP/nz" "$TMP/nz.soll" "keep.txt drop.txt"
  refute "snapshot: target neither rendered nor with a base refused" \
    ts snapshot "$TMP/nz" "$TMP/nz.soll" keep.txt nope.txt
  check "snapshot: nothing written when one target is refused" \
    file_is nz/.claude/template-base/keep.txt.base 'old\n'

  # --- stand-ins: --registry and --snapshot instead of the files below .claude/ ---
  put op/a.txt 'a\nb\nc\nP\n'
  put op/k.txt 'a\nP\n'
  put op.snap/a.txt.base 'a\nb\nc\n'
  put op.snap/k.txt.base 'a\nb\n'
  put op.soll/a.txt 'A\nb\nc\n'
  put op.soll/k.txt 'a\nT\n'
  put op.reg '## Files\n\n| Path | Kind | Reason | Since |\n|---|---|---|---|\n| `k.txt` | keep | project wins | 2026-10-25 |\n'
  check "status with stand-ins runs" \
    eval 'ts status --registry "$TMP/op.reg" --snapshot "$TMP/op.snap" "$TMP/op" > "$TMP/os.tsv"'
  check "status: bases from the stand-in snapshot" row_is os a.txt deviates none "+1 -0"
  check "status: kind from the stand-in registry" row_is os k.txt deviates keep
  ts status "$TMP/op" > /dev/null 2>&1
  check "status without stand-in: no snapshot, exit 3" test $? -eq 3
  check "merge with stand-ins runs" \
    eval 'ts merge --registry "$TMP/op.reg" --snapshot "$TMP/op.snap" "$TMP/op" "$TMP/op.soll" "$TMP/oo" > "$TMP/om.tsv"'
  check "merge: stand-in base" row_is om a.txt merged 0
  check "merge: keep row of the stand-in registry" row_is om k.txt kept 1 keep
  check "snapshot into a stand-in folder" \
    eval 'ts snapshot --snapshot "$TMP/op.snap2" "$TMP/op" "$TMP/op.soll" a.txt > /dev/null'
  check "snapshot: base written to the stand-in" file_is op.snap2/a.txt.base 'A\nb\nc\n'
  refute "snapshot: project left alone" test -e "$TMP/op/.claude"
  tgit "$TMP/op" init -q
  tgit "$TMP/op" add -A
  tgit "$TMP/op" commit -q -m base
  put op/a.txt 'a\nb\nc\nQ\n'
  check "changed with stand-ins runs" \
    eval 'ts changed --registry "$TMP/op.reg" --snapshot "$TMP/op.snap" "$TMP/op" > "$TMP/oc.tsv"'
  check "changed: touched file against the stand-in base" row_is oc a.txt deviates none
  refute "an option the command does not take is refused" \
    ts render --registry "$TMP/op.reg" "$TEMPLATE" "$TMP/op.reg" "$TMP/ox"
  refute "snapshot takes no --base" ts snapshot --base "$TMP/op.snap" "$TMP/op" "$TMP/op.soll" a.txt
  refute "unknown option refused" ts status --nope "$TMP/op"
  refute "--registry needs an existing file" ts status --registry "$TMP/none.md" "$TMP/op"

  # --- base-from-history (needs the full history of this checkout) ---------------
  if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2> /dev/null)" = false ]; then
    for b_v in 0.11.2 0.13.2 1.0.0 1.2.1; do
      check "base-from-history $b_v" eval 'ts base-from-history "$ROOT" "$b_v" "$TMP/h-$b_v" > /dev/null'
      check "base-from-history $b_v: MANIFEST exported" test -f "$TMP/h-$b_v/template/MANIFEST.md"
    done
    check "base-from-history 0.13.2: version file" file_is h-0.13.2/template/VERSION '0.13.2\n'
    check "base-from-history 1.0.0: plugin.json" grep -q '"version": "1.0.0"' "$TMP/h-1.0.0/.claude-plugin/plugin.json"
    check "base-from-history 1.2.1 (no template change): plugin.json" \
      grep -q '"version": "1.2.1"' "$TMP/h-1.2.1/.claude-plugin/plugin.json"
    refute "base-from-history: unknown version refused" ts base-from-history "$ROOT" 0.0.1 "$TMP/h-x"
    refute "base-from-history: kit-only version before the move refused" \
      ts base-from-history "$ROOT" 0.20.0 "$TMP/h-w"
  fi
  refute "base-from-history: invalid version refused" ts base-from-history "$ROOT" 1.x "$TMP/h-y"
  refute "base-from-history: not a git checkout refused" ts base-from-history "$TMP/nosnap" 1.0.0 "$TMP/h-z"
}
