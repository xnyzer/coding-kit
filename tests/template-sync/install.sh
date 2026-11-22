# Installer cases for tests/template-sync/run.sh — sourced, uses its helpers. They run the
# kit's install.sh with bash in an empty environment (env -i): a test HOME, the answers on
# stdin, and a PATH of fake folders only — links to the system tools the installer and
# template-sync.sh call (sh is the shell of the pass), a fake claude, and per case a fake
# gh, brew or xdg-user-dir. A real gh or brew of the machine never takes part. The fakes
# log their calls to $IN_LOG.

IN=$ROOT/install.sh
IN_BASH=$(command -v bash || true)

# Tools the installer and template-sync.sh call, linked from where this machine has them.
IN_TOOLS='awk basename cat chmod cksum cp cut date dirname env find git grep head id ls
mkdir mktemp mv od rm sed sort tail tr uname wc xargs'

# in_new NAME — a fresh case folder: HOME in $IN_HOME, the state of the fakes in
# $TMP/in/NAME/state.
in_new() {
  rm -rf "${TMP:?}/in/$1"
  mkdir -p "$TMP/in/$1/test-home" "$TMP/in/$1/state"
  IN_HOME=$TMP/in/$1/test-home
}

# in_input NAME LINE… — the answers, one per line.
in_input() {
  ii_name=$1
  shift
  printf '%s\n' "$@" > "$TMP/in/$ii_name.input"
}

# in_run NAME [VAR=value…] — runs the installer for case NAME; stdout in $TMP/in/NAME.out,
# the exit code in $TMP/in/NAME.status, the calls of the fakes in $TMP/in/NAME.log. The
# PATH is the base folder unless a VAR=value sets it.
in_run() {
  ir_name=$1
  shift
  [ -f "$TMP/in/$ir_name.input" ] || : > "$TMP/in/$ir_name.input"
  : > "$TMP/in/$ir_name.log"
  ir_status=0
  (cd "$TMP/in/$ir_name" && env -i HOME="$TMP/in/$ir_name/test-home" PATH="$IN_BIN" \
    IN_LOG="$TMP/in/$ir_name.log" IN_STATE="$TMP/in/$ir_name/state" "$@" \
    "$IN_BASH" "$IN") < "$TMP/in/$ir_name.input" > "$TMP/in/$ir_name.out" 2>&1 || ir_status=$?
  printf '%s\n' "$ir_status" > "$TMP/in/$ir_name.status"
}

in_status() { [ "$(cat "$TMP/in/$1.status")" = "$2" ]; }
in_says() { grep -qF -- "$2" "$TMP/in/$1.out"; }
in_called() { grep -qxF -- "$2" "$TMP/in/$1.log"; }
in_calls_like() { grep -q -- "$2" "$TMP/in/$1.log"; }
in_env() { printf '%s' "$TMP/in/$1/test-home/.claude/coding-kit.env"; }
in_has_env() { [ -f "$(in_env "$1")" ]; }

# in_value NAME KEY EXPECTED — the personal config of NAME, sourced by the shell of the
# pass in the case folder, sets CODING_KIT_KEY to EXPECTED; "(unset)" stands for a key it
# does not set.
in_value() {
  iv_got=$(cd "$TMP/in/$1" && env -i "$(command -v "$SH")" -c \
    '. "$1" && eval "printf %s \"\${CODING_KIT_$2-(unset)}\""' sh "$(in_env "$1")" "$2") ||
    return 1
  [ "$iv_got" = "$3" ]
}

in_owner_only() {
  [ "$(ls -l "$(in_env "$1")" | cut -c1-10)" = "-rw-------" ]
}

in_gitconfig() {  # a global git config with name and address in $IN_HOME
  printf '%s\n' '[user]' '  name = Ada Example' '  email = ada@example.org' \
    > "$IN_HOME/.gitconfig"
}

in_fake() {  # FILE — the fake read from stdin, made executable
  cat > "$1"
  chmod +x "$1"
}

run_install_cases() {
  if [ -z "$IN_BASH" ]; then
    fail "install: bash not found — the installer cases need it"
    return
  fi

  # The folders on PATH: base (system tools, sh, claude), gh, brew, xdg-user-dir.
  rm -rf "${TMP:?}/in"
  IN_BIN=$TMP/in/bin
  IN_GH=$TMP/in/gh-bin
  IN_BREW=$TMP/in/brew-bin
  IN_XDG=$TMP/in/xdg-bin
  mkdir -p "$IN_BIN" "$IN_GH" "$IN_BREW" "$IN_XDG"
  for it_tool in $IN_TOOLS; do
    it_path=$(command -v "$it_tool") && ln -s "$it_path" "$IN_BIN/$it_tool"
  done
  ln -s "$(command -v "$SH")" "$IN_BIN/sh"

  in_fake "$IN_BIN/claude" <<'EOF'
#!/bin/sh
printf 'claude %s\n' "$*" >> "$IN_LOG"
case "$*" in
  --version) echo "9.9.9 (Claude Code)" ;;
  "plugin marketplace list") echo "xnyzer" ;;
  "plugin list") echo "coding-kit@xnyzer" ;;
