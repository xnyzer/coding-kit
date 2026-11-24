# Installer cases for tests/template-sync/run.sh — sourced, uses its helpers. They run the
# kit's install.sh with bash in an empty environment (env -i): a test HOME, the answers on
# stdin, and a PATH of fake folders only — wrappers for the system tools the installer and
# template-sync.sh call (sh is the shell of the pass), fakes for claude and uname, and per
# case fakes for gh, brew, pacman with sudo, winget, scoop, mise or xdg-user-dir. A real
# gh, brew, winget, scoop or mise of the machine never takes part. The fakes log their
# calls to $IN_LOG.

IN=$ROOT/install.sh
IN_BASH=$(command -v bash || true)

# Tools the installer and template-sync.sh call, wrapped from where this machine has them.
IN_TOOLS='awk basename cat chmod cksum cp cut date dirname env find git grep head id ls
mkdir mktemp mv od rm sed sort tail tr wc xargs'

# in_new NAME — a fresh case folder: HOME in $IN_HOME, the state of the fakes in
# $TMP/in/NAME/state, and $IN_PKG — the folder brew, pacman and scoop install mise into
# (put it on PATH to see it; winget installs into its package folder instead).
in_new() {
  rm -rf "${TMP:?}/in/$1"
  mkdir -p "$TMP/in/$1/test-home" "$TMP/in/$1/state/bin"
  IN_HOME=$TMP/in/$1/test-home
  IN_PKG=$TMP/in/$1/state/bin
}

# in_config — an existing personal config in $IN_HOME, so the run asks nothing before the
# toolchain.
in_config() {
  mkdir -p "$IN_HOME/.claude"
  printf '%s\n' 'CODING_KIT_PROJECTS_DIR="/somewhere"' > "$IN_HOME/.claude/coding-kit.env"
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
    GIT_CONFIG_NOSYSTEM=1 IN_LOG="$TMP/in/$ir_name.log" \
    IN_STATE="$TMP/in/$ir_name/state" "$@" \
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

  # The folders on PATH: base (system tools, sh, claude, uname), gh, brew, pacman with
  # sudo, winget, scoop, mise, the three tools mise installs, xdg-user-dir.
  rm -rf "${TMP:?}/in"
  IN_BIN=$TMP/in/bin
  IN_GH=$TMP/in/gh-bin
  IN_BREW=$TMP/in/brew-bin
  IN_PACMAN=$TMP/in/pacman-bin
  IN_WINGET=$TMP/in/winget-bin
  IN_SCOOP=$TMP/in/scoop-bin
  IN_MISE=$TMP/in/mise-bin
  IN_TOOLS_BIN=$TMP/in/tools-bin
  IN_XDG=$TMP/in/xdg-bin
  mkdir -p "$IN_BIN" "$IN_GH" "$IN_BREW" "$IN_PACMAN" "$IN_WINGET" "$IN_SCOOP" "$IN_MISE" \
    "$IN_TOOLS_BIN" "$IN_XDG"
  for it_tool in $IN_TOOLS; do
    it_path=$(command -v "$it_tool") && wrap_tool "$it_path" "$IN_BIN/$it_tool"
  done
  wrap_tool "$(command -v "$SH")" "$IN_BIN/sh"

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
  # uname: macOS unless IN_UNAME_S says otherwise; the kernel release from IN_UNAME_R.
  in_fake "$IN_BIN/uname" <<'EOF'
#!/bin/sh
case "${1:-}" in
  -r) printf '%s\n' "${IN_UNAME_R:-23.0.0}" ;;
  *) printf '%s\n' "${IN_UNAME_S:-Darwin}" ;;
esac
EOF
  # mise: a tool counts as installed globally when $IN_STATE/mise-TOOL exists.
  in_fake "$IN_MISE/mise" <<'EOF'
#!/bin/sh
printf 'mise %s\n' "$*" >> "$IN_LOG"
case "$1" in
  which) [ -f "$IN_STATE/mise-$2" ] ;;
  use)
    shift
    [ "$1" = -g ] && shift
    for tool in "$@"; do : > "$IN_STATE/mise-$tool"; done ;;
esac
EOF
  # brew and pacman install the mise fake (next to their own folder) into $IN_STATE/bin;
  # brew fails with IN_BREW_FAIL=1.
  in_fake "$IN_BREW/brew" <<'EOF'
