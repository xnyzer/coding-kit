#!/usr/bin/env bash
# coding-kit installer — new-machine bootstrap. Idempotent: safe to re-run anytime.
#
# What it does (each step checks state first, nothing runs twice):
#   1. Preconditions: gh (authenticated) and claude must be installed.
#   2. Adds the xnyzer marketplace and installs the coding-kit plugin.
#   3. Creates the personal config ~/.claude/coding-kit.env (prefilled via gh api).
#   4. Reports the kit's global rules; it never writes them or ~/.claude/CLAUDE.md —
#      setting them up is /coding-kit:update-conventions global in a Claude session.
#   5. Checks the base toolchain (mise, just, lefthook, gitleaks); offers brew install.
#   6. Checks that the mise shims reach every shell (template-sync.sh mise-check); offers
#      the activation line for the end of the shell's startup file.
#
# Usage:
#   ./install.sh            # normal run (marketplace from GitHub)
#   ./install.sh --local    # add the marketplace from this checkout instead (development)
set -euo pipefail

MARKETPLACE_REPO="xnyzer/coding-kit"
MARKETPLACE_NAME="xnyzer"
PLUGIN_NAME="coding-kit"
# Claude Code's config folder: CLAUDE_CONFIG_DIR moves all of ~/.claude.
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ENV_FILE="$CONFIG_DIR/coding-kit.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
CODING_KIT_DEFAULT_HOST="github"
CODING_KIT_EMAIL_GITHUB="$NOREPLY"
CODING_KIT_PROJECTS_DIR="$PROJECTS_DIR"
EOF
  chmod 600 "$ENV_FILE"
  ok "angelegt (chmod 600)"
fi

# --- 4. Global kit rules ------------------------------------------------------
# Only reports. Setting up and syncing the rules — with the interview for reply language
# and explanation level, a diff and a confirmation — is /coding-kit:update-conventions
# global in a Claude session; a CLAUDE.md of the user's own is never touched.
say "Globale Kit-Regeln"

RULES_FILE="$CONFIG_DIR/rules/coding-kit.md"
USER_CLAUDE_MD="$CONFIG_DIR/CLAUDE.md"
if [ -f "$USER_CLAUDE_MD" ] && grep -qF "Gepflegt als Vorlage im coding-kit" "$USER_CLAUDE_MD"; then
  warn "$USER_CLAUDE_MD ist eine Kopie der früheren Kit-Vorlage — /coding-kit:update-conventions global übernimmt den Kit-Teil in die Kit-Regeln (nur nach Bestätigung, Persönliches bleibt)"
elif [ -f "$USER_CLAUDE_MD" ]; then
  ok "eigene $USER_CLAUDE_MD gefunden — das Kit fasst sie nie an"
fi
if [ -f "$RULES_FILE" ]; then
  ok "Kit-Regeln eingerichtet ($RULES_FILE)"
else
  warn "Kit-Regeln noch nicht eingerichtet (optional) — in einer Claude-Session: /coding-kit:update-conventions global"
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

# --- 6. mise in every shell --------------------------------------------------
# Terminals, VS Code and Claude Code take their PATH from an interactive shell; the tools
# a project pins with mise reach them only when the activation line ends its startup
# file, after other tool managers such as nvm. mise-check decides (its verdict line);
# this step only words the result and appends the line on approval.
if command -v mise >/dev/null 2>&1; then
  say "mise in jeder Shell"
  TEMPLATE_SYNC="$SCRIPT_DIR/plugins/coding-kit/scripts/template-sync.sh"
  MISE_CHECK="$(sh "$TEMPLATE_SYNC" mise-check)"
  mise_field() { # $1 line kind, $2 field number
    printf '%s\n' "$MISE_CHECK" | awk -F '\t' -v k="$1" -v n="$2" '$1 == k { print $n; exit }'
  }
  RC="$(mise_field rc 2)"
  LINE="$(mise_field line 2)"
  ADD_LINE="$(mise_field add 2)"
  VERDICT="$(mise_field verdict 2)"
  # Shadowed tools grouped by the directory that holds them: "node, npm aus ~/<dir>".
  SHADOWED="$(printf '%s\n' "$MISE_CHECK" | awk -F '\t' -v home="$HOME" '
    $1 == "shadowed" {
      if (!($3 in tools)) order[++n] = $3
      tools[$3] = ($3 in tools) ? tools[$3] ", " $2 : $2
    }
    END {
      for (i = 1; i <= n; i++) {
        dir = order[i]
        if (index(dir, home "/") == 1) dir = "~" substr(dir, length(home) + 1)
        printf "%s%s aus %s", (i > 1 ? "; " : ""), tools[order[i]], dir
      }
    }')"

  case "$VERDICT" in
    ok)
      ok "mise ist aktiv — in Projekten gelten die Versionen aus mise.toml"
      ;;
    commented)
      warn "In $RC steht die Aktivierung nur auskommentiert — prüfen: $ADD_LINE"
      ;;
    manual)
      [ -z "$SHADOWED" ] || warn "Vor den Shims von mise: $SHADOWED"
      if [ "$ADD_LINE" = - ]; then
        warn "Für diese Shell trägt der Installer nichts ein — siehe: mise activate --help"
      else
        warn "Für diese Shell trägt der Installer nichts ein — ans Ende ihrer Startdatei: $ADD_LINE"
      fi
      ;;
    restart)
      warn "Die Aktivierung steht in $RC — sie wirkt nach einem Neustart von Terminal bzw. VS Code"
      ;;
    hook)
      warn "Die Aktivierung steht am Ende von $RC, trotzdem vor den Shims: $SHADOWED —" \
        "nach einem Neustart von Terminal bzw. VS Code erneut prüfen; bleibt es," \
        "wechselt etwas die Version beim Ordnerwechsel (etwa ein Hook von nvm)"
      ;;
    offer)
      if [ -n "$SHADOWED" ]; then
        warn "Vor den Shims von mise: $SHADOWED — die Aktivierung muss danach stehen"
      else
        warn "mise ist nicht aktiv — Werkzeuge aus mise fehlen oder laufen in anderen Versionen"
      fi
      if ask_yes_no "Zeile ans Ende von $RC anhängen ($ADD_LINE)?" n; then
        MISE_OUT="$(mktemp -d)"
        sh "$TEMPLATE_SYNC" set-mise "$RC" "$MISE_OUT/rc" >/dev/null
        cp "$MISE_OUT/rc/$(basename "$RC")" "$RC"
        rm -rf "$MISE_OUT"
        ok "eingetragen — Terminal bzw. VS Code neu starten, dann gilt es"
        if [ "$LINE" = present ]; then
          ok "die ältere Zeile mit mise activate weiter oben in $RC kann raus"
        fi
      else
        warn "übersprungen — von Hand ans Ende von $RC: $ADD_LINE"
      fi
      ;;
    *)
      fail "mise-check lieferte kein bekanntes Ergebnis: $VERDICT"
      ;;
  esac
fi

say "Fertig. Nächste Schritte: neue Claude-Code-Session starten, Skills unter /coding-kit:<name> prüfen;"
say "für die globalen Kit-Regeln dort /coding-kit:update-conventions global (fragt Antwortsprache und Erklär-Niveau ab)."
