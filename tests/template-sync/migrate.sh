# migrate cases for tests/template-sync/run.sh — sourced, uses its helpers. A small old
# project (PROGRESS.md, PROGRESS-ARCHIVE.md) covers every rule of the command once; a
# word check compares the old text with the feature files independently of the script.

# mg_fixture DIR [yaml] — the old project in DIR; with yaml the FEATURE-INDEX uses the
# "features:" list form.
mg_fixture() {
  rm -rf "${1:?}"
  mkdir -p "$1"
  cat > "$1/PROGRESS.md" << 'EOF'
# demo — Progress

<!-- section:progress-head -->
Living task list.
<!-- /section:progress-head -->

---

## Done

| Step | Description | Completed |
|------|-------------|-----------|
| F-001 | Foundation laid without an archive entry | 2026-01-10 |
| F-002a | First part | 2026-02-01 |

---

## Open tasks — work top to bottom

### F-002 — Planned feature with substeps

**Status:** PLANNED

**Problem:** Something is missing.

#### Notes

A note under the intake.

#### F-002b — Second part

**What:** the rest.

```sh
# a comment, not a heading
```

---

## Feature ideas (backlog)

### F-003 — Idea in the backlog

**Problem:** later.

## Schritt 1.2 — old format entry

Text of an old step.

---

EOF
  if [ "${2:-}" = yaml ]; then
    printf '%s\n' '<!-- FEATURE-INDEX' 'next-feature: F-006' 'features:' \
      '  F-001: Foundation (DONE)' '  F-002: Planned feature with substeps (PLANNED)' \
      '  F-003: Idea in the backlog' '  F-004: Merged idea (→ aufgegangen in F-002/F-003)' \
      '  F-005: Number without content' '-->' >> "$1/PROGRESS.md"
  else
    printf '%s\n' '<!-- FEATURE-INDEX' 'next-feature: F-006' 'F-001 Foundation (DONE)' \
      'F-002 Planned feature with substeps (PLANNED)' 'F-003 Idea in the backlog' \
      'F-004 Merged idea (→ aufgegangen in F-002/F-003)' 'F-005 Number without content' \
      '-->' >> "$1/PROGRESS.md"
  fi
  cat > "$1/PROGRESS-ARCHIVE.md" << 'EOF'
# demo — Progress Archive

Finished tasks, newest first.

---

## F-002a — First part (2026-02-01)

Part of F-002.

### Details

Detail text.

---

## F-007b — Second step of an old feature (2026-01-06)

Second step text.

## F-007a — First step of an old feature (2026-01-05)

First step text.
EOF
}

mg_run() {  # NAME [OPTION…] — migrate $TMP/NAME.p into $TMP/NAME.out, listing in NAME.tsv
  mr_name=$1
  shift
  rm -rf "${TMP:?}/$mr_name.out"
  $SH "$SCRIPT" migrate "$@" "$TMP/$mr_name.p" "$TMP/$mr_name.out" > "$TMP/$mr_name.tsv" 2> "$TMP/$mr_name.err"
}

mg_line() {  # NAME LINE — the listing has exactly this tab-separated line
  grep -qxF -- "$2" "$TMP/$1.tsv"
}

mg_file() {  # NAME ID — path of the feature file for ID
  ls "$TMP/$1.out/features/$2"-*.md 2> /dev/null | sed -n 1p
}

mg_has() {  # NAME ID TEXT — the feature file contains the line TEXT
  mh_f=$(mg_file "$1" "$2") && [ -n "$mh_f" ] && grep -qxF -- "$3" "$mh_f"
}

mg_before() {  # NAME ID FIRST SECOND — both lines in the file, FIRST above SECOND
  mb_f=$(mg_file "$1" "$2") && [ -n "$mb_f" ] || return 1
  awk -v a="$3" -v b="$4" '$0 == a && !x { x = NR } $0 == b && !y { y = NR } END { exit !(x && y && x < y) }' "$mb_f"
}