#!/bin/sh
printf 'brew %s\n' "$*" >> "$IN_LOG"
[ "${IN_BREW_FAIL:-}" != 1 ] || exit 1
if [ "$*" = "install mise" ]; then
  cp "$(dirname "$0")/../mise-bin/mise" "$IN_STATE/bin/mise"
fi
EOF
  in_fake "$IN_PACMAN/pacman" <<'EOF'
#!/bin/sh
printf 'pacman %s\n' "$*" >> "$IN_LOG"
if [ "$*" = "-S mise" ]; then
  cp "$(dirname "$0")/../mise-bin/mise" "$IN_STATE/bin/mise"
fi
EOF
  in_fake "$IN_PACMAN/sudo" <<'EOF'
#!/bin/sh
printf 'sudo %s\n' "$*" >> "$IN_LOG"
exec "$@"
EOF
  # winget installs the mise fake into its package folder below LOCALAPPDATA (a POSIX
  # path here; the cygpath stand-in keeps it), off PATH as on Windows; it fails with
  # IN_WINGET_FAIL=1 and installs elsewhere with IN_WINGET_ELSEWHERE=1. scoop installs
  # it into $IN_STATE/bin, which its shims stand for.
  in_fake "$IN_WINGET/winget" <<'EOF'
#!/bin/sh
printf 'winget %s\n' "$*" >> "$IN_LOG"
[ "${IN_WINGET_FAIL:-}" != 1 ] || exit 1
if [ "$*" = "install jdx.mise" ]; then
  if [ "${IN_WINGET_ELSEWHERE:-}" = 1 ]; then
    dir=$LOCALAPPDATA/Programs/mise
  else
    dir=$LOCALAPPDATA/Microsoft/WinGet/Packages/jdx.mise_Test/mise/bin
  fi
  mkdir -p "$dir"
  cp "$(dirname "$0")/../mise-bin/mise" "$dir/mise"
fi
EOF
  in_fake "$IN_SCOOP/scoop" <<'EOF'
#!/bin/sh
printf 'scoop %s\n' "$*" >> "$IN_LOG"
if [ "$*" = "install mise" ]; then
  cp "$(dirname "$0")/../mise-bin/mise" "$IN_STATE/bin/mise"
