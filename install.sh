#!/usr/bin/env bash
# coding-kit installer — new-machine bootstrap. Idempotent: safe to re-run anytime.
#
# What it does (each step checks state first, nothing runs twice):
#   1. Preconditions: claude must be installed. gh decides whether the run uses GitHub:
#      ready, logged out (offers gh auth login) or missing; without GitHub the run goes
#      on only after a confirmation. On Windows it names CLAUDE_CODE_GIT_BASH_PATH for
#      settings.json when Git Bash lies outside C:\Program Files\Git (never writes it).
#   2. Adds the xnyzer marketplace and installs the coding-kit plugin.
#   3. Creates the personal config ~/.claude/coding-kit.env — prefilled via gh api, or
#      asked for without GitHub; host and commit addresses go through template-sync.sh
#      set-global. On Windows the projects folder is stored as C:/…, and the report
#      names the user profile instead of chmod 600.
#   4. Reports the kit's global rules; it never writes them or ~/.claude/CLAUDE.md —
#      setting them up is /coding-kit:update-conventions global in a Claude session.
#   5. Checks the base toolchain (mise, just, lefthook, gitleaks) outside any project
#      (template-sync.sh tool-check). Offers mise through brew or pacman (Windows: winget
#      or scoop; after winget it finds mise in winget's package folder in the same run),
#      else names the way by hand (unknown systems: by hand only); then offers just,
#      lefthook and gitleaks through mise use -g. A closing line names what is open.
#      Under WSL it warns that Claude Code on Windows needs the run in Git Bash.
#   6. Checks that the mise shims reach every shell (template-sync.sh mise-check); offers
#      the activation line for the end of the shell's startup file (Windows: offers to
#      put the shims first in the user PATH, template-sync.sh set-mise-path).
# In its own window on Windows (double-click) it waits for Enter at the end, so the
# window stays open after success and failure alike.
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
TEMPLATE_SYNC="$SCRIPT_DIR/plugins/coding-kit/scripts/template-sync.sh"
KIT_RULES="$SCRIPT_DIR/plugins/coding-kit/global/coding-kit.md"
LOCAL_MODE=false
[ "${1:-}" = "--local" ] && LOCAL_MODE=true

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
fail() { printf '    \033[31m✗\033[0m %s\n' "$*"; exit 1; }

# Questions go to stdout with printf, not `read -p`: read prints its prompt only when the
# input is a terminal.

# end_question — after an answer: a terminal echoes the Enter, input from a pipe or file
# does not, so the next output would join the question's line.
end_question() {
  [ -t 0 ] || echo
}
ask_yes_no() { # $1 question, $2 default (j/n)
  local answer="" default="${2:-n}"
  printf '    %s [%s] ' "$1" "$([ "$default" = j ] && echo "J/n" || echo "j/N")"
  read -r answer || true
  end_question
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[jJyY] ]]
}

# ask_value QUESTION DEFAULT CHECK — asks until the answer (empty = DEFAULT) passes the
# function CHECK, then leaves it in ANSWER. CHECK prints its reason when it rejects. At
# the end of the input the default counts once; a rejected answer then aborts instead of
# asking forever.
ANSWER=""
ask_value() {
  local question="$1" default="$2" check="$3" line at_end
  while true; do
    line="" at_end=false
    if [ -n "$default" ]; then
      printf '    %s [%s]: ' "$question" "$default"
    else
      printf '    %s: ' "$question"
    fi
    read -r line || at_end=true
    end_question
    ANSWER="${line:-$default}"
    if "$check" "$ANSWER"; then
      return 0
    fi
    [ "$at_end" = false ] || fail "Eingabe zu Ende, bevor eine gültige Antwort kam — erneut ausführen"
  done
}

# A value the personal config can hold: template-sync.sh rejects a whole config that has a
# tab or {{ in a value (load_env).
config_value() {
  case "$1" in
    *$'\t'* | *"{{"*)
      warn "ein Tab oder {{ geht in der Personal-Config nicht"
      return 1
      ;;
  esac
}

