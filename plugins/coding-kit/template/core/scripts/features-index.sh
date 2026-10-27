#!/bin/sh
# Features index — keeps features/INDEX.md in step with the feature files.
#
# Usage:
#   sh scripts/features-index.sh check [DIR]   report every finding; exit 1 when there is one
#   sh scripts/features-index.sh write [DIR]   regenerate the table of all features, then check
#
# DIR defaults to `features`. `just check` runs `check`, `just features-index` runs
# `write`. The pre-commit hook only checks: a hook that rewrites files would put changes
# into the commit that nobody has seen.
#
# A feature is one file DIR/F-NNN-short-name.md (after the number: lowercase ASCII
# letters, digits and hyphens) that starts with a header block between two `---` lines.
# Only plain `key: value` lines are allowed there — no quotes, no multi-line values;
# lists are comma-separated. F-000-template.md is the template and is skipped.
#
#   id             F-NNN, the number of the file name                       required
#   title          at most 70 characters                                    required
#   type           feature | fix | change                                   required
#   status         BACKLOG | PLANNED | IN-PROGRESS | DONE | DROPPED | SUPERSEDED  required
#   size           S | M | L; empty until /prep-step sets it
#   created        YYYY-MM-DD                                               required
#   done           YYYY-MM-DD; required for DONE, allowed for DROPPED and SUPERSEDED,
#                  empty while the feature is open
#   depends-on     F-numbers
#   superseded-by  F-numbers; required for SUPERSEDED, empty otherwise
#
# `write` replaces only the lines between the marker lines `<!-- features-index -->` and
# `<!-- /features-index -->` in INDEX.md: one table row per feature, sorted by number.
# The first two lines inside the markers stay as the table head when they are table
# lines, so a project can translate the head. Everything else in INDEX.md is left as it
# is. While a header block is broken, `write` writes nothing and lists the findings.
#
# `check` reports broken header blocks, duplicate numbers, a table that differs from what
# `write` would produce, a missing or too low `next-feature: F-NNN` line, and F-numbers in
# the recommended order — the text between the index-head zone and the table — that have
# no file or are not open (BACKLOG, PLANNED, IN-PROGRESS).
#
# POSIX sh + awk only, no other toolchain. awk runs with LC_ALL=C and counts title
# characters itself, so every awk counts the same.

set -u

usage() {
  echo 'usage: sh scripts/features-index.sh check|write [DIR]' >&2
  exit 2
}

[ $# -ge 1 ] && [ $# -le 2 ] || usage
mode=$1
case $mode in
  check | write) ;;
  *) usage ;;
esac
dir=${2:-features}
index=$dir/INDEX.md

if [ ! -f "$index" ]; then
  printf '%s: missing — a project from before coding-kit 2.0.0 migrates with /update-conventions\n' "$index"
  exit 1
fi

# The feature files as arguments, the template left out.
set --
for f in "$dir"/F-*.md; do
  [ -f "$f" ] || continue
  [ "${f##*/}" = F-000-template.md ] && continue
  set -- "$@" "$f"
done

# Arguments: the feature files, then INDEX.md (always last). Variables: mode (check or
# write) and out (write only: the file the new INDEX.md goes to).
program='
function trim(s) {
  sub(/^[ \t]+/, "", s)
  sub(/[ \t]+$/, "", s)
  return s
}

# Characters, not bytes: drop the UTF-8 continuation bytes before counting.
function chars(s) {
  gsub(/[\200-\277]/, "", s)
  return length(s)
}

function number(id) {
  return substr(id, 3) + 0
}

function is_id(s) {
  return s ~ /^F-[0-9][0-9][0-9][0-9]*$/
}

function is_date(s) {
  return s ~ /^[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]$/
}

# A comma-separated list of F-numbers as "F-001, F-002"; "!" when an item is none.
function id_list(s,    n, parts, i, item, result) {
  result = ""
  if (s == "") return result
  n = split(s, parts, ",")
  for (i = 1; i <= n; i++) {
    item = trim(parts[i])
    if (!is_id(item)) return "!"
    result = result (result == "" ? "" : ", ") item
  }
  return result
}

function report(where, msg) {
  print where ": " msg
}

# A finding in feature file I; any such finding keeps `write` from writing.
function bad(i, msg) {
  report(path[i], msg)
  feature_findings++
}

