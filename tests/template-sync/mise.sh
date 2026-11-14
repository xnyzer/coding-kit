# Whether the mise shims reach the shell (mise-check) for tests/template-sync/run.sh —
# sourced after sync.sh, uses its helpers.

# An empty executable at PATH.
mt_exe() {  # PATH
  printf '#!/bin/sh\n' > "$1"
  chmod +x "$1"
}

# mise-check with the home and data folder below $TMP/mise and extra environment
# (VAR=value…), its output in $TMP/mise/NAME.out. Every variable the check reads starts
# empty or fixed, so the environment of the test run does not leak in.
mt_run() {  # NAME VAR=value…
  mt_name=$1
  shift
  env HOME="$TMP/mise/home" ZDOTDIR= MISE_DATA_DIR="$TMP/mise/data" XDG_DATA_HOME= \
    MISE_SHELL= SHELL=/bin/zsh "$@" $SH "$SCRIPT" mise-check > "$TMP/mise/$mt_name.out"
}

# NAME's output has the line made of FIELD… joined by tabs.
mt_has() {  # NAME FIELD…
  mh_file=$TMP/mise/$1.out
  shift
  mh_line=$1
  shift
  for mh_field in "$@"; do mh_line="$mh_line	$mh_field"; done
  grep -qxF -- "$mh_line" "$mh_file"
}

# NAME's output has a line starting with KIND.
mt_kind() {  # NAME KIND
  grep -q "^$2	" "$TMP/mise/$1.out"
}