# A plain address — the pattern commit-email in template-sync.sh accepts —, empty, or "-":
# both mean "ask at commit time" ("-" for when a suggestion would fill an empty answer).
EMAIL_PATTERN='^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$'
email_value() {
  [ -z "$1" ] || [ "$1" = - ] && return 0
  [[ "$1" =~ $EMAIL_PATTERN ]] && return 0
  warn "'$1' ist keine einfache Adresse (etwa name@example.org)"
  return 1
}

# The hosts on offer, set before asking; template-sync.sh set-global checks the choice
# again against its own list (HOSTS there).
HOST_CHOICES=""
host_value() {
  case " $HOST_CHOICES " in
    *" $1 "*) return 0 ;;
  esac
  warn "'$1' ist kein Host zur Auswahl — möglich: ${HOST_CHOICES// / | }"
  return 1
}

# Value for a double-quoted line of the personal config: the shell expands $ and ` there
# and reads \ and " as escapes (the same quoting as template-sync.sh set-global).
env_quote() {
  printf '%s' "$1" | sed 's/[\\"$`]/\\&/g'
}

# ~/Documents when it exists; else the documents folder of the desktop (xdg-user-dir, e.g.
# ~/Dokumente) when it exists and is not the home folder itself; else the home folder.
default_projects_dir() {
  local docs=""
  if [ -d "$HOME/Documents" ]; then
    docs="$HOME/Documents"
  elif command -v xdg-user-dir >/dev/null 2>&1; then
    docs="$(xdg-user-dir DOCUMENTS 2>/dev/null || true)"
    if [ "$docs" = "$HOME" ] || [ ! -d "$docs" ]; then docs=""; fi
  fi
  printf '%s/Coding-Projects' "${docs:-$HOME}"
}

# config_path PATH — the path as the personal config holds it: on Windows in the form
# C:/…, which Git Bash, PowerShell and Windows programs all read; elsewhere unchanged.
config_path() {
  if [ "$PLATFORM" = windows ]; then
    cygpath -m "$1"
  else
    printf '%s' "$1"
  fi
}

# The platform, for the steps that differ on it.
case "$(uname -s)" in
  Darwin) PLATFORM=macos ;;
  Linux) PLATFORM=linux ;;
  MINGW* | MSYS* | CYGWIN*) PLATFORM=windows ;;
  *) PLATFORM=unknown ;;
esac

# One handler for the end of every run — finished, fail or an error. It removes the work
# folder of step 3 and, when the installer has its own window on Windows (a double-click:
# a terminal as input and the first shell of the window, SHLVL 1), waits for Enter so
# the window does not close over the last lines. A run inside an open Git Bash has
# SHLVL 2 and does not wait.
ENV_WORK=""
on_exit() {
  [ -z "$ENV_WORK" ] || rm -rf "$ENV_WORK"
  if [ "$PLATFORM" = windows ] && [ -t 0 ] && [ "${SHLVL:-}" = 1 ]; then
    printf '\nEnter drücken, um das Fenster zu schließen … '
    read -r _ || true
  fi
}
trap on_exit EXIT

# --- 1. Preconditions --------------------------------------------------------
say "Voraussetzungen prüfen"

command -v claude >/dev/null 2>&1 || fail "claude (Claude Code) fehlt — siehe https://code.claude.com/docs"
ok "claude installiert ($(claude --version 2>/dev/null | head -1))"

# On Windows Claude Code runs hooks through Git Bash; outside the standard folder it may
# not find it, and then the hooks fail in PowerShell. CLAUDE_CODE_GIT_BASH_PATH in the env
# of settings.json names it — only reported here, never written.
if [ "$PLATFORM" = windows ] && [ -z "${CLAUDE_CODE_GIT_BASH_PATH:-}" ] \
  && ! grep -qs CLAUDE_CODE_GIT_BASH_PATH "$CONFIG_DIR/settings.json"; then
  GIT_BASH="$(cygpath -w "$BASH")"
  GIT_BASH="${GIT_BASH%.exe}.exe"
  case "$(printf '%s' "$GIT_BASH" | tr '[:upper:]' '[:lower:]')" in
    'c:\program files\git\'*) ;;
    *)
      warn "Die Git Bash liegt nicht unter C:\\Program Files\\Git — findet Claude Code sie" \
        "nicht, scheitern die Hooks. In $CONFIG_DIR/settings.json unter \"env\" eintragen:" \
        "\"CLAUDE_CODE_GIT_BASH_PATH\": \"$(printf '%s' "$GIT_BASH" | sed 's/\\/\\\\/g')\""
      ;;
  esac
