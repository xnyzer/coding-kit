#!/usr/bin/env bash
# coding-kit stop hook: block the stop ONCE per stop cycle when a kit-managed
# project has uncommitted work, so /step-done (checks, secrets scan, docs,
# commit question) is not forgotten.
#
# Project detection — fires ONLY when at least one of these exists:
#   - PROGRESS.md containing a FEATURE-INDEX block
#   - .claude/template-version (stamped by /new-project)
# In any other repository the hook stays completely silent.
#
# Loop protection: when stdin carries "stop_hook_active": true this stop was
# already blocked once by a stop hook — allow it through (exit 0).
set -u

STDIN_JSON="$(cat 2>/dev/null || true)"

# Already continuing because of a stop hook → never block twice.
if printf '%s' "$STDIN_JSON" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# --- project detection -------------------------------------------------------
is_kit_project=false
if [ -f "$DIR/.claude/template-version" ]; then
  is_kit_project=true
elif [ -f "$DIR/PROGRESS.md" ] && grep -q "FEATURE-INDEX" "$DIR/PROGRESS.md" 2>/dev/null; then
  is_kit_project=true
fi
[ "$is_kit_project" = true ] || exit 0

# --- uncommitted work? -------------------------------------------------------
git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

dirty=false
git -C "$DIR" diff --quiet HEAD 2>/dev/null || dirty=true            # unstaged (tracked)
git -C "$DIR" diff --cached --quiet 2>/dev/null || dirty=true        # staged
if [ -n "$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null)" ]; then
  dirty=true                                                          # untracked, not ignored
fi
[ "$dirty" = true ] || exit 0

# Block the stop once and point at /step-done. English on purpose: the message
# is an instruction to Claude inside arbitrary (often public/English) projects.
cat <<'JSON'
{
  "decision": "block",
  "reason": "[coding-kit] Uncommitted changes in this project. If the current task is finished, run /coding-kit:step-done (checks, secrets scan, PROGRESS docs, commit question). If work is still in progress, briefly tell the user this reminder was deferred and continue. Never commit without explicit user approval."
}
JSON
exit 0