esac
EOF
  # gh: logged in when $IN_STATE/logged-in exists; gh auth login succeeds with
  # IN_LOGIN=ok. The name tests the quoting of a value from gh api; IN_GH_NAME replaces
  # it.
  in_fake "$IN_GH/gh" <<'EOF'
#!/bin/sh
printf 'gh %s\n' "$*" >> "$IN_LOG"
case "$1 $2" in
  "auth status") [ -f "$IN_STATE/logged-in" ] ;;
  "auth login") [ "${IN_LOGIN:-}" = ok ] && : > "$IN_STATE/logged-in" ;;
  "api user")
    case "$4" in
      .login) echo octo ;;
      .id) echo 42 ;;
      *)
        if [ -n "${IN_GH_NAME:-}" ]; then
          printf '%s\n' "$IN_GH_NAME"
        else
          echo 'Octo "Cat" $HOME'
        fi ;;
    esac ;;
  *) exit 3 ;;
esac
EOF
  in_fake "$IN_BREW/brew" <<'EOF'
#!/bin/sh
printf 'brew %s\n' "$*" >> "$IN_LOG"
EOF
  in_fake "$IN_XDG/xdg-user-dir" <<'EOF'
#!/bin/sh
printf '%s\n' "$IN_XDG_DIR"
EOF
  in_noreply=42+octo@users.noreply.github.com

  # gh ready, end of input at once: the defaults — GitHub prefill, host github.
  in_new ready
  mkdir "$IN_HOME/Documents"
  : > "$TMP/in/ready/state/logged-in"
  in_run ready PATH="$IN_GH:$IN_BIN"
  check "install: gh ready runs through" in_status ready 0
  check "install: gh ready asks the host with github first" \
    in_says ready "Git-Host neuer Projekte (github | azure | git) [github]"
  check "install: gh ready writes the login" in_value ready GITHUB_LOGIN octo
  check "install: gh ready writes the name from gh, quoted" \
    in_value ready GIT_AUTHOR_NAME 'Octo "Cat" $HOME'
  check "install: gh ready writes host github" in_value ready DEFAULT_HOST github
  check "install: gh ready writes the noreply address" in_value ready EMAIL_GITHUB "$in_noreply"
  check "install: gh ready asks no other address" in_value ready EMAIL_AZURE "(unset)"
  check "install: default projects folder below Documents" \
    in_value ready PROJECTS_DIR "$TMP/in/ready/test-home/Documents/Coding-Projects"
  check "install: the personal config is owner-only" in_owner_only ready
  check "install: set-global adds the comment of the kit rules" \
    grep -q '^CODING_KIT_DEFAULT_HOST="github"  # ' "$(in_env ready)"

  # gh ready, another host: its address is asked too, the noreply address stays.
  in_new ready-azure
  : > "$TMP/in/ready-azure/state/logged-in"
  in_input ready-azure azure me@corp.example.com ''
  in_run ready-azure PATH="$IN_GH:$IN_BIN"
  check "install: gh ready with host azure runs through" in_status ready-azure 0
  check "install: host azure is written" in_value ready-azure DEFAULT_HOST azure
  check "install: the azure address is written" in_value ready-azure EMAIL_AZURE me@corp.example.com
  check "install: the noreply address stays with host azure" \
    in_value ready-azure EMAIL_GITHUB "$in_noreply"

  # Logged out, login offered and done: on with GitHub.
  in_new login-ok
  in_input login-ok ''
  in_run login-ok PATH="$IN_GH:$IN_BIN" IN_LOGIN=ok
  check "install: login runs through" in_status login-ok 0
  check "install: login is offered and run" in_called login-ok "gh auth login"
  check "install: after the login the run uses GitHub" in_value login-ok GITHUB_LOGIN octo
  check "install: after the login host github" in_value login-ok DEFAULT_HOST github

  # Logged out, login and the run without GitHub declined: abort before setting up.
  in_new decline
  in_input decline n n
  in_run decline PATH="$IN_GH:$IN_BIN"
  check "install: declining both aborts" in_status decline 1
  check "install: the abort names gh auth login" \
    in_says decline "gh auth login, dann erneut ausführen"
  refute "install: the abort writes no personal config" in_has_env decline
  refute "install: the abort sets up no plugin" in_calls_like decline '^claude plugin'
  refute "install: a declined login is not run" in_called decline "gh auth login"

  # Logged out, login fails, run without GitHub confirmed: gh asked nothing more.
  in_new login-fails
  in_gitconfig
  in_input login-fails '' j
  in_run login-fails PATH="$IN_GH:$IN_BIN" IN_LOGIN=fail
  check "install: a failed login and no GitHub runs through" in_status login-fails 0
  check "install: the failed login was tried" in_called login-fails "gh auth login"
  check "install: without GitHub host git" in_value login-fails DEFAULT_HOST git
  check "install: without GitHub the address from git config" \
    in_value login-fails EMAIL_GIT ada@example.org
  check "install: without GitHub no login key" in_value login-fails GITHUB_LOGIN "(unset)"
  check "install: without GitHub no GitHub address" in_value login-fails EMAIL_GITHUB "(unset)"
  refute "install: without GitHub no gh api" in_calls_like login-fails '^gh api'

  # Logged out, login declined, run without GitHub confirmed: gh only asked for its state.
  in_new decline-on
  in_input decline-on n j
  in_run decline-on PATH="$IN_GH:$IN_BIN"
  check "install: declined login and no GitHub runs through" in_status decline-on 0
  check "install: gh is only asked for its state" \
    [ "$(grep '^gh ' "$TMP/in/decline-on.log")" = "gh auth status" ]

  # gh missing, no brew: the hint and the abort by default.
  in_new missing
  in_run missing
  check "install: gh missing aborts by default" in_status missing 1
  check "install: gh missing names the GitHub CLI page" in_says missing "https://cli.github.com"
  refute "install: gh missing writes no personal config" in_has_env missing

  # gh missing with brew: the brew command.
  in_new missing-brew
  in_run missing-brew PATH="$IN_BREW:$IN_BIN"
  check "install: gh missing with brew names brew install gh" \
    in_says missing-brew "brew install gh"

  # gh missing, run without GitHub with the defaults from git config.
  in_new missing-on
  mkdir "$IN_HOME/Documents"
  in_gitconfig
  in_input missing-on j
  in_run missing-on
  check "install: gh missing and no GitHub runs through" in_status missing-on 0
  check "install: without GitHub github is not on offer" \
    in_says missing-on "Git-Host neuer Projekte (git | azure) [git]"
  check "install: the name from git config" in_value missing-on GIT_AUTHOR_NAME "Ada Example"
  check "install: gh missing, host git" in_value missing-on DEFAULT_HOST git
  check "install: gh missing, the address from git config" \
    in_value missing-on EMAIL_GIT ada@example.org
  check "install: gh missing, no login key" in_value missing-on GITHUB_LOGIN "(unset)"
  check "install: gh missing, the personal config is owner-only" in_owner_only missing-on

  # Rejected answers are asked again; a leading ~ becomes the home folder.
  in_new invalid
  in_input invalid j Name github gitlab azure not-an-address me@corp.example.com '~/Code'
  in_run invalid
  check "install: rejected answers, then valid ones, run through" in_status invalid 0
  check "install: github is rejected without GitHub" in_says invalid "'github' ist kein Host"
  check "install: an unknown host is rejected" in_says invalid "'gitlab' ist kein Host"
  check "install: an invalid address is rejected" in_says invalid "keine einfache Adresse"
  check "install: the host asked again is written" in_value invalid DEFAULT_HOST azure
  check "install: the address asked again is written" in_value invalid EMAIL_AZURE me@corp.example.com
  check "install: ~/ becomes the home folder" \
    in_value invalid PROJECTS_DIR "$TMP/in/invalid/test-home/Code"

  # Characters the shell would read inside double quotes stay as typed.
  in_new quoting
  in_quoted_name='Ada "Q" $HOME `touch pwned` \x'
  in_quoted_dir="$TMP/in/quoting/a \$b \"c\" \\d"
  in_input quoting j "$in_quoted_name" '' '' "$in_quoted_dir"
  in_run quoting
  check "install: special characters run through" in_status quoting 0
  check "install: the name with special characters stays as typed" \
    in_value quoting GIT_AUTHOR_NAME "$in_quoted_name"
  check "install: the folder with special characters stays as typed" \
    in_value quoting PROJECTS_DIR "$in_quoted_dir"
  refute "install: a backtick in a value runs nothing" has in/quoting/pwned

  # A tab or {{ would make the whole personal config unreadable for template-sync.sh: such
  # answers are asked again, a name from gh api gives way to the login.
  in_new no-tab
  in_input no-tab j "$(printf 'Ada\tExample')" Ada '' '' 'a{{b' "$TMP/in/no-tab/p"
  in_run no-tab
  check "install: tab and {{ answers, then valid ones, run through" in_status no-tab 0
  check "install: a tab or {{ is rejected" in_says no-tab "ein Tab oder {{"
  check "install: the name asked again after a tab" in_value no-tab GIT_AUTHOR_NAME Ada
  check "install: the folder asked again after {{" in_value no-tab PROJECTS_DIR "$TMP/in/no-tab/p"
  in_new gh-tab
  : > "$TMP/in/gh-tab/state/logged-in"
  in_run gh-tab PATH="$IN_GH:$IN_BIN" IN_GH_NAME="$(printf 'Octo\tCat')"
  check "install: a gh name with a tab runs through" in_status gh-tab 0
  check "install: a gh name with a tab gives way to the login" \
    in_value gh-tab GIT_AUTHOR_NAME octo

  # With an address from git config, "-" still means: ask at commit time.
  in_new dash-address
  in_gitconfig
  in_input dash-address j '' '' -
  in_run dash-address
  check "install: - as address runs through" in_status dash-address 0
  check "install: - offered next to the suggestion" \
    in_says dash-address "(- = beim Commit fragen) [ada@example.org]"
  check "install: - leaves the address empty" in_value dash-address EMAIL_GIT ""

  # No name and no address in git config: both stay empty, the name with a warning.
  in_new no-git
  in_input no-git j
  in_run no-git
  check "install: no git config runs through" in_status no-git 0
  check "install: no name gives a warning" in_says no-git "kein Autorname"
  check "install: the name stays empty" in_value no-git GIT_AUTHOR_NAME ""
  check "install: the address stays empty (ask at commit time)" in_value no-git EMAIL_GIT ""

  # The input ends on a rejected answer: abort instead of asking forever.
  in_new eof
  printf 'j\n\ngitlab' > "$TMP/in/eof.input"
  in_run eof
  check "install: a rejected answer at the end of input aborts" in_status eof 1
  check "install: the abort says the input ended" in_says eof "Eingabe zu Ende"
  refute "install: the abort at the end of input writes nothing" in_has_env eof

  # An existing personal config: untouched, gh only reported, no question about GitHub.
  in_new exists
  mkdir -p "$IN_HOME/.claude"
  printf '%s\n' 'CODING_KIT_PROJECTS_DIR="/somewhere"' > "$IN_HOME/.claude/coding-kit.env"
  cksum < "$IN_HOME/.claude/coding-kit.env" > "$TMP/in/exists.before"
  in_run exists PATH="$IN_GH:$IN_BIN"
  check "install: an existing config runs through" in_status exists 0
  check "install: an existing config stays as it is" \
    [ "$(cksum < "$IN_HOME/.claude/coding-kit.env")" = "$(cat "$TMP/in/exists.before")" ]
  check "install: with a config gh is only reported" in_says exists "nicht angemeldet"
  refute "install: with a config no login is offered" in_says exists "gh auth login"
  refute "install: with a config no question about GitHub" in_says exists "Ohne GitHub"

  # The projects folder without ~/Documents: the documents folder of the desktop, unless
  # it is the home folder itself or missing; else the home folder.
  in_new xdg
  mkdir "$IN_HOME/Dokumente"
  in_input xdg j
  in_run xdg PATH="$IN_XDG:$IN_BIN" IN_XDG_DIR="$IN_HOME/Dokumente"
  check "install: projects folder in the desktop's documents folder" \
    in_value xdg PROJECTS_DIR "$TMP/in/xdg/test-home/Dokumente/Coding-Projects"
  in_new xdg-home
  in_input xdg-home j
  in_run xdg-home PATH="$IN_XDG:$IN_BIN" IN_XDG_DIR="$IN_HOME"
  check "install: documents folder = home, projects folder in the home folder" \
    in_value xdg-home PROJECTS_DIR "$TMP/in/xdg-home/test-home/Coding-Projects"
  in_new xdg-missing
  in_input xdg-missing j
  in_run xdg-missing PATH="$IN_XDG:$IN_BIN" IN_XDG_DIR="$IN_HOME/Gone"
  check "install: a missing documents folder counts as none" \
    in_value xdg-missing PROJECTS_DIR "$TMP/in/xdg-missing/test-home/Coding-Projects"
  in_new no-docs
  in_input no-docs j
  in_run no-docs
  check "install: no documents folder, projects folder in the home folder" \
    in_value no-docs PROJECTS_DIR "$TMP/in/no-docs/test-home/Coding-Projects"
}