fi

if ! command -v gh >/dev/null 2>&1; then
  GH_STATE=missing
elif gh auth status >/dev/null 2>&1; then
  GH_STATE=ready
else
  GH_STATE=logged-out
fi
if command -v brew >/dev/null 2>&1; then
  GH_INSTALL_HINT="installieren: brew install gh"
else
  GH_INSTALL_HINT="installieren: siehe https://cli.github.com"
fi

# GitHub matters only for creating the personal config; an existing one is never touched,
# so then gh is only reported.
USE_GITHUB=false
if [ -f "$ENV_FILE" ]; then
  case "$GH_STATE" in
    ready) ok "gh installiert und angemeldet" ;;
    logged-out) warn "gh ist installiert, aber nicht angemeldet" ;;
    missing) warn "gh (GitHub CLI) fehlt" ;;
  esac
else
  case "$GH_STATE" in
    ready)
      ok "gh installiert und angemeldet"
      USE_GITHUB=true
      ;;
    logged-out)
      warn "gh ist installiert, aber nicht angemeldet"
      if ask_yes_no "Jetzt bei GitHub anmelden (gh auth login)?" j \
        && gh auth login && gh auth status >/dev/null 2>&1; then
        ok "gh angemeldet"
        USE_GITHUB=true
      else
        warn "nicht angemeldet"
      fi
      ;;
    missing)
      warn "gh (GitHub CLI) fehlt — $GH_INSTALL_HINT"
      ;;
  esac
  if [ "$USE_GITHUB" = false ]; then
    if ! ask_yes_no "Ohne GitHub weitermachen (Personal-Config ohne gh api, Host git oder azure)?" n; then
      if [ "$GH_STATE" = missing ]; then
        fail "abgebrochen — gh $GH_INSTALL_HINT, dann erneut ausführen"
      fi
      fail "abgebrochen — gh auth login, dann erneut ausführen"
    fi
    ok "weiter ohne GitHub"
  fi
