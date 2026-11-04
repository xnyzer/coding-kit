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
#   render-global KIT ENV OUT
#       Renders the kit's global rules KIT (global/coding-kit.md of the plugin) with the
#       personal values of ENV (the personal config ~/.claude/coding-kit.env, shell
#       syntax — read, never executed; a missing file has no values) into
#       OUT/rules/coding-kit.md (OUT missing or empty), its path below the Claude config
#       folder. Lines: key <CODING_KIT_NAME> <set|empty|missing> per value the rules read;
#       legacy CODING_KIT_GIT_NOREPLY_EMAIL CODING_KIT_EMAIL_GITHUB <rename|superseded>
#       while the old commit address is set (superseded: the new key is set too); then
#       rendered <target>. An empty or missing value drops its template:optional
#       block: reply-language without CODING_KIT_REPLY_LANGUAGE, level-NAME unless
#       CODING_KIT_EXPLAIN_LEVEL is NAME (a level without a block is refused),
#       explain-note without CODING_KIT_EXPLAIN_NOTE, explain without level and note.
#       zones then takes OUT as SEEDS and the config folder as PROJECT.
#   set-global [--rename-legacy] KIT ENV OUT [NAME=value…]
#       Writes the personal config ENV (a missing file counts as empty) with the given
#       values into OUT/coding-kit.env (OUT missing or empty; mode 600). NAME is a
#       CODING_KIT_ key the global rules read, the default host of new projects
#       (CODING_KIT_DEFAULT_HOST, one of HOSTS) or the commit address of a host
#       (CODING_KIT_EMAIL_<HOST>, see commit-email); its line becomes NAME="value"
#       followed by the comment of that key in KIT. The first assignment of a key (also behind
#       export) is replaced in place and later ones are dropped, a key the file lacks is
#       appended; every other line stays as it is (a missing final newline is added).
#       --rename-legacy moves the old commit address CODING_KIT_GIT_NOREPLY_EMAIL to
#       CODING_KIT_EMAIL_GITHUB (unless that key is set or given) and removes every
#       assignment of the old key; then NAME=value is optional. Lines: set <NAME>
#       <replaced|added>, dropped <NAME>, then written coding-kit.env. Refused: an
#       unknown or repeated NAME, a tab, line break or {{ in a value, a level without a
#       block in KIT.
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
#   snapshot [--seeds] [--snapshot DIR] PROJECT SOLL TARGET…
#       Sets the base of each TARGET to its rendered version; a TARGET that SOLL no
#       longer has loses its base. Line: <target> <set|removed>. A TARGET that is neither
#       rendered nor has a base is refused before anything is written. With --seeds the
#       TARGETs are seed files (SOLL a render with --seeds): their base is
#       <target>.seed, which only zones reads; a TARGET with a managed base is refused.
#   base-from-history KIT VERSION OUT
#       Exports the template of VERSION from the git history of a coding-kit checkout
#       into OUT/template (missing or empty OUT); a release without template changes
#       has the template of the commit that set its version. Line: <template dir> <commit>.
#   zones [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SEEDS OUT [NAME…]
#       Compares the marked blocks of PROJECT with SEEDS (a render with --seeds): the
#       section:NAME zones of the seed files and the fragment:NAME blocks in the
#       module:coding-standards slot. The base of a target is <target>.base of the
#       snapshot, else <target>.seed (snapshot --seeds), or DIR/<target> with --base.
#       Line per block: <target> <section|fragment> <name> <state> <+a -d>, states:
#       identical, differs, override (an override line in the project's block; the count
#       is what the template changed since the base), new (a fragment only SEEDS has, or
#       a zone neither the project nor its base has), opted-out (a zone the base has and
#       the project lost: the user removed its markers), bare (a zone the base lacks
#       whose content stands verbatim in the file outside every zone and the slot),
#       unconfirmed (a zone the project lacks while the file has no base to tell new
#       from opted-out), removed (a zone the project and its base have and SEEDS no
#       longer has), unmarked (the file has no zone markers or no slot at all), local
#       (only the project has it, or a removed zone with an override line), no-file
#       (the project deleted the file: it has a base, or the block is a fragment),
#       new-file (a seed file the project lacks and has no base for: the template added
#       it), broken (unbalanced, nested or duplicate markers), skipped (skip row). A block
#       that neither side has gets no line. OUT/<target> is the project file with every
#       differing, new and removed block applied — only the NAMEs given, if any; for a
#       new-file it is the whole rendered file;
#       opted-out, bare and unconfirmed zones only when named. A differing block is
#       replaced, a removed zone is deleted with its content; a bare zone, and an
#       opted-out one whose content still stands, gets its markers around that text;
#       a new zone goes behind its nearest predecessor of the render order in the file,
#       without one before its nearest successor, without both to the end; a new
#       fragment goes behind its nearest predecessor in the slot (without one to the
#       slot's start) and replaces the placeholder text of a slot without fragments.
#       OUT/.zones/<kind>/<name>.<project|template|base> hold the blocks for the diffs.
#   lock-check PROJECT
#       Checks the mise.lock of PROJECT against lockfile_platforms in [settings] of its
#       mise.toml and the platforms its CI installs on (runs-on of the workflows that
#       use jdx/mise-action). Lines: platforms <list|missing>; ci <platform|unknown>
#       <runs-on> <workflow> per runner, or ci none; lockfile missing. Without the
#       setting or the lock file nothing follows. Then per lock entry or configured
#       tool: tool <name> <version> <state> <missing platforms>, states complete, gaps
#       (platforms missing, none of the CI), ci-gap (a CI platform missing — the CI
#       installs with --locked and fails), no-url (a backend that records no download
#       URL, e.g. npm or cargo — never a gap), unlocked (in mise.toml, not in the lock),
#       stale (in the lock, not in mise.toml).
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
#   migrate [--index FILE] [--sections INTAKE,PLAN,HISTORY] PROJECT OUT
#       Moves the document model before coding-kit 2.0.0 — PROGRESS.md with its
#       FEATURE-INDEX block and PROGRESS-ARCHIVE.md of PROJECT — into one feature file per
#       F-number, OUT/features/F-NNN-<short name>.md (OUT missing or empty; MANIFEST
#       § Features), word for word. Number, title and status come from the FEATURE-INDEX
#       (a "(→ aufgegangen in F-…)" suffix: SUPERSEDED with superseded-by); an open entry
#       (### F-NNN) gives its text to the intake section, its substeps (F-NNNa …) to the
#       plan; the archive sections of a number become history entries, oldest first, and
#       a Done-table row without an archive section becomes one itself. Headings inside a
#       moved block keep their distance to it. Status: SUPERSEDED from the index; with an
#       open entry its **Status:** line (else PLANNED with substeps, BACKLOG without),
#       IN-PROGRESS once history exists; without one DONE when there is history, else the
#       index status, else BACKLOG. The title comes from the index line, else from the
#       heading of the open entry or the archive section of the number (else its oldest
#       section). created and done are the earliest and latest date of
#       the history; the git history of the two files fills in the day a number first
#       appeared (also when earlier) and the day its index line got (DONE). type is
#       always feature. --sections names the three section headings (default
#       Intake,Plan,History) in the language of the living docs; --index copies a
#       rendered features/INDEX.md to OUT with next-feature set. Lines:
#       unassigned <file> <from-to> <heading> (a block with content outside every
#       F-entry, e.g. an old "Schritt 1.2"), feature <F-NNN> <status> <path> <sources>,
#       empty <F-NNN> (only an index line), conflict <F-NNN> <index status> <entry
#       status>, date <F-NNN> <created|done> git, missing <F-NNN> <created|done>,
#       type feature <count>, next-feature <F-NNN>, requirements REQUIREMENTS.md (left
#       to the skill), index features/INDEX.md. Nothing is written into PROJECT.
#   settings CONFIG
#       Reads CONFIG/settings.json, the user settings of Claude Code (CONFIG is the
#       config folder, ~/.claude or $CLAUDE_CONFIG_DIR). Lines: file
#       <missing|valid|invalid> (invalid with a reason, then nothing else), then per
#       setting the kit sets (autoMemoryEnabled, cleanupPeriodDays) key <name> <raw
#       value|missing|duplicate>. Only the top level counts.
#   set-settings CONFIG OUT NAME=value…
#       Writes CONFIG/settings.json (a missing file counts as {}) with the given values
#       into OUT/settings.json (OUT missing or empty). An existing top-level member gets
#       the new value in place, a missing one is inserted first in the object with the
#       indentation of the members; every other byte stays. Lines: set <name>
#       <replaced|added>, then written settings.json. Refused: another NAME, a value
#       other than true/false (autoMemoryEnabled) or a positive whole number
#       (cleanupPeriodDays), a NAME given twice, a file that is no valid JSON object or
#       has the NAME twice — then nothing is written.
#   memory-dir CONFIG PROJECT
#       Finds the auto memory folder of PROJECT: autoMemoryDirectory of the local, then
#       the project, then the user settings (~/ follows HOME); else
#       $CLAUDE_CODE_PROJECT_DIR_NAME below CONFIG/projects; else the folder named after
#       the main checkout (worktrees share it; every byte that is no ASCII letter or
#       digit becomes -, the path as given and with symlinks resolved); else every
#       folder whose transcripts name that path as working directory. Line:
#       <setting|env|name|transcript|none> <present|absent> <own|shared> <memory
#       folder>; shared holds other projects too: the user setting, the env name, or a
#       folder whose transcripts name a name twin (another path the rule maps to the
#       same folder, "my app" and "my.app"); none names the folder the rule gives.
#   host [--answers FILE] PROJECT
#       Names the git host of PROJECT (MANIFEST § Hosts). Lines: host <name>
#       <answers|remote|none> — HOST of the answers, else what the remote origin
#       suggests (a supported host as itself, anything else git), else git without a
#       remote; remote <kind> <host name|->, kinds: a supported host, azure, gitlab,
#       forgejo, other (another server, e.g. GitHub Enterprise), local (a path or
#       file:// URL), none; unsupported <kind> for a recognized host the kit does not
#       support yet (it runs as git); no-origin <names> when other remotes exist but no
#       origin; mismatch <HOST> <kind> when the answers name another host than the
#       remote suggests. Only the host name of a URL is printed, never a user or token.
#       Refused: a HOST that is no supported host.
#   commit-email [--answers FILE] ENV PROJECT
#       The commit address of PROJECT: the host as host names it, then the address the
#       personal config ENV (read, never executed; a missing file has no values) holds
#       for that host — CODING_KIT_EMAIL_<HOST> in upper case, on github also the older
#       CODING_KIT_GIT_NOREPLY_EMAIL. Never the address of another host. Lines: host
#       <name> <answers|remote|none>; email <config|legacy|missing|invalid> <key>
#       <address|->, invalid for anything but a plain address (letters, digits and
#       . _ % + - around one @, a domain with a dot) — so the value is safe to quote.
#   default-host ENV
#       The host a new project starts on, read from CODING_KIT_DEFAULT_HOST in the
#       personal config ENV (read, never executed). Line: default-host <host>
#       <config|none|invalid> [value]; without the key github (none), a value that is no
#       name of HOSTS gives github with invalid and the value.
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
# Git hosts the kit supports (MANIFEST § Hosts); the validator compares the list with the
# MANIFEST table.
HOSTS='github git'
SLOT_OPEN='<!-- module:coding-standards -->'
SLOT_CLOSE='<!-- /module:coding-standards -->'
# Set by parse_opts.
BASE_DIR=
ANSWERS_OPT=
REGISTRY_OPT=
SNAPSHOT_OPT=
INDEX_OPT=
SECTIONS_OPT=Intake,Plan,History
RENAME_LEGACY=0
CHANGED=0
SEEDS=0

