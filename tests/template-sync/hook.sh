# Hook cases for tests/template-sync/run.sh — sourced after global.sh, uses its helpers.
# The SessionStart hook runs with $SH against a stand-in Claude config folder
# (CLAUDE_CONFIG_DIR) and plugin data folder (CLAUDE_PLUGIN_DATA); it must never fail.
# The Stop hook runs with $SH in stand-in git repositories (CLAUDE_PROJECT_DIR).

HOOK=$ROOT/plugins/coding-kit/hooks/session-start.sh
STOP_HOOK=$ROOT/plugins/coding-kit/hooks/stop-reminder.sh

# stop_hook NAME [STDIN] — runs the Stop hook for the repository $TMP/NAME; stdout in
# $TMP/NAME.out, exit status in $TMP/NAME.rc.
stop_hook() {
  sh_input='{"hook_event_name": "Stop"}'
  [ $# -gt 1 ] && sh_input=$2
  printf '%s' "$sh_input" |
    CLAUDE_PROJECT_DIR="$TMP/$1" $SH "$STOP_HOOK" > "$TMP/$1.out" 2> "$TMP/$1.err"
  echo $? > "$TMP/$1.rc"
}

# repo NAME [FILE…] — a git repository with the files (empty content), all committed.
repo() {
  rp_name=$1
  shift
  rm -rf "${TMP:?}/$rp_name"
  mkdir -p "$TMP/$rp_name"
  git -C "$TMP/$rp_name" init -q
  for rp_file in "$@"; do
    mkdir -p "$(dirname "$TMP/$rp_name/$rp_file")"
    : > "$TMP/$rp_name/$rp_file"
  done
  git -C "$TMP/$rp_name" add -A
  git -C "$TMP/$rp_name" -c user.name=test -c user.email=test@example.com \
    commit -q --allow-empty -m init
}

blocks() {  # NAME — exit 0 and the block decision in the output
  [ "$(cat "$TMP/$1.rc")" = 0 ] && grep -q '"decision": "block"' "$TMP/$1.out"
}

# hook NAME — runs the hook for $TMP/NAME.cfg and $TMP/NAME.data; stdout in
# $TMP/NAME.out, exit status in $TMP/NAME.rc.
hook() {
  printf '{"hook_event_name": "SessionStart", "source": "startup"}' |
    CLAUDE_CONFIG_DIR="$TMP/$1.cfg" CLAUDE_PLUGIN_ROOT="$ROOT/plugins/coding-kit" \
      CLAUDE_PLUGIN_DATA="$TMP/$1.data" $SH "$HOOK" > "$TMP/$1.out" 2> "$TMP/$1.err"
  echo $? > "$TMP/$1.rc"
}

silent() {  # NAME — exit 0 and no output
  [ "$(cat "$TMP/$1.rc")" = 0 ] && [ ! -s "$TMP/$1.out" ]
}

says() {  # NAME TEXT — exit 0 and TEXT in the output
  [ "$(cat "$TMP/$1.rc")" = 0 ] && grep -qF -- "$2" "$TMP/$1.out"
}

# The output is one line of SessionStart context in the documented JSON shape.
context_json() {  # NAME
  [ "$(wc -l < "$TMP/$1.out" | tr -d ' ')" = 1 ] &&
    grep -q '^{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "\[coding-kit\] .*"}}$' "$TMP/$1.out"
}

# synced NAME ENV-LINE… — config folder with the env lines, the rendered rules installed
# and the base of that sync set, as update-conventions global leaves them.
synced() {
  sy_name=$1
  shift
  mkdir -p "$TMP/$sy_name.cfg/rules"
  printf '%s\n' "$@" > "$TMP/$sy_name.cfg/coding-kit.env"
  ts render-global "$KIT" "$TMP/$sy_name.cfg/coding-kit.env" "$TMP/$sy_name.soll" > /dev/null &&
    cp "$TMP/$sy_name.soll/$G" "$TMP/$sy_name.cfg/$G" &&
    ts snapshot --snapshot "$TMP/$sy_name.data/global-base" "$TMP/$sy_name.cfg" \
      "$TMP/$sy_name.soll" "$G" > /dev/null
}

run_hook_cases() {
  # Stop hook: a project with features/INDEX.md and open changes gets one reminder
  repo s-feat features/INDEX.md
  printf 'change\n' > "$TMP/s-feat/features/INDEX.md"
  stop_hook s-feat
  check "stop hook: features/INDEX.md with open changes blocks once" blocks s-feat
  check "stop hook: the reminder names step-done" says s-feat '/coding-kit:step-done'
  stop_hook s-feat '{"stop_hook_active": true}'
  check "stop hook: never blocks twice in one stop cycle" silent s-feat
  repo s-clean features/INDEX.md
  stop_hook s-clean
  check "stop hook: features/INDEX.md, nothing open: silent" silent s-clean
  repo s-new features/INDEX.md
  : > "$TMP/s-new/untracked.txt"
  stop_hook s-new
  check "stop hook: an untracked file counts as open" blocks s-new
  repo s-old PROGRESS.md
  printf '<!-- FEATURE-INDEX\nnext-feature: F-002\n-->\n' > "$TMP/s-old/PROGRESS.md"
  stop_hook s-old
  check "stop hook: old format before the migration still blocks" blocks s-old
  repo s-stamp .claude/template-version
  : > "$TMP/s-stamp/work.txt"
  stop_hook s-stamp
  check "stop hook: a stamped project blocks" blocks s-stamp
  repo s-foreign README.md
  printf 'change\n' > "$TMP/s-foreign/README.md"
  : > "$TMP/s-foreign/PROGRESS.md"
  stop_hook s-foreign
  check "stop hook: a foreign repository stays silent" silent s-foreign

  # The header of the former template, shortened to the part the hook looks for.
  OLD_COPY='# Globale House-Defaults — Claude Code\n\n> Gepflegt als Vorlage im coding-kit; auf neuen Rechnern richtet der Installer sie ein.\n\n## Sprache & Stil\n'

  mkdir -p "$TMP/h-none.cfg"
  hook h-none
  check "hook: no global rules, no CLAUDE.md: silent" silent h-none

  put h-own.cfg/CLAUDE.md '# My rules\n\n- Answer in English.\n'
  hook h-own
  check "hook: only a CLAUDE.md of the user's own: silent" silent h-own

  put h-old.cfg/CLAUDE.md "$OLD_COPY"
  hook h-old
  check "hook: old kit copy is reported" says h-old 'is a copy of the former kit template'
  check "hook: old kit copy names the command" says h-old '/coding-kit:update-conventions global'
  check "hook: the hint is SessionStart context JSON" context_json h-old

  check "hook setup: synced rules" synced h-sync 'CODING_KIT_EXPLAIN_LEVEL=junior'
  hook h-sync
  check "hook: rules equal to the last sync: silent" silent h-sync

  check "hook setup: synced rules, change declined" synced h-dec 'CODING_KIT_EXPLAIN_LEVEL=junior'
  edit_rules h-dec.cfg '{ sub(/Conventional Commits, englisch/, "Conventional Commits, deutsch"); print }'
  hook h-dec
  check "hook: a declined or local change is not reported again" silent h-dec

  # An older kit text in the base stands in for a kit update since the last sync.
  check "hook setup: synced rules, kit changed" synced h-kit 'CODING_KIT_EXPLAIN_LEVEL=junior'
  awk '{ sub(/Direkt und präzise\./, "Direkt."); print }' "$TMP/h-kit.data/global-base/$G.base" \
    > "$TMP/h-kit.base.tmp" && mv "$TMP/h-kit.base.tmp" "$TMP/h-kit.data/global-base/$G.base"
  hook h-kit
  check "hook: kit rules changed since the last sync are reported" says h-kit 'changed since the last sync'
  check "hook: the change hint is SessionStart context JSON" context_json h-kit

  check "hook setup: synced rules, value changed" synced h-val 'CODING_KIT_EXPLAIN_LEVEL=junior'
  printf '%s\n' 'CODING_KIT_EXPLAIN_LEVEL=senior' > "$TMP/h-val.cfg/coding-kit.env"
  hook h-val
  check "hook: a changed value is reported" says h-val 'changed since the last sync'

  check "hook setup: synced rules, base missing" synced h-nob 'CODING_KIT_EXPLAIN_LEVEL=junior'
  rm -rf "$TMP/h-nob.data"
  hook h-nob
  check "hook: rules without a base are reported" says h-nob 'changed since the last sync'

  check "hook setup: synced rules, broken config" synced h-bad 'CODING_KIT_EXPLAIN_LEVEL=junior'
  printf '%s\n' 'CODING_KIT_EXPLAIN_LEVEL="junior' > "$TMP/h-bad.cfg/coding-kit.env"
  hook h-bad
  check "hook: an unreadable personal config is reported" says h-bad 'cannot be read'

  put h-for.cfg/rules/coding-kit.md '# my own rules file\n'
  hook h-for
  check "hook: a rules file without the kit identifier: silent" silent h-for

  check "hook setup: synced rules next to an old copy" synced h-both 'CODING_KIT_EXPLAIN_LEVEL=junior'
  put h-both.cfg/CLAUDE.md "$OLD_COPY"
  hook h-both
  check "hook: old copy next to synced rules is still reported" says h-both 'is a copy of the former kit template'
  refute "hook: synced rules next to an old copy are not reported as changed" \
    says h-both 'changed since the last sync'
}