fi

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
  # The address arguments for set-global: the GitHub noreply address, then the address
  # of a chosen host other than GitHub. Never empty in the end — bash 3.2 (macOS) treats
  # an empty array under set -u as unbound.
  EMAIL_ARGS=()
  if [ "$USE_GITHUB" = true ]; then
    GH_LOGIN="$(gh api user --jq '.login')"
    GH_ID="$(gh api user --jq '.id')"
    AUTHOR_NAME="$(gh api user --jq '.name // .login')"
    if ! config_value "$AUTHOR_NAME"; then
      warn "statt des Namens aus gh api gilt der Login"
      AUTHOR_NAME="$GH_LOGIN"
    fi
    NOREPLY="${GH_ID}+${GH_LOGIN}@users.noreply.github.com"
    echo "    Vorbefüllt via gh api: Login '$GH_LOGIN', Name '$AUTHOR_NAME', E-Mail '$NOREPLY'"
    EMAIL_ARGS+=("CODING_KIT_EMAIL_GITHUB=$NOREPLY")
    HOST_CHOICES="github azure git"
    ask_value "Git-Host neuer Projekte (${HOST_CHOICES// / | })" github host_value
  else
    ask_value "Autorname für Commits" "$(git config --global user.name 2>/dev/null || true)" config_value
    AUTHOR_NAME="$ANSWER"
    [ -n "$AUTHOR_NAME" ] || warn "kein Autorname eingetragen — Commits nehmen den Namen aus git config"
    # Without gh, GitHub projects cannot be created.
    HOST_CHOICES="git azure"
    ask_value "Git-Host neuer Projekte (${HOST_CHOICES// / | })" git host_value
  fi
  HOST="$ANSWER"
  if [ "$HOST" != github ]; then
    HOST_KEY="CODING_KIT_EMAIL_$(printf '%s' "$HOST" | tr 'a-z' 'A-Z')"
    GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
    if [ -n "$GIT_EMAIL" ]; then
      ask_value "Commit-Adresse für Projekte auf $HOST (- = beim Commit fragen)" "$GIT_EMAIL" email_value
    else
      ask_value "Commit-Adresse für Projekte auf $HOST (leer = beim Commit fragen)" "" email_value
    fi
    [ "$ANSWER" != - ] || ANSWER=""
    EMAIL_ARGS+=("$HOST_KEY=$ANSWER")
  fi
  ask_value "Projekte-Verzeichnis" "$(config_path "$(default_projects_dir)")" config_value
  PROJECTS_DIR="$ANSWER"
  # Inside quotes the shell never expands a leading ~.
  case "$PROJECTS_DIR" in
    "~") PROJECTS_DIR="$HOME" ;;
    "~/"*) PROJECTS_DIR="$HOME/${PROJECTS_DIR#"~/"}" ;;
  esac
  PROJECTS_DIR="$(config_path "$PROJECTS_DIR")"

  # The keys only the installer writes go into a base file; set-global adds host and
  # addresses with the comments of the kit rules. The result moves into place with
  # owner-only rights.
  ENV_WORK="$(mktemp -d)"
  {
    echo "# coding-kit personal config — created by install.sh, NEVER commit this file."
    echo "# Skills resolve identity at runtime (git config / gh api) where possible;"
    echo "# this file is the offline fallback and holds non-resolvable personal choices."
    if [ "$USE_GITHUB" = true ]; then
      echo "CODING_KIT_GITHUB_LOGIN=\"$(env_quote "$GH_LOGIN")\""
    fi
    echo "CODING_KIT_GIT_AUTHOR_NAME=\"$(env_quote "$AUTHOR_NAME")\""
    echo "CODING_KIT_PROJECTS_DIR=\"$(env_quote "$PROJECTS_DIR")\""
  } > "$ENV_WORK/base.env"
  sh "$TEMPLATE_SYNC" set-global "$KIT_RULES" "$ENV_WORK/base.env" "$ENV_WORK/out" \
    "CODING_KIT_DEFAULT_HOST=$HOST" "${EMAIL_ARGS[@]}" >/dev/null ||
    fail "template-sync.sh set-global ist gescheitert"
  mkdir -p "$(dirname "$ENV_FILE")"
  (umask 077 && cp "$ENV_WORK/out/coding-kit.env" "$ENV_FILE")
  chmod 600 "$ENV_FILE"
  if [ "$PLATFORM" = windows ]; then
    # Git Bash cannot set file modes on NTFS; the rights of the user profile protect it.
    ok "angelegt (geschützt durch die Rechte deines Benutzerprofils) — Host neuer Projekte: $HOST"
  else
    ok "angelegt (chmod 600) — Host neuer Projekte: $HOST"
  fi
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

# Only mise itself comes from a package manager of the platform; just, lefthook and
# gitleaks then come through mise (`mise use -g`), the same way everywhere.
MISE_DOCS="https://mise.jdx.dev/installing-mise.html"
# WSL runs a Linux kernel built by Microsoft.
if [ "$PLATFORM" = linux ] && uname -r | grep -qi microsoft; then
  warn "WSL erkannt — die Einrichtung gilt nur für ein Claude Code innerhalb von WSL;" \
    "für Claude Code unter Windows den Installer in Git Bash ausführen"
fi

# missing_tools TOOL… — leaves the tools tool-check does not find in MISSING, reporting
# each one. A tool counts only when it runs outside any project — a mise shim without a
# version stops there with "No version is set"; tool-check decides.
MISSING=()
missing_tools() {
  local check tool state
  check="$(sh "$TEMPLATE_SYNC" tool-check "$@")" || fail "template-sync.sh tool-check ist gescheitert"
  MISSING=()
  while IFS=$'\t' read -r _ tool state; do
    if [ "$state" = present ]; then
      ok "$tool vorhanden"
    else
      MISSING+=("$tool")
      warn "$tool fehlt"
    fi
  done <<< "$check"
}

