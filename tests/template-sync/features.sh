# Features index cases for tests/template-sync/run.sh — sourced, uses its helpers.
# They test the template script scripts/features-index.sh as a project runs it: from the
# project root, on features/.

FI=$TEMPLATE/core/scripts/features-index.sh

# fx_run NAME MODE — runs the script in project NAME; output in $TMP/NAME.out.
fx_run() {
  (cd "$TMP/$1" && $SH "$FI" "$2") > "$TMP/$1.out" 2>&1
}

fx_ok() { fx_run "$1" check; }

# fx_finds NAME TEXT — the check fails and its output contains TEXT.
fx_finds() {
  ! fx_run "$1" check && grep -qF -- "$2" "$TMP/$1.out"
}

# fx_base NAME — project NAME with the rendered features/INDEX.md, next-feature F-100.
fx_base() {
  rm -rf "${TMP:?}/$1"
  mkdir -p "$TMP/$1/features"
  sed 's/^next-feature: .*/next-feature: F-100/' "$TMP/fx-render/features/INDEX.md" \
    > "$TMP/$1/features/INDEX.md"
}

# fx_feature NAME NUMBER STATUS TITLE [LINE]… — features/F-NUMBER-demo-NUMBER.md with a
# valid header block for STATUS; each LINE is one more header line.
fx_feature() {
  ff_name=$1 ff_num=$2 ff_status=$3 ff_title=$4
  shift 4
  {
    printf '%s\n' --- "id: F-$ff_num" "title: $ff_title" 'type: feature' \
      "status: $ff_status" 'created: 2026-10-01'
    [ $# -gt 0 ] && printf '%s\n' "$@"
    printf '%s\n' --- '' "# F-$ff_num — $ff_title"
  } > "$TMP/$ff_name/features/F-$ff_num-demo-$ff_num.md"
}

# fx_order NAME TEXT — the recommended order of project NAME says TEXT.
fx_order() {
  awk -v t="$2" '/^_Nothing planned yet/ { print t; next } { print }' \
    "$TMP/$1/features/INDEX.md" > "$TMP/$1.index" && mv "$TMP/$1.index" "$TMP/$1/features/INDEX.md"
}

# fx_block NAME — the lines from the start marker to the end marker of the table.
fx_block() {
  sed -n '/^<!-- features-index -->$/,/^<!-- \/features-index -->$/p' "$TMP/$1/features/INDEX.md"
}

# fx_outside NAME — INDEX.md without the table block.
fx_outside() {
  sed '/^<!-- features-index -->$/,/^<!-- \/features-index -->$/d' "$TMP/$1/features/INDEX.md"
}

fx_same_outside() {  # NAME BEFORE-FILE
  fx_outside "$1" | cmp -s - "$2"
}

fx_block_is() {  # NAME EXPECTED-FILE
  fx_block "$1" | cmp -s - "$2"
}

run_features_cases() {
  # A fresh render: the template index and the CLAUDE.md overview
  check "render with seeds for the features cases" render fx-render docs-only private --seeds
  check "fresh render: the features check passes" fx_ok fx-render
  check "fresh render: template file left out of the check" has fx-render/features/F-000-template.md
  check "fresh render: empty table" eval '[ "$(fx_block fx-render | wc -l | tr -d " ")" = 4 ]'
  for fx_h in '### Goals' '### Non-goals' '### Constraints'; do
    check "fresh render: CLAUDE.md overview has $fx_h" contains fx-render/CLAUDE.md "$fx_h"
  done
  check "ts-node render with seeds" render fx-ts ts-node public --seeds
  check "fresh ts-node render: the features check passes" fx_ok fx-ts

  # write: rows from the header blocks, sorted by number, the rest untouched
  fx_base fxw
  fx_feature fxw 003 BACKLOG 'Pipe | im Titel'
  fx_feature fxw 1000 PLANNED 'Above 999' 'size: M' 'depends-on: F-003, F-001'
  fx_feature fxw 001 DONE 'Größe ändern' 'done: 2026-10-05'
  fx_feature fxw 002 SUPERSEDED 'Merged' 'superseded-by: F-001,F-003'
  sed 's/^next-feature: .*/next-feature: F-1001/' "$TMP/fxw/features/INDEX.md" > "$TMP/fxw.index"
  mv "$TMP/fxw.index" "$TMP/fxw/features/INDEX.md"
  fx_order fxw '1. F-003 — first; then F-1000 (needs F-003).'
  fx_outside fxw > "$TMP/fxw.outside"
  check "before write: the check reports the stale table" fx_finds fxw "out of date"
  check "write succeeds" fx_run fxw write
  printf '%s\n' '<!-- features-index -->' '| ID | Title | Status | Done |' \
    '|----|-------|--------|------|' \
    '| [F-001](F-001-demo-001.md) | Größe ändern | DONE | 2026-10-05 |' \
    '| [F-002](F-002-demo-002.md) | Merged | SUPERSEDED → F-001, F-003 |  |' \
    '| [F-003](F-003-demo-003.md) | Pipe \| im Titel | BACKLOG |  |' \
    '| [F-1000](F-1000-demo-1000.md) | Above 999 | PLANNED |  |' \
    '<!-- /features-index -->' > "$TMP/fxw.expected"
  check "write: rows sorted by number, linked, status and date" fx_block_is fxw "$TMP/fxw.expected"
  check "write: head, order and next-feature untouched" fx_same_outside fxw "$TMP/fxw.outside"
  check "after write: the check passes" fx_ok fxw
  cp "$TMP/fxw/features/INDEX.md" "$TMP/fxw.written"
  check "write again" fx_run fxw write
  check "write again: nothing changes" cmp -s "$TMP/fxw/features/INDEX.md" "$TMP/fxw.written"

  # A translated table head stays
  sed -e 's/^| ID | Title | Status | Done |$/| ID | Titel | Status | Fertig |/' \
    "$TMP/fxw/features/INDEX.md" > "$TMP/fxw.index"
  mv "$TMP/fxw.index" "$TMP/fxw/features/INDEX.md"
  check "translated head: write succeeds" fx_run fxw write
  check "translated head: kept" contains fxw/features/INDEX.md '| ID | Titel | Status | Fertig |'
  check "translated head: the check passes" fx_ok fxw

  # A hand edit in the table is reported
  sed 's/| Merged |/| Merged by hand |/' "$TMP/fxw/features/INDEX.md" > "$TMP/fxw.index"
  mv "$TMP/fxw.index" "$TMP/fxw/features/INDEX.md"
  check "hand-edited row: stale table" fx_finds fxw "out of date"

  # Header block findings, one project each
  fx_base fxr
  fx_feature fxr 001 BACKLOG 'Fine'
  check "valid single feature: write and check pass" fx_run fxr write

  fx_base fxm
  printf '%s\n' --- 'id: F-001' 'type: feature' 'status: BACKLOG' 'created: 2026-10-01' --- \
    > "$TMP/fxm/features/F-001-demo-001.md"
  check "missing title" fx_finds fxm '`title` is missing or empty'

  fx_base fxi
  fx_feature fxi 001 BACKLOG 'Fine'
  mv "$TMP/fxi/features/F-001-demo-001.md" "$TMP/fxi/features/F-002-demo-002.md"
  check "id does not match the file name" fx_finds fxi 'does not match the file name'

  fx_base fxs
  fx_feature fxs 001 OPEN 'Fine'
  check "unknown status" fx_finds fxs 'status `OPEN` is not one of'

  fx_base fxd
  fx_feature fxd 001 DONE 'Fine'
  check "DONE without done" fx_finds fxd 'status DONE needs a `done` date'

  fx_base fxo
  fx_feature fxo 001 PLANNED 'Fine' 'done: 2026-10-02'
  check "done set while open" fx_finds fxo '`done` is set, but the status PLANNED is open'

  fx_base fxdr
  fx_feature fxdr 001 DROPPED 'Fine'
  check "DROPPED without done passes" fx_run fxdr write

  fx_base fxsu
  fx_feature fxsu 001 SUPERSEDED 'Fine'
  check "SUPERSEDED without superseded-by" fx_finds fxsu 'status SUPERSEDED needs `superseded-by`'

  fx_base fxsb
  fx_feature fxsb 001 BACKLOG 'Fine' 'superseded-by: F-002'
  check "superseded-by on another status" fx_finds fxsb '`superseded-by` is set, but the status is BACKLOG'

  fx_base fxl
  fx_feature fxl 001 BACKLOG 'Fine' 'depends-on: F-1, other'
  check "list that is not F-numbers" fx_finds fxl 'depends-on is not a comma-separated list'

  fx_base fxt
  fx_t=
  fx_n=0
  while [ "$fx_n" -lt 70 ]; do
    fx_t="${fx_t}ä"
    fx_n=$((fx_n + 1))
  done
  fx_feature fxt 001 BACKLOG "$fx_t"
  check "title of 70 characters with umlauts passes" fx_run fxt write
  fx_feature fxt 001 BACKLOG "${fx_t}x"
  check "title of 71 characters" fx_finds fxt 'the title has 71 characters'

  fx_base fxq
  fx_feature fxq 001 BACKLOG '"Quoted"'
  check "quoted value" fx_finds fxq 'the value of `title` is quoted'

  fx_base fxu
  fx_feature fxu 001 BACKLOG 'Fine' 'priority: high'
  check "unknown field" fx_finds fxu 'unknown header field `priority`'

  fx_base fxh
  printf '%s\n' '# F-001 — no header' > "$TMP/fxh/features/F-001-demo-001.md"
  : > "$TMP/fxh/features/F-002-demo-002.md"
  check "no header block" fx_finds fxh 'F-001-demo-001.md: no header block'
  check "empty file: no header block" fx_finds fxh 'F-002-demo-002.md: no header block'

  fx_base fxc
  printf '%s\n' --- 'id: F-001' 'title: Open end' > "$TMP/fxc/features/F-001-demo-001.md"
  check "header block not closed" fx_finds fxc 'no closing `---` line'

  fx_base fxn
  fx_feature fxn 001 BACKLOG 'Fine'
  mv "$TMP/fxn/features/F-001-demo-001.md" "$TMP/fxn/features/F-001-Demo.md"
  check "file name not lowercase" fx_finds fxn 'the file name is not F-NNN-short-name.md'

  # Index findings
  fx_base fxdup
  fx_feature fxdup 001 BACKLOG 'One'
  cp "$TMP/fxdup/features/F-001-demo-001.md" "$TMP/fxdup/features/F-001-other.md"
  check "duplicate number" fx_finds fxdup 'the number F-001 is used by more than one file'

  fx_base fxnf
  fx_feature fxnf 001 BACKLOG 'Fine'
  fx_run fxnf write
  sed 's/^next-feature: .*/next-feature: F-001/' "$TMP/fxnf/features/INDEX.md" > "$TMP/fxnf.index"
  mv "$TMP/fxnf.index" "$TMP/fxnf/features/INDEX.md"
  check "next-feature too low" fx_finds fxnf 'next-feature F-001 is not above the highest number F-001'
  grep -v '^next-feature:' "$TMP/fxnf/features/INDEX.md" > "$TMP/fxnf.index"
  mv "$TMP/fxnf.index" "$TMP/fxnf/features/INDEX.md"
  check "next-feature missing" fx_finds fxnf 'no `next-feature: F-NNN` line'

  fx_base fxdone
  fx_feature fxdone 001 DONE 'Finished' 'done: 2026-10-02'
  fx_feature fxdone 002 IN-PROGRESS 'Running'
  fx_run fxdone write
  fx_order fxdone '1. F-002 — running; F-001 is done.'
  check "done feature in the order" fx_finds fxdone 'names F-001, which is DONE — only open features'
  check "open feature in the order is fine" eval '! grep -qF "names F-002" "$TMP/fxdone.out"'

  fx_base fxgone
  fx_feature fxgone 001 BACKLOG 'Fine'
  fx_run fxgone write
  fx_order fxgone '1. F-007 — not there.'
  check "order names a missing feature" fx_finds fxgone 'names F-007, which has no feature file'

  fx_base fxmk
  grep -v '^<!-- /features-index -->$' "$TMP/fxmk/features/INDEX.md" > "$TMP/fxmk.index"
  mv "$TMP/fxmk.index" "$TMP/fxmk/features/INDEX.md"
  check "end marker missing" fx_finds fxmk 'needs one `<!-- features-index -->` line'

  # write refuses while a header block is broken, and leaves INDEX.md alone
  fx_base fxwr
  fx_feature fxwr 001 OPEN 'Fine'
  cp "$TMP/fxwr/features/INDEX.md" "$TMP/fxwr.before"
  refute "write with a broken header block fails" fx_run fxwr write
  check "write with a broken header block: INDEX.md unchanged" \
    cmp -s "$TMP/fxwr/features/INDEX.md" "$TMP/fxwr.before"

  # No INDEX.md at all
  rm -rf "${TMP:?}/fxnone"
  mkdir -p "$TMP/fxnone/features"
  refute "missing INDEX.md fails" fx_run fxnone check
  check "missing INDEX.md: names the migration" grep -qF 'migrates with /update-conventions' "$TMP/fxnone.out"
}
