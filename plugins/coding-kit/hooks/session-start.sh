#!/usr/bin/env bash
# coding-kit SessionStart hook: one line of context when the kit's global rules need a
# sync, silent otherwise. It only reads; it never writes a file.
#
# Hints, for Claude to pass on to the user once:
#   - CLAUDE.md in the Claude config folder is a copy of the former kit template (its
#     header line): /coding-kit:update-conventions global moves the kit part into the
#     rules file and keeps the personal lines.
#   - rules/coding-kit.md carries the kit identifier, and the kit file rendered with the
#     current personal values differs from the base of the last sync
#     (${CLAUDE_PLUGIN_DATA}/global-base, set by update-conventions): the kit rules or
#     the values changed.
#   - The personal config cannot be read.
# A user without the kit's global rules, or with a rules file of their own, hears
# nothing. Every path exits 0, so a hiccup never shows up as a hook error.
set -u

# The session info on stdin is not needed.
cat > /dev/null 2>&1 || true

CONFIG="${CLAUDE_CONFIG_DIR:-${HOME:-}/.claude}"
ROOT="${CLAUDE_PLUGIN_ROOT:-}"
DATA="${CLAUDE_PLUGIN_DATA:-}"
RULES="$CONFIG/rules/coding-kit.md"
OLD_HEADER='Gepflegt als Vorlage im coding-kit'
ID_LINE='<!-- coding-kit:global-rules -->'
COMMAND='/coding-kit:update-conventions global'

hints=

if [ -f "$CONFIG/CLAUDE.md" ] && grep -qF -- "$OLD_HEADER" "$CONFIG/CLAUDE.md" 2> /dev/null; then
  hints="$hints $CONFIG/CLAUDE.md is a copy of the former kit template; $COMMAND moves the kit part to $RULES and keeps the personal lines."
fi

if [ -n "$ROOT" ] && [ -f "$RULES" ] && [ "$(sed -n 1p "$RULES" 2> /dev/null)" = "$ID_LINE" ]; then
  work=$(mktemp -d "${TMPDIR:-/tmp}/coding-kit-hook.XXXXXX" 2> /dev/null) || exit 0
  trap 'rm -rf "$work"' EXIT
  if sh "$ROOT/scripts/template-sync.sh" render-global "$ROOT/global/coding-kit.md" \
    "$CONFIG/coding-kit.env" "$work/out" > /dev/null 2>&1; then
    # Without a data folder there is no base to compare with: say nothing.
    if [ -n "$DATA" ] && ! cmp -s "$work/out/rules/coding-kit.md" "$DATA/global-base/rules/coding-kit.md.base"; then
      hints="$hints The kit's global rules or the personal values changed since the last sync; $COMMAND shows the changes section by section."
    fi
  else
    hints="$hints The personal config $CONFIG/coding-kit.env cannot be read for the kit's global rules; $COMMAND shows why."
  fi
fi

[ -n "$hints" ] || exit 0

# English on purpose, like the stop hook: an instruction to Claude in any project.
text="[coding-kit]$hints Tell the user once, briefly; the user starts the command."
escaped=$(printf '%s' "$text" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "%s"}}\n' "$escaped"
exit 0