# offer_install COMMAND… — runs COMMAND after a yes (default no) and succeeds only when it
# ran and succeeded; a no or a failure is named, so the closing line "Offen: …" has a
# hint above it.
offer_install() {
  if ! ask_yes_no "mise installieren ($*)?" n; then
    warn "übersprungen — von Hand: $*"
    return 1
  fi
  "$@" && return 0
  warn "$* ist gescheitert"
  return 1
}

# find_winget_mise — winget puts the package folder of mise on the user PATH, but only
# for shells started afterwards. When mise lies there, its folder goes first on PATH for
# the rest of this run.
find_winget_mise() {
  local base dir
  if [ -n "${LOCALAPPDATA:-}" ]; then
    base="$(cygpath -u "$LOCALAPPDATA")"
  else
    base="$HOME/AppData/Local"
  fi
  for dir in "$base"/Microsoft/WinGet/Packages/jdx.mise_*/mise/bin; do
    if [ -f "$dir/mise" ] || [ -f "$dir/mise.exe" ]; then
      PATH="$dir:$PATH"
      return 0
    fi
  done
  return 1
}

# offer_mise — offers mise through the package manager of the platform, or names the way
# by hand; unknown systems get only the way by hand.
offer_mise() {
  case "$PLATFORM" in
    windows)
      if find_winget_mise; then
        ok "mise liegt im Paketordner von winget — eine neue Git Bash findet es von selbst"
      elif command -v winget >/dev/null 2>&1; then
        if offer_install winget install jdx.mise && ! find_winget_mise; then
          warn "mise ist nicht im Paketordner von winget — Git Bash neu starten, dann erneut ausführen"
        fi
      elif command -v scoop >/dev/null 2>&1; then
        offer_install scoop install mise || true
      else
        warn "Weder winget noch scoop — mise von Hand: winget install jdx.mise oder scoop install mise, danach Git Bash neu starten und erneut ausführen"
      fi
      return 0
      ;;
    unknown)
      warn "Unbekanntes System — der Installer installiert nichts; mise von Hand: $MISE_DOCS"
      return 0
      ;;
  esac
  if command -v brew >/dev/null 2>&1; then
    offer_install brew install mise || true
  elif command -v pacman >/dev/null 2>&1; then
    offer_install sudo pacman -S mise || true
  else
    # Never run here: the official script comes from the network, and the folder it
    # installs into must be on PATH first.
    warn "Weder brew noch pacman — mise von Hand: curl https://mise.run | sh (oder $MISE_DOCS), danach erneut ausführen"
  fi
}

# What is still missing at the end, for the closing line "Offen: …".
OPEN=()

missing_tools mise
if [ "${#MISSING[@]}" -gt 0 ]; then
  offer_mise
  if command -v mise >/dev/null 2>&1; then
    ok "mise installiert"
  else
    OPEN+=(mise)
  fi
fi

missing_tools just lefthook gitleaks
if [ "${#MISSING[@]}" -gt 0 ]; then
  if ! command -v mise >/dev/null 2>&1; then
    warn "${MISSING[*]} kommen über mise — erst mise installieren"
    OPEN+=("${MISSING[@]}")
  elif ask_yes_no "Fehlende Tools global über mise installieren (mise use -g ${MISSING[*]})?" n; then
    # From the home folder, so no project mise.toml takes part.
    (cd "$HOME" && mise use -g "${MISSING[@]}") || warn "mise use -g ist gescheitert"
    missing_tools "${MISSING[@]}"
    if [ "${#MISSING[@]}" -gt 0 ]; then OPEN+=("${MISSING[@]}"); fi
  else
    warn "übersprungen — von Hand: mise use -g ${MISSING[*]}"
    OPEN+=("${MISSING[@]}")
  fi
fi