# Every content line of the old files stands in the feature files as often as there, and
# nothing else does: blocks the listing calls unassigned, the head before the first
# level-2 heading, the FEATURE-INDEX, the Done table and the status lines stay out; the
# main heading of an open entry gives way to the title line, the Done row of a number
# without an archive section becomes its description. Headings count without their #.
words_kept() {  # NAME
  awk -F '\t' -v tsv="$TMP/$1.tsv" '
    function norm(l) { sub(/\r$/, "", l); sub(/^#+[ \t]+/, "", l); gsub(/^[ \t]+|[ \t]+$/, "", l); return l }
    BEGIN {
      while ((getline l < tsv) > 0) {
        split(l, f, "\t")
        if (f[1] == "unassigned") { split(f[3], r, "-"); nu++; u_file[nu] = f[2]; u_from[nu] = r[1]; u_to[nu] = r[2] }
      }
    }
    FNR == 1 { file = FILENAME; sub(/.*\//, "", file); fence = 0; head = 1; inidx = 0; entry = 0 }
    function unassigned(    i) {
      for (i = 1; i <= nu; i++) if (u_file[i] == file && FNR >= u_from[i] && FNR <= u_to[i]) return 1
      return 0
    }
    file ~ /^PROGRESS/ {
      line = $0
      if (line ~ /^[ \t]*(```|~~~)/) fence = !fence
      if (!fence && line ~ /^## /) head = 0
      if (line ~ /^<!-- FEATURE-INDEX/) { inidx = 1; next }
      if (inidx) { if (line ~ /-->/) inidx = 0; next }
      if (head || unassigned()) next
      if (!fence && match(line, /^#+ /)) {
        lvl = RLENGTH - 1
        if (line ~ /^#+ F-[0-9][0-9][0-9]/) {
          if (!entry || lvl <= elvl) { entry = 1; elvl = lvl; if (file == "PROGRESS-ARCHIVE.md") arch[substr(line, lvl + 2, index(substr(line, lvl + 2), " ") - 1)] = 1
            if (file == "PROGRESS.md" && line !~ /^#+ F-[0-9]+[a-z][ :]/) next }
        } else if (lvl <= elvl) entry = 0
      }
      if (file == "PROGRESS.md" && line ~ /^\|[ \t]*F-[0-9]/) { n = split(line, c, "|"); row[c[2]] = c[3]; next }
      if (file == "PROGRESS.md" && !entry) next
      if (line ~ /^\*\*Status:?\*\*/) next
      l = norm(line)
      if (l == "" || l == "---") next
      src[l]++
      next
    }
    {
      if (FNR == 1) { fm = 0 }
      if ($0 == "---" && fm < 2) { fm++; next }
      if (fm < 2) next
      if ($0 ~ /^# F-/ || $0 ~ /^## / || $0 ~ /^<!-- migrated:/) next
      if ($0 ~ /^### F-[0-9]+[a-z]? \([0-9-]+\)$/ || $0 ~ /^### F-[0-9]+[a-z]?$/) next
      l = norm($0)
      if (l == "" || l == "---") next
      got[l]++
    }
    END {
      for (id in row) { k = id; gsub(/[ \t]/, "", k); if (!(k in arch)) src[norm(row[id])]++ }
      bad = 0
      for (l in src) if (got[l] != src[l]) { print "lost or doubled: " l; bad = 1 }
      for (l in got) if (!(l in src)) { print "invented: " l; bad = 1 }
      exit bad
    }' "$TMP/$1.p/PROGRESS.md" $(ls "$TMP/$1.p/PROGRESS-ARCHIVE.md" 2> /dev/null) \
    "$TMP/$1.out"/features/F-*.md
}

run_migrate_cases() {
  mg_fixture "$TMP/mg.p"
  check "migrate runs" mg_run mg
  check "migrate: open entry with history is IN-PROGRESS" mg_line mg "$(printf 'feature\tF-002\tIN-PROGRESS\tfeatures/F-002-planned-feature-with-substeps.md\tindex,open,archive:1')"
  check "migrate: done row without archive section is DONE" mg_line mg "$(printf 'feature\tF-001\tDONE\tfeatures/F-001-foundation.md\tindex,done-row:1')"
  check "migrate: backlog entry without status line" mg_line mg "$(printf 'feature\tF-003\tBACKLOG\tfeatures/F-003-idea-in-the-backlog.md\tindex,open')"
  check "migrate: aufgegangen in is SUPERSEDED" mg_line mg "$(printf 'feature\tF-004\tSUPERSEDED\tfeatures/F-004-merged-idea.md\tindex')"
  check "migrate: number without content is listed" mg_line mg "$(printf 'empty\tF-005')"
  check "migrate: archive-only number is DONE" mg_line mg "$(printf 'feature\tF-007\tDONE\tfeatures/F-007-first-step-of-an-old-feature.md\tarchive:2')"
  check "migrate: old format is listed, not guessed" mg_line mg "$(printf 'unassigned\tPROGRESS.md\t46-51\tSchritt 1.2 — old format entry')"
  check "migrate: next-feature above the highest number" mg_line mg "$(printf 'next-feature\tF-008')"
  check "migrate: dates unknown without git are listed" mg_line mg "$(printf 'missing\tF-003\tcreated')"
  check "migrate: type defaulted for every file" mg_line mg "$(printf 'type\tfeature\t6')"
  refute "migrate: no REQUIREMENTS.md, no requirements line" grep -q '^requirements' "$TMP/mg.tsv"
  check "migrate: superseded-by from the index" mg_has mg F-004 'superseded-by: F-002, F-003'
  check "migrate: status line leaves the intake" eval '! grep -q "Status:" "$(mg_file mg F-002)"'
  check "migrate: intake text word for word" mg_has mg F-002 '**Problem:** Something is missing.'
  check "migrate: heading under the intake one level up" mg_has mg F-002 '### Notes'
  check "migrate: open substep in the plan" mg_before mg F-002 '## Plan' '### F-002b — Second part'
  check "migrate: code fence line untouched" mg_has mg F-002 '# a comment, not a heading'
  check "migrate: archive section in the history" mg_before mg F-002 '## History' '### F-002a — First part (2026-02-01)'
  check "migrate: heading inside an archive section keeps its distance" mg_has mg F-002 '#### Details'
  check "migrate: history oldest first" mg_before mg F-007 '### F-007a — First step of an old feature (2026-01-05)' '### F-007b — Second step of an old feature (2026-01-06)'
  check "migrate: created and done from the history" eval 'mg_has mg F-007 "created: 2026-01-05" && mg_has mg F-007 "done: 2026-01-06"'
  check "migrate: done row becomes a history entry" eval 'mg_has mg F-001 "### F-001 (2026-01-10)" && mg_has mg F-001 "Foundation laid without an archive entry"'
  check "migrate: done row with archive section is not doubled" eval '! grep -q "^### F-002a (" "$(mg_file mg F-002)"'
  check "migrate: empty number gets a note" mg_has mg F-005 '<!-- migrated: the old FEATURE-INDEX had only this line for the number -->'
  check "migrate: every word kept, nothing invented" words_kept mg

  # Without the archive the Done row of a substep is the history of its feature.
  mg_fixture "$TMP/mgn.p"
  rm "$TMP/mgn.p/PROGRESS-ARCHIVE.md"
  check "migrate without archive runs" mg_run mgn
  check "migrate without archive: done row of a substep is history" mg_line mgn "$(printf 'feature\tF-002\tIN-PROGRESS\tfeatures/F-002-planned-feature-with-substeps.md\tindex,open,done-row:1')"
  check "migrate without archive: done row in the history" mg_has mgn F-002 '### F-002a (2026-02-01)'
  refute "migrate without archive: no archive-only number" eval 'grep -q "F-007" "$TMP/mgn.tsv"'
  check "migrate without archive: every word kept" words_kept mgn

  # The list form of the index, a REQUIREMENTS.md and translated section names.
  mg_fixture "$TMP/mgy.p" yaml
  printf '# Requirements\n' > "$TMP/mgy.p/REQUIREMENTS.md"
  check "migrate with list index and requirements runs" mg_run mgy --sections Erfassung,Plan,Verlauf
  check "migrate: list index gives the same status" mg_line mgy "$(printf 'feature\tF-001\tDONE\tfeatures/F-001-foundation.md\tindex,done-row:1')"
  check "migrate: REQUIREMENTS.md is left to the skill" mg_line mgy "$(printf 'requirements\tREQUIREMENTS.md')"
  check "migrate: section names as given" eval 'mg_has mgy F-002 "## Erfassung" && mg_has mgy F-002 "## Verlauf"'

  # In git: dates from the history, then a valid index.
  mg_fixture "$TMP/mgg.p"
  git -C "$TMP/mgg.p" init -q
  git -C "$TMP/mgg.p" add -A
  GIT_AUTHOR_DATE=2026-03-03T12:00:00 GIT_COMMITTER_DATE=2026-03-03T12:00:00 \
    git -C "$TMP/mgg.p" -c user.name=test -c user.email=test@example.com commit -q -m old
  render mgg-seeds docs-only private --seeds
  check "migrate in git with index runs" mg_run mgg --index "$TMP/mgg-seeds/features/INDEX.md"
  check "migrate: created from git when no date is written" mg_line mgg "$(printf 'date\tF-003\tcreated\tgit')"
  check "migrate: created from git in the file" mg_has mgg F-003 'created: 2026-03-03'
  check "migrate: written date wins over a later git date" mg_has mgg F-002 'created: 2026-02-01'
  check "migrate: index copied with next-feature" contains mgg.out/features/INDEX.md 'next-feature: F-008'
  check "migrate: index listed" mg_line mgg "$(printf 'index\tfeatures/INDEX.md')"
  check "migrate: the features index accepts the result" \
    eval '$SH "$TEMPLATE/core/scripts/features-index.sh" write "$TMP/mgg.out/features" > /dev/null'

  # Refusals
  mkdir -p "$TMP/mgx.out"
  : > "$TMP/mgx.out/keep"
  mg_fixture "$TMP/mgx.p"
  refute "migrate refuses a non-empty OUT" eval '$SH "$SCRIPT" migrate "$TMP/mgx.p" "$TMP/mgx.out" > /dev/null 2>&1'
  refute "migrate refuses a project without PROGRESS.md" eval '$SH "$SCRIPT" migrate "$TMP/mgg-seeds" "$TMP/mgx2.out" > /dev/null 2>&1'
}
