# synced-folder cases for tests/template-sync/run.sh — sourced, uses its helpers. They run
# template-sync.sh synced-folder in an environment of PATH, a test HOME and the variables a
# case sets, so the OneDrive variables of the machine never take part. Folders in drive
# form are strings only; nothing below them has to exist.

# sy_run HOME [VAR=value…] -- ARG… — synced-folder with ARG…, HOME and the variables;
# output in $TMP/sy/out, errors in $TMP/sy/err, status as the function's. The loop turns
# the -- into the command, so the variables stay in front of it for env.
sy_run() {
  sr_home=$1
  shift
  sr_count=$#
  while [ "$sr_count" -gt 0 ]; do
    if [ "$1" = -- ]; then
      set -- "$@" "$SH" "$SCRIPT" synced-folder
    else
      set -- "$@" "$1"
    fi
    shift
    sr_count=$((sr_count - 1))
  done
  env -i PATH="$PATH" HOME="$sr_home" "$@" > "$TMP/sy/out" 2> "$TMP/sy/err"
}

# sy_is LINE [VAR=value…] -- ARG… — synced-folder prints LINE (\t for a tab), HOME is
# $TMP/sy/plain.
sy_is() {
  si_want=$(printf '%b' "$1")
  shift
  sy_run "$TMP/sy/plain" "$@" || return 1
  [ "$(cat "$TMP/sy/out")" = "$si_want" ]
}

# sy_status STATUS [VAR=value…] -- ARG… — synced-folder ends with STATUS.
sy_status() {
  ss_want=$1
  shift
  sy_run "$TMP/sy/plain" "$@"
  [ $? -eq "$ss_want" ]
}

