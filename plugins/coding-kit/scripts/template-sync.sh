#!/bin/sh
# template-sync.sh — deterministic helper behind the coding-kit template contract
# (template/MANIFEST.md). Skills call it with resolved paths:
#
#   sh template-sync.sh render [--seeds] TEMPLATE ANSWERS OUT
#
# render  Writes the pure instantiation of TEMPLATE for the project that ANSWERS
#         describes (.claude/template-answers, MANIFEST § Answers) into OUT, which must
#         be missing or empty, and prints one line per written file:
#           <target> TAB <managed|seed> TAB <core|module>
#         Without --seeds only managed targets are written. With --seeds the seed files
#         follow as raw instantiation: concretising template:adapt spots and the license
#         text stays with the calling skill.
#
# POSIX sh plus awk, sed, find, sort and mktemp. No network, no writes outside OUT and a
# private temp directory. Exit status 1 on a contract violation, 2 on wrong usage.

set -eu

TAB=$(printf '\t')

die() {
  printf 'template-sync: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'usage: sh template-sync.sh render [--seeds] TEMPLATE ANSWERS OUT\n' >&2
  exit 2
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
  if awk -v content="$2" '
    BEGIN { open = "<!-- module:coding-standards -->"; shut = "<!-- /module:coding-standards -->" }
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
  if [ -e "$OUT" ]; then
    [ -d "$OUT" ] || die "$OUT exists and is not a directory"
    [ -z "$(ls -A "$OUT")" ] || die "$OUT is not empty"
  fi

  WORK=$(mktemp -d "${TMPDIR:-/tmp}/template-sync.XXXXXX") || die "cannot create a temp directory"
  trap 'rm -rf "$WORK"' EXIT
  trap 'exit 1' HUP INT TERM

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

case ${1:-} in
  render)
    shift
    render "$@"
    ;;
  *) usage ;;
esac