fi
EOF
  for it_tool in just lefthook gitleaks; do
    printf '%s\n' '#!/bin/sh' | in_fake "$IN_TOOLS_BIN/$it_tool"
  done
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
  check_owner_only "install: the personal config is owner-only" "$(in_env ready)"
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
  check_owner_only "install: gh missing, the personal config is owner-only" \
    "$(in_env missing-on)"

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

  # --- toolchain (step 5); an existing config, so only step 5 asks ---

  # mise there, the three tools missing, mise use -g accepted: installed, nothing open.
  in_new mise-use
  in_config
  in_input mise-use j
  in_run mise-use PATH="$IN_MISE:$IN_BIN"
  check "install: mise use -g runs through" in_status mise-use 0
  check "install: mise use -g is offered and run for the missing tools" \
    in_called mise-use "mise use -g just lefthook gitleaks"
  check "install: after mise use -g tool-check finds the tools" in_says mise-use "gitleaks vorhanden"
  refute "install: after mise use -g nothing is open" in_says mise-use "Offen:"
  check "install: mise not active, step 6 still runs" in_says mise-use "mise in jeder Shell"

  # mise use -g declined: the tools are open, mise is not called to install.
  in_new mise-decline
  in_config
  in_run mise-decline PATH="$IN_MISE:$IN_BIN"
  check "install: declined mise use -g runs through" in_status mise-decline 0
  refute "install: declined mise use -g installs nothing" in_calls_like mise-decline '^mise use'
  check "install: declined tools are open" in_says mise-decline "Offen: just lefthook gitleaks"
  check "install: declined tools get the way by hand" \
    in_says mise-decline "übersprungen — von Hand: mise use -g just lefthook gitleaks"

  # brew install mise declined: the way by hand above the closing line, mise is open.
  in_new brew-decline
  in_config
  in_run brew-decline PATH="$IN_PKG:$IN_BREW:$IN_BIN"
  refute "install: declined brew install mise installs nothing" \
    in_called brew-decline "brew install mise"
  check "install: declined brew install mise gets the way by hand" \
    in_says brew-decline "übersprungen — von Hand: brew install mise"
  check "install: declined brew install mise, mise is open" \
    in_says brew-decline "Offen: mise just lefthook gitleaks"

  # The tools already there (e.g. from brew): nothing offered, nothing rebuilt.
  in_new tools-there
  in_config
  in_run tools-there PATH="$IN_MISE:$IN_TOOLS_BIN:$IN_BIN"
  check "install: tools already there run through" in_status tools-there 0
  refute "install: tools already there, no mise use -g" in_calls_like tools-there '^mise use'
  refute "install: tools already there, nothing open" in_says tools-there "Offen:"

  # mise missing, macOS with brew: brew install mise, then mise use -g in the same run;
  # brew is never asked for the three tools.
  in_new brew-mise
  in_config
  in_input brew-mise j j
  in_run brew-mise PATH="$IN_PKG:$IN_BREW:$IN_BIN"
  check "install: mise via brew runs through" in_status brew-mise 0
  check "install: brew install mise is offered and run" in_called brew-mise "brew install mise"
  check "install: after brew, mise use -g in the same run" \
    in_called brew-mise "mise use -g just lefthook gitleaks"
  refute "install: brew is not used for the three tools" in_calls_like brew-mise '^brew install just'
  refute "install: mise via brew, nothing open" in_says brew-mise "Offen:"

  # brew install mise fails: the run goes on, mise and the tools are open.
  in_new brew-fails
  in_config
  in_input brew-fails j
  in_run brew-fails PATH="$IN_PKG:$IN_BREW:$IN_BIN" IN_BREW_FAIL=1
  check "install: a failed brew install still runs through" in_status brew-fails 0
  check "install: a failed brew install is named" in_says brew-fails "brew install mise ist gescheitert"
  check "install: after a failed brew install mise is open" \
    in_says brew-fails "Offen: mise just lefthook gitleaks"

  # Linux with brew: the same way.
  in_new linux-brew
  in_config
  in_input linux-brew j j
  in_run linux-brew PATH="$IN_PKG:$IN_BREW:$IN_BIN" IN_UNAME_S=Linux
  check "install: Linux with brew offers brew install mise" in_called linux-brew "brew install mise"

  # Arch: sudo pacman -S mise; the three tools declined stay open.
  in_new arch
  in_config
  in_input arch j n
  in_run arch PATH="$IN_PKG:$IN_PACMAN:$IN_BIN" IN_UNAME_S=Linux
  check "install: Arch runs through" in_status arch 0
  check "install: Arch offers and runs sudo pacman -S mise" in_called arch "sudo pacman -S mise"
  check "install: Arch, mise is installed" in_says arch "mise installiert"
  check "install: Arch, declined tools are open" in_says arch "Offen: just lefthook gitleaks"

  # Linux without brew and pacman: the official command named, nothing run, all open.
  in_new linux-bare
  in_config
  in_run linux-bare IN_UNAME_S=Linux
  check "install: Linux without brew and pacman runs through" in_status linux-bare 0
  check "install: names the official mise command" in_says linux-bare "curl https://mise.run | sh"
  check "install: names the mise install page" \
    in_says linux-bare "https://mise.jdx.dev/installing-mise.html"
  refute "install: without brew and pacman nothing is installed" \
    grep -qE '^(brew|pacman|sudo|mise) ' "$TMP/in/linux-bare.log"
  check "install: without mise everything is open" \
    in_says linux-bare "Offen: mise just lefthook gitleaks"

  # Windows: cygpath and the user PATH from the stand-ins of mise.sh (mt_os_fakes; uname
  # stays the one of $IN_BIN).
  IN_WIN=$TMP/in/win-bin
  mkdir -p "$IN_WIN"
  mt_os_fakes "$IN_WIN"
  rm -f "$IN_WIN/uname"

  # Windows (Git Bash) with brew on PATH, without winget and scoop: the ways by hand.
  in_new windows
  in_config
  in_run windows PATH="$IN_PKG:$IN_BREW:$IN_BIN:$IN_WIN" IN_UNAME_S=MINGW64_NT-10.0-19045
  check "install: Windows runs through" in_status windows 0
  check "install: Windows without winget and scoop says so" in_says windows "Weder winget noch scoop"
  check "install: Windows names winget" in_says windows "winget install jdx.mise"
  check "install: Windows names scoop" in_says windows "scoop install mise"
  refute "install: Windows offers no brew" in_calls_like windows '^brew'
  refute "install: Windows asks nothing about brew" in_says windows "brew install mise"
  check "install: Windows without mise, mise is open" \
    in_says windows "Offen: mise just lefthook gitleaks"

  # Windows with winget: mise lands in winget's package folder, off PATH; the installer
  # finds it there in the same run and goes on with mise use -g.
  in_new win-winget
  in_config
  in_input win-winget j j
  in_run win-winget PATH="$IN_PKG:$IN_WINGET:$IN_SCOOP:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-winget/local"
  check "install: Windows with winget runs through" in_status win-winget 0
  check "install: Windows offers and runs winget install jdx.mise" \
    in_called win-winget "winget install jdx.mise"
  refute "install: Windows with winget does not use scoop" in_calls_like win-winget '^scoop'
  check "install: after winget, mise use -g in the same run" \
    in_called win-winget "mise use -g just lefthook gitleaks"
  refute "install: after winget, nothing open" in_says win-winget "Offen:"
  check "install: after winget, step 6 runs" in_says win-winget "mise in jeder Shell"
  in_new win-winget-no
  in_config
  in_run win-winget-no PATH="$IN_PKG:$IN_WINGET:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-winget-no/local"
  refute "install: declined winget installs nothing" in_calls_like win-winget-no '^winget'
  check "install: declined winget gets the way by hand" \
    in_says win-winget-no "übersprungen — von Hand: winget install jdx.mise"
  check "install: declined winget, mise is open" \
    in_says win-winget-no "Offen: mise just lefthook gitleaks"
  in_new win-winget-fail
  in_config
  in_input win-winget-fail j
  in_run win-winget-fail PATH="$IN_PKG:$IN_WINGET:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-winget-fail/local" \
    IN_WINGET_FAIL=1
  check "install: a failed winget still runs through" in_status win-winget-fail 0
  check "install: a failed winget is named" \
    in_says win-winget-fail "winget install jdx.mise ist gescheitert"
  check "install: after a failed winget, mise is open" \
    in_says win-winget-fail "Offen: mise just lefthook gitleaks"
  in_new win-winget-elsewhere
  in_config
  in_input win-winget-elsewhere j
  in_run win-winget-elsewhere PATH="$IN_PKG:$IN_WINGET:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-winget-elsewhere/local" \
    IN_WINGET_ELSEWHERE=1
  check "install: mise not in winget's package folder — restart and run again" \
    in_says win-winget-elsewhere "Git Bash neu starten, dann erneut ausführen"
  check "install: mise not in winget's package folder, mise is open" \
    in_says win-winget-elsewhere "Offen: mise just lefthook gitleaks"
  # Installed by winget before, the shell not restarted since: found, not offered again.
  in_new win-winget-before
  in_config
  in_win_pkg=$TMP/in/win-winget-before/local/Microsoft/WinGet/Packages/jdx.mise_Test/mise/bin
  mkdir -p "$in_win_pkg"
  cp "$IN_MISE/mise" "$in_win_pkg/mise"
  in_run win-winget-before PATH="$IN_PKG:$IN_WINGET:$IN_TOOLS_BIN:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-winget-before/local"
  check "install: mise from an earlier winget run is found" \
    in_says win-winget-before "mise liegt im Paketordner von winget"
  refute "install: mise from an earlier winget run is not installed again" \
    in_calls_like win-winget-before '^winget'
  refute "install: mise from an earlier winget run, nothing open" \
    in_says win-winget-before "Offen:"

  # Windows without winget, with scoop: scoop install mise.
  in_new win-scoop
  in_config
  in_input win-scoop j
  in_run win-scoop PATH="$IN_PKG:$IN_SCOOP:$IN_TOOLS_BIN:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-scoop/local"
  check "install: Windows with scoop runs through" in_status win-scoop 0
  check "install: Windows offers and runs scoop install mise" \
    in_called win-scoop "scoop install mise"
  check "install: after scoop, mise is installed" in_says win-scoop "mise installiert"

  # Windows with mise (step 6): the shims below %LOCALAPPDATA%\mise; the stand-in
  # PowerShell logs what set-mise-path hands it to the case's pslog. Declined at the end
  # of input, then accepted.
  in_new win-offer
  in_config
  in_run win-offer PATH="$IN_MISE:$IN_TOOLS_BIN:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-offer/local" \
    MT_PSLOG="$TMP/in/win-offer.pslog"
  check "install: Windows with mise runs through" in_status win-offer 0
  # The folder as Windows writes it: the stand-in cygpath -w turns the slashes round.
  in_win_dir=$(printf '%s' "$TMP/in/win-offer/local/mise/shims" | tr / '\\')
  check "install: Windows, shims not in the user PATH — offers to put them first" \
    in_says win-offer "Shim-Ordner $in_win_dir vorn in den Benutzer-PATH eintragen?"
  check "install: Windows, declined — the way by hand" \
    in_says win-offer "übersprungen — von Hand: $in_win_dir ganz vorn in den Benutzer-PATH"
  refute "install: Windows, declined — the user PATH stays" test -e "$TMP/in/win-offer.pslog"
  refute "install: Windows offers no startup file" in_says win-offer "Startdatei"
  in_new win-yes
  in_config
  in_input win-yes j
  in_run win-yes PATH="$IN_MISE:$IN_TOOLS_BIN:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-yes/local" \
    MT_PSLOG="$TMP/in/win-yes.pslog"
  check "install: Windows, accepted runs through" in_status win-yes 0
  in_win_dir=$(printf '%s' "$TMP/in/win-yes/local/mise/shims" | tr / '\\')
  check "install: Windows, accepted — set-mise-path gets the shims folder" \
    grep -qxF -- "$in_win_dir" "$TMP/in/win-yes.pslog"
  check "install: Windows, accepted — says to restart" in_says win-yes "eingetragen —"
  in_new win-manual
  in_config
  in_win_shims=$TMP/in/win-manual/local/mise/shims
  mkdir -p "$in_win_shims"
  printf '%s\n' '#!/bin/sh' | in_fake "$in_win_shims/just"
  in_run win-manual PATH="$IN_MISE:$IN_TOOLS_BIN:$in_win_shims:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-manual/local" \
    MT_USERPATH="$in_win_shims"
  check "install: Windows, shadowed from outside the user PATH runs through" \
    in_status win-manual 0
  check "install: Windows names the shadowing and the system PATH" \
    in_says win-manual "das kommt aus dem System-PATH oder der Git Bash"
  refute "install: Windows, shadowed, no startup file" in_says win-manual "Startdatei"
  # The user PATH unreadable: where the shadowing folder sits is not known.
  in_new win-unknown
  in_config
  in_win_shims=$TMP/in/win-unknown/local/mise/shims
  mkdir -p "$in_win_shims"
  printf '%s\n' '#!/bin/sh' | in_fake "$in_win_shims/just"
  in_run win-unknown PATH="$IN_MISE:$IN_TOOLS_BIN:$in_win_shims:$IN_BIN:$IN_WIN" \
    IN_UNAME_S=MINGW64_NT-10.0-19045 LOCALAPPDATA="$TMP/in/win-unknown/local" MT_PS=fail
  check "install: Windows, user PATH unreadable runs through" in_status win-unknown 0
  check "install: Windows, user PATH unreadable — the way by hand with the settings" \
    in_says win-unknown "Umgebungsvariablen für dieses Konto bearbeiten"
  refute "install: Windows, user PATH unreadable — no claim about the system PATH" \
    in_says win-unknown "System-PATH"

  # An unknown system: nothing installed, the install page named.
  in_new unknown-os
  in_config
  in_run unknown-os PATH="$IN_PKG:$IN_BREW:$IN_BIN" IN_UNAME_S=SunOS
  check "install: an unknown system is named" in_says unknown-os "Unbekanntes System"
  check "install: an unknown system names the mise install page" \
    in_says unknown-os "https://mise.jdx.dev/installing-mise.html"
  refute "install: an unknown system offers no brew" in_calls_like unknown-os '^brew'

  # WSL: treated as Linux, with the note.
  in_new wsl
  in_config
  in_run wsl IN_UNAME_S=Linux IN_UNAME_R=5.15.153-microsoft-standard-WSL2
  check "install: WSL is named" in_says wsl "WSL erkannt"
  check "install: WSL is treated as Linux" in_says wsl "curl https://mise.run | sh"
  in_new linux-not-wsl
  in_config
  in_run linux-not-wsl IN_UNAME_S=Linux IN_UNAME_R=6.8.0-45-generic
  refute "install: plain Linux is not WSL" in_says linux-not-wsl "WSL erkannt"
}
