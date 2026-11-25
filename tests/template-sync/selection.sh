# Selection cases for tests/template-sync/run.sh — sourced, uses its helpers.
# They test the kit script scripts/script-tests.sh, which picks the test groups a change
# touches, in small repositories of their own (--list prints the choice instead of
# running it), and that run.sh refuses a group it does not know.

# sel_repo NAME — a committed repository in $TMP/sel/NAME with a copy of script-tests.sh
# and files at most paths the cases change (a path without one becomes a new file).
sel_repo() {
  sr_dir=$TMP/sel/$1
  rm -rf "$sr_dir"
  mkdir -p "$sr_dir/scripts" "$sr_dir/plugins/coding-kit/hooks" \
    "$sr_dir/plugins/coding-kit/scripts" "$sr_dir/tests/template-sync"
  cp "$ROOT/scripts/script-tests.sh" "$sr_dir/scripts/"
  for sr_file in README.md install.sh scripts/release-notes.sh \
    plugins/coding-kit/hooks/stop.sh plugins/coding-kit/scripts/template-sync.sh \
    tests/template-sync/run.sh tests/template-sync/mise.sh \
    tests/template-sync/install.sh tests/template-sync/detect.sh; do
    echo base > "$sr_dir/$sr_file"
  done
  git -C "$sr_dir" init -q
  git -C "$sr_dir" add -A
  git -C "$sr_dir" -c user.name=t -c user.email=test@example.com commit -q -m base
}

# sel_change NAME PATH… — changes the files at PATH in repository NAME (new ones too).
sel_change() {
  sc_dir=$TMP/sel/$1
  shift
  for sc_path in "$@"; do
    mkdir -p "$(dirname "$sc_dir/$sc_path")"
    echo changed >> "$sc_dir/$sc_path"
  done
}

# sel_lists NAME EXPECTED [OPTION…] — script-tests.sh --list in repository NAME prints
# exactly EXPECTED and succeeds.
sel_lists() {
  sl_dir=$TMP/sel/$1 sl_want=$2
  shift 2
  sl_got=$(cd "$sl_dir" && $SH scripts/script-tests.sh --list "$@") || return 1
  [ "$sl_got" = "$sl_want" ]
}

run_selection_cases() {
  # Only documentation: no group.
  sel_repo doc
  sel_change doc README.md
  check "selection: a change the tests do not see runs no group" sel_lists doc none

  # The installer: its group only.
  sel_repo inst
  sel_change inst install.sh
  check "selection: install.sh runs the install group" sel_lists inst install

  # Two areas: both groups, each once.
  sel_repo two
  sel_change two install.sh plugins/coding-kit/hooks/stop.sh \
    tests/template-sync/install.sh
  check "selection: two areas run both groups, each once" sel_lists two "install hook"

  # A test file runs its group, and the groups that call its helpers.
  sel_repo test
  sel_change test tests/template-sync/detect.sh
  check "selection: a test file runs its group" sel_lists test detect
  sel_repo stand-ins
  sel_change stand-ins tests/template-sync/mise.sh
  check "selection: mise.sh runs the groups that use its stand-ins" \
    sel_lists stand-ins "mise install"
  sel_repo zones
  sel_change zones tests/template-sync/zones.sh
  check "selection: zones.sh runs the groups that use its helpers" \
    sel_lists zones "zones global"
  sel_repo fixtures
  sel_change fixtures tests/template-sync/sync.sh
  check "selection: sync.sh, whose helpers most groups use, runs all groups" \
    sel_lists fixtures all

  # A script another one calls runs the caller's group too; a file a case reads, its group.
  sel_repo notes
  sel_change notes scripts/release-notes.sh
  check "selection: release-notes.sh runs the publish-release group too" \
    sel_lists notes "release-notes publish-release"
  sel_repo lock
  sel_change lock mise.lock
  check "selection: mise.lock runs the privacy group" sel_lists lock privacy

  # Shared parts run all groups, whatever else changed.
  sel_repo core
  sel_change core install.sh plugins/coding-kit/scripts/template-sync.sh
  check "selection: template-sync.sh runs all groups" sel_lists core all
  sel_repo runner
  sel_change runner tests/template-sync/run.sh
  check "selection: run.sh runs all groups" sel_lists runner all
  sel_repo self
  sel_change self scripts/script-tests.sh
  check "selection: script-tests.sh runs all groups" sel_lists self all

  # A new file counts like a changed one.
  sel_repo new
  sel_change new plugins/coding-kit/hooks/new.sh
  check "selection: a new hook file runs the hook group" sel_lists new hook

  # --staged sees only the index.
  sel_repo staged
  sel_change staged install.sh plugins/coding-kit/hooks/stop.sh
  git -C "$TMP/sel/staged" add plugins/coding-kit/hooks/stop.sh
  check "selection: --staged runs the groups of staged changes only" \
    sel_lists staged hook --staged
  check "selection: without --staged unstaged changes count too" \
    sel_lists staged "install hook"

  # Without a commit to compare with: all groups.
  rm -rf "$TMP/sel/empty"
  mkdir -p "$TMP/sel/empty/scripts"
  cp "$ROOT/scripts/script-tests.sh" "$TMP/sel/empty/scripts/"
  git -C "$TMP/sel/empty" init -q
  check "selection: without a commit all groups run" sel_lists empty all

  # Unknown arguments stop with exit 2.
  check "selection: an unknown option ends with 2" eval \
    '(cd "$TMP/sel/inst" && $SH scripts/script-tests.sh --nope) > /dev/null 2>&1;
     [ $? -eq 2 ]'
  check "selection: run.sh refuses an unknown group with 2" eval \
    '$SH "$ROOT/tests/template-sync/run.sh" no-such-group \
       > /dev/null 2> "$TMP/sel/unknown.err";
     [ $? -eq 2 ] && grep -q "unknown group: no-such-group" "$TMP/sel/unknown.err"'
  check "selection: run.sh refuses two group names in one argument with 2" eval \
    '$SH "$ROOT/tests/template-sync/run.sh" render sync "render sync" \
       > /dev/null 2>&1;
     [ $? -eq 2 ]'
}