run_mise_cases() {
  mt_home=$TMP/mise/home
  mt_shims=$TMP/mise/data/shims
  mt_nvm=$TMP/mise/nvm
  mt_bin=$TMP/mise/bin
  mkdir -p "$mt_home" "$mt_shims" "$mt_nvm" "$mt_bin"
  mt_exe "$mt_shims/node"
  mt_exe "$mt_shims/go"
  mt_exe "$mt_nvm/node"
  mt_exe "$mt_bin/mise"
  mt_zsh_line='eval "$(mise activate zsh --shims)"'

  # Nothing set up yet: no startup file, shims off PATH.
  check "mise-check: runs without startup file" mt_run none PATH="$mt_bin:$PATH"
  check "mise-check: names the shell" mt_has none shell zsh
  check "mise-check: finds mise" mt_has none mise found
  check "mise-check: names the missing .zshrc" mt_has none rc "$mt_home/.zshrc" missing
  check "mise-check: no startup file, no line" mt_has none line absent
  check "mise-check: shims off PATH" mt_has none shims "$mt_shims" off-path
  check "mise-check: not activated" mt_has none activated no
  check "mise-check: the zsh line to add" mt_has none add "$mt_zsh_line"
  refute "mise-check: no shadowing while the shims are off PATH" mt_kind none shadowed
  check "mise-check: verdict offer without a line" mt_has none verdict offer

  # The line ends .zshrc, nvm comes before the shims on PATH (before a restart).
  printf '%s\n' 'export NVM_DIR="$HOME/.nvm"' '. "$NVM_DIR/nvm.sh"' '' '# mise, last' \
    "$mt_zsh_line" '' '# trailing comment' > "$mt_home/.zshrc"
  cksum < "$mt_home/.zshrc" > "$TMP/mise/zshrc.before"
  check "mise-check: runs with shims on PATH" \
    mt_run last PATH="$mt_nvm:$mt_shims:$mt_bin:$PATH"
  check "mise-check: line last (blanks and comments after it do not count)" \
    mt_has last line last
  check "mise-check: shims on PATH" mt_has last shims "$mt_shims" on-path
  check "mise-check: activated by the shims" mt_has last activated yes
  check "mise-check: names the directory that shadows a shim" \
    mt_has last shadowed node "$mt_nvm"
  refute "mise-check: a shim no directory before it holds is not shadowed" \
    grep -q "^shadowed	go	" "$TMP/mise/last.out"
  check "mise-check: line last yet shadowed — verdict hook" mt_has last verdict hook
  check "mise-check: runs with nothing before the shims" \
    mt_run clean PATH="$mt_shims:$mt_bin:$PATH"
  check "mise-check: activated, nothing shadowed — verdict ok" mt_has clean verdict ok
  check "mise-check: runs with the line in place, shims off PATH" \
    mt_run restart PATH="$mt_bin:$PATH"
  check "mise-check: line in place, not active — verdict restart" mt_has restart verdict restart
  check "mise-check: writes nothing" sh -c 'cksum < "$1" | cmp -s - "$2"' sh \
    "$mt_home/.zshrc" "$TMP/mise/zshrc.before"

  # The line comes before nvm in .zshrc: present, not last.
  printf '%s\n' "$mt_zsh_line" 'export NVM_DIR="$HOME/.nvm"' '. "$NVM_DIR/nvm.sh"' \
    > "$mt_home/.zshrc"
  check "mise-check: runs with the line before nvm" mt_run early PATH="$mt_bin:$PATH"
  check "mise-check: line present but not last" mt_has early line present
  check "mise-check: runs with the line before nvm, nvm first on PATH" \
    mt_run early2 PATH="$mt_nvm:$mt_shims:$mt_bin:$PATH"
  check "mise-check: line before a shadowing manager — verdict offer" \
    mt_has early2 verdict offer

  # Only commented out.
  printf '%s\n' "# $mt_zsh_line" 'alias ll="ls -l"' > "$mt_home/.zshrc"
  check "mise-check: runs with a commented line" mt_run commented PATH="$mt_bin:$PATH"
  check "mise-check: commented line" mt_has commented line commented
  check "mise-check: verdict commented" mt_has commented verdict commented

  # Activated without shims: MISE_SHELL set, shims off PATH, no shadowing checked.
  check "mise-check: runs with MISE_SHELL" \
    mt_run noshims MISE_SHELL=zsh PATH="$mt_nvm:$mt_bin:$PATH"
  check "mise-check: MISE_SHELL counts as activated" mt_has noshims activated yes
  refute "mise-check: no shadowing without shims on PATH" mt_kind noshims shadowed
  check "mise-check: activated without shims — verdict ok" mt_has noshims verdict ok

  # Activated without shims, shims on PATH too: the install directories of mise put first
  # by the activation hold the pinned versions and do not count as shadowing.
  mt_installs=$TMP/mise/data/installs/node/24/bin
  mkdir -p "$mt_installs"
  mt_exe "$mt_installs/node"
  check "mise-check: runs with mise install directories first" \
    mt_run installs MISE_SHELL=zsh PATH="$mt_installs:$mt_shims:$mt_bin:$PATH"
  refute "mise-check: its own install directories do not shadow" mt_kind installs shadowed
  check "mise-check: install directories first — verdict ok" mt_has installs verdict ok

  # ZDOTDIR moves the startup file; XDG_DATA_HOME the shims when MISE_DATA_DIR is unset.
  check "mise-check: runs with ZDOTDIR and XDG_DATA_HOME" mt_run xdg \
    ZDOTDIR="$TMP/mise/zdot" MISE_DATA_DIR= XDG_DATA_HOME="$TMP/mise/xdg" PATH="$mt_bin:$PATH"
  check "mise-check: .zshrc below ZDOTDIR" mt_has xdg rc "$TMP/mise/zdot/.zshrc" missing
  check "mise-check: shims below XDG_DATA_HOME" \
    mt_has xdg shims "$TMP/mise/xdg/mise/shims" off-path

  # bash: the line, but no startup file yet; another shell: neither.
  check "mise-check: runs under bash" mt_run bash SHELL=/bin/bash PATH="$mt_bin:$PATH"
  check "mise-check: bash names the shell" mt_has bash shell bash
  check "mise-check: bash has no startup file yet" mt_has bash rc - -
  check "mise-check: bash, no line state" mt_has bash line -
  check "mise-check: the bash line to add" \
    mt_has bash add 'eval "$(mise activate bash --shims)"'
  check "mise-check: bash without startup file — verdict manual" mt_has bash verdict manual
  check "mise-check: runs under bash with shadowing" \
    mt_run bash2 SHELL=/bin/bash PATH="$mt_nvm:$mt_shims:$mt_bin:$PATH"
  check "mise-check: bash names the shadowing" mt_has bash2 shadowed node "$mt_nvm"
  check "mise-check: bash, active but shadowed — verdict manual" mt_has bash2 verdict manual
  check "mise-check: runs under fish" mt_run fish SHELL=/usr/local/bin/fish PATH="$mt_bin:$PATH"
  check "mise-check: the fish line to add" mt_has fish add 'mise activate fish --shims | source'
  check "mise-check: runs under another shell" mt_run nu SHELL=/usr/local/bin/nu PATH="$mt_bin:$PATH"
  check "mise-check: other shells get no line" mt_has nu add -

  refute "mise-check: refuses an operand" ts mise-check extra

  # set-mise: the startup file with the line appended, written into OUT only.
  mt_comment='# mise: project-pinned tools via shims, last so they come before other tool managers.'
  printf '%s\n' 'alias ll="ls -l"' > "$TMP/mise/rc1"
  cp "$TMP/mise/rc1" "$TMP/mise/rc1.orig"
  check "set-mise: writes the file" mt_set rc1 "$TMP/mise/rc1" sm1
  check "set-mise: names the written file" file_is mise/sm1.out 'written\trc1\n'
  printf '%s\n' 'alias ll="ls -l"' '' "$mt_comment" "$mt_zsh_line" > "$TMP/mise/rc1.want"
  check "set-mise: lines kept, blank line, comment, activation line" \
    cmp -s "$TMP/mise/sm1/rc1" "$TMP/mise/rc1.want"
  check "set-mise: the startup file itself stays as it was" \
    cmp -s "$TMP/mise/rc1" "$TMP/mise/rc1.orig"
  printf 'alias ll="ls -l"' > "$TMP/mise/rc2"
  check "set-mise: runs on a file without final newline" mt_set rc2 "$TMP/mise/rc2" sm2
  check "set-mise: completes the last line first" cmp -s "$TMP/mise/sm2/rc2" "$TMP/mise/rc1.want"
  check "set-mise: runs on a missing file" mt_set rc3 "$TMP/mise/no-such-rc" sm3
  printf '\n%s\n%s\n' "$mt_comment" "$mt_zsh_line" > "$TMP/mise/rc3.want"
  check "set-mise: a missing file counts as empty" \
    cmp -s "$TMP/mise/sm3/no-such-rc" "$TMP/mise/rc3.want"
  check "set-mise: runs under bash" mt_set bash1 "$TMP/mise/rc1" sm4 SHELL=/bin/bash
  check "set-mise: bash gets the bash line" \
    grep -qxF 'eval "$(mise activate bash --shims)"' "$TMP/mise/sm4/rc1"
  refute "set-mise: refuses a shell without known line" \
    mt_set nu1 "$TMP/mise/rc1" sm5 SHELL=/usr/local/bin/nu
  refute "set-mise: writes nothing for such a shell" test -e "$TMP/mise/sm5"
  mkdir -p "$TMP/mise/sm6"
  : > "$TMP/mise/sm6/other"
  refute "set-mise: refuses a non-empty OUT" mt_set full "$TMP/mise/rc1" sm6
  refute "set-mise: needs RC and OUT" ts set-mise "$TMP/mise/rc1"

  # tool-check: a tool counts only when it runs outside any project. The stand-in mise
  # knows kt-global as a global version, and only when asked from the home folder
  # (compared resolved: TMPDIR may end in a slash, so HOME can hold a //).
  mt_fake=$TMP/mise/fake
  mt_sys=$TMP/mise/sys
  mt_inst=$TMP/mise/data/installs/kt-inst/1/bin
  mkdir -p "$mt_fake" "$mt_sys" "$mt_inst"
  printf '%s\n' '#!/bin/sh' \
    '[ "$1" = which ] && [ "$2" = kt-global ] || exit 1' \
    '[ "$(pwd -P)" = "$(cd "$HOME" && pwd -P)" ]' > "$mt_fake/mise"
  chmod +x "$mt_fake/mise"
  mt_exe "$mt_shims/kt-shim"
  mt_exe "$mt_shims/kt-global"
  mt_exe "$mt_sys/kt-sys"
  mt_exe "$mt_inst/kt-inst"
  check "tool-check: runs" mt_tool tools "$mt_fake:$mt_inst:$mt_shims:$mt_sys:$PATH" \
    kt-sys kt-shim kt-inst kt-global kt-none
  check "tool-check: a tool in a directory on PATH is present" \
    mt_has tools tool kt-sys present
  check "tool-check: a shim without a global version is missing" \
    mt_has tools tool kt-shim missing
  check "tool-check: an install directory of mise does not count" \
    mt_has tools tool kt-inst missing
  check "tool-check: a global version in mise counts" mt_has tools tool kt-global present
  check "tool-check: a tool found nowhere is missing" mt_has tools tool kt-none missing
  check "tool-check: one line per tool" sh -c '[ "$(wc -l < "$1")" -eq 5 ]' sh \
    "$TMP/mise/tools.out"
  refute "tool-check: needs a TOOL" ts tool-check
  refute "tool-check: refuses a TOOL with a slash" ts tool-check ../kt-sys
  refute "tool-check: refuses an empty TOOL" ts tool-check ''
}

# set-mise RC $TMP/mise/OUT with SHELL zsh unless given (VAR=value…), its output in
# $TMP/mise/OUT.out.
mt_set() {  # NAME RC OUT VAR=value…
  ms_rc=$2 ms_out=$3
  shift 3
  env HOME="$TMP/mise/home" ZDOTDIR= SHELL=/bin/zsh "$@" \
    $SH "$SCRIPT" set-mise "$ms_rc" "$TMP/mise/$ms_out" > "$TMP/mise/$ms_out.out"
}

# tool-check TOOL… with the home and data folder below $TMP/mise and PATH as given, its
# output in $TMP/mise/NAME.out.
mt_tool() {  # NAME PATH TOOL…
  mt_name=$1 mt_path=$2
  shift 2
  env HOME="$TMP/mise/home" MISE_DATA_DIR="$TMP/mise/data" XDG_DATA_HOME= \
    PATH="$mt_path" $SH "$SCRIPT" tool-check "$@" > "$TMP/mise/$mt_name.out"
}