die() {
  printf 'template-sync: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat >&2 << 'EOF'
usage: sh template-sync.sh render [--seeds] TEMPLATE ANSWERS OUT
       sh template-sync.sh render-global KIT ENV OUT
       sh template-sync.sh set-global [--rename-legacy] KIT ENV OUT [NAME=value...]
       sh template-sync.sh status [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT
       sh template-sync.sh changed [--registry FILE] [--snapshot DIR] PROJECT
       sh template-sync.sh merge [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SOLL OUT
       sh template-sync.sh snapshot [--seeds] [--snapshot DIR] PROJECT SOLL TARGET...
       sh template-sync.sh base-from-history KIT VERSION OUT
       sh template-sync.sh zones [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SEEDS OUT [NAME...]
       sh template-sync.sh lock-check PROJECT
       sh template-sync.sh detect [--changed] [--answers FILE] [--registry FILE] TEMPLATE PROJECT [SIGNAL...]
       sh template-sync.sh migrate [--index FILE] [--sections INTAKE,PLAN,HISTORY] PROJECT OUT
       sh template-sync.sh settings CONFIG
       sh template-sync.sh set-settings CONFIG OUT NAME=value...
       sh template-sync.sh memory-dir CONFIG PROJECT
       sh template-sync.sh host [--answers FILE] PROJECT
       sh template-sync.sh commit-email [--answers FILE] ENV PROJECT
       sh template-sync.sh default-host ENV
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
    !($1 in known) && $1 !~ /^(MODULE|VISIBILITY|HOST|OPTIONAL|FRAGMENTS)$/ {
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

# § Core-managed files → "source<TAB>target<TAB>kind<TAB>public-only|-<TAB>host|-".
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
      host = "-"
      if (match(pol, /host:[a-z]+/)) host = substr(pol, RSTART + 5, RLENGTH - 5)
      print src "\t" tgt "\t" kind "\t" (pol ~ /public-only/ ? "public-only" : "-") "\t" host
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
    # Not NR == FNR: the values table may be empty (render-global without values).
    FILENAME == ARGV[1] { tok["{{" $1 "}}"] = substr($0, length($1) + 2); next }
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
  # A project without HOST predates it and lives on GitHub (MANIFEST § Answers).
  HOST=$(value_of HOST) || HOST=github
  check_host "$HOST"
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
    *" host-"*)
      die "answers OPTIONAL: the host blocks are derived from HOST, do not list them"
      ;;
  esac
  if [ "$(value_of LICENSE_SPDX || true)" = TBD ]; then
    OPTIONAL="$OPTIONAL license-tbd"
  else
    OPTIONAL="$OPTIONAL license"
  fi
  OPTIONAL="$OPTIONAL host-$HOST"

  if ! value_of PROJECT_NAME_SNAKE > /dev/null && r_name=$(value_of PROJECT_NAME); then
    add_value PROJECT_NAME_SNAKE "$(printf '%s' "$r_name" | tr '-' '_')"
  fi
  # The Go module path: below the repository URL on a host, the bare name without one.
  # A host without a case here leaves it unset, so go.mod reports it as unresolved.
  if ! value_of GO_MODULE > /dev/null && r_name=$(value_of PROJECT_NAME); then
    case $HOST in
      git) add_value GO_MODULE "$r_name" ;;
      github)
        if r_owner=$(value_of OWNER); then add_value GO_MODULE "github.com/$r_owner/$r_name"; fi
        ;;
    esac
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

  while IFS="$TAB" read -r r_src r_tgt r_kind r_pub r_host; do
    case $r_kind in
      seed)
        [ "$seeds" -eq 1 ] || continue
        r_policy=seed
        ;;
      managed | module) r_policy=managed ;;
      *) die "MANIFEST: unknown policy '$r_kind' for $r_src" ;;
    esac
    if [ "$r_pub" = public-only ] && [ "$VISIBILITY" != public ]; then continue; fi
    if [ "$r_host" != - ] && [ "$r_host" != "$HOST" ]; then continue; fi
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
      # The suffix keeps tools in the kit repo from reading the source as real.
      f_tgt=${f_tgt%.tmpl}
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
      --seeds) po_for='render snapshot' po_n=1 ;;
      --changed) po_for=detect po_n=1 ;;
      --base) po_for='status merge zones' po_n=2 ;;
      --answers) po_for='detect host commit-email' po_n=2 ;;
      --registry) po_for='status changed merge zones detect' po_n=2 ;;
      --snapshot) po_for='status changed merge snapshot zones' po_n=2 ;;
      --index | --sections) po_for=migrate po_n=2 ;;
      --rename-legacy) po_for=set-global po_n=1 ;;
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
      --index)
        [ -f "$2" ] || die "index file not found: $2"
        INDEX_OPT=$2
        ;;
      --sections) SECTIONS_OPT=$2 ;;
      --rename-legacy) RENAME_LEGACY=1 ;;
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
  # A seed file's base keeps its own suffix, so status, merge and changed never read it.
  sn_suffix=.base
  if [ "$SEEDS" = 1 ]; then sn_suffix=.seed; fi
  # All targets are checked before anything is written.
  for sn_t in "$@"; do
    check_target "$sn_t"
    if [ ! -f "$SOLL/$sn_t" ] && [ ! -f "$SNAP_PATH/$sn_t$sn_suffix" ]; then
      die "unknown target '$sn_t': not rendered in $SOLL and no base — pass each target as an argument of its own"
    fi
    if [ "$SEEDS" = 1 ] && [ -f "$SNAP_PATH/$sn_t.base" ]; then
      die "'$sn_t' has a managed base — --seeds takes seed files only"
    fi
  done
  for sn_t in "$@"; do
    sn_base=$SNAP_PATH/$sn_t$sn_suffix
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
  if [ ! -f "$zo_b" ]; then
    zo_b=
    # A seed file's base (snapshot --seeds); --base names its files without a suffix.
    if [ -z "$BASE_DIR" ] && [ -f "$SNAP_PATH/$1.seed" ]; then zo_b=$SNAP_PATH/$1.seed; fi
  fi
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
    # First project line where the content of render block i stands verbatim outside
    # every block and the slot and outside text found before (TK); 0 when nowhere. A block
    # without a non-blank line is never searched. Found lines are taken.
    function find_text(i,   n, s, x, ok) {
      n = BC["r", i] - BO["r", i] - 1
      ok = 0
      for (x = 1; x <= n; x++) if (L["r", BO["r", i] + x] !~ /^[ \t]*$/) ok = 1
      if (!ok) return 0
      for (s = 1; s + n - 1 <= N["p"]; s++) {
        ok = 1
        for (x = 0; x < n && ok; x++)
          if ((s + x) in TK || L["p", s + x] != L["r", BO["r", i] + 1 + x]) ok = 0
        if (ok) {
          for (x = 0; x < n; x++) TK[s + x] = 1
          return s
        }
      }
      return 0
    }
    BEGIN {
      OFS = "\t"
      load(rf, "r"); scan("r")
      if (SB["r"]) exit 9
      for (i = 1; i <= NB["r"]; i++) if (BR["r", i]) exit 9
      hasp = (pf != "")
      if (hasp) {
        load(pf, "p"); scan("p")
        # Lines of blocks and the slot: text there is never taken for a missing zone.
        for (j = 1; j <= NB["p"]; j++)
          if (BO["p", j]) for (x = BO["p", j]; x <= BC["p", j]; x++) TK[x] = 1
        if (SO["p"]) for (x = SO["p"]; x <= (SC["p"] ? SC["p"] : N["p"]); x++) TK[x] = 1
      }
      # Without a base a missing zone cannot tell new from opted-out.
      hasb = (bf != "")
      if (hasb) { load(bf, "b"); scan("b") }

      for (i = 1; i <= NB["r"]; i++) {
        k = K["r", i]; n = NM["r", i]
        j = (("p", k, n) in ID) ? ID["p", k, n] : 0
        named = (sel != "" && index(sel, " " n " "))
        tf = zdir "/" k "/" n ".template"; pf2 = zdir "/" k "/" n ".project"
        from = "-"; to = "-"
        if (skip == 1) st = "skipped"
        # A missing seed file with a base was deleted; without one the template added
        # it. Fragments live in a managed file, which merge creates.
        else if (!hasp && (hasb || k == "fragment")) st = "no-file"
        else if (!hasp) { st = "new-file"; dump("r", i, tf); from = empty; to = tf }
        else if (k == "fragment" && SB["p"]) st = "broken"
        else if (k == "fragment" && !SO["p"]) { st = "unmarked"; dump("r", i, tf) }
        else if (j && BR["p", j]) st = "broken"
        else if (j && OV["p", j]) {
          st = "override"
          dump("r", i, tf); dump("p", j, pf2)
          # What the template changed since the base.
          if ((("b", k, n) in ID) && !BR["b", ID["b", k, n]]) {
            from = zdir "/" k "/" n ".base"; to = tf
            dump("b", ID["b", k, n], from)
          }
        }
        else if (j && same("r", i, "p", j)) st = "identical"
        else if (j) { st = "differs"; dump("r", i, tf); dump("p", j, pf2); from = pf2; to = tf }
        else if (k == "fragment") { st = "new"; dump("r", i, tf); from = empty; to = tf }
        # A zone the base has was opted out of, also when its text stayed (TX: where it
        # stands, so taking it back only wraps it). Text of another missing zone that
        # stands unmarked is bare: wrapping it beats inserting it a second time.
        else if (hasb && (("b", k, n) in ID)) {
          st = "opted-out"; dump("r", i, tf); TX[i] = find_text(i)
        }
        else if ((TX[i] = find_text(i))) { st = "bare"; dump("r", i, tf) }
        else if (!HS["p"]) { st = "unmarked"; dump("r", i, tf) }
        else if (!hasb) { st = "unconfirmed"; dump("r", i, tf); from = empty; to = tf }
        else { st = "new"; dump("r", i, tf); from = empty; to = tf }
        # A new file comes whole from the render as soon as one of its zones is taken.
        if (st == "new-file" && (sel == "" || named)) {
          newfile = 1; napplied++
          print n >> applied
        }
        # Opted-out, unconfirmed and bare zones only when named: the user decides.
        if (((st == "differs" || st == "new") && (sel == "" || named)) ||
          ((st == "opted-out" || st == "unconfirmed" || st == "bare") && named)) {
          AP[i] = 1; napplied++
          print n >> applied
        }
        print target, k, n, st, from, to
      }
      for (j = 1; j <= NB["p"]; j++) {
        k = K["p", j]; n = NM["p", j]
        if (("r", k, n) in ID) continue
        pf2 = zdir "/" k "/" n ".project"
        from = "-"; to = "-"
        if (skip == 1) st = "skipped"
        else if (BR["p", j]) st = "broken"
        # A zone the template dropped since the base; an override line keeps it local.
        else if (k == "section" && (("b", k, n) in ID) && !OV["p", j]) {
          st = "removed"; dump("p", j, pf2); from = pf2; to = empty
          if (sel == "" || index(sel, " " n " ")) {
            RM[BO["p", j]] = j; napplied++
            print n >> applied
          }
        }
        else { st = "local"; dump("p", j, pf2) }
        print target, k, n, st, from, to
      }
      close(applied)
      if (!napplied) exit 0
      if (newfile) {
        printf "" > o
        for (x = 1; x <= N["r"]; x++) print L["r", x] > o
        close(o)
        exit 0
      }

      # Differing blocks are replaced in place. A new zone goes behind its nearest
      # predecessor in the render order that is in the file (or arrives with it), without
      # one before its nearest successor in the file, without both to the end. A new
      # fragment goes behind its nearest predecessor in the render order that is in the
      # slot (or arrives with it), without one to the start of the slot.
      for (i = 1; i <= NB["r"]; i++) {
        if (!AP[i]) continue
        k = K["r", i]; n = NM["r", i]
        if (("p", k, n) in ID) { REPL[BO["p", ID["p", k, n]]] = i; continue }
        # A zone whose text stands unmarked only gets its markers around that text.
        if (TX[i]) {
          WO[TX[i]] = i; WC[TX[i] + BC["r", i] - BO["r", i] - 2] = i
          AT[i] = "after"; AL[i] = TX[i] + BC["r", i] - BO["r", i] - 2
          continue
        }
        if (k == "section") {
          at = ""
          for (x = i - 1; x >= 1 && at == ""; x--) {
            if (K["r", x] != "section") continue
            if (("p", "section", NM["r", x]) in ID) {
              y = ID["p", "section", NM["r", x]]
              if (!BR["p", y]) { at = "after"; al = BC["p", y] }
            } else if (AP[x]) { at = AT[x]; al = AL[x] }
          }
          for (x = i + 1; x <= NB["r"] && at == ""; x++) {
            if (K["r", x] != "section" || !(("p", "section", NM["r", x]) in ID)) continue
            y = ID["p", "section", NM["r", x]]
            if (!BR["p", y]) { at = "before"; al = BO["p", y] }
          }
          if (at == "") { at = "end"; al = N["p"] }
          AT[i] = at; AL[i] = al
          if (at == "after") G[al, ++GN[al]] = i
          else if (at == "before") GB[al, ++GBN[al]] = i
          else GE[++GEN] = i
          continue
        }
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
        for (m = 1; m <= GBN[i]; m++) {
          if (m == 1 && i > 1 && L["p", i - 1] !~ /^[ \t]*$/) print "" > o
          emit(GB[i, m]); print "" > o
        }
        if (i in RM) {
          # Removing a zone between blank lines (or at the start) takes one of them along.
          e = BC["p", RM[i]]
          if (e < N["p"] && L["p", e + 1] ~ /^[ \t]*$/ &&
            (i == 1 || L["p", i - 1] ~ /^[ \t]*$/)) e++
          i = e
          continue
        }
        if (i in REPL) {
          x = REPL[i]
          print L["p", i] > o
          for (y = BO["r", x] + 1; y < BC["r", x]; y++) print L["r", y] > o
          i = BC["p", ID["p", K["r", x], NM["r", x]]]
        }
        if (i in WO) print L["r", BO["r", WO[i]]] > o
        print L["p", i] > o
        if (i in WC) print L["r", BC["r", WC[i]]] > o
        for (m = 1; m <= GN[i]; m++) {
          if (i == SO["p"]) { emit(G[i, m]); print "" > o }
          else { print "" > o; emit(G[i, m]) }
        }
      }
      for (m = 1; m <= GEN; m++) {
        if (m > 1 || L["p", N["p"]] !~ /^[ \t]*$/) print "" > o
        emit(GE[m])
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
      || die "$zs_name: no block of that name to apply (differs, new, new-file, removed, opted-out, bare, unconfirmed)"
  done
}

# --- render-global --------------------------------------------------------------

# Values of the personal config the global rules read, without the CODING_KIT_ prefix;
# the validator compares the list with the placeholders of the kit file.
GLOBAL_KEYS='REPLY_LANGUAGE EXPLAIN_LEVEL EXPLAIN_NOTE'
GLOBAL_TARGET=rules/coding-kit.md

# ENV → "NAME<TAB>value" per CODING_KIT_NAME assignment, NAME without the prefix. Reads
# the shell syntax of the personal config — NAME="value", 'value' or a bare word, also
# behind export and followed by a # comment — without executing anything: no expansion,
# only the escapes \" \\ \$ \` inside double quotes. A later assignment wins, as in the
# shell; other lines are ignored.
load_env() {  # ENV
  awk '
    function fail(msg) { print "template-sync: " FILENAME " line " FNR ": " msg | "cat 1>&2"; bad = 1 }
    { sub(/\r$/, "") }
    /^[ \t]*(#|$)/ { next }
    {
      line = $0
      sub(/^[ \t]+/, "", line)
      sub(/^export[ \t]+/, "", line)
      if (line !~ /^CODING_KIT_[A-Z0-9_]+=/) next
      eq = index(line, "=")
      name = substr(line, 12, eq - 12)
      rest = substr(line, eq + 1)
      q = substr(rest, 1, 1)
      if (q == "\"") {
        val = ""; closed = 0
        for (i = 2; i <= length(rest); i++) {
          c = substr(rest, i, 1)
          if (c == "\\" && i < length(rest) && index("\"\\$`", substr(rest, i + 1, 1))) {
            i++; val = val substr(rest, i, 1); continue
          }
          if (c == "\"") { closed = 1; break }
          val = val c
        }
        tail = substr(rest, i + 1)
      } else if (q == "\047") {
        quote_at = index(substr(rest, 2), "\047")
        closed = quote_at > 0
        val = substr(rest, 2, quote_at - 1); tail = substr(rest, quote_at + 2)
      } else {
        closed = 1
        match(rest, /^[^ \t]*/)
        val = substr(rest, 1, RLENGTH); tail = substr(rest, RLENGTH + 1)
      }
      key = "CODING_KIT_" name
      if (!closed) { fail(key ": unterminated quote"); next }
      if (tail !~ /^([ \t]+(#.*)?)?$/) { fail(key ": unexpected text after the value"); next }
      if (index(val, "\t") || index(val, "{{")) { fail(key ": value contains a tab or {{"); next }
      value[name] = val
    }
    END {
      for (n in value) print n "\t" value[n]
      close("cat 1>&2")
      exit bad
    }' "$1"
}

# The level blocks of KIT as KIT_LEVELS (" einsteiger junior …", the list of levels);
# dies on a block render-global does not know.
kit_levels() {  # KIT
  sed -n 's/^[[:space:]]*<!--[[:space:]]*template:optional:\([a-z0-9-]*\)[[:space:]]*-->[[:space:]]*$/\1/p' \
    "$1" > "$WORK/blocks"
  KIT_LEVELS=
  while IFS= read -r kl_block; do
    case $kl_block in
      reply-language | explain | explain-note) ;;
      level-?*) KIT_LEVELS="$KIT_LEVELS ${kl_block#level-}" ;;
      *) die "$1: unknown block template:optional:$kl_block" ;;
    esac
  done < "$WORK/blocks"
}

check_level() {  # LEVEL — one of KIT_LEVELS, or die
  case " $KIT_LEVELS " in
    *" $1 "*) ;;
    *) die "CODING_KIT_EXPLAIN_LEVEL: unknown level '$1' (known:$KIT_LEVELS)" ;;
  esac
}

