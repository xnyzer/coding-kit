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
#   status [--base DIR] PROJECT
#       Compares every target of the base snapshot (.claude/template-base/<target>.base)
#       with the project. Line: <target> <unchanged|deviates|missing> <registry> <+a -d>.
#       --base takes the bases from a rendered DIR instead (no suffix) — for a project
#       that has no snapshot yet; merge accepts it the same way.
#   changed PROJECT
#       Like status, for the targets the working tree touches (against HEAD, plus
#       untracked files) — the backstop of /step-done. Edits below the snapshot itself
#       come out as <path> snapshot-edited.
#   merge [--base DIR] PROJECT SOLL OUT
#       Three-way merge per target: base snapshot, project, rendered SOLL. Results go to
#       OUT (missing or empty). Line: <target> <class> <conflicts> <registry>, classes:
#       identical, template-only, project-only, merged, caught-up (the result equals
#       the template although the project deviated — the template has caught up),
#       conflict, kept (keep row: conflicts resolved to the project), two-way (no base),
#       new, missing (project deleted it), removed (no longer rendered), skipped.
#   snapshot PROJECT SOLL TARGET…
#       Sets the base of each TARGET to its rendered version; a TARGET that SOLL no
#       longer has loses its base. Line: <target> <set|removed>.
#   base-from-history KIT VERSION OUT
#       Exports the template of VERSION from the git history of a coding-kit checkout
#       into OUT/template (missing or empty OUT). Line: <template dir> <commit>.
#
# <registry> is the kind of the matching row in the Files table of
# .claude/convention-overrides.md: skip, keep, adapt, registered (row without kind) or
# none. Comparisons ignore CR line ends, a missing final newline and the content of the
# module:coding-standards slot (fragments are synced one by one, never with the file).
#
# POSIX sh plus git, awk, sed, find, sort, tar and mktemp. No network, no writes outside
# the named directories and a private temp directory. Exit status 1 on a contract
# violation, 2 on wrong usage, 3 when PROJECT has no base snapshot (status, changed).

set -eu

TAB=$(printf '\t')
SNAP_DIR=.claude/template-base
REGISTRY=.claude/convention-overrides.md
SLOT_OPEN='<!-- module:coding-standards -->'
SLOT_CLOSE='<!-- /module:coding-standards -->'
BASE_DIR=

die() {
  printf 'template-sync: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat >&2 << 'EOF'
usage: sh template-sync.sh render [--seeds] TEMPLATE ANSWERS OUT
       sh template-sync.sh status [--base DIR] PROJECT
       sh template-sync.sh changed PROJECT
       sh template-sync.sh merge [--base DIR] PROJECT SOLL OUT
       sh template-sync.sh snapshot PROJECT SOLL TARGET...
       sh template-sync.sh base-from-history KIT VERSION OUT
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

# Slot content: language fragment, declared catalog fragments, FRAGMENTS — each trimmed
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
  seeds=0
  if [ "${1:-}" = "--seeds" ]; then
    seeds=1
    shift
  fi
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
load_registry() {  # PROJECT
  : > "$WORK/registry.tsv"
  [ -f "$1/$REGISTRY" ] || return 0
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
    END { close("cat 1>&2"); exit bad }' "$1/$REGISTRY" > "$WORK/registry.tsv" \
    || die "invalid Files table in $1/$REGISTRY"
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

# Targets with a base in PROJECT's snapshot, sorted.
snapshot_targets() {  # PROJECT
  (cd "$1/$SNAP_DIR" && find . -type f -name '*.base') | sed 's|^\./||; s|\.base$||' | LC_ALL=C sort
}

# Where the base of TARGET lives: the snapshot of $P, or $BASE_DIR when --base was given.
base_of() {  # TARGET
  if [ -n "$BASE_DIR" ]; then
    printf '%s\n' "$BASE_DIR/$1"
  else
    printf '%s\n' "$P/$SNAP_DIR/$1.base"
  fi
}

# Targets that have a base, sorted.
base_targets() {
  if [ -n "$BASE_DIR" ]; then
    (cd "$BASE_DIR" && find . -type f) | sed 's|^\./||' | LC_ALL=C sort
  elif [ -d "$P/$SNAP_DIR" ]; then
    snapshot_targets "$P"
  fi
}

# Optional leading "--base DIR" of status and merge; sets BASE_DIR, ARGS_SHIFT.
parse_base() {
  BASE_DIR=
  ARGS_SHIFT=0
  if [ "${1:-}" = --base ]; then
    [ $# -ge 2 ] || usage
    [ -d "$2" ] || die "base directory not found: $2"
    BASE_DIR=$2
    ARGS_SHIFT=2
  fi
}

require_snapshot() {  # PROJECT
  [ -d "$1" ] || die "project not found: $1"
  if [ ! -d "$1/$SNAP_DIR" ]; then
    printf 'template-sync: no base snapshot in %s (%s)\n' "$1" "$SNAP_DIR" >&2
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
  parse_base "$@"
  shift "$ARGS_SHIFT"
  [ $# -eq 1 ] || usage
  P=$1
  if [ -z "$BASE_DIR" ]; then require_snapshot "$P"; fi
  [ -d "$P" ] || die "project not found: $P"
  setup_work
  load_registry "$P"
  base_targets > "$WORK/targets.lst"
  while IFS= read -r st_t; do
    compare_line "$st_t"
  done < "$WORK/targets.lst"
}

changed() {
  [ $# -eq 1 ] || usage
  P=$1
  BASE_DIR=
  require_snapshot "$1"
  setup_work
  load_registry "$1"
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
    if [ -f "$1/$SNAP_DIR/$ch_p.base" ]; then compare_line "$ch_p"; fi
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
  parse_base "$@"
  shift "$ARGS_SHIFT"
  [ $# -eq 3 ] || usage
  P=$1 SOLL=$2 OUT=$3
  [ -d "$P" ] || die "project not found: $P"
  [ -d "$SOLL" ] || die "rendered template not found: $SOLL"
  check_out_dir "$OUT"
  setup_work
  load_registry "$P"
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
  [ -d "$P" ] || die "project not found: $P"
  [ -d "$SOLL" ] || die "rendered template not found: $SOLL"
  for sn_t in "$@"; do
    check_target "$sn_t"
    sn_base=$P/$SNAP_DIR/$sn_t.base
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

cmd=${1:-}
[ $# -eq 0 ] || shift
case $cmd in
  render) render "$@" ;;
  status) status "$@" ;;
  changed) changed "$@" ;;
  merge) merge "$@" ;;
  snapshot) snapshot "$@" ;;
  base-from-history) base_from_history "$@" ;;
  *) usage ;;
esac
