#!/bin/sh
# template-sync.sh — deterministic helper behind the coding-kit template contract
# (template/MANIFEST.md). Skills call it with resolved paths; every command prints
# tab-separated lines for the skill to show.
#
#   render [--seeds] TEMPLATE ANSWERS OUT
#       Writes the pure instantiation of TEMPLATE for the project that ANSWERS describes
#       (.claude/template-answers, MANIFEST § Answers) into OUT (missing or empty).
#       Line per file: <target> <managed|seed> <core|module>. Without --seeds only the
#       managed targets; with --seeds the seed files follow as raw instantiation
#       (template:adapt spots and the license text stay with the calling skill).
#   status [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT
#       Compares every target of the base snapshot (.claude/template-base/<target>.base)
#       with the project. Line: <target> <unchanged|deviates|missing> <registry> <+a -d>.
#       --base takes the bases from a rendered DIR instead (no suffix) — for a project
#       that has no snapshot yet; merge accepts it the same way.
#   changed [--registry FILE] [--snapshot DIR] PROJECT
#       Like status, for the targets the working tree touches (against HEAD, plus
#       untracked files) — the backstop of /step-done. Edits below the snapshot itself
#       come out as <path> snapshot-edited.
#   merge [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SOLL OUT
#       Three-way merge per target: base snapshot, project, rendered SOLL. Results go to
#       OUT (missing or empty). Line: <target> <class> <conflicts> <registry>, classes:
#       identical, template-only, project-only, merged, caught-up (the result equals
#       the template although the project deviated — the template has caught up),
#       conflict, kept (keep row: conflicts resolved to the project), two-way (no base),
#       new, missing (project deleted it), removed (no longer rendered), skipped.
#   snapshot [--snapshot DIR] PROJECT SOLL TARGET…
#       Sets the base of each TARGET to its rendered version; a TARGET that SOLL no
#       longer has loses its base. Line: <target> <set|removed>. A TARGET that is neither
#       rendered nor has a base is refused before anything is written.
#   base-from-history KIT VERSION OUT
#       Exports the template of VERSION from the git history of a coding-kit checkout
#       into OUT/template (missing or empty OUT); a release without template changes
#       has the template of the commit that set its version. Line: <template dir> <commit>.
#   zones [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SEEDS OUT [NAME…]
#       Compares the marked blocks of PROJECT with SEEDS (a render with --seeds): the
#       section:NAME zones of the seed files and the fragment:NAME blocks in the
#       module:coding-standards slot. Line per block: <target> <section|fragment> <name>
#       <state> <+a -d>, states: identical, differs, override (an override line in the
#       project's block; the count is what the template changed since the base,
#       fragments only), new (a fragment only SEEDS has), opted-out (the project removed
#       the zone's markers), unmarked (the file has no zone markers or no slot at all),
#       local (only the project has it), no-file, broken (unbalanced, nested or
#       duplicate markers), skipped (skip row). A block that neither side has gets no
#       line. OUT/<target> is the project file with every differing and new block
#       applied — only the NAMEs given, if any: a differing block is replaced, a new
#       fragment goes behind its nearest predecessor of the render order in the slot
#       (without one to the slot's start) and replaces the placeholder text of a slot
#       without fragments. OUT/.zones/<kind>/<name>.<project|template|base> hold the
#       blocks for the diffs.
#   detect [--changed] [--answers FILE] [--registry FILE] TEMPLATE PROJECT [SIGNAL…]
#       Matches the signals of PROJECT against the stack modules and catalog fragments
#       of TEMPLATE (MANIFEST § Detection). Without SIGNAL it reads the files git lists
#       for the project; with --changed only the signals the working tree adds against
#       HEAD; with SIGNAL arguments (type:value, a file signal names a planned path)
#       only those. Line per hit: <module|fragment> <name> <covered|declined|missing>
#       <signal (first path[ +more])>, … — modules first. A fragment is covered by its
#       marker in the slot or because the module of the answers declares it. Without
#       .claude/template-answers the module check is skipped (note on stderr). Then a
#       line per tool the template has no convention for: tool <name>
#       <unknown|declined> <tool:name (first path[ +more])>.
#
# Options name a stand-in for a file of PROJECT, so a skill can go on with files it
# prepared in a temp folder while a write below .claude/ waits for approval:
#   --answers FILE   instead of .claude/template-answers
#   --registry FILE  instead of .claude/convention-overrides.md
#   --snapshot DIR   instead of .claude/template-base (snapshot writes there)
# Options come before the operands; a command refuses one it does not take.
#
# <registry> is the kind of the matching row in the Files table of
# .claude/convention-overrides.md: skip, keep, adapt, registered (row without kind) or
# none. Comparisons ignore CR line ends, a missing final newline and the content of the
# module:coding-standards slot (fragments are synced one by one, never with the file).
# A marker (slot, section, fragment, override) counts only on a line of its own.
#
# POSIX sh plus git, awk, sed, find, sort, tar and mktemp. No network, no writes outside
# the named directories and a private temp directory. Exit status 1 on a contract
# violation, 2 on wrong usage, 3 when PROJECT has no base snapshot (status, changed).

set -eu

TAB=$(printf '\t')
SNAP_DIR=.claude/template-base
REGISTRY=.claude/convention-overrides.md
ANSWERS_FILE=.claude/template-answers
# Signal types detect reads (MANIFEST § Detection); the validator compares the list
# with the MANIFEST table.
SIGNAL_TYPES='npm pypi go tool file'
SLOT_OPEN='<!-- module:coding-standards -->'
SLOT_CLOSE='<!-- /module:coding-standards -->'
# Set by parse_opts.
BASE_DIR=
ANSWERS_OPT=
REGISTRY_OPT=
SNAPSHOT_OPT=
CHANGED=0
SEEDS=0