# The comment of KEY in the key comment of KIT (the text behind # on its KEY= line);
# status 1 when KIT has no such line.
kit_comment() {  # KIT KEY
  awk -v k="$2" '
    { sub(/\r$/, "") }
    index($0, k "=") == 1 && index($0, "#") {
      c = substr($0, index($0, "#") + 1)
      sub(/^[ \t]+/, "", c)
      print c
      found = 1
      exit
    }
    END { exit !found }' "$1"
}

# Value of NAME (without the prefix) in the parsed personal config; status 1 when unset.
env_value() {  # NAME
  awk -F "$TAB" -v k="$1" '
    $1 == k { print substr($0, length(k) + 2); found = 1 }
    END { exit !found }' "$WORK/env.tsv"
}

render_global() {
  [ $# -eq 3 ] || usage
  RG_KIT=$1 RG_ENV=$2 RG_OUT=$3
  [ -f "$RG_KIT" ] || die "kit rules not found: $RG_KIT"
  check_out_dir "$RG_OUT"
  setup_work
  : > "$WORK/env.tsv"
  if [ -f "$RG_ENV" ]; then
    load_env "$RG_ENV" > "$WORK/env.tsv" || die "invalid personal config: $RG_ENV"
  fi
  # Only values that are set go into the table finalize substitutes from; an empty one
  # drops its block instead.
  : > "$WORK/values.tsv"
  : > "$WORK/keys.tsv"
  # Word splitting of the key list is intended.
  for rg_name in $GLOBAL_KEYS; do
    if rg_val=$(env_value "$rg_name"); then
      if [ -n "$rg_val" ]; then
        add_value "$rg_name" "$rg_val"
        rg_state=set
      else
        rg_state=empty
      fi
    else
      rg_state=missing
    fi
    printf 'key\tCODING_KIT_%s\t%s\n' "$rg_name" "$rg_state" >> "$WORK/keys.tsv"
  done
  # The commit address from before the keys per host: still to rename, or superseded
  # when the new key is set as well.
  if rg_old=$(env_value "$LEGACY_EMAIL_KEY") && [ -n "$rg_old" ]; then
    rg_key=$(email_key github)
    if rg_new=$(env_value "$rg_key") && [ -n "$rg_new" ]; then
      rg_state=superseded
    else
      rg_state=rename
    fi
    printf 'legacy\tCODING_KIT_%s\tCODING_KIT_%s\t%s\n' "$LEGACY_EMAIL_KEY" "$rg_key" \
      "$rg_state" >> "$WORK/keys.tsv"
  fi
  rg_lang=$(value_of REPLY_LANGUAGE) || rg_lang=
  rg_level=$(value_of EXPLAIN_LEVEL) || rg_level=
  rg_note=$(value_of EXPLAIN_NOTE) || rg_note=
  kit_levels "$RG_KIT"
  OPTIONAL=
  if [ -n "$rg_lang" ]; then OPTIONAL="$OPTIONAL reply-language"; fi
  if [ -n "$rg_level" ]; then
    check_level "$rg_level"
    OPTIONAL="$OPTIONAL level-$rg_level"
  fi
  if [ -n "$rg_note" ]; then OPTIONAL="$OPTIONAL explain-note"; fi
  if [ -n "$rg_level$rg_note" ]; then OPTIONAL="$OPTIONAL explain"; fi
  finalize "$RG_KIT" "$WORK/global.md" || die "$RG_KIT: unbalanced or nested template:optional block"
  [ ! -s "$WORK/missing" ] || die "$RG_KIT: unresolved placeholder: $(missing_tokens)"
  mkdir -p "$RG_OUT/${GLOBAL_TARGET%/*}"
  mv "$WORK/global.md" "$RG_OUT/$GLOBAL_TARGET"
  cat "$WORK/keys.tsv"
  printf 'rendered\t%s\n' "$GLOBAL_TARGET"
}

set_global() {
  if [ "$RENAME_LEGACY" -eq 1 ]; then [ $# -ge 3 ] || usage; else [ $# -ge 4 ] || usage; fi
  SG_KIT=$1 SG_ENV=$2 SG_OUT=$3
  shift 3
  [ -f "$SG_KIT" ] || die "kit rules not found: $SG_KIT"
  check_out_dir "$SG_OUT"
  setup_work
  # --rename-legacy: the old commit address moves to the GitHub key — unless that key is
  # set already or given — and every assignment of the old key goes. The value never
  # leaves the script.
  sg_drop=
  if [ "$RENAME_LEGACY" -eq 1 ]; then
    sg_drop=$LEGACY_EMAIL_KEY
    sg_new=$(email_key github)
    : > "$WORK/env.tsv"
    if [ -f "$SG_ENV" ]; then
      load_env "$SG_ENV" > "$WORK/env.tsv" || die "invalid personal config: $SG_ENV"
    fi
    case " $* " in
      *" CODING_KIT_$sg_new="*) ;;
      *)
        if ! { sg_cur=$(env_value "$sg_new") && [ -n "$sg_cur" ]; } \
          && sg_old=$(env_value "$LEGACY_EMAIL_KEY") && [ -n "$sg_old" ]; then
          set -- "$@" "CODING_KIT_$sg_new=$sg_old"
        fi
        ;;
    esac
  fi
  kit_levels "$SG_KIT"
  # The values of the global rules, the default host of new projects, then the commit
  # address per host.
  sg_keys="$GLOBAL_KEYS DEFAULT_HOST$(email_keys)"
  sg_nl='
'
  : > "$WORK/given"
  : > "$WORK/lines.given"
  for sg_arg in "$@"; do
    case $sg_arg in
      CODING_KIT_*=*) ;;
      *) die "expected CODING_KIT_NAME=value, not '$sg_arg'" ;;
    esac
    sg_key=${sg_arg%%=*}
    sg_val=${sg_arg#*=}
    sg_name=${sg_key#CODING_KIT_}
    case " $sg_keys " in
      *" $sg_name "*) ;;
      *) die "$sg_key: not a key of the personal config the kit writes" ;;
    esac
    if grep -qxF -- "$sg_name" "$WORK/given"; then die "$sg_key: given twice"; fi
    printf '%s\n' "$sg_name" >> "$WORK/given"
    case $sg_val in
      *"$TAB"* | *"$sg_nl"* | *'{{'*) die "$sg_key: value contains a tab, a line break or {{" ;;
    esac
    if [ "$sg_name" = EXPLAIN_LEVEL ] && [ -n "$sg_val" ]; then check_level "$sg_val"; fi
    if [ "$sg_name" = DEFAULT_HOST ] && [ -n "$sg_val" ]; then
      case " $HOSTS " in
        *" $sg_val "*) ;;
        *) die "$sg_key: must be one of: $HOSTS — not '$sg_val'" ;;
      esac
    fi
    sg_comment=$(kit_comment "$SG_KIT" "$sg_key") || die "$SG_KIT: no key comment for $sg_key"
    # Inside double quotes the shell would expand $ and ` and read \ and " as escapes.
    sg_quoted=$(printf '%s' "$sg_val" | sed 's/[\\"$`]/\\&/g')
    printf '%s\t%s="%s"  # %s\n' "$sg_name" "$sg_key" "$sg_quoted" "$sg_comment" >> "$WORK/lines.given"
  done
  # The new lines in the order of the keys (word splitting of the list is intended).
  : > "$WORK/lines.tsv"
  for sg_name in $sg_keys; do
    awk -F "$TAB" -v k="$sg_name" '$1 == k' "$WORK/lines.given" >> "$WORK/lines.tsv"
  done
  : > "$WORK/env.in"
  if [ -f "$SG_ENV" ]; then cp "$SG_ENV" "$WORK/env.in"; fi
  : > "$WORK/status"
  # Replaces the first assignment of each given key in place and drops later ones (they
  # would win in the shell), appends the keys the file lacks behind a blank line; every
  # other line goes through unchanged. A file with CRLF line ends gets CRLF lines.
  awk -F "$TAB" -v status="$WORK/status" -v drop="$sg_drop" '
    FILENAME == ARGV[1] { line[$1] = substr($0, length($1) + 2); order[++n] = $1; next }
    FNR == 1 { crlf = ($0 ~ /\r$/) }
    {
      t = $0
      sub(/\r$/, "", t)
      last = t
      lines++
      sub(/^[ \t]+/, "", t)
      sub(/^export[ \t]+/, "", t)
      if (match(t, /^CODING_KIT_[A-Z0-9_]+=/)) {
        name = substr(t, 12, RLENGTH - 12)
        if (name == drop) {
          if (!dropped) print "dropped\tCODING_KIT_" name > status
          dropped = 1
          next
        }
        if (name in line) {
          if (!(name in done)) {
            print line[name] (crlf ? "\r" : "")
            print "set\tCODING_KIT_" name "\treplaced" > status
            done[name] = 1
          }
          next
        }
      }
      print
    }
    END {
      for (i = 1; i <= n; i++) {
        name = order[i]
        if (name in done) continue
        if (!separated && lines && last != "") { print (crlf ? "\r" : ""); separated = 1 }
        print line[name] (crlf ? "\r" : "")
        print "set\tCODING_KIT_" name "\tadded" > status
      }
    }' "$WORK/lines.tsv" "$WORK/env.in" > "$WORK/coding-kit.env"
  mkdir -p "$SG_OUT"
  mv "$WORK/coding-kit.env" "$SG_OUT/coding-kit.env"
  chmod 600 "$SG_OUT/coding-kit.env"
  for sg_name in $sg_keys; do
    grep "^set${TAB}CODING_KIT_$sg_name$TAB" "$WORK/status" || true
  done
  grep "^dropped$TAB" "$WORK/status" || true
  printf 'written\tcoding-kit.env\n'
}