run_synced_cases() {
  mkdir -p "$TMP/sy/plain" "$TMP/sy/box/Dropbox"
  sy_od='C:\Profiles\u\OneDrive'

  # OneDrive by its variables; the three forms of a drive path are the same folder.
  check "synced: a folder in OneDrive" \
    sy_is "synced\tonedrive\t$sy_od" OneDrive="$sy_od" -- 'C:/Profiles/u/OneDrive/Dokumente/p'
  check "synced: backslashes count as slashes" \
    sy_is "synced\tonedrive\t$sy_od" OneDrive="$sy_od" -- 'C:\Profiles\u\OneDrive\p'
  check "synced: the Git Bash form /c/ counts as C:/" \
    sy_is "synced\tonedrive\t$sy_od" OneDrive="$sy_od" -- /c/Profiles/u/OneDrive/p
  check "synced: a drive path in any case" \
    sy_is "synced\tonedrive\t$sy_od" OneDrive="$sy_od" -- c:/profiles/U/onedrive/P
  check "synced: OneDriveConsumer counts" \
    sy_is "synced\tonedrive\t$sy_od" OneDriveConsumer="$sy_od" -- C:/Profiles/u/OneDrive/p
  check "synced: OneDriveCommercial with blanks and a dash" \
    sy_is 'synced\tonedrive\tC:\\Profiles\\u\\OneDrive - Firma' \
    OneDrive="$sy_od" OneDriveCommercial='C:\Profiles\u\OneDrive - Firma' \
    -- 'C:/Profiles/u/OneDrive - Firma/p'
  check "synced: the sync folder itself" \
    sy_is "synced\tonedrive\t$sy_od" OneDrive="$sy_od" -- C:/Profiles/u/OneDrive
  check "synced: the sync folder with / at the end" \
    sy_is "synced\tonedrive\t$sy_od" OneDrive="$sy_od" -- C:/Profiles/u/OneDrive/

  # Outside: the home folder above it, a neighbour with the same start, no variables.
  check "synced: the home folder above OneDrive is local" \
    sy_is local OneDrive="$sy_od" -- C:/Profiles/u/Coding-Projects
  check "synced: a neighbour with the same start is local" \
    sy_is local OneDrive="$sy_od" -- C:/Profiles/u/OneDrive-Backup/p
  check "synced: without the variables nothing is OneDrive" \
    sy_is local -- C:/Profiles/u/OneDrive/p
  check "synced: an empty variable is no sync folder" \
    sy_is local OneDrive= -- /

  # Dropbox: the folder in HOME, only when it exists.
  check "synced: a folder in ~/Dropbox" \
    eval 'sy_run "$TMP/sy/box" -- "$TMP/sy/box/Dropbox/p" &&
      [ "$(cat "$TMP/sy/out")" = "$(printf "synced\tdropbox\t%s" "$TMP/sy/box/Dropbox")" ]'
  check "synced: a neighbour of ~/Dropbox is local" \
    eval 'sy_run "$TMP/sy/box" -- "$TMP/sy/box/Dropbox2/p" &&
      [ "$(cat "$TMP/sy/out")" = local ]'
  check "synced: without ~/Dropbox nothing is Dropbox" \
    sy_is local -- "$TMP/sy/plain/Dropbox/p"

  # --config: the projects folder of the personal config, read and never executed.
  printf '%s\n' 'CODING_KIT_PROJECTS_DIR="C:/Profiles/u/OneDrive/Projects"' > "$TMP/sy/in.env"
  printf '%s\n' 'CODING_KIT_PROJECTS_DIR="C:/Profiles/u/Code"' > "$TMP/sy/out.env"
  printf '%s\n' 'CODING_KIT_GITHUB_LOGIN="octo"' > "$TMP/sy/none.env"
  # The touch would leave a file in $TMP/sy if anything ran the value.
  printf '%s\n' 'CODING_KIT_PROJECTS_DIR="$HOME/Dropbox/p$(touch '"$TMP/sy/pwned"')"' \
    > "$TMP/sy/home.env"
  printf '%s\n' "CODING_KIT_PROJECTS_DIR='~/Dropbox'" > "$TMP/sy/tilde.env"
  check "synced: --config, the projects folder in OneDrive" \
    sy_is "synced\tonedrive\t$sy_od" OneDrive="$sy_od" -- --config "$TMP/sy/in.env"
  check "synced: --config, the projects folder outside" \
    sy_is local OneDrive="$sy_od" -- --config "$TMP/sy/out.env"
  check "synced: --config without the key gives none" \
    sy_is none OneDrive="$sy_od" -- --config "$TMP/sy/none.env"
  check "synced: --config, a missing file gives none" \
    sy_is none -- --config "$TMP/sy/no-such.env"
  check "synced: --config, \$HOME at the start counts as HOME" \
    eval 'sy_run "$TMP/sy/box" -- --config "$TMP/sy/home.env" &&
      [ "$(cat "$TMP/sy/out")" = "$(printf "synced\tdropbox\t%s" "$TMP/sy/box/Dropbox")" ]'
  refute "synced: --config runs nothing from the file" has sy/pwned
  check "synced: --config, ~ at the start counts as HOME" \
    eval 'sy_run "$TMP/sy/box" -- --config "$TMP/sy/tilde.env" &&
      [ "$(cat "$TMP/sy/out")" = "$(printf "synced\tdropbox\t%s" "$TMP/sy/box/Dropbox")" ]'

  # Refused: no path, an empty one, a tab, a path next to --config, --config elsewhere.
  check "synced: without a path it ends with 2" sy_status 2 --
  check "synced: an empty path ends with 2" sy_status 2 -- ''
  check "synced: a tab in the path ends with 1" sy_status 1 -- "$(printf 'C:/a\tb')"
  check "synced: --config with a path ends with 2" \
    sy_status 2 -- --config "$TMP/sy/in.env" C:/x
  check "synced: another command takes no --config" \
    eval '$SH "$SCRIPT" default-host --config "$TMP/sy/in.env" x > /dev/null 2>&1; [ $? -eq 2 ]'
}