# One line of feature file I. state: 0 nothing read, 1 inside the header block,
# 2 after it, 3 the file does not start with one.
function header_line(i,    key, val) {
  sub(/\r$/, "")
  if (state[i] == 0) {
    state[i] = ($0 == "---") ? 1 : 3
    return
  }
  if (state[i] != 1) return
  if ($0 == "---") {
    state[i] = 2
    return
  }
  if ($0 ~ /^[ \t]*$/) return
  if (!match($0, /^[a-z][a-z-]*:/) || (length($0) > RLENGTH && substr($0, RLENGTH + 1, 1) != " ")) {
    bad(i, "header line " FNR " is not a plain `key: value` line")
    return
  }
  key = substr($0, 1, RLENGTH - 1)
  val = trim(substr($0, RLENGTH + 1))
  if (!(key in known)) {
    bad(i, "unknown header field `" key "`")
    return
  }
  if ((i, key) in field) {
    bad(i, "header field `" key "` appears twice")
    return
  }
  if (val ~ /^["\047]/) bad(i, "the value of `" key "` is quoted — write it plain")
  field[i, key] = val
}

function check_feature(i,    base, prefix, id, st, d, k, n) {
  base = path[i]
  sub(/.*\//, "", base)
  file_base[i] = base
  if (base !~ /^F-[0-9][0-9][0-9][0-9]*-[a-z0-9]+(-[a-z0-9]+)*\.md$/)
    bad(i, "the file name is not F-NNN-short-name.md (lowercase letters, digits, hyphens)")
  if (state[i] == 0 || state[i] == 3) {
    bad(i, "no header block — the file must start with a `---` line")
    return
  }
  if (state[i] == 1) {
    bad(i, "the header block has no closing `---` line")
    return
  }
  for (k = 1; k <= nrequired; k++)
    if (field[i, required[k]] == "") bad(i, "the header field `" required[k] "` is missing or empty")

  id = field[i, "id"]
  prefix = ""
  if (match(base, /^F-[0-9]+/)) prefix = substr(base, 1, RLENGTH)
  if (id != "" && !is_id(id)) bad(i, "id `" id "` is not F-NNN")
  else if (id != "" && prefix != "" && id != prefix) bad(i, "id " id " does not match the file name")

  n = chars(field[i, "title"])
  if (n > 70) bad(i, "the title has " n " characters — at most 70")

  if (field[i, "type"] != "" && !(field[i, "type"] in valid_type))
    bad(i, "type `" field[i, "type"] "` is not one of feature, fix, change")
  if (!(field[i, "size"] in valid_size))
    bad(i, "size `" field[i, "size"] "` is not one of S, M, L")
  if (field[i, "created"] != "" && !is_date(field[i, "created"]))
    bad(i, "created `" field[i, "created"] "` is not YYYY-MM-DD")

  st = field[i, "status"]
  d = field[i, "done"]
  if (st != "" && !(st in valid_status))
    bad(i, "status `" st "` is not one of BACKLOG, PLANNED, IN-PROGRESS, DONE, DROPPED, SUPERSEDED")
  if (d != "" && !is_date(d)) bad(i, "done `" d "` is not YYYY-MM-DD")
  if (st == "DONE" && d == "") bad(i, "status DONE needs a `done` date")
  if ((st in is_open) && d != "") bad(i, "`done` is set, but the status " st " is open")

  if (id_list(field[i, "depends-on"]) == "!") bad(i, "depends-on is not a comma-separated list of F-numbers")
  superseded[i] = id_list(field[i, "superseded-by"])
  if (superseded[i] == "!") bad(i, "superseded-by is not a comma-separated list of F-numbers")
  if (st == "SUPERSEDED" && superseded[i] == "") bad(i, "status SUPERSEDED needs `superseded-by`")
  if (st != "" && st != "SUPERSEDED" && superseded[i] != "")
    bad(i, "`superseded-by` is set, but the status is " st)

  if (is_id(id)) {
    usable[i] = 1
    count[id]++
    if (st in valid_status) status_of[id] = st
    if (number(id) > highest) {
      highest = number(id)
      highest_id = id
    }
  }
}

# The table rows for the usable feature files, sorted by number, then file name.
function build_table(    i, j, n, t, order, parts, k, title, cell, a, b) {
  n = 0
  for (i = 1; i <= nfiles; i++) {
    if (!(i in usable)) continue
    n++
    order[n] = i
    for (j = n; j > 1; j--) {
      a = order[j - 1]
      b = order[j]
      if (number(field[a, "id"]) < number(field[b, "id"]) ||
          (number(field[a, "id"]) == number(field[b, "id"]) && file_base[a] <= file_base[b])) break
      order[j - 1] = b
      order[j] = a
    }
  }
  for (j = 1; j <= n; j++) {
    i = order[j]
    # A pipe in a title would end its cell.
    k = split(field[i, "title"], parts, "|")
    title = parts[1]
    for (t = 2; t <= k; t++) title = title "\\|" parts[t]
    cell = field[i, "status"]
    if (cell == "SUPERSEDED") cell = cell " → " superseded[i]
    rows[j] = "| [" field[i, "id"] "](" file_base[i] ") | " title " | " cell " | " field[i, "done"] " |"
  }
  nrows = n
}

BEGIN {
  nknown = split("id title type status size created done depends-on superseded-by", list, " ")
  for (k = 1; k <= nknown; k++) known[list[k]] = 1
  nrequired = split("id title type status created", required, " ")
  nst = split("BACKLOG PLANNED IN-PROGRESS DONE DROPPED SUPERSEDED", list, " ")
  for (k = 1; k <= nst; k++) valid_status[list[k]] = 1
  is_open["BACKLOG"] = 1
  is_open["PLANNED"] = 1
  is_open["IN-PROGRESS"] = 1
  valid_type["feature"] = 1
  valid_type["fix"] = 1
  valid_type["change"] = 1
  valid_size[""] = 1
  valid_size["S"] = 1
  valid_size["M"] = 1
  valid_size["L"] = 1
  # Registered up front, so an empty file — awk reads no line of it — still counts.
  index_path = ARGV[ARGC - 1]
  nfiles = 0
  for (k = 1; k < ARGC - 1; k++) {
    nfiles++
    path[nfiles] = ARGV[k]
    slot[ARGV[k]] = nfiles
  }
}

FILENAME != index_path {
  header_line(slot[FILENAME])
  next
}

{
  sub(/\r$/, "")
  nlines++
  line[nlines] = $0
}

END {
  for (i = 1; i <= nfiles; i++) check_feature(i)
  for (i = 1; i <= nfiles; i++)
    if ((i in usable) && count[field[i, "id"]] > 1)
      bad(i, "the number " field[i, "id"] " is used by more than one file")

  head_end = 0
  starts = 0
  ends = 0
  next_lines = 0
  for (n = 1; n <= nlines; n++) {
    t = trim(line[n])
    if (t == "<!-- /section:index-head -->" && head_end == 0) head_end = n
    if (t == "<!-- features-index -->") {
      starts++
      table_start = n
    }
    if (t == "<!-- /features-index -->") {
      ends++
      table_end = n
    }
    if (t ~ /^next-feature:/) {
      if (t ~ /^next-feature: F-[0-9][0-9][0-9][0-9]*$/) {
        next_lines++
        next_id = substr(t, 15)
      } else if (mode == "check") report(index_path ":" n, "not a `next-feature: F-NNN` line")
    }
  }
  markers_ok = (starts == 1 && ends == 1 && table_start < table_end)
  if (!markers_ok)
    report(index_path, "needs one `<!-- features-index -->` line and one `<!-- /features-index -->` line after it")

  build_table()
  if (markers_ok && table_end - table_start > 2 && line[table_start + 1] ~ /^\|/ && line[table_start + 2] ~ /^\|/) {
    head1 = line[table_start + 1]
    head2 = line[table_start + 2]
  } else {
    head1 = "| ID | Title | Status | Done |"
    head2 = "|----|-------|--------|------|"
  }

  if (mode == "write") {
    if (feature_findings > 0 || !markers_ok) exit 1
    for (n = 1; n <= table_start; n++) print line[n] > out
    print head1 > out
    print head2 > out
    for (j = 1; j <= nrows; j++) print rows[j] > out
    for (n = table_end; n <= nlines; n++) print line[n] > out
    close(out)
    exit 0
  }

  # check: the table, next-feature and the recommended order
  if (markers_ok && feature_findings == 0) {
    stale = (table_end - table_start - 1 != nrows + 2)
    if (!stale) stale = (line[table_start + 1] != head1 || line[table_start + 2] != head2)
    for (j = 1; !stale && j <= nrows; j++) stale = (line[table_start + 2 + j] != rows[j])
    if (stale) report(index_path, "the table of all features is out of date — run `just features-index`")
  }

  if (next_lines == 0) report(index_path, "no `next-feature: F-NNN` line")
  else if (next_lines > 1) report(index_path, "more than one `next-feature` line")
  else if (number(next_id) <= highest)
    report(index_path, "next-feature " next_id " is not above the highest number " highest_id)

  if (markers_ok) {
    for (n = head_end + 1; n < table_start; n++) {
      s = line[n]
      while (match(s, /F-[0-9][0-9][0-9][0-9]*/)) {
        id = substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
        if (!(id in count))
          report(index_path ":" n, "the recommended order names " id ", which has no feature file")
        else if ((id in status_of) && !(status_of[id] in is_open))
          report(index_path ":" n, "the recommended order names " id ", which is " status_of[id] " — only open features belong there")
      }
    }
  }
}'

if [ "$mode" = write ]; then
  tmp=$(mktemp "${TMPDIR:-/tmp}/features-index.XXXXXX") || exit 1
  if ! LC_ALL=C awk -v mode=write -v out="$tmp" "$program" "$@" "$index"; then
    rm -f "$tmp"
    echo 'features-index: table not written — fix the findings above' >&2
    exit 1
  fi
  if cmp -s "$tmp" "$index"; then
    echo "features-index: $index is up to date"
  else
    # cat keeps the file and its permissions; mv would take over the temp file mode.
    cat "$tmp" > "$index"
    echo "features-index: table written to $index"
  fi
  rm -f "$tmp"
fi

findings=$(LC_ALL=C awk -v mode=check -v out= "$program" "$@" "$index")
if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  printf 'features-index: %s finding(s)\n' "$(printf '%s\n' "$findings" | wc -l | tr -d ' ')" >&2
  exit 1
fi
exit 0