die() {
  printf 'template-sync: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat >&2 << 'EOF'
usage: sh template-sync.sh render [--seeds] TEMPLATE ANSWERS OUT
       sh template-sync.sh status [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT
       sh template-sync.sh changed [--registry FILE] [--snapshot DIR] PROJECT
       sh template-sync.sh merge [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SOLL OUT
       sh template-sync.sh snapshot [--snapshot DIR] PROJECT SOLL TARGET...
       sh template-sync.sh base-from-history KIT VERSION OUT
       sh template-sync.sh zones [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SEEDS OUT [NAME...]
       sh template-sync.sh detect [--changed] [--answers FILE] [--registry FILE] TEMPLATE PROJECT [SIGNAL...]
EOF
  exit 2
}

# Private temp directory, removed on exit.
setup_work() {
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/template-sync.XXXXXX") || die "cannot create a temp directory"
  trap 'rm -rf "$WORK"' EXIT
  trap 'exit 1' HUP INT TERM
}

# OUT must be missing or an empty directory.
check_out_dir() {  # DIR
  if [ -e "$1" ]; then
    [ -d "$1" ] || die "$1 exists and is not a directory"
    [ -z "$(ls -A "$1")" ] || die "$1 is not empty"
  fi
}

# --- answers and values --------------------------------------------------------

# ANSWERS → "KEY<TAB>value" lines. Rejects input that would make rendering ambiguous.
load_answers() {
  awk '
    function fail(msg) { print "template-sync: answers line " NR ": " msg | "cat 1>&2"; bad = 1 }
    { sub(/\r$/, "") }
    /^[ \t]*$/ || /^[ \t]*#/ { next }
    {
      eq = index($0, "=")
      if (eq == 0) { fail("expected KEY=value"); next }
      key = substr($0, 1, eq - 1); val = substr($0, eq + 1)
      gsub(/^[ \t]+|[ \t]+$/, "", key); gsub(/^[ \t]+|[ \t]+$/, "", val)
      if (key !~ /^[A-Z][A-Z0-9_]*$/) { fail("invalid key \"" key "\""); next }
      if (key in seen) { fail("duplicate key " key); next }
      if (index(val, "\t") || index(val, "{{")) { fail(key " contains a tab or {{"); next }
      seen[key] = 1
      print key "\t" val
    }
    END { close("cat 1>&2"); exit bad }' "$1"
}

# Value of KEY from the values table; status 1 when the key is not set.
value_of() {
  awk -F "$TAB" -v k="$1" '
    $1 == k { print substr($0, length(k) + 2); found = 1 }
    END { exit !found }' "$WORK/values.tsv"
}

add_value() {
  printf '%s\t%s\n' "$1" "$2" >> "$WORK/values.tsv"
}

# Comma- or space-separated list value as space-separated names (empty when unset).
list_of() {
  lo_raw=$(value_of "$1") || lo_raw=
  printf '%s' "$lo_raw" | tr ',' ' ' | tr -s ' ' | sed 's/^ //; s/ $//'
}

check_names() {  # WHERE NAMES…
  cn_where=$1
  shift
  for cn_name in "$@"; do
    case $cn_name in
      *[!a-z0-9-]*) die "$cn_where: invalid name '$cn_name' (lowercase, digits, hyphens)" ;;
    esac
  done
}

# Warn about keys that are neither placeholders of this template nor structural keys —
# usually a typo that would otherwise go unnoticed.
warn_unknown_keys() {
  awk -F "$TAB" '
    NR == FNR {
      if ($0 ~ /^\|[ \t]*`[{][{][A-Z][A-Z0-9_]*[}][}]`/) {
        t = $0; sub(/^\|[ \t]*`[{][{]/, "", t); sub(/[}][}].*$/, "", t); known[t] = 1
      }
      next
    }
    !($1 in known) && $1 !~ /^(MODULE|VISIBILITY|OPTIONAL|FRAGMENTS)$/ {
      print "template-sync: warning: answers key " $1 " is not used by this template" | "cat 1>&2"
    }
    END { close("cat 1>&2") }' "$TEMPLATE/MANIFEST.md" "$WORK/values.tsv"
}

# CODEQL_LANGUAGES as the module's MODULE.md declares it ("`<token>` → `<value>`").
module_codeql() {
  awk -v name="CODEQL_LANGUAGES" '
    BEGIN { tok = "`{{" name "}}`"; arrow = "→" }
    {
      i = index($0, tok)
      if (!i) next
      rest = substr($0, i + length(tok)); sub(/^[ \t]+/, "", rest)
      if (substr(rest, 1, length(arrow)) != arrow) next
      rest = substr(rest, length(arrow) + 1)
      if (match(rest, /^[ \t]*`[^`]+`/)) {
        v = substr(rest, RSTART, RLENGTH); sub(/^[^`]*`/, "", v); sub(/`$/, "", v)
        print v
        exit
      }
    }' "$MODDIR/MODULE.md"
}

# Plugin version for TEMPLATE_VERSION: plugin.json next to the template, or the VERSION
# file that templates up to 0.16.0 carried.
template_version() {
  tv_json=$TEMPLATE/../.claude-plugin/plugin.json
  if [ -f "$tv_json" ]; then
    sed -n 's/.*"version"[ ]*:[ ]*"\([^"]*\)".*/\1/p' "$tv_json" | sed -n 1p
  elif [ -f "$TEMPLATE/VERSION" ]; then
    sed -n 1p "$TEMPLATE/VERSION"
  fi
}

# --- MANIFEST and MODULE.md tables ---------------------------------------------

# § Core-managed files → "source<TAB>target<TAB>kind<TAB>public-only|-".
core_rows() {
  awk -F'|' '
    /^## / { insec = ($0 ~ /^## Core-managed files[ \t]*$/); next }
    insec && $2 ~ /`core\// {
      src = $2; tgt = $3; pol = $4
      gsub(/^[ \t`]+|[ \t`]+$/, "", src)
      gsub(/^[ \t]+|[ \t]+$/, "", tgt); gsub(/`/, "", tgt)
      if (tgt == "same path") tgt = substr(src, 6)
      gsub(/^[ \t]+|[ \t]+$/, "", pol)
      kind = pol; sub(/[^a-z-].*$/, "", kind)
      print src "\t" tgt "\t" kind "\t" (pol ~ /public-only/ ? "public-only" : "-")
    }' "$TEMPLATE/MANIFEST.md"
}

# § Module contract → "part<TAB>target" for every part with a target file.
part_rows() {
  awk -F'|' '
    /^## / { insec = ($0 ~ /^## Module contract[ \t]*$/); next }
    insec && /^\|/ {
      part = $2; tgt = $3
      gsub(/^[ \t]+|[ \t]+$/, "", part); gsub(/^[ \t]+|[ \t]+$/, "", tgt)
      if (part !~ /^`[^`]+`$/ || tgt !~ /^`[^`]+`$/) next
      gsub(/`/, "", part); gsub(/`/, "", tgt)
      print part "\t" tgt
    }' "$TEMPLATE/MANIFEST.md"
}

# Target of a module part per the contract; status 1 when the contract has no such row.
part_target() {
  awk -F "$TAB" -v p="$1" '$1 == p { print $2; found = 1 } END { exit !found }' "$WORK/parts.tsv"
}

# MODULE.md § File policies (files/) → "path<TAB>policy word" per listed file.
file_policies() {
  awk -F'|' '
    /^## / { insec = ($0 ~ /^## File policies/); next }
    insec && /^\|/ {
      ents = $2; pol = $3
      sub(/^[ \t]+/, "", pol); kind = pol; sub(/[^a-z].*$/, "", kind)
      while (match(ents, /`[^`]+`/)) {
        print substr(ents, RSTART + 1, RLENGTH - 2) "\t" kind
        ents = substr(ents, RSTART + RLENGTH)
      }
    }' "$MODDIR/MODULE.md"
}

# Policy of a file below files/: the row naming its full path; templates before 1.1.0
# may name a file by its bare name, which counts when it is unambiguous.
policy_of() {
  awk -F "$TAB" -v r="$1" '
    BEGIN { b = r; sub(/.*\//, "", b) }
    $1 == r { print $2; found = 1; exit }
    index($1, "/") == 0 && $1 == b { cand = $2; n++ }
    END { if (!found) { if (n == 1) print cand; else exit 1 } }' "$WORK/policies.tsv"
}

# Catalog fragments the module declares ("Standards fragments: `a`, `b` — note").
declared_fragments() {
  awk '
    /Standards fragments:/ {
      s = substr($0, index($0, "Standards fragments:") + length("Standards fragments:"))
      sub(/^[* \t]+/, "", s)
      cut = 0
      for (i = 1; i <= 2; i++) {
        dash = (i == 1) ? " — " : " – "
        j = index(s, dash)
        if (j && (!cut || j < cut)) cut = j
      }
      if (cut) s = substr(s, 1, cut - 1)
      gsub(/^[ \t]+|[ \t]+$/, "", s)
      if (s == "" || s == "(none)" || s == "none") exit
      n = split(s, parts, ",")
      for (i = 1; i <= n; i++) {
        p = parts[i]; gsub(/[ \t`]/, "", p)
        if (p != "" && p != "none") print p
      }
      exit
    }' "$MODDIR/MODULE.md"
}

# --- content transformations ----------------------------------------------------

# merge_tools, insert_below_marker and fill_slot rewrite FILE in place via $WORK/next.
rewrite() {  # FILE
  mv "$WORK/next" "$1"
}

# mise.part.toml: its [tools] entries follow the last entry of the core [tools] table.
merge_tools() {  # FILE PART
  if awk -v part="$2" '
    BEGIN {
      while ((getline l < part) > 0) {
        sub(/\r$/, "", l)
        if (l ~ /^[ \t]*\[/) { intools = (l ~ /^[ \t]*\[tools\][ \t]*$/); if (!intools) bad = 1; continue }
        if (l ~ /^[ \t]*$/) continue
        if (!intools) { bad = 1; continue }
        add[++n] = l
      }
      close(part)
    }
    { line[NR] = $0 }
    END {
      if (bad || n == 0) exit 4
      for (i = 1; i <= NR; i++) if (line[i] ~ /^[ \t]*\[tools\][ \t]*$/) { t = i; break }
      if (!t) exit 5
      h = NR + 1
      for (i = t + 1; i <= NR; i++) if (line[i] ~ /^[ \t]*\[/) { h = i; break }
      last = t
      for (i = t + 1; i < h; i++) if (line[i] !~ /^[ \t]*$/) last = i
      for (i = 1; i <= last; i++) print line[i]
      for (j = 1; j <= n; j++) print add[j]
      for (i = last + 1; i <= NR; i++) print line[i]
    }' "$1" > "$WORK/next"; then
    rewrite "$1"
  else
    die "cannot merge $2: it must hold a non-empty [tools] table only, and the target needs one"
  fi
}

# gitignore.part / ci.part.yml: inserted directly below the marker line.
insert_below_marker() {  # FILE MARKER PART
  if awk -v m="$2" -v part="$3" '
    { print }
    !done && index($0, m) {
      while ((getline l < part) > 0) print l
      close(part)
      done = 1
    }
    END { if (!done) exit 3 }' "$1" > "$WORK/next"; then
    rewrite "$1"
  else
    die "marker '$2' not found for $3"
  fi
}

# Fragments replace the slot's placeholder text, one blank line between them.
fill_slot() {  # FILE CONTENT
  if awk -v content="$2" -v open="$SLOT_OPEN" -v shut="$SLOT_CLOSE" '
    { t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t) }
    t == open {
      print
      while ((getline l < content) > 0) print l
      close(content)
      skip = 1; seen = 1
      next
    }
    t == shut { skip = 0 }
    !skip { print }
    END { if (!seen) exit 6 }' "$1" > "$WORK/next"; then
    rewrite "$1"
  else
    die "no module:coding-standards slot in $SLOT_TARGET"
  fi
}

# Last pass, SRC → DST: template:optional blocks, then literal placeholder substitution.
# A kept optional block loses its two marker lines, a dropped one goes with its content;
# an unbalanced or nested block exits 7. Leftover placeholder tokens are listed in
# $WORK/missing for the caller.
finalize() {  # SRC DST
  : > "$WORK/missing"
  awk -F "$TAB" -v keep=" $OPTIONAL " -v miss="$WORK/missing" '
    function lit(s, t, r,   o, i) {
      o = ""
      while ((i = index(s, t)) > 0) { o = o substr(s, 1, i - 1) r; s = substr(s, i + length(t)) }
      return o s
    }
    NR == FNR { tok["{{" $1 "}}"] = substr($0, length($1) + 2); next }
    { t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t) }
    t ~ /^<!--[ \t]*template:optional:[a-z0-9-]+[ \t]*-->$/ {
      if (name != "") exit 7
      name = t; sub(/^<!--[ \t]*template:optional:/, "", name); sub(/[ \t]*-->$/, "", name)
      drop = !index(keep, " " name " ")
      next
    }
    t ~ /^<!--[ \t]*\/template:optional:[a-z0-9-]+[ \t]*-->$/ {
      n = t; sub(/^<!--[ \t]*\/template:optional:/, "", n); sub(/[ \t]*-->$/, "", n)
      if (n != name) exit 7
      name = ""; drop = 0
      next
    }
    drop { next }
    {
      line = $0
      if (index(line, "{{")) {
        for (k in tok) if (index(line, k)) line = lit(line, k, tok[k])
        rest = line
        while (match(rest, /[{][{][A-Z][A-Z0-9_]*[}][}]/)) {
          print substr(rest, RSTART, RLENGTH) > miss
          rest = substr(rest, RSTART + RLENGTH)
        }
      }
      print line
    }
    END { if (name != "") exit 7 }' "$WORK/values.tsv" "$1" > "$2"
}

missing_tokens() {
  sort -u "$WORK/missing" | tr '\n' ' '
}

subst_path() {  # PATH
  printf '%s\n' "$1" > "$WORK/path"
  finalize "$WORK/path" "$WORK/path.out" || die "cannot substitute path $1"
  [ ! -s "$WORK/missing" ] || die "unresolved placeholder in path $1: $(missing_tokens)"
  cat "$WORK/path.out"
}

# Does SRC need the module's CodeQL language while the module declares none?
needs_absent_codeql() {  # SRC
  [ -z "$CODEQL" ] || return 1
  nc_tok='{{'
  nc_tok="${nc_tok}CODEQL_LANGUAGES}}"
  grep -F -q "$nc_tok" "$1"
}

# --- render -------------------------------------------------------------------

emit() {  # SRC TARGET POLICY ORIGIN
  e_src=$1 e_tgt=$2
  e_dst=$OUT/$e_tgt
  [ ! -e "$e_dst" ] || die "two sources render to $e_tgt"
  e_in=$e_src
  while IFS="$TAB" read -r e_part e_ptgt; do
    [ "$e_ptgt" = "$e_tgt" ] || continue
    [ -f "$MODDIR/$e_part" ] || continue
    case $e_part in
      justfile | CODING-STANDARDS.part.md) continue ;;  # source swap / slot, see render
      mise.part.toml | gitignore.part | ci.part.yml) ;;
      *) die "MANIFEST § Module contract names part $e_part, which this script cannot apply" ;;
    esac
    if [ "$e_in" = "$e_src" ]; then
      e_in=$WORK/stage
      cat "$e_src" > "$e_in"
    fi
    case $e_part in
      mise.part.toml) merge_tools "$e_in" "$MODDIR/$e_part" ;;
      gitignore.part) insert_below_marker "$e_in" "# module:gitignore" "$MODDIR/$e_part" ;;
      ci.part.yml) insert_below_marker "$e_in" "# module:ci-jobs" "$MODDIR/$e_part" ;;
    esac
  done < "$WORK/parts.tsv"
  if [ "$e_tgt" = "$SLOT_TARGET" ] && [ -s "$WORK/slot" ]; then
    if [ "$e_in" = "$e_src" ]; then
      e_in=$WORK/stage
      cat "$e_src" > "$e_in"
    fi
    fill_slot "$e_in" "$WORK/slot"
  fi
  e_dir=${e_dst%/*}
  [ -d "$e_dir" ] || mkdir -p "$e_dir"
  finalize "$e_in" "$e_dst" || die "unbalanced or nested template:optional block in $e_tgt"
  [ ! -s "$WORK/missing" ] || die "unresolved placeholder in $e_tgt: $(missing_tokens)"
  if [ -x "$e_src" ]; then chmod +x "$e_dst"; fi
  printf '%s\t%s\t%s\n' "$e_tgt" "$3" "$4"
}

# Slot content: module fragment, declared catalog fragments, FRAGMENTS — each trimmed
# of surrounding blank lines, one blank line between them.
compose_slot() {
  : > "$WORK/slot"
  : > "$WORK/frags"
  if [ -f "$MODDIR/CODING-STANDARDS.part.md" ]; then
    printf '%s\t%s\n' "$MODULE" "$MODDIR/CODING-STANDARDS.part.md" >> "$WORK/frags"
  fi
  for cs_name in $(declared_fragments) $FRAGMENTS; do
    check_names "modules/$MODULE/MODULE.md Standards fragments" "$cs_name"
    cs_file=$TEMPLATE/modules/standards/$cs_name.md
    [ -f "$cs_file" ] || die "fragment '$cs_name' not found in modules/standards/"
    printf '%s\t%s\n' "$cs_name" "$cs_file" >> "$WORK/frags"
  done
  awk -F "$TAB" '
    !($1 in seen) {
      seen[$1] = 1
      n = 0
      while ((getline l < $2) > 0) { sub(/\r$/, "", l); buf[++n] = l }
      close($2)
      s = 1; while (s <= n && buf[s] ~ /^[ \t]*$/) s++
      e = n; while (e >= s && buf[e] ~ /^[ \t]*$/) e--
      if (s > e) next
      if (printed) print ""
      for (i = s; i <= e; i++) print buf[i]
      printed = 1
    }' "$WORK/frags" > "$WORK/slot"
}

render() {
  seeds=$SEEDS
  [ $# -eq 3 ] || usage
  TEMPLATE=$1 ANSWERS=$2 OUT=$3
  [ -f "$TEMPLATE/MANIFEST.md" ] || die "no MANIFEST.md in $TEMPLATE"
  [ -f "$ANSWERS" ] || die "answers file not found: $ANSWERS"
  check_out_dir "$OUT"
  setup_work

  load_answers "$ANSWERS" > "$WORK/values.tsv" || die "invalid answers file: $ANSWERS"
  warn_unknown_keys

  MODULE=$(value_of MODULE) || die "answers: MODULE is missing"
  case $MODULE in
    '' | standards | *[!a-z0-9-]*) die "answers: invalid MODULE '$MODULE'" ;;
  esac
  MODDIR=$TEMPLATE/modules/$MODULE
  [ -f "$MODDIR/MODULE.md" ] || die "module '$MODULE' not found in $TEMPLATE/modules"
  VISIBILITY=$(value_of VISIBILITY) || die "answers: VISIBILITY is missing"
  case $VISIBILITY in
    public | private) ;;
    *) die "answers: VISIBILITY must be public or private, not '$VISIBILITY'" ;;
  esac
  OPTIONAL=$(list_of OPTIONAL)
  FRAGMENTS=$(list_of FRAGMENTS)
  # Word splitting of the name lists is intended.
  check_names "answers OPTIONAL" $OPTIONAL
  check_names "answers FRAGMENTS" $FRAGMENTS
  # The license blocks follow LICENSE_SPDX (MANIFEST § Answers), never the answers list.
  case " $OPTIONAL " in
    *" license "* | *" license-tbd "*)
      die "answers OPTIONAL: the license blocks are derived from LICENSE_SPDX, do not list them"
      ;;
  esac
  if [ "$(value_of LICENSE_SPDX || true)" = TBD ]; then
    OPTIONAL="$OPTIONAL license-tbd"
  else
    OPTIONAL="$OPTIONAL license"
  fi

  if ! value_of PROJECT_NAME_SNAKE > /dev/null && r_name=$(value_of PROJECT_NAME); then
    add_value PROJECT_NAME_SNAKE "$(printf '%s' "$r_name" | tr '-' '_')"
  fi
  CODEQL=$(module_codeql)
  if [ -n "$CODEQL" ]; then add_value CODEQL_LANGUAGES "$CODEQL"; fi
  if ! value_of TEMPLATE_VERSION > /dev/null; then
    r_version=$(template_version)
    if [ -n "$r_version" ]; then add_value TEMPLATE_VERSION "$r_version"; fi
  fi

  core_rows > "$WORK/core.tsv"
  [ -s "$WORK/core.tsv" ] || die "no rows in MANIFEST § Core-managed files"
  part_rows > "$WORK/parts.tsv"
  SLOT_TARGET=$(part_target CODING-STANDARDS.part.md) || SLOT_TARGET=
  compose_slot

  mkdir -p "$OUT"

  while IFS="$TAB" read -r r_src r_tgt r_kind r_pub; do
    case $r_kind in
      seed)
        [ "$seeds" -eq 1 ] || continue
        r_policy=seed
        ;;
      managed | module) r_policy=managed ;;
      *) die "MANIFEST: unknown policy '$r_kind' for $r_src" ;;
    esac
    if [ "$r_pub" = public-only ] && [ "$VISIBILITY" != public ]; then continue; fi
    r_from=$TEMPLATE/$r_src
    [ -f "$r_from" ] || die "MANIFEST lists $r_src, which is missing"
    # A module part that replaces the core file (the justfile) becomes the source.
    if [ "$r_kind" = module ] && r_part=$(basename "$r_tgt") \
      && [ "$(part_target "$r_part" 2> /dev/null || true)" = "$r_tgt" ] \
      && [ -f "$MODDIR/$r_part" ]; then
      r_from=$MODDIR/$r_part
    fi
    if needs_absent_codeql "$r_from"; then continue; fi
    emit "$r_from" "$r_tgt" "$r_policy" core
  done < "$WORK/core.tsv"

  if [ -d "$MODDIR/files" ]; then
    file_policies > "$WORK/policies.tsv"
    (cd "$MODDIR/files" && find . -type f ! -name .DS_Store) | sed 's|^\./||' | LC_ALL=C sort > "$WORK/files.lst"
    while IFS= read -r f_rel; do
      f_kind=$(policy_of "$f_rel") || die "files/$f_rel has no row in modules/$MODULE/MODULE.md § File policies"
      case $f_kind in
        managed) ;;
        seed) [ "$seeds" -eq 1 ] || continue ;;
        *) die "modules/$MODULE/MODULE.md: policy of $f_rel must start with managed or seed" ;;
      esac
      f_tgt=$(subst_path "$f_rel") || exit 1
      emit "$MODDIR/files/$f_rel" "$f_tgt" "$f_kind" module
    done < "$WORK/files.lst"
  fi
}

# --- project side: normalization, registry, snapshot ----------------------------

# IN → OUT with LF line ends and a final newline; with "mask" the lines inside the
# module:coding-standards slot are dropped, the two marker lines stay. A slot that is
# never closed stays as it is.
normalize() {  # IN OUT [mask]
  awk -v mask="${3:-}" -v open="$SLOT_OPEN" -v shut="$SLOT_CLOSE" '
    { sub(/\r$/, ""); t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t) }
    mask != "" && !inslot && t == open { print; inslot = 1; n = 0; next }
    inslot && t == shut { inslot = 0; print; next }
    inslot { buf[++n] = $0; next }
    { print }
    END { if (inslot) for (i = 1; i <= n; i++) print buf[i] }' "$1" > "$2"
}

# Content of the slot in IN (LF line ends) → OUT; status 1 when IN has no slot.
slot_of() {  # IN OUT
  awk -v open="$SLOT_OPEN" -v shut="$SLOT_CLOSE" '
    { sub(/\r$/, ""); t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t) }
    inslot && t == shut { inslot = 0; done = 1; exit }
    inslot { print }
    !done && t == open { inslot = 1 }
    END { exit !done }' "$1" > "$2"
}

# IN with SLOT inserted below the first slot opening → OUT; status 1 when IN has none.
unmask() {  # IN SLOT OUT
  awk -v slot="$2" -v open="$SLOT_OPEN" '
    { print; t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t) }
    !done && t == open {
      while ((getline l < slot) > 0) print l
      close(slot)
      done = 1
    }
    END { exit !done }' "$1" > "$3"
}

# Files table of the deviation registry → "path-or-glob<TAB>kind" lines in
# $WORK/registry.tsv. A row lists one or more paths (comma-separated, backticks allowed);
# its kind is skip, keep, adapt or empty ("registered").
load_registry() {
  : > "$WORK/registry.tsv"
  [ -f "$REG_PATH" ] || return 0
  awk '
    function fail(msg) { print "template-sync: " FILENAME ": " msg | "cat 1>&2"; bad = 1 }
    /^#+[ \t]/ { insec = ($0 ~ /^## Files[ \t]*$/); next }
    insec && /^\|/ {
      split($0, c, "|")
      paths = c[2]; kind = c[3]
      gsub(/^[ \t]+|[ \t]+$/, "", paths); gsub(/[ \t`]/, "", kind); kind = tolower(kind)
      if (paths == "" || paths ~ /^[:-]+$/ || tolower(paths) == "path" || paths ~ /^_/) next
      if (kind == "") kind = "registered"
      else if (kind != "skip" && kind != "keep" && kind != "adapt") {
        fail("unknown kind \"" kind "\" for " paths); next
      }
      n = split(paths, p, ",")
      for (i = 1; i <= n; i++) {
        x = p[i]; gsub(/[ \t`]/, "", x)
        if (x != "") print x "\t" kind
      }
    }
    END { close("cat 1>&2"); exit bad }' "$REG_PATH" > "$WORK/registry.tsv" \
    || die "invalid Files table in $REG_PATH"
}

# Kind of the first registry row whose path or glob matches TARGET; "none" without one.
# Globs follow sh case patterns, so * also matches /.
kind_of() {  # TARGET
  while IFS="$TAB" read -r ko_glob ko_kind; do
    # The pattern must stay unquoted to act as a glob.
    case $1 in
      $ko_glob)
        printf '%s\n' "$ko_kind"
        return 0
        ;;
    esac
  done < "$WORK/registry.tsv"
  printf 'none\n'
}

# Targets with a base in the snapshot, sorted.
snapshot_targets() {
  (cd "$SNAP_PATH" && find . -type f -name '*.base') | sed 's|^\./||; s|\.base$||' | LC_ALL=C sort
}

# Where the base of TARGET lives: the snapshot, or $BASE_DIR when --base was given.
base_of() {  # TARGET
  if [ -n "$BASE_DIR" ]; then
    printf '%s\n' "$BASE_DIR/$1"
  else
    printf '%s\n' "$SNAP_PATH/$1.base"
  fi
}

# Targets that have a base, sorted.
base_targets() {
  if [ -n "$BASE_DIR" ]; then
    (cd "$BASE_DIR" && find . -type f) | sed 's|^\./||' | LC_ALL=C sort
  elif [ -d "$SNAP_PATH" ]; then
    snapshot_targets
  fi
}

# Leading options of COMMAND (see the header) → BASE_DIR, ANSWERS_OPT, REGISTRY_OPT,
# SNAPSHOT_OPT, CHANGED, SEEDS; OPTS_SHIFT counts the arguments they took.
parse_opts() {  # COMMAND ARGS…
  po_cmd=$1
  shift
  OPTS_SHIFT=0
  while [ $# -gt 0 ]; do
    case $1 in
      --seeds) po_for=render po_n=1 ;;
      --changed) po_for=detect po_n=1 ;;
      --base) po_for='status merge zones' po_n=2 ;;
      --answers) po_for=detect po_n=2 ;;
      --registry) po_for='status changed merge zones detect' po_n=2 ;;
      --snapshot) po_for='status changed merge snapshot zones' po_n=2 ;;
      --*)
        printf 'template-sync: unknown option %s\n' "$1" >&2
        usage
        ;;
      *) return 0 ;;
    esac
    case " $po_for " in
      *" $po_cmd "*) ;;
      *)
        printf 'template-sync: %s takes no %s\n' "${po_cmd:-this command}" "$1" >&2
        usage
        ;;
    esac
    [ $# -ge "$po_n" ] || usage
    case $1 in
      --seeds) SEEDS=1 ;;
      --changed) CHANGED=1 ;;
      --base)
        [ -d "$2" ] || die "base directory not found: $2"
        BASE_DIR=$2
        ;;
      --answers)
        [ -f "$2" ] || die "answers file not found: $2"
        ANSWERS_OPT=$2
        ;;
      --registry)
        [ -f "$2" ] || die "registry not found: $2"
        REGISTRY_OPT=$2
        ;;
      --snapshot) SNAPSHOT_OPT=$2 ;;
    esac
    shift "$po_n"
    OPTS_SHIFT=$((OPTS_SHIFT + po_n))
  done
}

# Where PROJECT's answers, registry and snapshot are: their usual place, or the stand-in
# an option names.
set_paths() {  # PROJECT
  ANS_PATH=${ANSWERS_OPT:-$1/$ANSWERS_FILE}
  REG_PATH=${REGISTRY_OPT:-$1/$REGISTRY}
  SNAP_PATH=${SNAPSHOT_OPT:-$1/$SNAP_DIR}
}

require_snapshot() {  # PROJECT
  [ -d "$1" ] || die "project not found: $1"
  if [ ! -d "$SNAP_PATH" ]; then
    printf 'template-sync: no base snapshot at %s\n' "$SNAP_PATH" >&2
    exit 3
  fi
}

# Changed lines between two normalized files as "+added -deleted".
diffstat() {  # A B
  git diff --no-index --numstat -- "$1" "$2" | awk '{ a += $1; d += $2 } END { printf "+%d -%d\n", a, d }'
}

# State of TARGET in $P against its base: unchanged, deviates or missing, plus the
# diffstat ("-" when there is nothing to count).
compare_line() {  # TARGET
  cl_kind=$(kind_of "$1")
  if [ ! -e "$P/$1" ]; then
    printf '%s\tmissing\t%s\t-\n' "$1" "$cl_kind"
    return 0
  fi
  normalize "$(base_of "$1")" "$WORK/cl.base" mask
  normalize "$P/$1" "$WORK/cl.project" mask
  if cmp -s "$WORK/cl.base" "$WORK/cl.project"; then
    printf '%s\tunchanged\t%s\t-\n' "$1" "$cl_kind"
  else
    printf '%s\tdeviates\t%s\t%s\n' "$1" "$cl_kind" "$(diffstat "$WORK/cl.base" "$WORK/cl.project")"
  fi
}

check_target() {  # TARGET — relative, inside the project
  case $1 in
    '' | /* | .. | ../* | */.. | */../*) die "invalid target path '$1'" ;;
  esac
}

# --- status, changed -----------------------------------------------------------

status() {
  [ $# -eq 1 ] || usage
  P=$1
  set_paths "$P"
  if [ -z "$BASE_DIR" ]; then require_snapshot "$P"; fi
  [ -d "$P" ] || die "project not found: $P"
  setup_work
  load_registry
  base_targets > "$WORK/targets.lst"
  while IFS= read -r st_t; do
    compare_line "$st_t"
  done < "$WORK/targets.lst"
}

changed() {
  [ $# -eq 1 ] || usage
  P=$1
  set_paths "$P"
  require_snapshot "$1"
  setup_work
  load_registry
  git -C "$1" rev-parse --git-dir > /dev/null 2>&1 || die "$1 is not a git repository"
  if git -C "$1" rev-parse --verify -q HEAD > /dev/null; then
    git -C "$1" -c core.quotePath=false diff --name-only --relative HEAD -- > "$WORK/touched"
  else
    git -C "$1" -c core.quotePath=false ls-files --cached > "$WORK/touched"
  fi
  git -C "$1" -c core.quotePath=false ls-files --others --exclude-standard >> "$WORK/touched"
  LC_ALL=C sort -u "$WORK/touched" > "$WORK/touched.lst"
  while IFS= read -r ch_p; do
    case $ch_p in
      "$SNAP_DIR"/*)
        printf '%s\tsnapshot-edited\t-\t-\n' "$ch_p"
        continue
        ;;
    esac
    if [ -f "$SNAP_PATH/$ch_p.base" ]; then compare_line "$ch_p"; fi
  done < "$WORK/touched.lst"
}

# --- merge ----------------------------------------------------------------------

# --diff-algorithm needs git 2.44 or later; older versions merge with the default.
merge_algorithm() {
  : > "$WORK/empty"
  if git merge-file -p --diff-algorithm=histogram "$WORK/empty" "$WORK/empty" "$WORK/empty" > /dev/null 2>&1; then
    printf '%s' '--diff-algorithm=histogram'
  fi
}

# Writes a merge result: FILE as is, or with the project's slot content put back.
finish() {  # FILE TARGET
  if [ "$MG_SLOT" = 1 ]; then
    unmask "$1" "$WORK/mg.slot" "$MG_RES" \
      || die "$2: the template dropped the module:coding-standards slot — merge it by hand"
  else
    cp "$1" "$MG_RES"
  fi
}

merge_one() {  # TARGET
  mg_t=$1
  mg_kind=$(kind_of "$mg_t")
  mg_base=$(base_of "$mg_t")
  mg_ours=$P/$mg_t
  mg_theirs=$SOLL/$mg_t
  MG_RES=$OUT/$mg_t
  mg_n=0
  if [ "$mg_kind" = skip ]; then
    mg_class=skipped
  elif [ ! -f "$mg_theirs" ]; then
    mg_class=removed
  elif [ ! -f "$mg_ours" ]; then
    if [ -f "$mg_base" ]; then
      mg_class=missing
    else
      mg_class=new
      mkdir -p "${MG_RES%/*}"
      normalize "$mg_theirs" "$MG_RES"
    fi
  else
    mkdir -p "${MG_RES%/*}"
    MG_SLOT=0
    if slot_of "$mg_ours" "$WORK/mg.slot"; then MG_SLOT=1; fi
    normalize "$mg_ours" "$WORK/mg.ours" mask
    normalize "$mg_theirs" "$WORK/mg.theirs" mask
    if [ -f "$mg_base" ]; then normalize "$mg_base" "$WORK/mg.base" mask; fi
    if cmp -s "$WORK/mg.ours" "$WORK/mg.theirs"; then
      if [ ! -f "$mg_base" ] || cmp -s "$WORK/mg.ours" "$WORK/mg.base"; then
        mg_class=identical
      else
        mg_class=caught-up
      fi
      normalize "$mg_ours" "$MG_RES"
    elif [ ! -f "$mg_base" ]; then
      mg_class=two-way
      finish "$WORK/mg.theirs" "$mg_t"
    elif cmp -s "$WORK/mg.ours" "$WORK/mg.base"; then
      mg_class=template-only
      finish "$WORK/mg.theirs" "$mg_t"
    elif cmp -s "$WORK/mg.theirs" "$WORK/mg.base"; then
      mg_class=project-only
      normalize "$mg_ours" "$MG_RES"
    else
      set +e
      # $ALGORITHM is empty or one word, so it stays unquoted.
      git merge-file -p --diff3 $ALGORITHM -L project -L "template base" -L "template new" \
        "$WORK/mg.ours" "$WORK/mg.base" "$WORK/mg.theirs" > "$WORK/mg.result"
      mg_n=$?
      set -e
      [ "$mg_n" -lt 128 ] || die "git merge-file failed for $mg_t"
      if [ "$mg_n" -eq 0 ]; then
        if cmp -s "$WORK/mg.result" "$WORK/mg.theirs"; then mg_class=caught-up; else mg_class=merged; fi
      elif [ "$mg_kind" = keep ]; then
        mg_class=kept
        git merge-file -p --ours $ALGORITHM "$WORK/mg.ours" "$WORK/mg.base" "$WORK/mg.theirs" \
          > "$WORK/mg.result" || die "git merge-file --ours failed for $mg_t"
      else
        mg_class=conflict
      fi
      finish "$WORK/mg.result" "$mg_t"
    fi
  fi
  printf '%s\t%s\t%s\t%s\n' "$mg_t" "$mg_class" "$mg_n" "$mg_kind"
}

merge() {
  [ $# -eq 3 ] || usage
  P=$1 SOLL=$2 OUT=$3
  set_paths "$P"
  [ -d "$P" ] || die "project not found: $P"
  [ -d "$SOLL" ] || die "rendered template not found: $SOLL"
  check_out_dir "$OUT"
  setup_work
  load_registry
  ALGORITHM=$(merge_algorithm)
  {
    base_targets
    (cd "$SOLL" && find . -type f) | sed 's|^\./||'
  } | LC_ALL=C sort -u > "$WORK/targets.lst"
  mkdir -p "$OUT"
  while IFS= read -r mg_target; do
    merge_one "$mg_target"
  done < "$WORK/targets.lst"
}

# --- snapshot, base-from-history ------------------------------------------------

snapshot() {
  [ $# -ge 3 ] || usage
  P=$1 SOLL=$2
  shift 2
  set_paths "$P"
  [ -d "$P" ] || die "project not found: $P"
  [ -d "$SOLL" ] || die "rendered template not found: $SOLL"
  # All targets are checked before anything is written.
  for sn_t in "$@"; do
    check_target "$sn_t"
    if [ ! -f "$SOLL/$sn_t" ] && [ ! -f "$SNAP_PATH/$sn_t.base" ]; then
      die "unknown target '$sn_t': not rendered in $SOLL and no base — pass each target as an argument of its own"
    fi
  done
  for sn_t in "$@"; do
    sn_base=$SNAP_PATH/$sn_t.base
    if [ -f "$SOLL/$sn_t" ]; then
      mkdir -p "${sn_base%/*}"
      cp "$SOLL/$sn_t" "$sn_base"
      printf '%s\tset\n' "$sn_t"
    else
      rm -f "$sn_base"
      printf '%s\tremoved\n' "$sn_t"
    fi
  done
}

# Version recorded at COMMIT: plugin.json from 1.0.0 on, template/VERSION before.
version_at() {  # KIT COMMIT
  va_v=$(git -C "$1" show "$2:plugins/coding-kit/.claude-plugin/plugin.json" 2> /dev/null \
    | sed -n 's/.*"version"[ ]*:[ ]*"\([^"]*\)".*/\1/p' | sed -n 1p)
  if [ -z "$va_v" ]; then
    va_v=$(git -C "$1" show "$2:plugins/coding-kit/template/VERSION" 2> /dev/null | sed -n 1p)
  fi
  printf '%s\n' "$va_v"
}

# The template of a version is its state at the newest commit that touches the template
# while carrying that version: later commits of a released version cannot change the
# template, because the version rule demands a bump for that.
base_from_history() {
  [ $# -eq 3 ] || usage
  KIT=$1 WANT=$2 OUT=$3
  case $WANT in
    '' | *[!0-9.]*) die "invalid version '$WANT'" ;;
  esac
  git -C "$KIT" rev-parse --git-dir > /dev/null 2>&1 || die "$KIT is not a git checkout"
  check_out_dir "$OUT"
  setup_work
  git -C "$KIT" log --format=%H -- plugins/coding-kit/template > "$WORK/commits"
  bf_commit=
  while IFS= read -r bf_c; do
    if [ "$(version_at "$KIT" "$bf_c")" = "$WANT" ]; then
      bf_commit=$bf_c
      break
    fi
  done < "$WORK/commits"
  if [ -z "$bf_commit" ]; then
    # No template change in this release: the commit that set the version has its template.
    # Kit commits from before the template moved into the plugin carry none and are skipped.
    git -C "$KIT" log --format=%H -- plugins/coding-kit/.claude-plugin/plugin.json > "$WORK/bumps"
    while IFS= read -r bf_c; do
      git -C "$KIT" cat-file -e "$bf_c:plugins/coding-kit/template/MANIFEST.md" 2> /dev/null \
        || continue
      if [ "$(version_at "$KIT" "$bf_c")" = "$WANT" ]; then
        bf_commit=$bf_c
        break
      fi
    done < "$WORK/bumps"
  fi
  [ -n "$bf_commit" ] || die "no template of version $WANT in the history of $KIT (shallow clone?)"
  mkdir -p "$WORK/x" "$OUT"
  git -C "$KIT" archive "$bf_commit" plugins/coding-kit/template | (cd "$WORK/x" && tar -xf -)
  mv "$WORK/x/plugins/coding-kit/template" "$OUT/template"
  if git -C "$KIT" cat-file -e "$bf_commit:plugins/coding-kit/.claude-plugin/plugin.json" 2> /dev/null; then
    mkdir -p "$OUT/.claude-plugin"
    git -C "$KIT" show "$bf_commit:plugins/coding-kit/.claude-plugin/plugin.json" \
      > "$OUT/.claude-plugin/plugin.json"
  fi
  printf '%s\t%s\n' "$OUT/template" "$bf_commit"
}

# --- zones ----------------------------------------------------------------------

# A zone marker or the slot opening on a line of its own: the files zones looks at.
ZONE_LINE_RE='^[[:space:]]*<!--[[:space:]]*(/?section:[a-z0-9][a-z0-9-]*|module:coding-standards)[[:space:]]*-->[[:space:]]*$'

# Targets of SEEDS whose rendered or project file has zone markers or the slot, sorted.
zone_targets() {
  (cd "$SEEDS" && find . -type f) | sed 's|^\./||' | LC_ALL=C sort | while IFS= read -r zt_t; do
    if grep -q -E "$ZONE_LINE_RE" "$SEEDS/$zt_t" \
      || { [ -f "$P/$zt_t" ] && grep -q -E "$ZONE_LINE_RE" "$P/$zt_t"; }; then
      printf '%s\n' "$zt_t"
    fi
  done
}

# One target: prints "target<TAB>kind<TAB>name<TAB>state<TAB>from<TAB>to" per block (from
# and to name the files whose diffstat completes the line, "-" for none), writes the
# block files below $ZDIR and, when it applies a block, $WORK/zone.out. Blocks are parsed
# per file as r (render), p (project) and b (base): a marker counts only on a line of its
# own, fragments only inside the first slot. Exit 9: broken markers in the render.
zones_one() {  # TARGET SKIP
  zo_p=
  if [ -f "$P/$1" ]; then zo_p=$P/$1; fi
  zo_b=$(base_of "$1")
  [ -f "$zo_b" ] || zo_b=
  awk -v target="$1" -v skip="$2" -v rf="$SEEDS/$1" -v pf="$zo_p" -v bf="$zo_b" \
    -v zdir="$ZDIR" -v sel="$ZSEL" -v empty="$WORK/empty" -v applied="$WORK/applied" \
    -v o="$WORK/zone.out" -v open="$SLOT_OPEN" -v shut="$SLOT_CLOSE" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function load(f, s,   l, n) {
      n = 0
      while ((getline l < f) > 0) { sub(/\r$/, "", l); L[s, ++n] = l }
      close(f)
      N[s] = n
    }
    # Block marker → MK kind, MN name, MC closing; 0 for any other line.
    function marker(t,   m, c) {
      if (t !~ /^<!--[ \t]*\/?(section|fragment):[a-z0-9][a-z0-9-]*[ \t]*-->$/) return 0
      m = t; sub(/^<!--[ \t]*/, "", m); sub(/[ \t]*-->$/, "", m)
      MC = (substr(m, 1, 1) == "/")
      if (MC) m = substr(m, 2)
      c = index(m, ":"); MK = substr(m, 1, c - 1); MN = substr(m, c + 1)
      return 1
    }
    # A second block of the same kind and name breaks the first.
    function add(s, k, n, from, to, ov, br,   x) {
      if ((s, k, n) in ID) { BR[s, ID[s, k, n]] = 1; return }
      x = ++NB[s]
      K[s, x] = k; NM[s, x] = n; BO[s, x] = from; BC[s, x] = to; OV[s, x] = ov; BR[s, x] = br
      ID[s, k, n] = x
    }
    # Per side s: NB blocks (K kind, NM name, BO/BC marker lines, OV override, BR broken),
    # SO/SC slot lines, SB slot never closed, HS any section marker, FM fragment markers
    # in the slot. (Not NF: that is the field count of awk.)
    function scan(s,   i, t, os, oso, ovs, of, ofo, ovf, inslot) {
      NB[s] = 0; SO[s] = 0; SC[s] = 0; SB[s] = 0; HS[s] = 0; FM[s] = 0
      for (i = 1; i <= N[s]; i++) {
        t = trim(L[s, i])
        if (!SO[s] && t == open) { SO[s] = i; inslot = 1; continue }
        if (inslot && t == shut) {
          SC[s] = i; inslot = 0
          if (of != "") { add(s, "fragment", of, 0, 0, 0, 1); of = "" }
          continue
        }
        if (marker(t)) {
          if (MK == "section") {
            HS[s] = 1
            if (!MC && os == "") { os = MN; oso = i; ovs = 0 }
            else if (MC && os == MN) { add(s, "section", MN, oso, i, ovs, 0); os = "" }
            else {
              if (os != "") add(s, "section", os, 0, 0, 0, 1)
              add(s, "section", MN, 0, 0, 0, 1); os = ""
            }
          } else if (inslot) {
            FM[s]++
            if (!MC && of == "") { of = MN; ofo = i; ovf = 0 }
            else if (MC && of == MN) { add(s, "fragment", MN, ofo, i, ovf, 0); of = "" }
            else {
              if (of != "") add(s, "fragment", of, 0, 0, 0, 1)
              add(s, "fragment", MN, 0, 0, 0, 1); of = ""
            }
          }
          continue
        }
        if (t ~ /^<!--[ \t]*override:.*-->$/) {
          if (os != "") ovs = 1
          if (of != "") ovf = 1
        }
      }
      if (os != "") add(s, "section", os, 0, 0, 0, 1)
      if (of != "") add(s, "fragment", of, 0, 0, 0, 1)
      if (inslot) SB[s] = 1
    }
    function same(a, i, b, j,   n, x) {
      n = BC[a, i] - BO[a, i]
      if (n != BC[b, j] - BO[b, j]) return 0
      for (x = 1; x < n; x++) if (L[a, BO[a, i] + x] != L[b, BO[b, j] + x]) return 0
      return 1
    }
    # Content of a block (without its markers) → file F.
    function dump(s, i, f,   x) {
      printf "" > f
      for (x = BO[s, i] + 1; x < BC[s, i]; x++) print L[s, x] > f
      close(f)
    }
    # A block with its markers → the result.
    function emit(i,   x) {
      for (x = BO["r", i]; x <= BC["r", i]; x++) print L["r", x] > o
    }
    BEGIN {
      OFS = "\t"
      load(rf, "r"); scan("r")
      if (SB["r"]) exit 9
      for (i = 1; i <= NB["r"]; i++) if (BR["r", i]) exit 9
      hasp = (pf != "")
      if (hasp) { load(pf, "p"); scan("p") }
      if (bf != "") { load(bf, "b"); scan("b") }

      for (i = 1; i <= NB["r"]; i++) {
        k = K["r", i]; n = NM["r", i]
        j = (("p", k, n) in ID) ? ID["p", k, n] : 0
        tf = zdir "/" k "/" n ".template"; pf2 = zdir "/" k "/" n ".project"
        from = "-"; to = "-"
        if (skip == 1) st = "skipped"
        else if (!hasp) st = "no-file"
        else if (k == "fragment" && SB["p"]) st = "broken"
        else if (k == "fragment" && !SO["p"]) { st = "unmarked"; dump("r", i, tf) }
        else if (j && BR["p", j]) st = "broken"
        else if (j && OV["p", j]) {
          st = "override"
          dump("r", i, tf); dump("p", j, pf2)
          # Fragments only: what the template changed since the base.
          if (k == "fragment" && (("b", k, n) in ID) && !BR["b", ID["b", k, n]]) {
            from = zdir "/" k "/" n ".base"; to = tf
            dump("b", ID["b", k, n], from)
          }
        }
        else if (j && same("r", i, "p", j)) st = "identical"
        else if (j) { st = "differs"; dump("r", i, tf); dump("p", j, pf2); from = pf2; to = tf }
        else if (k == "fragment") { st = "new"; dump("r", i, tf); from = empty; to = tf }
        else { st = HS["p"] ? "opted-out" : "unmarked"; dump("r", i, tf) }
        if ((st == "differs" || st == "new") && (sel == "" || index(sel, " " n " "))) {
          AP[i] = 1; napplied++
          print n >> applied
        }
        print target, k, n, st, from, to
      }
      for (j = 1; j <= NB["p"]; j++) {
        k = K["p", j]; n = NM["p", j]
        if (("r", k, n) in ID) continue
        if (skip == 1) st = "skipped"
        else if (BR["p", j]) st = "broken"
        else { st = "local"; dump("p", j, zdir "/" k "/" n ".project") }
        print target, k, n, st, "-", "-"
      }
      close(applied)
      if (!napplied) exit 0

      # Differing blocks are replaced in place; a new fragment goes behind its nearest
      # predecessor in the render order that is in the slot (or arrives with it), without
      # one to the start of the slot.
      for (i = 1; i <= NB["r"]; i++) {
        if (!AP[i]) continue
        k = K["r", i]; n = NM["r", i]
        if (("p", k, n) in ID) { REPL[BO["p", ID["p", k, n]]] = i; continue }
        anchor = SO["p"]
        for (x = i - 1; x >= 1; x--) {
          if (K["r", x] != "fragment") continue
          if (("p", "fragment", NM["r", x]) in ID) {
            y = ID["p", "fragment", NM["r", x]]
            if (!BR["p", y]) { anchor = BC["p", y]; break }
          } else if (AP[x]) { anchor = ANC[x]; break }
        }
        ANC[i] = anchor
        G[anchor, ++GN[anchor]] = i
      }
      # In a slot without fragments the new ones replace the placeholder text.
      placeholder = (FM["p"] == 0)
      printf "" > o
      for (i = 1; i <= N["p"]; i++) {
        if (placeholder && i == SO["p"] && GN[i]) {
          print L["p", i] > o
          for (m = 1; m <= GN[i]; m++) { if (m > 1) print "" > o; emit(G[i, m]) }
          i = SC["p"]
          print L["p", i] > o
          continue
        }
        if (i in REPL) {
          x = REPL[i]
          print L["p", i] > o
          for (y = BO["r", x] + 1; y < BC["r", x]; y++) print L["r", y] > o
          i = BC["p", ID["p", K["r", x], NM["r", x]]]
        }
        print L["p", i] > o
        for (m = 1; m <= GN[i]; m++) {
          if (i == SO["p"]) { emit(G[i, m]); print "" > o }
          else { print "" > o; emit(G[i, m]) }
        }
      }
      close(o)
    }'
}

zones() {
  [ $# -ge 3 ] || usage
  P=$1 SEEDS=$2 OUT=$3
  shift 3
  set_paths "$P"
  [ -d "$P" ] || die "project not found: $P"
  [ -d "$SEEDS" ] || die "rendered template not found: $SEEDS"
  check_out_dir "$OUT"
  ZSEL=
  for zs_name in "$@"; do
    case $zs_name in
      '' | *[!a-z0-9-]*) die "invalid block name '$zs_name' — pass each name as an argument of its own" ;;
    esac
    ZSEL="$ZSEL $zs_name"
  done
  if [ -n "$ZSEL" ]; then ZSEL="$ZSEL "; fi
  setup_work
  load_registry
  : > "$WORK/empty"
  : > "$WORK/applied"
  ZDIR=$OUT/.zones
  mkdir -p "$ZDIR/section" "$ZDIR/fragment"
  zone_targets > "$WORK/zone-targets"
  while IFS= read -r zn_t; do
    zn_skip=0
    if [ "$(kind_of "$zn_t")" = skip ]; then zn_skip=1; fi
    rm -f "$WORK/zone.out"
    zones_one "$zn_t" "$zn_skip" > "$WORK/zone.tsv" \
      || die "$SEEDS/$zn_t: unbalanced, nested or duplicate section or fragment markers"
    if [ -f "$WORK/zone.out" ]; then
      mkdir -p "$(dirname "$OUT/$zn_t")"
      mv "$WORK/zone.out" "$OUT/$zn_t"
    fi
    while IFS="$TAB" read -r zn_tt zn_k zn_n zn_s zn_from zn_to; do
      zn_stat=-
      if [ "$zn_from" != - ]; then
        zn_stat=$(diffstat "$zn_from" "$zn_to")
        if [ "$zn_stat" = "+0 -0" ]; then zn_stat=-; fi
      fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$zn_tt" "$zn_k" "$zn_n" "$zn_s" "$zn_stat"
    done < "$WORK/zone.tsv"
  done < "$WORK/zone-targets"
  # Word splitting of the name list is intended.
  for zs_name in $ZSEL; do
    grep -qxF -- "$zs_name" "$WORK/applied" \
      || die "$zs_name: no differing or new block of that name to apply"
  done
}

# --- detect ---------------------------------------------------------------------

# Normalized PyPI name (lowercase, each run of -, _ and . as one -), shared by the
# readers and the declarations.
AWK_PYPI='function pypi(s) { s = tolower(s); gsub(/[-_.]+/, "-", s); return s }'

# Signals TEMPLATE declares → "kind<TAB>name<TAB>signal": the Signals: line of each
# MODULE.md, then the trigger column of the fragment catalog (characteristics have none).
declared_signals() {
  for ds_doc in "$TEMPLATE"/modules/*/MODULE.md; do
    [ -f "$ds_doc" ] || continue
    ds_name=${ds_doc%/MODULE.md}
    ds_name=${ds_name##*/}
    awk -v name="$ds_name" '
      /^[*]*Signals:/ {
        s = substr($0, index($0, "Signals:") + length("Signals:"))
        sub(/^[* \t]+/, "", s)
        j = index(s, " — ")
        if (!j) j = index(s, " – ")
        if (j) s = substr(s, 1, j - 1)
        gsub(/^[ \t]+|[ \t]+$/, "", s)
        if (s == "" || s == "(none)" || s == "none") exit
        n = split(s, parts, ",")
        for (i = 1; i <= n; i++) {
          p = parts[i]; gsub(/[ \t`]/, "", p)
          if (p != "") print "module\t" name "\t" p
        }
        exit
      }' "$ds_doc"
  done
  awk '
    /^## / { insec = ($0 ~ /^## Catalog[ \t]*$/); next }
    insec && /^\|[ \t]*`[a-z0-9-]+`[ \t]*\|/ {
      n = split($0, c, "|")
      name = c[2]; gsub(/[ \t`]/, "", name)
      trig = c[n - 1]
      if (index(trig, "*characteristic:*")) next
      while (match(trig, /`[^`]+`/)) {
        print "fragment\t" name "\t" substr(trig, RSTART + 1, RLENGTH - 2)
        trig = substr(trig, RSTART + RLENGTH)
      }
    }' "$TEMPLATE/modules/standards/README.md"
}

# Declarations on stdin with a known type each; PyPI names normalized.
typed_declarations() {
  awk -F "$TAB" -v types=" $SIGNAL_TYPES " "$AWK_PYPI"'
    {
      t = $3; sub(/:.*/, "", t); v = substr($3, length(t) + 2)
      if (!index($3, ":") || v == "" || !index(types, " " t " ")) {
        print "template-sync: " $1 " " $2 ": invalid signal \"" $3 "\"" | "cat 1>&2"
        bad = 1
        next
      }
      if (t == "pypi") v = pypi(v)
      print $1 "\t" $2 "\t" t ":" v
    }
    END { close("cat 1>&2"); exit bad }'
}

# package.json: the names in dependencies, devDependencies, peerDependencies and
# optionalDependencies. A small tokenizer, so minified JSON reads as well.
npm_signals() {  # FILE REL
  awk -v rel="$2" '
    { buf = buf $0 "\n" }
    END {
      deps["dependencies"] = 1; deps["devDependencies"] = 1
      deps["peerDependencies"] = 1; deps["optionalDependencies"] = 1
      n = length(buf); d = 0; i = 1
      while (i <= n) {
        c = substr(buf, i, 1)
        if (c == "\"") {
          s = ""; i++
          while (i <= n) {
            c = substr(buf, i, 1)
            if (c == "\\") { s = s substr(buf, i, 2); i += 2; continue }
            if (c == "\"") break
            s = s c; i++
          }
          if (obj[d] && want[d]) {
            key[d] = s; want[d] = 0
            if (d == 2 && (key[1] in deps)) print "npm:" s "\t" rel
          }
        } else if (c == "{") { d++; obj[d] = 1; want[d] = 1 }
        else if (c == "[") { d++; obj[d] = 0 }
        else if (c == "}" || c == "]") { if (d > 0) d-- }
        else if (c == "," && obj[d]) want[d] = 1
        i++
      }
    }' "$1"
}

# pyproject.toml: PEP 508 names in dependencies of [project], in
# [project.optional-dependencies] and [dependency-groups], and the keys of the Poetry
# dependency tables (without python). Strings inside inline tables are not names.
pyproject_signals() {  # FILE REL
  awk -v rel="$2" "$AWK_PYPI"'
    function emit(spec) {
      if (match(spec, /^[ \t]*[A-Za-z0-9][A-Za-z0-9._-]*/)) {
        spec = substr(spec, RSTART, RLENGTH); gsub(/[ \t]/, "", spec)
        print "pypi:" pypi(spec) "\t" rel
      }
    }
    # Counts inline-table braces in TEXT; 1 when the array closes there.
    function closes(text,   i, ch) {
      for (i = 1; i <= length(text); i++) {
        ch = substr(text, i, 1)
        if (ch == "{") brace++
        else if (ch == "}") brace--
        else if (ch == "]" && brace <= 0) return 1
      }
      return 0
    }
    # Names in one line of an array; 1 while the array goes on. emit() runs match()
    # itself, so the position of the string is kept before.
    function collect(line,   pre, h, at, len) {
      while (match(line, /"[^"]*"|\047[^\047]*\047/)) {
        at = RSTART; len = RLENGTH
        pre = substr(line, 1, at - 1)
        if ((h = index(pre, "#"))) return !closes(substr(pre, 1, h - 1))
        if (closes(pre)) return 0
        if (brace <= 0) emit(substr(line, at + 1, len - 2))
        line = substr(line, at + len)
      }
      sub(/#.*/, "", line)
      return !closes(line)
    }
    { sub(/\r$/, "") }
    inarr { inarr = collect($0); next }
    /^[ \t]*\[/ {
      t = $0; sub(/^[ \t]*\[+[ \t]*/, "", t); sub(/[ \t]*\].*$/, "", t); gsub(/["\047 ]/, "", t)
      tbl = t
      poetry = (tbl == "tool.poetry.dependencies" || tbl == "tool.poetry.dev-dependencies" \
        || tbl ~ /^tool\.poetry\.group\.[^.]+\.dependencies$/)
      next
    }
    /^[ \t]*#/ || !/=/ { next }
    {
      k = substr($0, 1, index($0, "=") - 1); gsub(/[ \t"\047]/, "", k)
      v = substr($0, index($0, "=") + 1)
      if (poetry) {
        if (k != "python") print "pypi:" pypi(k) "\t" rel
        next
      }
      if ((tbl == "project" && k == "dependencies") || tbl == "project.optional-dependencies" \
        || tbl == "dependency-groups") {
        if (sub(/^[ \t]*\[/, "", v)) { brace = 0; inarr = collect(v) }
      }
    }' "$1"
}

# requirements*.txt: one requirement per line; options (-r, -e …), URLs and paths are not
# names.
requirements_signals() {  # FILE REL
  awk -v rel="$2" "$AWK_PYPI"'
    { sub(/\r$/, ""); sub(/^#.*/, ""); sub(/[ \t]#.*/, "") }
    /^[ \t]*-/ { next }
    match($0, /^[ \t]*[A-Za-z0-9][A-Za-z0-9._-]*/) {
      name = substr($0, RSTART, RLENGTH); gsub(/[ \t]/, "", name)
      if (substr($0, RSTART + RLENGTH) ~ /^[:+]/) next
      print "pypi:" pypi(name) "\t" rel
    }' "$1"
}

# go.mod: required module paths, except // indirect; a path with a major-version suffix
# also counts without it.
gomod_signals() {  # FILE REL
  awk -v rel="$2" '
    function emit(p) {
      print "go:" p "\t" rel
      if (sub(/\/v[0-9]+$/, "", p)) print "go:" p "\t" rel
    }
    { sub(/\r$/, "") }
    inreq && /^[ \t]*\)/ { inreq = 0; next }
    inreq {
      if (index($0, "// indirect")) next
      sub(/\/\/.*/, "")
      if (NF >= 2) emit($1)
      next
    }
    /^[ \t]*require[ \t]*\(/ { inreq = 1; next }
    /^[ \t]*require[ \t]/ {
      if (index($0, "// indirect")) next
      sub(/\/\/.*/, "")
      if (NF >= 3) emit($2)
    }' "$1"
}

# mise.toml: the keys of [tools] and the names of [tools.NAME] tables.
mise_signals() {  # FILE REL
  awk -v rel="$2" '
    { sub(/\r$/, "") }
    /^[ \t]*\[/ {
      t = $0; sub(/^[ \t]*\[[ \t]*/, "", t); sub(/[ \t]*\].*$/, "", t)
      intools = (t == "tools")
      if (substr(t, 1, 6) == "tools.") {
        k = substr(t, 7); gsub(/["\047]/, "", k)
        print "tool:" k "\t" rel
      }
      next
    }
    intools && /=/ && !/^[ \t]*#/ {
      k = substr($0, 1, index($0, "=") - 1)
      gsub(/^[ \t]+|[ \t]+$/, "", k); gsub(/^["\047]|["\047]$/, "", k)
      if (k != "") print "tool:" k "\t" rel
    }' "$1"
}

# Manifest signals of FILE, read as the project path REL.
manifest_signals() {  # FILE REL
  case ${2##*/} in
    package.json) npm_signals "$1" "$2" ;;
    pyproject.toml) pyproject_signals "$1" "$2" ;;
    requirements*.txt) requirements_signals "$1" "$2" ;;
    go.mod) gomod_signals "$1" "$2" ;;
    mise.toml | .mise.toml) mise_signals "$1" "$2" ;;
  esac
}

# Declared file globs that match a path of LIST → "file:GLOB<TAB>path". A glob without
# / matches the file name, one with / the whole path; * and ? as in sh, also across /.
file_signals() {  # LIST
  awk -F "$TAB" -v decl="$WORK/declared.tsv" '
    function re(g,   o, i, j, c, cls) {
      o = "^"
      for (i = 1; i <= length(g); i++) {
        c = substr(g, i, 1)
        if (c == "*") o = o ".*"
        else if (c == "?") o = o "."
        else if (c == "[" && (j = index(substr(g, i + 1), "]")) > 1) {
          cls = substr(g, i + 1, j - 1)
          if (substr(cls, 1, 1) == "!") cls = "^" substr(cls, 2)
          o = o "[" cls "]"; i += j
        } else if (index("\\^$.|+(){}[]", c)) o = o "\\" c
        else o = o c
      }
      return o "$"
    }
    FILENAME == decl {
      if ($3 ~ /^file:/) {
        g = substr($3, 6)
        if (!(g in rx)) { rx[g] = re(g); whole[g] = index(g, "/") > 0 }
      }
      next
    }
    {
      b = $0; sub(/.*\//, "", b)
      for (g in rx) if ((whole[g] ? $0 : b) ~ rx[g]) print "file:" g "\t" $0
    }' "$WORK/declared.tsv" "$1"
}

# Files of PROJECT: "worktree" = tracked plus untracked and not ignored, without deleted
# ones; "head" = the files of HEAD. The snapshot never counts.
file_list() {  # PROJECT worktree|head
  if [ "$2" = head ]; then
    git -C "$1" -c core.quotePath=false ls-tree -r --name-only HEAD
  else
    git -C "$1" -c core.quotePath=false ls-files --cached --others --exclude-standard \
      | LC_ALL=C sort -u > "$WORK/fl.all"
    git -C "$1" -c core.quotePath=false ls-files --deleted | LC_ALL=C sort -u > "$WORK/fl.del"
    LC_ALL=C comm -23 "$WORK/fl.all" "$WORK/fl.del"
  fi | awk -v snap="$SNAP_DIR/" 'index($0, snap) != 1'
}

# Signals of PROJECT in MODE (worktree or head) → "signal<TAB>path": manifest entries,
# then the declared file globs that match a path.
scan_signals() {  # PROJECT MODE
  file_list "$1" "$2" > "$WORK/files.$2"
  grep -E '(^|/)(package\.json|pyproject\.toml|requirements[^/]*\.txt|go\.mod|\.?mise\.toml)$' \
    "$WORK/files.$2" > "$WORK/manifests.$2" || true
  while IFS= read -r ss_rel; do
    if [ "$2" = head ]; then
      git -C "$1" show "HEAD:./$ss_rel" > "$WORK/blob" 2> /dev/null || continue
      manifest_signals "$WORK/blob" "$ss_rel"
    else
      [ -f "$1/$ss_rel" ] || continue
      manifest_signals "$1/$ss_rel" "$ss_rel"
    fi
  done < "$WORK/manifests.$2"
  file_signals "$WORK/files.$2"
}

# SIGNAL arguments → "signal<TAB>given"; a file signal names a planned path and is
# matched against the declared globs like a file of the project.
given_signals() {  # SIGNAL…
  : > "$WORK/given.files"
  for gs_sig in "$@"; do
    gs_type=${gs_sig%%:*}
    gs_val=${gs_sig#*:}
    case " $SIGNAL_TYPES " in
      *" $gs_type "*) ;;
      *) die "signal '$gs_sig': type must be one of: $SIGNAL_TYPES" ;;
    esac
    [ "$gs_type" != "$gs_sig" ] && [ -n "$gs_val" ] \
      || die "signal '$gs_sig' needs a value (type:value)"
    case $gs_type in
      file) printf '%s\n' "$gs_val" >> "$WORK/given.files" ;;
      pypi) printf 'pypi:%s\tgiven\n' "$gs_val" | awk -F "$TAB" "$AWK_PYPI"'
              { sub(/^pypi:/, "", $1); print "pypi:" pypi($1) "\t" $2 }' ;;
      go)
        printf '%s\tgiven\n' "$gs_sig"
        case $gs_val in
          */v[0-9] | */v[0-9][0-9]) printf 'go:%s\tgiven\n' "${gs_val%/v*}" ;;
        esac
        ;;
      *) printf '%s\tgiven\n' "$gs_sig" ;;
    esac
  done
  file_signals "$WORK/given.files"
}

# Rules rows of the registry that decline a proposal → "module:NAME", "fragment:NAME"
# or "tool:NAME".
declined_rows() {
  [ -f "$REG_PATH" ] || return 0
  awk '
    /^#+[ \t]/ { insec = ($0 ~ /^## Rules[ \t]*$/); next }
    insec && /^\|/ {
      split($0, c, "|"); r = c[2]; gsub(/[ \t`]/, "", r)
      if (r ~ /^(module|fragment):[a-z0-9][a-z0-9-]*$/ ||
          r ~ /^tool:[A-Za-z0-9][A-Za-z0-9._-]*$/) print r
    }' "$REG_PATH"
}

# Tools TEMPLATE has a convention for → "tool:NAME" lines: [tools] of the core mise.toml
# and of each module's mise.part.toml, then every declared tool: signal.
known_tools() {
  for kt_toml in "$TEMPLATE/core/mise.toml" "$TEMPLATE"/modules/*/mise.part.toml; do
    [ -f "$kt_toml" ] || continue
    mise_signals "$kt_toml" template | cut -f1
  done
  awk -F "$TAB" '$3 ~ /^tool:/ { print $3 }' "$WORK/declared.tsv"
}

# Tools of $WORK/project.lst that TEMPLATE has no convention for, with their state. A
# name with a backend prefix (npm:…, cargo:…) installs a package, not a language, and
# never counts.
report_tools() {
  known_tools > "$WORK/known"
  awk -F "$TAB" -v known="$WORK/known" -v dec="$WORK/declined" '
    FILENAME == known { k[$1] = 1; next }
    FILENAME == dec { d[$1] = 1; next }
    substr($1, 1, 5) == "tool:" {
      n = substr($1, 6)
      if (n == "" || index(n, ":") || ($1 in k)) next
      if (!(n in cnt)) { first[n] = $2; names[++nn] = n }
      cnt[n]++
    }
    END {
      for (i = 1; i <= nn; i++) {
        n = names[i]
        more = (cnt[n] > 1) ? " +" (cnt[n] - 1) : ""
        st = (("tool:" n) in d) ? "declined" : "unknown"
        print "tool\t" n "\t" st "\ttool:" n " (" first[n] more ")"
      }
    }' "$WORK/known" "$WORK/declined" "$WORK/project.lst" | LC_ALL=C sort -t "$TAB" -k2,2
}

# Hits of $WORK/project.tsv against $WORK/declared.tsv with their state; MODULE empty =
# no module check. Evidence per declared signal: first path (sorted) and how many more.
report_hits() {  # MODULE
  LC_ALL=C sort -u "$WORK/project.tsv" > "$WORK/project.lst"
  awk -F "$TAB" -v module="$1" -v cov="$WORK/covered" -v dec="$WORK/declined" \
    -v decl="$WORK/declared.tsv" '
    # covered by the answers (module) or the slot (fragment), else declined or missing.
    function state(kind, name) {
      if ((kind == "module") ? (name == module) : (name in covered)) return "covered"
      if ((kind ":" name) in declined) return "declined"
      return "missing"
    }
    FILENAME == cov { covered[$1] = 1; next }
    FILENAME == dec { declined[$1] = 1; next }
    FILENAME == decl {
      k = $1 "\t" $2
      if (!(k in seen)) { seen[k] = 1; keys[++nk] = k }
      sigs[k, ++ns[k]] = $3
      bysig[$3] = bysig[$3] "\n" k
      next
    }
    $1 in bysig {
      m = split(substr(bysig[$1], 2), ks, "\n")
      for (i = 1; i <= m; i++) {
        e = ks[i] SUBSEP $1
        if (!(e in cnt)) first[e] = $2
        cnt[e]++
      }
    }
    END {
      for (x = 1; x <= nk; x++) {
        k = keys[x]; split(k, kn, "\t")
        if (kn[1] == "module" && module == "") continue
        ev = ""
        for (j = 1; j <= ns[k]; j++) {
          e = k SUBSEP sigs[k, j]
          if (!(e in cnt)) continue
          more = (cnt[e] > 1) ? " +" (cnt[e] - 1) : ""
          ev = ev (ev == "" ? "" : ", ") sigs[k, j] " (" first[e] more ")"
        }
        if (ev != "") print kn[1] "\t" kn[2] "\t" state(kn[1], kn[2]) "\t" ev
      }
    }' "$WORK/covered" "$WORK/declined" "$WORK/declared.tsv" "$WORK/project.lst" \
    | LC_ALL=C sort -t "$TAB" -k1,1r -k2,2
}

detect() {
  [ $# -ge 2 ] || usage
  TEMPLATE=$1 P=$2
  shift 2
  set_paths "$P"
  [ -f "$TEMPLATE/MANIFEST.md" ] || die "no MANIFEST.md in $TEMPLATE"
  [ -d "$P" ] || die "project not found: $P"
  [ "$CHANGED" -eq 0 ] || [ $# -eq 0 ] || die "--changed reads the project, it takes no signals"
  setup_work
  declared_signals | typed_declarations > "$WORK/declared.tsv" \
    || die "invalid signal declarations in $TEMPLATE"

  if [ $# -gt 0 ]; then
    given_signals "$@" > "$WORK/project.tsv"
  else
    git -C "$P" rev-parse --git-dir > /dev/null 2>&1 || die "$P is not a git repository"
    scan_signals "$P" worktree > "$WORK/project.tsv"
    if [ "$CHANGED" -eq 1 ]; then
      if git -C "$P" rev-parse --verify -q HEAD > /dev/null; then
        scan_signals "$P" head > "$WORK/head.tsv"
      else
        : > "$WORK/head.tsv"
      fi
      awk -F "$TAB" -v old="$WORK/head.tsv" 'FILENAME == old { had[$1] = 1; next } !($1 in had)' \
        "$WORK/head.tsv" "$WORK/project.tsv" > "$WORK/added.tsv"
      mv "$WORK/added.tsv" "$WORK/project.tsv"
    fi
  fi

  dt_module=
  if [ -f "$ANS_PATH" ]; then
    load_answers "$ANS_PATH" > "$WORK/values.tsv" || die "invalid answers file: $ANS_PATH"
    dt_module=$(value_of MODULE) || die "answers: MODULE is missing"
  else
    printf 'template-sync: no answers file %s — module check skipped\n' "$ANS_PATH" >&2
  fi
  part_rows > "$WORK/parts.tsv"
  : > "$WORK/covered"
  dt_slot=$(part_target CODING-STANDARDS.part.md) || dt_slot=
  if [ -n "$dt_slot" ] && [ -f "$P/$dt_slot" ] && slot_of "$P/$dt_slot" "$WORK/slot"; then
    sed -n 's/^[[:space:]]*<!--[[:space:]]*fragment:\([a-z0-9-]*\)[[:space:]]*-->[[:space:]]*$/\1/p' \
      "$WORK/slot" > "$WORK/covered"
  fi
  # What the module of the answers declares comes with the render, marker or not.
  case $dt_module in
    '' | standards | *[!a-z0-9-]*) ;;
    *)
      MODDIR=$TEMPLATE/modules/$dt_module
      if [ -f "$MODDIR/MODULE.md" ]; then declared_fragments >> "$WORK/covered"; fi
      ;;
  esac
  declined_rows > "$WORK/declined"
  report_hits "$dt_module"
  report_tools
}

cmd=${1:-}
[ $# -eq 0 ] || shift
parse_opts "$cmd" "$@"
shift "$OPTS_SHIFT"
case $cmd in
  render) render "$@" ;;
  status) status "$@" ;;
  changed) changed "$@" ;;
  merge) merge "$@" ;;
  snapshot) snapshot "$@" ;;
  base-from-history) base_from_history "$@" ;;
  zones) zones "$@" ;;
  detect) detect "$@" ;;
  *) usage ;;
esac
