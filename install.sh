#!/usr/bin/env bash
# coding-kit installer — new-machine bootstrap. Idempotent: safe to re-run anytime.
#
# What it does (each step checks state first, nothing runs twice):
#   1. Preconditions: gh (authenticated) and claude must be installed.
#   2. Adds the xnyzer marketplace and installs the coding-kit plugin.
#   3. Creates the personal config ~/.claude/coding-kit.env (prefilled via gh api).
#   4. Offers to install the global ~/.claude/CLAUDE.md from the kit template (once it ships).
#   5. Checks the base toolchain (mise, just, lefthook, gitleaks); offers brew install.
#
# Usage:
#   ./install.sh            # normal run (marketplace from GitHub)
#   ./install.sh --local    # add the marketplace from this checkout instead (development)
set -euo pipefail

MARKETPLACE_REPO="xnyzer/coding-kit"
MARKETPLACE_NAME="xnyzer"
PLUGIN_NAME="coding-kit"
ENV_FILE="$HOME/.claude/coding-kit.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CLAUDE_TEMPLATE="$SCRIPT_DIR/templates/global-CLAUDE.md"
LOCAL_MODE=false
[ "${1:-}" = "--local" ] && LOCAL_MODE=true

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
fail() { printf '    \033[31m✗\033[0m %s\n' "$*"; exit 1; }

ask_yes_no() { # $1 question, $2 default (j/n)
  local answer default="${2:-n}"
  read -r -p "    $1 [$([ "$default" = j ] && echo "J/n" || echo "j/N")] " answer || true
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[jJyY] ]]
}

# --- 1. Preconditions --------------------------------------------------------
say "Voraussetzungen prüfen"

command -v gh >/dev/null 2>&1 || fail "gh (GitHub CLI) fehlt — installieren: brew install gh"
gh auth status >/dev/null 2>&1 || fail "gh ist nicht authentifiziert — ausführen: gh auth login"
ok "gh installiert und authentifiziert"

command -v claude >/dev/null 2>&1 || fail "claude (Claude Code) fehlt — siehe https://code.claude.com/docs"
ok "claude installiert ($(claude --version 2>/dev/null | head -1))"

# --- 2. Marketplace + plugin -------------------------------------------------
say "Marketplace & Plugin"

if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
  ok "Marketplace '$MARKETPLACE_NAME' ist bereits eingerichtet"
else
  if [ "$LOCAL_MODE" = true ]; then
    claude plugin marketplace add "$SCRIPT_DIR"
    ok "Marketplace '$MARKETPLACE_NAME' aus lokalem Checkout hinzugefügt"
  else
    claude plugin marketplace add "$MARKETPLACE_REPO"
    ok "Marketplace '$MARKETPLACE_NAME' von GitHub ($MARKETPLACE_REPO) hinzugefügt"
  fi
fi

if claude plugin list 2>/dev/null | grep -q "$PLUGIN_NAME"; then
  ok "Plugin '$PLUGIN_NAME' ist bereits installiert"
else
  claude plugin install "$PLUGIN_NAME@$MARKETPLACE_NAME"
  ok "Plugin '$PLUGIN_NAME@$MARKETPLACE_NAME' installiert"
  warn "Skills sind ggf. erst nach einem Session-Neustart sichtbar (/coding-kit:<skill>)"
fi

# --- 3. Personal config ------------------------------------------------------
say "Personal-Config ($ENV_FILE)"

if [ -f "$ENV_FILE" ]; then
  ok "existiert bereits — wird nicht angefasst (löschen und erneut ausführen zum Neuanlegen)"
else
  # Prefill what is resolvable at runtime; skills still prefer live resolution,
  # this file is the offline fallback plus the non-resolvable personal choices.
  GH_LOGIN="$(gh api user --jq '.login')"
  GH_ID="$(gh api user --jq '.id')"
  GH_NAME="$(gh api user --jq '.name // .login')"
  NOREPLY="${GH_ID}+${GH_LOGIN}@users.noreply.github.com"
  DEFAULT_PROJECTS_DIR="$HOME/Documents/Coding-Projects"

  echo "    Vorbefüllt via gh api: Login '$GH_LOGIN', E-Mail '$NOREPLY'"
  read -r -p "    Projekte-Verzeichnis [$DEFAULT_PROJECTS_DIR]: " PROJECTS_DIR || true
  PROJECTS_DIR="${PROJECTS_DIR:-$DEFAULT_PROJECTS_DIR}"

  mkdir -p "$(dirname "$ENV_FILE")"
  cat > "$ENV_FILE" <<EOF
# coding-kit personal config — created by install.sh, NEVER commit this file.
# Skills resolve identity at runtime (git config / gh api) where possible;
# this file is the offline fallback and holds non-resolvable personal choices.
CODING_KIT_GITHUB_LOGIN="$GH_LOGIN"
CODING_KIT_GIT_AUTHOR_NAME="$GH_NAME"
CODING_KIT_GIT_NOREPLY_EMAIL="$NOREPLY"
CODING_KIT_PROJECTS_DIR="$PROJECTS_DIR"
EOF
  chmod 600 "$ENV_FILE"
  ok "angelegt (chmod 600)"
fi

# --- 4. Global CLAUDE.md -----------------------------------------------------
say "Globale ~/.claude/CLAUDE.md"

if [ -f "$GLOBAL_CLAUDE_TEMPLATE" ]; then
  if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    ok "existiert bereits — wird nicht überschrieben (Abgleich: diff gegen templates/global-CLAUDE.md)"
  elif ask_yes_no "Globale CLAUDE.md aus der Kit-Vorlage einrichten?" j; then
    cp "$GLOBAL_CLAUDE_TEMPLATE" "$HOME/.claude/CLAUDE.md"
    ok "eingerichtet aus templates/global-CLAUDE.md"
  else
    warn "übersprungen"
  fi
else
  warn "Kit-Vorlage (templates/global-CLAUDE.md) existiert noch nicht — übersprungen"
fi

# --- 5. Toolchain ------------------------------------------------------------
say "Toolchain (mise, just, lefthook, gitleaks)"

MISSING=()
for tool in mise just lefthook gitleaks; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool vorhanden"
  else
    MISSING+=("$tool")
    warn "$tool fehlt"
  fi
done

if [ "${#MISSING[@]}" -gt 0 ]; then
  if command -v brew >/dev/null 2>&1; then
    if ask_yes_no "Fehlende Tools via brew installieren (${MISSING[*]})?" n; then
      brew install "${MISSING[@]}"
      ok "installiert: ${MISSING[*]}"
    else
      warn "übersprungen — manuell: brew install ${MISSING[*]}"
    fi
  else
    warn "brew fehlt — Tools manuell installieren: ${MISSING[*]}"
  fi
fi

say "Fertig. Nächste Schritte: neue Claude-Code-Session starten, Skills unter /coding-kit:<name> prüfen."