# --- lock-check -----------------------------------------------------------------

# Backends whose lock entries record no download URL, so `mise install --locked` needs
# none (mise documentation, mise.lock § Backend support); every other backend needs one
# per platform. A core tool is written core:<tool>.
NO_URL_BACKENDS='asdf cargo dotnet gem go npm pipx pypi spinel spm ubi core:dotnet core:rust core:swift'

# lockfile_platforms from [settings] of a mise.toml, one per line (single- or multi-line
# array); status 1 when the setting is missing.
lock_platforms() {  # MISE_TOML
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*\[/ && !collecting {
      t = $0; sub(/^[ \t]*\[[ \t]*/, "", t); sub(/[ \t]*\].*$/, "", t)
      insettings = (t == "settings")
      next
    }
    insettings && !collecting && /^[ \t]*lockfile_platforms[ \t]*=/ {
      collecting = 1; found = 1
      sub(/^[^=]*=/, "")
    }
    collecting {
      line = $0; sub(/#.*/, "", line)
      while (match(line, /"[^"]*"|\047[^\047]*\047/)) {
        print substr(line, RSTART + 1, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)
      }
      if (index($0, "]")) collecting = 0
    }
    END { exit !found }' "$1"
}

# Entries of a mise.lock → "name<TAB>version<TAB>backend<TAB> platform platform…", one
# per [[tools.NAME]] (one per version). As TOML has it, a [tools.NAME."platforms.P"]
# table belongs to the latest [[tools.NAME]] above it, wherever it stands.
lock_entries() {  # MISE_LOCK
  awk -v tab="$TAB" '
    function unq(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/^"|"$/, "", s); return s }
    { sub(/\r$/, "") }
    /^[ \t]*\[\[[ \t]*tools\./ {
      h = $0; sub(/^[ \t]*\[\[[ \t]*tools\./, "", h); sub(/[ \t]*\]\][ \t]*$/, "", h)
      cur = ++n
      name[n] = unq(h); ver[n] = "-"; be[n] = "-"; plats[n] = ""
      latest[name[n]] = n
      next
    }
    /^[ \t]*\[/ {
      cur = 0
      h = $0; sub(/^[ \t]*\[[ \t]*tools\./, "", h)
      i = index(h, ".\"platforms.")
      if (i && (unq(substr(h, 1, i - 1)) in latest)) {
        p = substr(h, i + 12); sub(/".*$/, "", p)
        x = latest[unq(substr(h, 1, i - 1))]
        plats[x] = plats[x] " " p
      }
      next
    }
    cur && /^[ \t]*version[ \t]*=/ { v = $0; sub(/^[^=]*=/, "", v); ver[cur] = unq(v) }
    cur && /^[ \t]*backend[ \t]*=/ { v = $0; sub(/^[^=]*=/, "", v); be[cur] = unq(v) }
    END { for (x = 1; x <= n; x++) print name[x] tab ver[x] tab be[x] tab plats[x] }' "$1"
}

# The platforms the CI runs mise on: "platform<TAB>runs-on<TAB>workflow" per runs-on line
# of each workflow that uses jdx/mise-action — from GitHub's runner labels, "unknown" for
# expressions, self-hosted runners and anything else.
ci_platforms() {  # PROJECT
  for cp_wf in "$1"/.github/workflows/*.yml "$1"/.github/workflows/*.yaml; do
    [ -f "$cp_wf" ] || continue
    grep -q 'jdx/mise-action' "$cp_wf" || continue
    awk -v wf="${cp_wf#"$1"/}" -v tab="$TAB" '
      { sub(/\r$/, "") }
      /^[ \t]*runs-on:/ {
        v = $0; sub(/^[ \t]*runs-on:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v)
        gsub(/^["\047]|["\047]$/, "", v)
        if (v == "") v = "-"
        p = "unknown"
        if (v ~ /^ubuntu-.*-arm$/) p = "linux-arm64"
        else if (v ~ /^ubuntu-[a-z0-9.]+$/) p = "linux-x64"
        else if (v == "macos-13" || v ~ /^macos-[a-z0-9.]+-(intel|large)$/) p = "macos-x64"
        else if (v ~ /^macos-[a-z0-9.-]+$/) p = "macos-arm64"
        else if (v ~ /^windows-.*-arm$/) p = "windows-arm64"
        else if (v ~ /^windows-[a-z0-9.-]+$/) p = "windows-x64"
        print p tab v tab wf
      }' "$cp_wf"
  done | LC_ALL=C sort -u
}

lock_check() {
  [ $# -eq 1 ] || usage
  P=$1
  [ -d "$P" ] || die "project not found: $P"
  [ -f "$P/mise.toml" ] || die "no mise.toml in $P"
  setup_work
  if lock_platforms "$P/mise.toml" > "$WORK/platforms"; then
    printf 'platforms\t%s\n' "$(awk 'NR > 1 { printf "," } { printf "%s", $0 }' "$WORK/platforms")"
  else
    printf 'platforms\tmissing\n'
  fi
  ci_platforms "$P" > "$WORK/ci"
  if [ -s "$WORK/ci" ]; then
    awk -v tab="$TAB" '{ print "ci" tab $0 }' "$WORK/ci"
  else
    printf 'ci\tnone\n'
  fi
  [ -s "$WORK/platforms" ] || return 0
  if [ ! -f "$P/mise.lock" ]; then
    printf 'lockfile\tmissing\n'
    return 0
  fi
  lock_entries "$P/mise.lock" > "$WORK/entries"
  mise_signals "$P/mise.toml" mise.toml | cut -f1 | sed 's/^tool://' | LC_ALL=C sort -u > "$WORK/tools"
  awk -F "$TAB" -v OFS="$TAB" -v tab="$TAB" -v nourl=" $NO_URL_BACKENDS " \
    -v pf="$WORK/platforms" -v cf="$WORK/ci" -v tf="$WORK/tools" '
    BEGIN {
      while ((getline l < pf) > 0) plat[++np] = l
      while ((getline l < cf) > 0) { split(l, c, tab); ci[c[1]] = 1 }
      while ((getline l < tf) > 0) configured[l] = 1
    }
    {
      name = $1; ver = $2; be = $3; locked[name] = 1
      if (!(name in configured)) { print "tool", name, ver, "stale", "-"; next }
      # Without a backend field, a prefixed name is its own backend; a bare name counts
      # as one that needs URLs.
      if (be == "-" && index(name, ":")) be = name
      type = substr(be, 1, index(be, ":") - 1)
      qual = (type == "core") ? be : type
      if (type != "" && (index(nourl, " " type " ") || index(nourl, " " qual " "))) {
        print "tool", name, ver, "no-url", "-"; next
      }
      have = " " $4 " "; miss = ""; blocks = 0
      for (i = 1; i <= np; i++) {
        if (index(have, " " plat[i] " ")) continue
        miss = miss (miss == "" ? "" : ",") plat[i]
        if (plat[i] in ci) blocks = 1
      }
      if (miss == "") print "tool", name, ver, "complete", "-"
      else print "tool", name, ver, (blocks ? "ci-gap" : "gaps"), miss
    }
    END {
      for (t in configured) if (!(t in locked)) print "tool", t, "-", "unlocked", "-"
    }' "$WORK/entries" | LC_ALL=C sort -t "$TAB" -k2,2 -k3,3
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

# --- migrate: the document model before 2.0.0 → feature files ----------------------

# Dates from the git history of PROJECT's PROGRESS.md and PROGRESS-ARCHIVE.md: per
# number the day of the first commit that added a line naming it ("first"), and the day
# the FEATURE-INDEX line got its (DONE) ("done"). Lines: <first|done> <F-NNN> <date>.
# Nothing when PROJECT is no git repository.
migrate_git_dates() {  # PROJECT
  git -C "$1" rev-parse --is-inside-work-tree > /dev/null 2>&1 || return 0
  git -C "$1" log --reverse --format='@@date %as' -p --no-color --no-ext-diff \
    -- PROGRESS.md PROGRESS-ARCHIVE.md 2> /dev/null | awk '
    /^@@date / { day = $2; next }
    /^\+\+\+/ || !/^\+/ { next }
    /next-feature/ { next }
    {
      line = $0
      done_line = (line ~ /^\+[ \t-]*F-[0-9][0-9][0-9][0-9]*:?[ \t]/ && index(line, "(DONE)"))
      while (match(line, /F-[0-9][0-9][0-9][0-9]*/)) {
        id = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        if (!(id in first)) { first[id] = day; print "first\t" id "\t" day }
        if (done_line && !(id in done)) { done[id] = day; print "done\t" id "\t" day }
        if (done_line) done_line = 0
      }
    }'
}

migrate() {  # PROJECT OUT
  [ $# -eq 2 ] || usage
  mg_p=$1 mg_out=$2
  [ -f "$mg_p/PROGRESS.md" ] || die "no PROGRESS.md in $mg_p"
  check_out_dir "$mg_out"
  case $SECTIONS_OPT in
    *,*,*) ;;
    *) die "--sections needs three names: INTAKE,PLAN,HISTORY" ;;
  esac
  setup_work
  migrate_git_dates "$mg_p" > "$WORK/gitdates"
  mg_archive=/dev/null
  [ -f "$mg_p/PROGRESS-ARCHIVE.md" ] && mg_archive=$mg_p/PROGRESS-ARCHIVE.md
  mkdir -p "$mg_out/features"
  LC_ALL=C awk -v out="$mg_out/features" -v sections="$SECTIONS_OPT" \
    -v gitf="$WORK/gitdates" -v progf="$mg_p/PROGRESS.md" -v archf="$mg_archive" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function base_of(id) { sub(/[a-z]$/, "", id); return id }
    function num(id) { return substr(base_of(id), 3) + 0 }
    function is_date(s) { return s ~ /^[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]$/ }

    # The last YYYY-MM-DD in S, or "".
    function last_date(s,    d) {
      d = ""
      while (match(s, /[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]/)) {
        d = substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
      }
      return d
    }

    # The F-number a heading text starts with (F-NNN or F-NNNa), or "".
    function f_id(t,    id, rest) {
      if (!match(t, /^F-[0-9][0-9][0-9][0-9]*[a-z]?/)) return ""
      id = substr(t, 1, RLENGTH)
      rest = substr(t, RLENGTH + 1)
      if (rest == "" || rest ~ /^([ :.,-]|—|–)/) return id
      return ""
    }

    # The text of a heading after its F-number and separator.
    function title_of(t) {
      sub(/^F-[0-9][0-9][0-9][0-9]*[a-z]?[ \t]*/, "", t)
      sub(/^(—|–|-|:)[ \t]*/, "", t)
      return trim(t)
    }

    function new_block(kind, level, id, text) {
      nb++
      b_doc[nb] = doc; b_kind[nb] = kind; b_level[nb] = level
      b_id[nb] = id; b_base[nb] = (id == "" ? "" : base_of(id)); b_head[nb] = text
      b_from[nb] = FNR; b_to[nb] = FNR; b_n[nb] = 0
      cur = nb
      if (kind == "entry") {
        known[b_base[nb]] = 1
        if (doc == "p") { pe_n[b_base[nb]]++; pe_b[b_base[nb], pe_n[b_base[nb]]] = nb }
        else { ae_n[b_base[nb]]++; ae_b[b_base[nb], ae_n[b_base[nb]]] = nb }
      }
    }

    function add_line(hl) {
      b_n[cur]++
      b_line[cur, b_n[cur]] = $0
      b_hl[cur, b_n[cur]] = hl
      b_to[cur] = FNR
    }

    function heading(level, text,    id) {
      id = f_id(text)
      if (b_kind[cur] == "entry" && level > b_level[cur] && (id == "" || base_of(id) == b_base[cur])) {
        add_line(level); return
      }
      if (id != "") { new_block("entry", level, id, text); return }
      if (level == 1 && b_kind[cur] == "head") { add_line(level); return }
      new_block("other", level, "", text)
    }

    # A row of the old Done table: | F-NNNx | description | date |
    function done_row(line,    n, c, i, id, desc, d) {
      n = split(line, c, "|")
      id = trim(c[2])
      desc = trim(c[3])
      for (i = 4; i < n - 1; i++) desc = desc " | " trim(c[i])
      d = trim(c[n - 1])
      if (!is_date(d)) d = ""
      nd++
      d_id[nd] = id; d_desc[nd] = desc; d_date[nd] = d
      done_ids[id] = 1
      known[base_of(id)] = 1
      b_has_done[cur] = 1
    }

    # A line of the FEATURE-INDEX block.
    function index_line(line,    id, rest, st, t, at) {
      line = trim(line)
      if (line ~ /^next-feature:/) {
        if (match(line, /F-[0-9][0-9][0-9][0-9]*/)) ix_next = substr(line, RSTART, RLENGTH)
        return
      }
      sub(/^-[ \t]*/, "", line)
      if (!match(line, /^F-[0-9][0-9][0-9][0-9]*:?[ \t]+/)) return
      id = substr(line, 1, RLENGTH)
      sub(/:?[ \t]+$/, "", id)
      rest = trim(substr(line, RLENGTH + 1))
      st = ""
      if (match(rest, /[ \t]*\(([A-Z]+-)?[A-Z]+\)$/)) {
        t = substr(rest, RSTART, RLENGTH)
        gsub(/[ \t()]/, "", t)
        if (t ~ /^(BACKLOG|PLANNED|IN-PROGRESS|DONE|DROPPED|SUPERSEDED)$/) {
          st = t
          rest = trim(substr(rest, 1, RSTART - 1))
        }
      }
      if (st == "" && match(rest, /[ \t]*\([^()]*\)$/)) {
        t = substr(rest, RSTART, RLENGTH)
        at = RSTART
        if ((t ~ /\([ \t]*→/ || t ~ /aufgegangen|merged|superseded|ersetzt/) && t ~ /F-[0-9][0-9][0-9]/) {
          st = "SUPERSEDED"
          ix_sup[id] = ids_in(t)
          rest = trim(substr(rest, 1, at - 1))
        }
      }
      ix_title[id] = rest
      ix_status[id] = st
      known[id] = 1
    }

    # All F-numbers in S as "F-001, F-002".
    function ids_in(s,    r, id) {
      r = ""
      while (match(s, /F-[0-9][0-9][0-9][0-9]*/)) {
        id = substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
        r = r (r == "" ? "" : ", ") id
      }
      return r
    }

    # Lines of an "other" block that carry content (not structure).
    function significant(b,    i, l, s) {
      s = 0
      for (i = 1; i <= b_n[b]; i++) {
        l = trim(b_line[b, i])
        if (l == "" || l ~ /^(---|\*\*\*)$/ || l ~ /^_.*_$/ || l ~ /^<!--.*-->$/) continue
        if (l ~ /^\|/ && (b_has_done[b] || l ~ /^\|[-: |]+\|$/ || l ~ /^\|[ \t]*(—|–|-)?[ \t]*\|/)) continue
        s++
      }
      return s
    }

    # Line I of block B, a heading moved by SHIFT levels (kept between 3 and 6).
    function shifted(b, i, shift,    l, n) {
      if (!b_hl[b, i]) return b_line[b, i]
      n = b_hl[b, i] + shift
      if (n < 3) n = 3
      if (n > 6) n = 6
      l = b_line[b, i]
      sub(/^#+/, "", l)
      return substr("######", 1, n) l
    }

    function slug(t,    s) {
      s = t
      gsub(/Ä/, "Ae", s); gsub(/Ö/, "Oe", s); gsub(/Ü/, "Ue", s)
      gsub(/ä/, "ae", s); gsub(/ö/, "oe", s); gsub(/ü/, "ue", s); gsub(/ß/, "ss", s)
      s = tolower(s)
      gsub(/[^a-z0-9]+/, "-", s)
      sub(/^-+/, "", s); sub(/-+$/, "", s)
      if (length(s) > 40) {
        s = substr(s, 1, 41)
        if (s ~ /-/) sub(/-[^-]*$/, "", s)
        else s = substr(s, 1, 40)
      }
      sub(/-+$/, "", s)
      return s == "" ? "feature" : s
    }

    function emit(line) { print line > path }
    function field(key, value) { emit(key ":" (value == "" ? "" : " " value)) }

    BEGIN {
      split(sections, sec, ",")
      while ((getline line < gitf) > 0) {
        split(line, g, "\t")
        if (g[1] == "first") git_first[g[2]] = g[3]
        else git_done[g[2]] = g[3]
      }
      close(gitf)
    }

    FNR == 1 {
      doc = (FILENAME == progf) ? "p" : "a"
      in_fence = 0; in_index = 0
      new_block("head", 1, "", "")
    }

    {
      sub(/\r$/, "")
      if (doc == "p" && !in_fence && !in_index && $0 ~ /^[ \t]*<!--[ \t]*FEATURE-INDEX/) {
        in_index = ($0 !~ /-->/)
        next
      }
      if (in_index) {
        if ($0 ~ /-->/) { in_index = 0; next }
        index_line($0)
        next
      }
      if ($0 ~ /^[ \t]*(```|~~~)/) { in_fence = !in_fence; add_line(0); next }
      if (!in_fence && match($0, /^#+ /)) { heading(RLENGTH - 1, substr($0, RLENGTH + 1)); next }
      if (!in_fence && doc == "p" && b_kind[cur] != "entry" &&
          $0 ~ /^\|[ \t]*F-[0-9][0-9][0-9][0-9]*[a-z]?[ \t]*\|/) done_row($0)
      add_line(0)
    }

    END {
      # What could not be assigned: other blocks with content.
      for (b = 1; b <= nb; b++)
        if (b_kind[b] == "other" && significant(b))
          printf "unassigned\t%s\t%d-%d\t%s\n", (b_doc[b] == "p" ? "PROGRESS.md" : "PROGRESS-ARCHIVE.md"),
            b_from[b], b_to[b], b_head[b]

      # The numbers, ascending.
      n = 0
      for (id in known) { n++; ord[n] = id }
      for (i = 2; i <= n; i++) {
        v = ord[i]
        for (j = i - 1; j >= 1 && num(ord[j]) > num(v); j--) ord[j + 1] = ord[j]
        ord[j + 1] = v
      }
      highest = 0
      defaulted = 0
      for (k = 1; k <= n; k++) {
        id = ord[k]
        if (num(id) > highest) highest = num(id)
        write_feature(id)
      }
      next_num = highest + 1
      if (ix_next != "" && num(ix_next) > next_num) next_num = num(ix_next)
      printf "type\tfeature\t%d\n", defaulted
      printf "next-feature\tF-%03d\n", next_num
    }

    function write_feature(id,    k, b, i, st, entry_st, nh, h, sources, title, created, done, f, plan_from, sub_id, d, prev, x, y) {
      # Status line and parts of the open entries
      entry_st = ""
      for (k = 1; k <= pe_n[id]; k++) {
        b = pe_b[id, k]
        for (i = 1; i <= b_n[b]; i++)
          if (match(b_line[b, i], /^\*\*Status:?\*\*:?[ \t]*[A-Z-]+/)) {
            entry_st = b_line[b, i]
            sub(/^\*\*Status:?\*\*:?[ \t]*/, "", entry_st)
            sub(/[^A-Z-].*$/, "", entry_st)
            b_skip[b, i] = 1
          }
      }

      # History items: archive sections newest first in the file → oldest first here,
      # then Done rows without an archive section of their own.
      nh = 0
      for (k = ae_n[id]; k >= 1; k--) {
        b = ae_b[id, k]; nh++
        h_kind[nh] = "a"; h_ref[nh] = b; h_date[nh] = last_date(b_head[b])
      }
      for (k = 1; k <= nd; k++) {
        if (base_of(d_id[k]) != id || archived(d_id[k])) continue
        nh++; h_kind[nh] = "d"; h_ref[nh] = k; h_date[nh] = d_date[k]
      }
      # Undated items take the date before them, then a stable sort by date.
      prev = ""
      for (i = 1; i <= nh; i++) { h_key[i] = (h_date[i] != "" ? h_date[i] : prev); prev = h_key[i]; h_pos[i] = i }
      for (i = 2; i <= nh; i++) {
        x = h_pos[i]
        for (j = i - 1; j >= 1 && h_key[h_pos[j]] > h_key[x]; j--) h_pos[j + 1] = h_pos[j]
        h_pos[j + 1] = x
      }

      # Status
      if (ix_status[id] == "SUPERSEDED") st = "SUPERSEDED"
      else if (pe_n[id] > 0) {
        st = entry_st
        if (st !~ /^(BACKLOG|PLANNED|IN-PROGRESS)$/) st = has_substeps(id) ? "PLANNED" : "BACKLOG"
        if (nh > 0) st = "IN-PROGRESS"
        if (ix_status[id] != "" && ix_status[id] != st && ix_status[id] != "PLANNED")
          printf "conflict\t%s\tindex %s\tentry %s\n", id, ix_status[id], st
      } else if (nh > 0) st = "DONE"
      else if (ix_status[id] != "") st = ix_status[id]
      else st = "BACKLOG"

      sources = ""
      if (id in ix_title) sources = "index"
      if (pe_n[id]) sources = sources (sources == "" ? "" : ",") "open"
      if (ae_n[id]) sources = sources (sources == "" ? "" : ",") "archive:" ae_n[id]
      for (k = 1; k <= nh; k++) if (h_kind[k] == "d") y++
      if (y) sources = sources (sources == "" ? "" : ",") "done-row:" y
      if (sources == "index") printf "empty\t%s\n", id

      # Title: the index line, else the first heading that names the number
      title = ix_title[id]
      if (title == "" && pe_n[id]) title = title_of(b_head[pe_b[id, 1]])
      if (title == "" && ae_n[id]) {
        # the section of the number itself, else the oldest one
        b = ae_b[id, ae_n[id]]
        for (k = 1; k <= ae_n[id]; k++) if (b_id[ae_b[id, k]] == id) { b = ae_b[id, k]; break }
        title = title_of(b_head[b])
        sub(/[ \t]*\([^()]*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][^()]*\)$/, "", title)
        sub(/[ \t]*(—|–|-)[ \t]*(DONE[ \t]*)?[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/, "", title)
      }
      if (title == "") title = id

      # Dates
      created = ""
      for (i = 1; i <= nh; i++) if (h_date[i] != "" && (created == "" || h_date[i] < created)) created = h_date[i]
      if (git_first[id] != "" && (created == "" || git_first[id] < created)) {
        created = git_first[id]; printf "date\t%s\tcreated\tgit\n", id
      }
      if (created == "") printf "missing\t%s\tcreated\n", id
      done = ""
      if (st == "DONE" || st == "DROPPED" || st == "SUPERSEDED") {
        for (i = 1; i <= nh; i++) if (h_date[i] > done) done = h_date[i]
        if (done == "" && st == "DONE" && git_done[id] != "") { done = git_done[id]; printf "date\t%s\tdone\tgit\n", id }
        if (done == "" && st == "DONE") printf "missing\t%s\tdone\n", id
      }

      f = id "-" slug(title) ".md"
      path = out "/" f
      printf "feature\t%s\t%s\tfeatures/%s\t%s\n", id, st, f, sources
      defaulted++

      emit("---")
      emit("id: " id)
      emit("title: " title)
      emit("type: feature")
      emit("status: " st)
      emit("size:")
      field("created", created)
      field("done", done)
      emit("depends-on:")
      field("superseded-by", st == "SUPERSEDED" ? ix_sup[id] : "")
      emit("---")
      emit("")
      emit("# " id " — " title)

      # Intake: the open entries up to their first substep
      plan_n = 0
      intake = 0
      for (k = 1; k <= pe_n[id]; k++) {
        b = pe_b[id, k]
        if (b_id[b] != id) { plan_b[++plan_n] = b; plan_at[plan_n] = 0; continue }
        plan_from = b_n[b] + 1
        for (i = 1; i <= b_n[b]; i++) {
          sub_id = (b_hl[b, i] ? f_id(substr(b_line[b, i], b_hl[b, i] + 2)) : "")
          if (sub_id != "" && sub_id != id) { plan_from = i; break }
        }
        span_skip(b, 1, plan_from - 1)
        if (sp_first) {
          if (!intake) { emit(""); emit("## " sec[1]); intake = 1 }
          emit("")
          for (i = sp_first; i <= sp_last; i++) if (!b_skip[b, i]) emit(shifted(b, i, 2 - b_level[b]))
        }
        if (plan_from <= b_n[b]) { plan_b[++plan_n] = b; plan_at[plan_n] = plan_from }
      }
      if (!intake && !pe_n[id] && !nh) {
        emit(""); emit("## " sec[1]); emit("")
        emit("<!-- migrated: the old FEATURE-INDEX had only this line for the number -->")
      }

      # Plan: the substeps still open
      if (plan_n) {
        emit(""); emit("## " sec[2])
        for (k = 1; k <= plan_n; k++) {
          b = plan_b[k]
          emit("")
          if (!plan_at[k]) {
            emit(substr("######", 1, 3) " " b_head[b])
            span_skip(b, 1, b_n[b])
          } else span_skip(b, plan_at[k], b_n[b])
          if (sp_first) {
            if (!plan_at[k]) emit("")
            # A substep that stood as its own entry keeps its children one level below it.
            for (i = sp_first; i <= sp_last; i++)
              if (!b_skip[b, i]) emit(shifted(b, i, (plan_at[k] ? 2 : 3) - b_level[b]))
          }
        }
      }

      # History: oldest first
      if (nh) {
        emit(""); emit("## " sec[3])
        for (k = 1; k <= nh; k++) {
          x = h_pos[k]
          emit("")
          if (h_kind[x] == "a") {
            b = h_ref[x]
            emit("### " b_head[b])
            span_skip(b, 1, b_n[b])
            if (sp_first) { emit(""); for (i = sp_first; i <= sp_last; i++) emit(shifted(b, i, 3 - b_level[b])) }
          } else {
            y = h_ref[x]
            emit("### " d_id[y] (d_date[y] != "" ? " (" d_date[y] ")" : ""))
            emit("")
            emit(d_desc[y])
          }
        }
      }
      close(path)
      for (k = 1; k <= nh; k++) delete h_kind[k]
    }

    # Like span, between FROM and TO, skipping removed status lines.
    function span_skip(b, from, to,    i, l) {
      sp_first = 0; sp_last = 0
      for (i = from; i <= to; i++) {
        l = trim(b_line[b, i])
        if (b_skip[b, i] || l == "" || l == "---") continue
        if (!sp_first) sp_first = i
        sp_last = i
      }
    }

    function archived(id,    k) {
      for (k = 1; k <= ae_n[base_of(id)]; k++) if (b_id[ae_b[base_of(id), k]] == id) return 1
      return 0
    }

    function has_substeps(id,    k, b, i, s) {
      for (k = 1; k <= pe_n[id]; k++) {
        b = pe_b[id, k]
        if (b_id[b] != id) return 1
        for (i = 1; i <= b_n[b]; i++) {
          if (!b_hl[b, i]) continue
          s = f_id(substr(b_line[b, i], b_hl[b, i] + 2))
          if (s != "" && s != id) return 1
        }
      }
      return 0
    }
  ' "$mg_p/PROGRESS.md" "$mg_archive" > "$WORK/listing"
  cat "$WORK/listing"
  [ -f "$mg_p/REQUIREMENTS.md" ] && printf 'requirements\tREQUIREMENTS.md\n'
  if [ -n "$INDEX_OPT" ]; then
    mg_next=$(awk -F "$TAB" '$1 == "next-feature" { print $2 }' "$WORK/listing")
    grep -q '^next-feature:' "$INDEX_OPT" || die "no next-feature line in $INDEX_OPT"
    sed "s/^next-feature:.*/next-feature: $mg_next/" "$INDEX_OPT" > "$mg_out/features/INDEX.md"
    printf 'index\tfeatures/INDEX.md\n'
  fi
  return 0
}

# --- Claude Code settings and the auto memory folder ------------------------------------

# The user settings the kit may set (update-conventions global), each with its check.
SETTINGS_KEYS='autoMemoryEnabled cleanupPeriodDays'

settings_value_ok() {  # NAME VALUE
  case $1 in
    autoMemoryEnabled)
      case $2 in true | false) return 0 ;; esac
      ;;
    cleanupPeriodDays)
      case $2 in '' | 0* | *[!0-9]*) ;; *) return 0 ;; esac
      ;;
  esac
  return 1
}

# Reads the JSON file FILE, whose top level must be an object. MODE get prints
# "file valid" and per name in KEYS "key <name> <raw value|missing|duplicate>"; MODE set
# writes FILE with the NAME=value pairs of SETS into OUT — an existing top-level member
# gets the new value in place, a missing one is inserted first in the object with the
# indentation of the members — and prints "set <name> <replaced|added>". Everything else
# stays byte for byte. An invalid file prints "file invalid <reason>" and exits 4.
json_top() {  # FILE MODE KEYS SETS OUT
  awk -v mode="$2" -v keys="$3" -v sets="$4" -v out="$5" '
    function fail(why) { if (!bad) reason = why; bad = 1; return 0 }
    function skipws() { while (p <= N && index(" \t\r\n", substr(S, p, 1))) p++ }
    function str(   c, e) {
      if (substr(S, p, 1) != "\"") return fail("string expected at " p)
      p++
      while (p <= N) {
        c = substr(S, p, 1)
        if (c == "\"") { p++; return 1 }
        if (c == "\\") {
          e = substr(S, p + 1, 1)
          if (e == "u") {
            if (substr(S, p + 2, 4) !~ /^[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]$/)
              return fail("bad \\u escape at " p)
            p += 6
            continue
          }
          if (!index("\"\\/bfnrt", e) || e == "") return fail("bad escape at " p)
          p += 2
          continue
        }
        p++
      }
      return fail("unterminated string")
    }
    function num() {
      if (!match(substr(S, p), /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][-+]?[0-9]+)?/))
        return fail("bad value at " p)
      p += RLENGTH
      return 1
    }
    function lit() {
      if (substr(S, p, 4) == "true" || substr(S, p, 4) == "null") { p += 4; return 1 }
      if (substr(S, p, 5) == "false") { p += 5; return 1 }
      return fail("bad value at " p)
    }
    function val(   c) {
      skipws()
      c = substr(S, p, 1)
      if (c == "{") return obj(0)
      if (c == "[") return arr()
      if (c == "\"") return str()
      if (c == "-" || index("0123456789", c)) return num()
      return lit()
    }
    function arr(   c) {
      p++
      skipws()
      if (substr(S, p, 1) == "]") { p++; return 1 }
      while (1) {
        if (!val()) return 0
        skipws()
        c = substr(S, p, 1)
        if (c == ",") { p++; continue }
        if (c == "]") { p++; return 1 }
        return fail("\",\" or \"]\" expected at " p)
      }
    }
    # top = 1 for the root object: its members are recorded (KS key start, VS/VE value).
    function obj(top,   c, ks, k, vs) {
      p++
      skipws()
      if (substr(S, p, 1) == "}") { if (top) CLOSE = p; p++; return 1 }
      while (1) {
        skipws()
        ks = p
        if (!str()) return 0
        k = substr(S, ks + 1, p - ks - 2)
        skipws()
        if (substr(S, p, 1) != ":") return fail("\":\" expected at " p)
        p++
        skipws()
        vs = p
        if (!val()) return 0
        if (top) {
          if (!FIRST) FIRST = ks
          if (k in VS) DUP[k] = 1
          VS[k] = vs; VE[k] = p
        }
        skipws()
        c = substr(S, p, 1)
        if (c == ",") { p++; continue }
        if (c == "}") { if (top) CLOSE = p; p++; return 1 }
        return fail("\",\" or \"}\" expected at " p)
      }
    }
    { S = S (NR > 1 ? "\n" : "") $0 }
    END {
      OFS = "\t"
      N = length(S); p = 1
      skipws()
      if (substr(S, p, 1) != "{") fail("the top level is not an object")
      else { OPEN = p; if (obj(1)) { skipws(); if (p <= N) fail("text after the object") } }
      if (bad) { print "file", "invalid", reason; exit 4 }
      if (mode == "get") {
        print "file", "valid"
        nk = split(keys, K, " ")
        for (i = 1; i <= nk; i++) {
          k = K[i]
          if (k in DUP) print "key", k, "duplicate"
          else if (k in VS) print "key", k, substr(S, VS[k], VE[k] - VS[k])
          else print "key", k, "missing"
        }
        exit 0
      }
      ns = split(sets, A, " ")
      for (i = 1; i <= ns; i++) {
        k = substr(A[i], 1, index(A[i], "=") - 1); NV[k] = substr(A[i], index(A[i], "=") + 1)
        if (k in DUP) { print "file", "invalid", "\"" k "\" appears twice"; exit 4 }
        if (k in VS) { nr++; R[nr] = k } else { na++; ADD[na] = k }
      }
      # Replace from the back, so earlier positions stay valid.
      for (i = 1; i <= nr; i++) for (j = i + 1; j <= nr; j++)
        if (VS[R[j]] > VS[R[i]]) { t = R[i]; R[i] = R[j]; R[j] = t }
      for (i = 1; i <= nr; i++) {
        k = R[i]
        S = substr(S, 1, VS[k] - 1) NV[k] substr(S, VE[k])
      }
      if (na && !FIRST) {
        # An empty object gets the members on lines of their own.
        ins = ""
        for (i = 1; i <= na; i++) ins = ins (i > 1 ? "," : "") "\n  \"" ADD[i] "\": " NV[ADD[i]]
        S = substr(S, 1, OPEN) ins "\n" substr(S, CLOSE)
      } else if (na) {
        pre = substr(S, OPEN + 1, FIRST - OPEN - 1)
        nl = 0
        for (i = 1; i <= length(pre); i++) if (substr(pre, i, 1) == "\n") nl = i
        ins = ""
        if (nl) {
          ind = substr(pre, nl + 1)
          for (i = 1; i <= na; i++) ins = ins "\n" ind "\"" ADD[i] "\": " NV[ADD[i]] ","
          S = substr(S, 1, OPEN) ins substr(S, OPEN + 1)
        } else {
          for (i = 1; i <= na; i++) ins = ins "\"" ADD[i] "\": " NV[ADD[i]] ", "
          S = substr(S, 1, FIRST - 1) ins substr(S, FIRST)
        }
      }
      printf "%s\n", S > out
      close(out)
      for (i = 1; i <= ns; i++) {
        k = substr(A[i], 1, index(A[i], "=") - 1)
        print "set", k, ((k in VS) ? "replaced" : "added")
      }
    }' "$1"
}

settings() {
  [ $# -eq 1 ] || usage
  ST_CONFIG=$1
  [ -d "$ST_CONFIG" ] || die "config folder not found: $ST_CONFIG"
  if [ ! -f "$ST_CONFIG/settings.json" ]; then
    printf 'file\tmissing\n'
    for st_key in $SETTINGS_KEYS; do printf 'key\t%s\tmissing\n' "$st_key"; done
    return 0
  fi
  json_top "$ST_CONFIG/settings.json" get "$SETTINGS_KEYS" '' '' || [ $? -eq 4 ]
}

set_settings() {
  [ $# -ge 3 ] || usage
  SS_CONFIG=$1 SS_OUT=$2
  shift 2
  [ -d "$SS_CONFIG" ] || die "config folder not found: $SS_CONFIG"
  check_out_dir "$SS_OUT"
  setup_work
  ss_sets=
  for ss_arg in "$@"; do
    case $ss_arg in
      *=*) ;;
      *) die "expected NAME=value, not '$ss_arg'" ;;
    esac
    ss_key=${ss_arg%%=*}
    ss_val=${ss_arg#*=}
    case " $SETTINGS_KEYS " in
      *" $ss_key "*) ;;
      *) die "$ss_key: not a setting the kit sets ($SETTINGS_KEYS)" ;;
    esac
    case " $ss_sets " in
      *" $ss_key="*) die "$ss_key: given twice" ;;
    esac
    settings_value_ok "$ss_key" "$ss_val" || die "$ss_key: invalid value '$ss_val'"
    ss_sets="$ss_sets $ss_arg"
  done
  ss_src=$SS_CONFIG/settings.json
  if [ ! -f "$ss_src" ]; then
    printf '{}\n' > "$WORK/settings.json"
    ss_src=$WORK/settings.json
  fi
  mkdir -p "$SS_OUT"
  json_top "$ss_src" set '' "$ss_sets" "$SS_OUT/settings.json" > "$WORK/listing" || {
    ss_why=$(cut -f3 "$WORK/listing")
    rm -f "$SS_OUT/settings.json"
    die "$SS_CONFIG/settings.json: not valid JSON ($ss_why) — nothing written"
  }
  cat "$WORK/listing"
  printf 'written\tsettings.json\n'
}

# A path as Claude Code names its project folder: every byte that is not an ASCII
# letter or digit becomes "-".
project_dir_name() {  # PATH
  printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9]/-/g'
}

# The string value of autoMemoryDirectory in the settings FILE, "~/" expanded; empty
# when the file lacks it. A value that is no plain absolute or ~/ path is skipped with a
# note, as Claude Code does not take it either.
memory_setting() {  # FILE
  [ -f "$1" ] || return 0
  ms_out=$(json_top "$1" get autoMemoryDirectory '' '') \
    || { printf 'template-sync: %s: not valid JSON, skipped\n' "$1" >&2; return 0; }
  ms_line=$(printf '%s\n' "$ms_out" | awk -F "$TAB" '$1 == "key" { print $3 }')
  case $ms_line in
    missing | '') return 0 ;;
    '"~/'*'"' | '"/'*'"') ;;
    *)
      printf 'template-sync: %s: autoMemoryDirectory %s is no absolute or ~/ path, skipped\n' \
        "$1" "$ms_line" >&2
      return 0
      ;;
  esac
  ms_val=${ms_line#\"}
  ms_val=${ms_val%\"}
  case $ms_val in
    *\\*)
      printf 'template-sync: %s: autoMemoryDirectory with an escape, skipped\n' "$1" >&2
      return 0
      ;;
    '~/'*) ms_val=$HOME/${ms_val#'~/'} ;;
  esac
  printf '%s\n' "$ms_val"
}

memory_line() {  # STAGE SCOPE DIR
  ml_state=absent
  if [ -d "$3" ]; then ml_state=present; fi
  printf '%s\t%s\t%s\t%s\n' "$1" "$ml_state" "$2" "$3"
}

# own, or shared when a transcript in the project folder FOLDER names a name twin: a
# working directory other than PATH and PATH2 that the name rule maps to the same folder
# ("my app" and "my.app"), so Claude Code shares it between both projects. Other paths
# a transcript names (a cd during the session) say nothing about the folder.
folder_scope() {  # FOLDER PATH PATH2
  grep -oh '"cwd":"[^"]*"' "$1"/*.jsonl 2> /dev/null | sort -u |
    LC_ALL=C awk -v name="${1##*/}" -v a="$2" -v b="$3" '
      {
        c = $0
        sub(/^"cwd":"/, "", c); sub(/"$/, "", c)
        if (c == a || c == b) next
        e = c
        gsub(/[^A-Za-z0-9]/, "-", e)
        if (e == name) twin = 1
      }
      END { print (twin ? "shared" : "own") }'
}

memory_dir() {
  [ $# -eq 2 ] || usage
  MD_CONFIG=$1 MD_P=$2
  [ -d "$MD_CONFIG" ] || die "config folder not found: $MD_CONFIG"
  [ -d "$MD_P" ] || die "project not found: $MD_P"
  # 2. autoMemoryDirectory: local before project before user settings. Set by the user,
  # it holds the memory of every project.
  for md_scope in own:"$MD_P/.claude/settings.local.json" own:"$MD_P/.claude/settings.json" \
    shared:"$MD_CONFIG/settings.json"; do
    md_dir=$(memory_setting "${md_scope#*:}")
    if [ -n "$md_dir" ]; then
      memory_line setting "${md_scope%%:*}" "$md_dir"
      return 0
    fi
  done
  # A folder name of one's own for every project of this config folder.
  if [ -n "${CLAUDE_CODE_PROJECT_DIR_NAME:-}" ]; then
    memory_line env shared "$MD_CONFIG/projects/$CLAUDE_CODE_PROJECT_DIR_NAME/memory"
    return 0
  fi
  # The repository the memory belongs to: worktrees share the one of the main checkout.
  md_common=$(git -C "$MD_P" rev-parse --git-common-dir 2> /dev/null) || md_common=
  case $md_common in
    .git | */.git) md_root=$(cd "$MD_P" && cd "$md_common/.." && pwd) ;;
    '') md_root=$(cd "$MD_P" && pwd) ;;
    *) md_root=$(git -C "$MD_P" rev-parse --show-toplevel) ;;
  esac
  md_phys=$(cd "$md_root" && pwd -P)
  # 3. The folder name derived from the path, as written and with symlinks resolved.
  for md_path in "$md_root" "$md_phys"; do
    md_name=$(project_dir_name "$md_path")
    if [ -d "$MD_CONFIG/projects/$md_name" ]; then
      memory_line name "$(folder_scope "$MD_CONFIG/projects/$md_name" "$md_root" "$md_phys")" \
        "$MD_CONFIG/projects/$md_name/memory"
      return 0
    fi
  done
  # 4. A folder whose transcripts name the path as their working directory (umlauts or
  # another path form give another name); several are listed for the skill to ask.
  md_found=0
  if [ -d "$MD_CONFIG/projects" ]; then
    for md_folder in "$MD_CONFIG/projects"/*/; do
      [ -d "$md_folder" ] || continue
      for md_path in "$md_root" "$md_phys"; do
        md_hit=$(grep -lF -e "\"cwd\":\"$md_path\"" -e "\"cwd\":\"$md_path/" \
          "$md_folder"*.jsonl 2> /dev/null | head -n 1) || md_hit=
        if [ -n "$md_hit" ]; then
          memory_line transcript "$(folder_scope "${md_folder%/}" "$md_root" "$md_phys")" \
            "${md_folder%/}/memory"
          md_found=1
          break
        fi
      done
    done
  fi
  if [ "$md_found" -eq 0 ]; then
    memory_line none own "$MD_CONFIG/projects/$(project_dir_name "$md_root")/memory"
  fi
  return 0
}

# --- host: the project's git host (MANIFEST § Hosts) --------------------------------

# Refuses a HOST value that is not exactly one name of HOSTS (an empty one too).
check_host() {  # VALUE
  case $1 in
    '' | *[!a-z]*) ;;
    *) case " $HOSTS " in *" $1 "*) return 0 ;; esac ;;
  esac
  die "answers: HOST must be one of: $HOSTS — not '$1'"
}

# The kind of server a remote URL points to, and its host name: "KIND<TAB>NAME". Kinds:
# a name of HOSTS, a recognized host the kit does not support yet (azure, gitlab,
# forgejo), other (any other server), local (a path or file:// URL). Only the host name
# leaves this function — never the user, a password or a token a URL may carry.
remote_kind() {  # URL
  rk_url=$1
  case $rk_url in
    file://*) printf 'local\t-\n'; return 0 ;;
    *://*)
      rk_name=${rk_url#*://}
      rk_name=${rk_name%%/*}
      ;;
    *:*)
      # scp form [user@]host:path — git reads it so only when no / precedes the colon.
      rk_name=${rk_url%%:*}
      case $rk_name in
        */* | '') printf 'local\t-\n'; return 0 ;;
      esac
      ;;
    *) printf 'local\t-\n'; return 0 ;;
  esac
  rk_name=${rk_name##*@}
  rk_name=${rk_name%%:*}
  rk_name=$(printf '%s' "$rk_name" | tr 'A-Z' 'a-z')
  case $rk_name in
    # A single letter is a Windows drive (C:\repo, C:/repo), not a server.
    ? | '') printf 'local\t-\n'; return 0 ;;
    github.com | ssh.github.com) rk_kind=github ;;
    dev.azure.com | ssh.dev.azure.com | *.visualstudio.com) rk_kind=azure ;;
    gitlab.com) rk_kind=gitlab ;;
    codeberg.org) rk_kind=forgejo ;;
    *) rk_kind=other ;;
  esac
  printf '%s\t%s\n' "$rk_kind" "$rk_name"
}

# The host of PROJECT, for host and commit-email (set_paths and setup_work first). Sets
# HO_HOST (HOST of the answers, empty without), HO_REMOTE ("kind<TAB>name" of origin),
# HO_KIND, HO_SUGGEST (what the remote suggests: a supported host as itself, anything
# else git) and HO_SOURCE (answers, remote or none) with HO_EFFECTIVE, the host in effect.
resolve_host() {  # PROJECT
  # HOST from the answers; a missing file or key leaves it empty. A value that is not
  # exactly one name of HOSTS — also an empty one — is refused.
  HO_HOST=
  if [ -f "$ANS_PATH" ]; then
    load_answers "$ANS_PATH" > "$WORK/values.tsv" || die "answers are invalid: $ANS_PATH"
    if HO_HOST=$(value_of HOST); then
      check_host "$HO_HOST"
    else
      HO_HOST=
    fi
  fi
  # The remote: origin only; a project that is no git repository has none.
  rh_url=$(git -C "$1" remote get-url origin 2> /dev/null) || rh_url=
  if [ -n "$rh_url" ]; then
    HO_REMOTE=$(remote_kind "$rh_url")
  else
    HO_REMOTE="none$TAB-"
  fi
  HO_KIND=${HO_REMOTE%%"$TAB"*}
  case " $HOSTS " in
    *" $HO_KIND "*) HO_SUGGEST=$HO_KIND ;;
    *) HO_SUGGEST=git ;;
  esac
  if [ -n "$HO_HOST" ]; then
    HO_EFFECTIVE=$HO_HOST HO_SOURCE=answers
  elif [ "$HO_KIND" = none ]; then
    HO_EFFECTIVE=$HO_SUGGEST HO_SOURCE=none
  else
    HO_EFFECTIVE=$HO_SUGGEST HO_SOURCE=remote
  fi
}

host() {
  [ $# -eq 1 ] || usage
  [ -d "$1" ] || die "project not found: $1"
  set_paths "$1"
  setup_work
  resolve_host "$1"
  printf 'host\t%s\t%s\n' "$HO_EFFECTIVE" "$HO_SOURCE"
  printf 'remote\t%s\n' "$HO_REMOTE"
  # A recognized host that is no supported one yet (remote_kind names the recognized).
  case $HO_KIND in
    other | local | none) ;;
    "$HO_SUGGEST") ;;
    *) printf 'unsupported\t%s\n' "$HO_KIND" ;;
  esac
  if [ "$HO_KIND" = none ]; then
    ho_others=$(git -C "$1" remote 2> /dev/null | tr '\n' ',' | sed 's/,$//') || ho_others=
    [ -z "$ho_others" ] || printf 'no-origin\t%s\n' "$ho_others"
  fi
  if [ -n "$HO_HOST" ] && [ "$HO_HOST" != "$HO_SUGGEST" ]; then
    printf 'mismatch\t%s\t%s\n' "$HO_HOST" "$HO_KIND"
  fi
  return 0
}

# --- commit-email: the commit address of a project's host ---------------------------

# The personal config key of the commit address on HOST, without the CODING_KIT_ prefix.
email_key() {  # HOST
  printf 'EMAIL_%s' "$(printf '%s' "$1" | tr 'a-z' 'A-Z')"
}

# The address keys of all hosts, in the order of HOSTS.
email_keys() {
  for ek_host in $HOSTS; do printf ' %s' "$(email_key "$ek_host")"; done
}

# --- default-host: the host a new project starts on --------------------------------

default_host() {
  [ $# -eq 1 ] || usage
  setup_work
  : > "$WORK/env.tsv"
  if [ -f "$1" ]; then
    load_env "$1" > "$WORK/env.tsv" || die "personal config is invalid: $1"
  fi
  if dh_host=$(env_value DEFAULT_HOST) && [ -n "$dh_host" ]; then
    case " $HOSTS " in
      *" $dh_host "*) printf 'default-host\t%s\tconfig\n' "$dh_host" ;;
      *) printf 'default-host\tgithub\tinvalid\t%s\n' "$dh_host" ;;
    esac
  else
    printf 'default-host\tgithub\tnone\n'
  fi
}

# Before the keys per host the personal config had one address, always GitHub's.
LEGACY_EMAIL_KEY=GIT_NOREPLY_EMAIL

commit_email() {
  [ $# -eq 2 ] || usage
  CE_ENV=$1
  [ -d "$2" ] || die "project not found: $2"
  set_paths "$2"
  setup_work
  resolve_host "$2"
  : > "$WORK/env.tsv"
  if [ -f "$CE_ENV" ]; then
    load_env "$CE_ENV" > "$WORK/env.tsv" || die "personal config is invalid: $CE_ENV"
  fi
  # Only the key of this host counts — never the address of another one.
  ce_key=$(email_key "$HO_EFFECTIVE")
  if ce_addr=$(env_value "$ce_key") && [ -n "$ce_addr" ]; then
    ce_state=config
  elif [ "$HO_EFFECTIVE" = github ] && ce_addr=$(env_value "$LEGACY_EMAIL_KEY") \
    && [ -n "$ce_addr" ]; then
    ce_state=legacy ce_key=$LEGACY_EMAIL_KEY
  else
    ce_state=missing ce_addr=-
  fi
  # Only plain addresses pass: a skill puts the value into a shell command.
  if [ "$ce_state" != missing ] && ! printf '%s\n' "$ce_addr" \
    | grep -Eqx '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'; then
    ce_state=invalid
  fi
  printf 'host\t%s\t%s\n' "$HO_EFFECTIVE" "$HO_SOURCE"
  printf 'email\t%s\tCODING_KIT_%s\t%s\n' "$ce_state" "$ce_key" "$ce_addr"
  return 0
}

cmd=${1:-}
[ $# -eq 0 ] || shift
parse_opts "$cmd" "$@"
shift "$OPTS_SHIFT"
case $cmd in
  render) render "$@" ;;
  render-global) render_global "$@" ;;
  set-global) set_global "$@" ;;
  status) status "$@" ;;
  changed) changed "$@" ;;
  merge) merge "$@" ;;
  snapshot) snapshot "$@" ;;
  base-from-history) base_from_history "$@" ;;
  zones) zones "$@" ;;
  lock-check) lock_check "$@" ;;
  detect) detect "$@" ;;
  migrate) migrate "$@" ;;
  settings) settings "$@" ;;
  set-settings) set_settings "$@" ;;
  memory-dir) memory_dir "$@" ;;
  host) host "$@" ;;
  commit-email) commit_email "$@" ;;
  default-host) default_host "$@" ;;
  *) usage ;;
esac
