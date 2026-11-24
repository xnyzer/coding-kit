# Whether the mise shims reach the shell (mise-check) for tests/template-sync/run.sh —
# sourced after sync.sh, uses its helpers.

# An empty executable at PATH.
mt_exe() {  # PATH
  printf '#!/bin/sh\n' > "$1"
  chmod +x "$1"
}

# Stand-ins for what the check asks the system, written into DIR: uname names the system
# from MT_UNAME_S (macOS unless set); cygpath turns Windows paths into POSIX ones (-u, -p
# for a list) and back (-w, -m with forward slashes), with the drive X: as the folder
# MT_DRIVE; powershell.exe
# prints the user PATH from MT_USERPATH, or fails with MT_PS=fail — asked to write it
# (set-mise-path), it appends the folder it got in CODING_KIT_SHIMS to the file
# MT_PSLOG instead.
mt_os_fakes() {  # DIR
  printf '%s\n' '#!/bin/sh' 'printf "%s\n" "${MT_UNAME_S:-Darwin}"' > "$1/uname"
  cat > "$1/cygpath" <<'EOF'
#!/bin/sh
mode=$1
shift
if [ "$mode" = -w ] || [ "$mode" = -m ]; then
  s=$1
  if [ -n "${MT_DRIVE:-}" ]; then
    case $s in
      "$MT_DRIVE"/*) s="X:${s#"$MT_DRIVE"}" ;;
    esac
  fi
  if [ "$mode" = -w ]; then
    printf '%s\n' "$s" | tr / '\\'
  else
    printf '%s\n' "$s"
  fi
  exit
fi
list=no
if [ "$1" = -p ]; then
  list=yes
  shift
fi
CP_IN=$1 CP_LIST=$list awk 'BEGIN {
  drive = ENVIRON["MT_DRIVE"]
  s = ENVIRON["CP_IN"]
  n = ENVIRON["CP_LIST"] == "yes" ? split(s, parts, ";") : split(s, parts, "\001")
  out = ""
  for (i = 1; i <= n; i++) {
    p = parts[i]
    gsub(/\\/, "/", p)
    if (p ~ /^[Xx]:/) p = drive substr(p, 3)
    out = out (i > 1 ? ":" : "") p
  }
  print out
}'
EOF
  cat > "$1/powershell.exe" <<'EOF'
#!/bin/sh
[ "${MT_PS:-}" != fail ] || exit 1
case $* in
  *SetValue*) printf '%s\n' "$CODING_KIT_SHIMS" >> "$MT_PSLOG" ;;
  *) printf '%s\r\n' "${MT_USERPATH:-}" ;;
esac
EOF
  chmod +x "$1/uname" "$1/cygpath" "$1/powershell.exe"
}

# mise-check with the home and data folder below $TMP/mise and extra environment
# (VAR=value…), its output in $TMP/mise/NAME.out. Every variable the check reads starts
# empty or fixed, so the environment of the test run does not leak in; the stand-ins of
# mt_os_fakes come with $mt_bin, which every case puts on PATH.
mt_run() {  # NAME VAR=value…
  mt_name=$1
  shift
  env HOME="$TMP/mise/home" ZDOTDIR= MISE_DATA_DIR="$TMP/mise/data" XDG_DATA_HOME= \
    MISE_SHELL= SHELL=/bin/zsh LOCALAPPDATA= MT_UNAME_S= MT_USERPATH= MT_PS= \
    MT_DRIVE="$TMP/mise/drive" "$@" $SH "$SCRIPT" mise-check > "$TMP/mise/$mt_name.out"
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
  mt_os=$TMP/mise/os
  mkdir -p "$mt_home" "$mt_shims" "$mt_nvm" "$mt_bin" "$mt_os"
  mt_exe "$mt_shims/node"
  mt_exe "$mt_shims/go"
  mt_exe "$mt_nvm/node"
  mt_exe "$mt_bin/mise"
  mt_os_fakes "$mt_bin"
  mt_os_fakes "$mt_os"
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
  refute "mise-check: no userpath line off Windows" mt_kind nu userpath

  refute "mise-check: refuses an operand" ts mise-check extra

  # Windows: the shims below %LOCALAPPDATA%\mise, the user PATH from PowerShell; the drive
  # X: is $mt_drive. A shim is shadowed by a folder of the user PATH (tools, also one with
  # a space in its name) or by one outside it (sys, as from the system PATH).
  mt_win=MT_UNAME_S=MINGW64_NT-10.0-26200
  mt_drive=$TMP/mise/drive
  mt_wshims=$mt_drive/Profile/AppData/Local/mise/shims
  mt_wuser='X:\Profile\AppData\Local\mise\shims'
  mkdir -p "$mt_wshims" "$mt_drive/tools" "$mt_drive/Program Files/tool" "$TMP/mise/winsys"
  mt_exe "$mt_wshims/node"
  mt_exe "$mt_drive/tools/node"
  mt_exe "$mt_drive/Program Files/tool/node"
  mt_exe "$TMP/mise/winsys/node"
  # The Windows environment every case below starts from.
  set -- "$mt_win" SHELL=/usr/bin/bash.exe MISE_DATA_DIR= \
    LOCALAPPDATA='X:\Profile\AppData\Local'
  check "mise-check: runs on Windows" mt_run win-none "$@" PATH="$mt_bin:$PATH"
  check "mise-check: Windows names the shell without .exe" mt_has win-none shell bash
  check "mise-check: Windows names no startup file" mt_has win-none rc - -
  check "mise-check: Windows has no line state" mt_has win-none line -
  check "mise-check: Windows has no line to add" mt_has win-none add -
  check "mise-check: Windows finds the shims below LOCALAPPDATA" \
    mt_has win-none shims "$mt_wshims" off-path
  check "mise-check: Windows without user PATH" mt_has win-none userpath absent
  check "mise-check: shims not in the user PATH — verdict offer-path" \
    mt_has win-none verdict offer-path
  check "mise-check: runs on Windows with XDG_DATA_HOME" \
    mt_run win-xdg "$@" XDG_DATA_HOME='X:\xdg' PATH="$mt_bin:$PATH"
  check "mise-check: Windows, shims below XDG_DATA_HOME in Windows form" \
    mt_has win-xdg shims "$mt_drive/xdg/mise/shims" off-path
  check "mise-check: runs on Windows with MISE_DATA_DIR" \
    mt_run win-mdd "$@" MISE_DATA_DIR='X:\mdd' PATH="$mt_bin:$PATH"
  check "mise-check: Windows, shims below MISE_DATA_DIR in Windows form" \
    mt_has win-mdd shims "$mt_drive/mdd/shims" off-path
  check "mise-check: runs on Windows with the shims in the user PATH only" \
    mt_run win-restart "$@" MT_USERPATH="X:\\tools;$mt_wuser" PATH="$mt_bin:$PATH"
  check "mise-check: Windows, shims in the user PATH" mt_has win-restart userpath present
  check "mise-check: in the user PATH, not yet on PATH — verdict restart" \
    mt_has win-restart verdict restart
  # Another case and a backslash at the end in the user PATH, another case on PATH.
  mt_wupper=$mt_drive/PROFILE/AppData/Local/mise/shims
  check "mise-check: runs on Windows with the shims spelled otherwise" \
    mt_run win-ok "$@" MT_USERPATH='X:\profile\appdata\local\MISE\shims\' \
    PATH="$mt_wupper:$mt_bin:$PATH"
  check "mise-check: Windows, another spelling in the user PATH counts" \
    mt_has win-ok userpath present
  check "mise-check: Windows, the shims spelled as on PATH" \
    mt_has win-ok shims "$mt_wupper" on-path
  check "mise-check: Windows, active and nothing shadowed — verdict ok" mt_has win-ok verdict ok
  check "mise-check: runs on Windows, shadowed from the user PATH" \
    mt_run win-user "$@" MT_USERPATH="X:\\tools;$mt_wuser" \
    PATH="$mt_drive/tools:$mt_wshims:$mt_bin:$PATH"
  check "mise-check: Windows names the shadowing" mt_has win-user shadowed node "$mt_drive/tools"
  check "mise-check: shadowed from before the shims in the user PATH — verdict offer-path" \
    mt_has win-user verdict offer-path
  check "mise-check: runs on Windows, shadowed from a folder with a space" \
    mt_run win-space "$@" MT_USERPATH="X:\\Program Files\\tool;$mt_wuser" \
    PATH="$mt_drive/Program Files/tool:$mt_wshims:$mt_bin:$PATH"
  check "mise-check: Windows names a shadowing folder with a space" \
    mt_has win-space shadowed node "$mt_drive/Program Files/tool"
  check "mise-check: a folder with a space in the user PATH — verdict offer-path" \
    mt_has win-space verdict offer-path
  check "mise-check: runs on Windows, shadowed from outside the user PATH" \
    mt_run win-sys "$@" MT_USERPATH="$mt_wuser;X:\\tools" \
    PATH="$TMP/mise/winsys:$mt_wshims:$mt_bin:$PATH"
  check "mise-check: shadowed from outside the user PATH — verdict manual" \
    mt_has win-sys verdict manual
  check "mise-check: runs on Windows, shims first in the user PATH, shadowed after it" \
    mt_run win-after "$@" MT_USERPATH="$mt_wuser;X:\\tools" \
    PATH="$mt_drive/tools:$mt_wshims:$mt_bin:$PATH"
  check "mise-check: a folder after the shims in the user PATH — verdict manual" \
    mt_has win-after verdict manual
  check "mise-check: runs on Windows without a readable user PATH" \
    mt_run win-unknown "$@" MT_PS=fail PATH="$mt_bin:$PATH"
  check "mise-check: Windows, user PATH unknown" mt_has win-unknown userpath unknown
  check "mise-check: user PATH unknown, not active — verdict manual" \
    mt_has win-unknown verdict manual
  check "mise-check: runs on Windows, user PATH unknown, shims on PATH" \
    mt_run win-unknown-ok "$@" MT_PS=fail PATH="$mt_wshims:$mt_bin:$PATH"
  check "mise-check: user PATH unknown, active and nothing shadowed — verdict ok" \
    mt_has win-unknown-ok verdict ok
  set --

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
  refute "set-mise: refuses on Windows" mt_set win1 "$TMP/mise/rc1" sm7 "$mt_win"
  refute "set-mise: writes nothing on Windows" test -e "$TMP/mise/sm7"

  # set-mise-path: hands the shims folder, as Windows writes it, to PowerShell; the
  # stand-in logs it instead of writing the user PATH.
  mt_wdir='X:\Profile\AppData\Local\mise\shims'
  check "set-mise-path: runs on Windows" mt_path smp1 "$mt_win"
  check "set-mise-path: names the folder it put first" \
    mt_has smp1 written user-path "$mt_wdir"
  check "set-mise-path: hands the folder to PowerShell" \
    grep -qxF -- "$mt_wdir" "$TMP/mise/smp1.pslog"
  refute "set-mise-path: refuses off Windows" mt_path smp2
  refute "set-mise-path: off Windows PowerShell is not called" test -e "$TMP/mise/smp2.pslog"
  refute "set-mise-path: fails when PowerShell fails" mt_path smp3 "$mt_win" MT_PS=fail
  mt_nops=$TMP/mise/nops
  mkdir -p "$mt_nops"
  mt_os_fakes "$mt_nops"
  rm -f "$mt_nops/powershell.exe"
  refute "set-mise-path: refuses without PowerShell" \
    mt_path smp4 "$mt_win" PATH="$mt_nops:/usr/bin:/bin"
  refute "set-mise-path: refuses an operand" ts set-mise-path extra

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
  check "tool-check: runs" mt_tool tools "$mt_os:$mt_fake:$mt_inst:$mt_shims:$mt_sys:$PATH" \
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

  # tool-check on Windows: a shim in the shims folder below %LOCALAPPDATA%\mise does not
  # count, while a tool in another folder does.
  mt_exe "$mt_wshims/kt-wshim"
  check "tool-check: runs on Windows" mt_wtool wtools "$mt_os:$mt_wshims:$mt_sys:$PATH" \
    kt-wshim kt-sys
  check "tool-check: Windows, a shim in the shims folder is missing" \
    mt_has wtools tool kt-wshim missing
  check "tool-check: Windows, a tool in another folder is present" \
    mt_has wtools tool kt-sys present
}

# set-mise RC $TMP/mise/OUT with SHELL zsh unless given (VAR=value…) and the stand-ins of
# mt_os_fakes first on PATH, its output in $TMP/mise/OUT.out.
mt_set() {  # NAME RC OUT VAR=value…
  ms_rc=$2 ms_out=$3
  shift 3
  env HOME="$TMP/mise/home" ZDOTDIR= SHELL=/bin/zsh MT_UNAME_S= PATH="$mt_os:$PATH" "$@" \
    $SH "$SCRIPT" set-mise "$ms_rc" "$TMP/mise/$ms_out" > "$TMP/mise/$ms_out.out"
}

# set-mise-path with the shims below %LOCALAPPDATA%\mise (drive X: is $mt_drive), the
# stand-ins of mt_os_fakes first on PATH and extra environment (VAR=value…); its output
# in $TMP/mise/NAME.out, what the stand-in PowerShell got in $TMP/mise/NAME.pslog.
mt_path() {  # NAME VAR=value…
  mp_name=$1
  shift
  env HOME="$TMP/mise/home" MISE_DATA_DIR= XDG_DATA_HOME= MT_UNAME_S= MT_PS= \
    LOCALAPPDATA='X:\Profile\AppData\Local' MT_DRIVE="$mt_drive" \
    MT_PSLOG="$TMP/mise/$mp_name.pslog" PATH="$mt_os:$PATH" "$@" \
    $SH "$SCRIPT" set-mise-path > "$TMP/mise/$mp_name.out"
}

# tool-check TOOL… with the home and data folder below $TMP/mise and PATH as given, its
# output in $TMP/mise/NAME.out.
mt_tool() {  # NAME PATH TOOL…
  mt_name=$1 mt_path=$2
  shift 2
  env HOME="$TMP/mise/home" MISE_DATA_DIR="$TMP/mise/data" XDG_DATA_HOME= MT_UNAME_S= \
    PATH="$mt_path" $SH "$SCRIPT" tool-check "$@" > "$TMP/mise/$mt_name.out"
}

# mt_tool on Windows: the shims below %LOCALAPPDATA%\mise, the drive X: is $mt_drive.
mt_wtool() {  # NAME PATH TOOL…
  mt_name=$1 mt_path=$2
  shift 2
  env HOME="$TMP/mise/home" MISE_DATA_DIR= XDG_DATA_HOME= "$mt_win" \
    LOCALAPPDATA='X:\Profile\AppData\Local' MT_DRIVE="$mt_drive" PATH="$mt_path" \
    $SH "$SCRIPT" tool-check "$@" > "$TMP/mise/$mt_name.out"
}