# --- 6. mise in every shell --------------------------------------------------
# Terminals, VS Code and Claude Code take their PATH from an interactive shell; the tools
# a project pins with mise reach them only when the activation line ends its startup
# file, after other tool managers such as nvm. On Windows they take it from the Windows
# environment instead, so the shims belong at the front of the user PATH. mise-check
# decides (its verdict line); this step only words the result and appends the line on
# approval.
if command -v mise >/dev/null 2>&1; then
  say "mise in jeder Shell"
  MISE_CHECK="$(sh "$TEMPLATE_SYNC" mise-check)"
  mise_field() { # $1 line kind, $2 field number
    printf '%s\n' "$MISE_CHECK" | awk -F '\t' -v k="$1" -v n="$2" '$1 == k { print $n; exit }'
  }
  RC="$(mise_field rc 2)"
  LINE="$(mise_field line 2)"
  ADD_LINE="$(mise_field add 2)"
  VERDICT="$(mise_field verdict 2)"
  # Only on Windows: whether the user PATH holds the shims, and their folder as Windows
  # writes it.
  USER_PATH="$(mise_field userpath 2)"
  if [ -n "$USER_PATH" ]; then
    WIN_SHIMS="$(cygpath -w "$(mise_field shims 2)")" || WIN_SHIMS="$(mise_field shims 2)"
  fi
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
      if [ "$USER_PATH" = unknown ]; then
        # Windows, user PATH unreadable: where a shadowing folder sits is not known.
        [ -z "$SHADOWED" ] || warn "Vor den Shims von mise: $SHADOWED"
        warn "Den Benutzer-PATH kann der Installer nicht lesen — von Hand: $WIN_SHIMS" \
          "ganz vorn in den Benutzer-PATH (Windows-Einstellungen, „Umgebungsvariablen für" \
          "dieses Konto bearbeiten“), danach Terminal bzw. VS Code neu starten"
      elif [ -n "$USER_PATH" ]; then
        # Windows: what shadows the shims comes before the user PATH.
        warn "Vor den Shims von mise: $SHADOWED — das kommt aus dem System-PATH oder" \
          "der Git Bash, die vor dem Benutzer-PATH stehen; ändern nur mit Admin-Rechten" \
          "oder das Werkzeug dort entfernen"
      else
        [ -z "$SHADOWED" ] || warn "Vor den Shims von mise: $SHADOWED"
        if [ "$ADD_LINE" = - ]; then
          warn "Für diese Shell trägt der Installer nichts ein — siehe: mise activate --help"
        else
          warn "Für diese Shell trägt der Installer nichts ein — ans Ende ihrer Startdatei: $ADD_LINE"
        fi
      fi
      ;;
    restart)
      if [ -n "$USER_PATH" ]; then
        warn "Der Shim-Ordner von mise steht im Benutzer-PATH — er wirkt nach einem Neustart" \
          "von Terminal bzw. VS Code"
      else
        warn "Die Aktivierung steht in $RC — sie wirkt nach einem Neustart von Terminal bzw. VS Code"
      fi
      ;;
    offer-path)
      if [ -n "$SHADOWED" ]; then
        warn "Vor den Shims von mise: $SHADOWED — der Shim-Ordner muss im Benutzer-PATH davor stehen"
      else
        warn "mise ist nicht aktiv — Werkzeuge aus mise fehlen oder laufen in anderen Versionen"
      fi
      MISE_BY_HAND="von Hand: $WIN_SHIMS ganz vorn in den Benutzer-PATH"
      MISE_BY_HAND+=" (Windows-Einstellungen, „Umgebungsvariablen für dieses Konto bearbeiten“),"
      MISE_BY_HAND+=" danach Terminal bzw. VS Code neu starten"
      if ask_yes_no "Shim-Ordner $WIN_SHIMS vorn in den Benutzer-PATH eintragen?" n; then
        if sh "$TEMPLATE_SYNC" set-mise-path >/dev/null; then
          ok "eingetragen — Terminal bzw. VS Code ganz schließen und neu starten, dann gilt es"
        else
          warn "Eintragen gescheitert — $MISE_BY_HAND"
        fi
      else
        warn "übersprungen — $MISE_BY_HAND"
      fi
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

if [ "${#OPEN[@]}" -gt 0 ]; then
  warn "Offen: ${OPEN[*]} — siehe die Hinweise oben, danach erneut ausführen"
fi
say "Fertig. Nächste Schritte: neue Claude-Code-Session starten, Skills unter /coding-kit:<name> prüfen;"
say "für die globalen Kit-Regeln dort /coding-kit:update-conventions global (fragt Antwortsprache und Erklär-Niveau ab)."
