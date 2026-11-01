# Claude Code settings and the auto memory folder (settings, set-settings, memory-dir)
# for tests/template-sync/run.sh — sourced after sync.sh, uses its fixture helpers.

# The script under test with one environment variable set (NAME=value first).
ts_env() {
  te_var=$1
  shift
  env "$te_var" $SH "$SCRIPT" "$@"
}

# The name Claude Code gives the project folder of PATH (the rule under test is spelled
# out once more here on purpose: every byte that is no ASCII letter or digit is "-").
folder_of() {  # PATH
  printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9]/-/g'
}

# A git repository at $TMP/NAME with one commit.
git_repo() {  # NAME
  mkdir -p "$TMP/$1"
  git -C "$TMP/$1" init -q
  git -C "$TMP/$1" -c user.name=t -c user.email=test@example.com commit -q --allow-empty -m init
}

run_settings_cases() {
  # --- settings: read the user settings ---------------------------------------------
  mkdir -p "$TMP/sc0"
  check "settings: missing file runs" eval 'ts settings "$TMP/sc0" > "$TMP/sc0.out"'
  check "settings: missing file and keys" file_is sc0.out \
    'file\tmissing\nkey\tautoMemoryEnabled\tmissing\nkey\tcleanupPeriodDays\tmissing\n'

  put sc1/settings.json '{\n  "cleanupPeriodDays": 30,\n  "permissions": {"allow": ["a", "b"]},\n  "n": -1.5e3\n}\n'
  check "settings: valid file runs" eval 'ts settings "$TMP/sc1" > "$TMP/sc1.out"'
  check "settings: values of the top level" file_is sc1.out \
    'file\tvalid\nkey\tautoMemoryEnabled\tmissing\nkey\tcleanupPeriodDays\t30\n'

  put sc2/settings.json '{"x": {"autoMemoryEnabled": true}, "s": "a } \\" {", "autoMemoryEnabled": false}\n'
  check "settings: nested key and braces in strings" eval 'ts settings "$TMP/sc2" > "$TMP/sc2.out"'
  check "settings: only the top-level key counts" file_is sc2.out \
    'file\tvalid\nkey\tautoMemoryEnabled\tfalse\nkey\tcleanupPeriodDays\tmissing\n'

  put sc3/settings.json '{ "a": 1,, }\n'
  check "settings: invalid file runs" eval 'ts settings "$TMP/sc3" > "$TMP/sc3.out"'
  check "settings: invalid file reported" grep -q '^file	invalid	' "$TMP/sc3.out"
  put sc4/settings.json '["autoMemoryEnabled"]\n'
  check "settings: top-level array runs" eval 'ts settings "$TMP/sc4" > "$TMP/sc4.out"'
  check "settings: top-level array is invalid" grep -q '^file	invalid	' "$TMP/sc4.out"
  put sc5/settings.json '{"a": "\\q"}\n'
  check "settings: bad escape runs" eval 'ts settings "$TMP/sc5" > "$TMP/sc5.out"'
  check "settings: bad escape is invalid" grep -q '^file	invalid	' "$TMP/sc5.out"
  put sc6/settings.json '{"a": 1} x\n'
  check "settings: text after the object runs" eval 'ts settings "$TMP/sc6" > "$TMP/sc6.out"'
  check "settings: text after the object is invalid" grep -q '^file	invalid	' "$TMP/sc6.out"
  put sc7/settings.json '{"cleanupPeriodDays": 30, "cleanupPeriodDays": 60}\n'
  check "settings: duplicate key runs" eval 'ts settings "$TMP/sc7" > "$TMP/sc7.out"'
  check "settings: duplicate key reported" grep -q '^key	cleanupPeriodDays	duplicate$' "$TMP/sc7.out"
  refute "settings: missing folder refused" ts settings "$TMP/nope"

  # --- set-settings: write the two values -----------------------------------------
  check "set-settings: missing file runs" \
    eval 'ts set-settings "$TMP/sc0" "$TMP/so0" autoMemoryEnabled=false cleanupPeriodDays=365 > "$TMP/so0.out"'
  check "set-settings: missing file gets an object" file_is so0/settings.json \
    '{\n  "autoMemoryEnabled": false,\n  "cleanupPeriodDays": 365\n}\n'
  check "set-settings: listing" file_is so0.out \
    'set\tautoMemoryEnabled\tadded\nset\tcleanupPeriodDays\tadded\nwritten\tsettings.json\n'

  check "set-settings: existing file runs" \
    eval 'ts set-settings "$TMP/sc1" "$TMP/so1" autoMemoryEnabled=false cleanupPeriodDays=365 > "$TMP/so1.out"'
  check "set-settings: replaced in place, added with the indentation" file_is so1/settings.json \
    '{\n  "autoMemoryEnabled": false,\n  "cleanupPeriodDays": 365,\n  "permissions": {"allow": ["a", "b"]},\n  "n": -1.5e3\n}\n'
  check "set-settings: replaced and added listed" file_is so1.out \
    'set\tautoMemoryEnabled\tadded\nset\tcleanupPeriodDays\treplaced\nwritten\tsettings.json\n'
  check "set-settings: the source stays" file_is sc1/settings.json \
    '{\n  "cleanupPeriodDays": 30,\n  "permissions": {"allow": ["a", "b"]},\n  "n": -1.5e3\n}\n'

  put sc8/settings.json '{"a": 1}\n'
  check "set-settings: one-line object runs" \
    eval 'ts set-settings "$TMP/sc8" "$TMP/so8" autoMemoryEnabled=false > /dev/null'
  check "set-settings: one-line object stays on one line" file_is so8/settings.json \
    '{"autoMemoryEnabled": false, "a": 1}\n'
  put sc9/settings.json '{}\n'
  check "set-settings: empty object runs" \
    eval 'ts set-settings "$TMP/sc9" "$TMP/so9" cleanupPeriodDays=400 > /dev/null'
  check "set-settings: empty object gets lines" file_is so9/settings.json \
    '{\n  "cleanupPeriodDays": 400\n}\n'
  put sc10/settings.json '{\n\t"a": 1\n}\n'
  check "set-settings: tab indentation runs" \
    eval 'ts set-settings "$TMP/sc10" "$TMP/so10" autoMemoryEnabled=false > /dev/null'
  check "set-settings: tab indentation kept" file_is so10/settings.json \
    '{\n\t"autoMemoryEnabled": false,\n\t"a": 1\n}\n'
  put sc11/settings.json '{\n  "autoMemoryEnabled": true\n}\n'
  check "set-settings: only key replaced runs" \
    eval 'ts set-settings "$TMP/sc11" "$TMP/so11" autoMemoryEnabled=false > /dev/null'
  check "set-settings: only key replaced" file_is so11/settings.json \
    '{\n  "autoMemoryEnabled": false\n}\n'

  refute "set-settings: unknown key refused" ts set-settings "$TMP/sc1" "$TMP/so12" model=opus
  refute "set-settings: boolean checked" ts set-settings "$TMP/sc1" "$TMP/so13" autoMemoryEnabled=yes
  refute "set-settings: zero days refused" ts set-settings "$TMP/sc1" "$TMP/so14" cleanupPeriodDays=0
  refute "set-settings: days are a number" ts set-settings "$TMP/sc1" "$TMP/so15" cleanupPeriodDays=1y
  refute "set-settings: key given twice refused" \
    ts set-settings "$TMP/sc1" "$TMP/so16" cleanupPeriodDays=1 cleanupPeriodDays=2
  refute "set-settings: invalid file refused" ts set-settings "$TMP/sc3" "$TMP/so17" autoMemoryEnabled=false
  refute "set-settings: nothing written for an invalid file" test -e "$TMP/so17/settings.json"
  refute "set-settings: duplicate key refused" ts set-settings "$TMP/sc7" "$TMP/so18" cleanupPeriodDays=365
  refute "set-settings: into a non-empty dir refused" \
    ts set-settings "$TMP/sc1" "$TMP/so1" autoMemoryEnabled=false

  # --- memory-dir: find the auto memory folder of a project -----------------------
  mkdir -p "$TMP/mc/projects"
  git_repo mp
  mp_phys=$(cd "$TMP/mp" && pwd -P)
  mkdir -p "$TMP/mc/projects/$(folder_of "$mp_phys")/memory"
  check "memory-dir: by name runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mp" > "$TMP/md1.out"'
  check "memory-dir: folder by name" file_is md1.out \
    "name\tpresent\town\t$TMP/mc/projects/$(folder_of "$mp_phys")/memory\n"
  mkdir -p "$TMP/mp/sub"
  check "memory-dir: from a subdirectory runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mp/sub" > "$TMP/md2.out"'
  check "memory-dir: a subdirectory belongs to the repository" cmp -s "$TMP/md1.out" "$TMP/md2.out"
  git -C "$TMP/mp" worktree add -q "$TMP/mpw" 2> /dev/null
  check "memory-dir: from a worktree runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mpw" > "$TMP/md3.out"'
  check "memory-dir: a worktree shares the main folder" cmp -s "$TMP/md1.out" "$TMP/md3.out"
  # The name rule maps "my app" and "my.app" to one folder: a transcript names the other.
  # A cd during a session, or a start in the parent folder, names another path too.
  put "mc/projects/$(folder_of "$mp_phys")/s.jsonl" \
    "{\"cwd\":\"$mp_phys/sub\"}\n{\"cwd\":\"/elsewhere/tmp\"}\n{\"cwd\":\"${mp_phys%/mp}\"}\n"
  check "memory-dir: own transcripts run" eval 'ts memory-dir "$TMP/mc" "$TMP/mp" > "$TMP/md3b.out"'
  check "memory-dir: other paths keep it own" cmp -s "$TMP/md1.out" "$TMP/md3b.out"
  put "mc/projects/$(folder_of "$mp_phys")/t.jsonl" "{\"cwd\":\"${mp_phys%/mp}.mp\"}\n"
  check "memory-dir: a name twin runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mp" > "$TMP/md3c.out"'
  check "memory-dir: a name twin makes it shared" grep -q '^name	present	shared	' "$TMP/md3c.out"
  rm -f "$TMP/mc/projects/$(folder_of "$mp_phys")/t.jsonl"

  # The name rule on spaces, brackets, dots, underscores and a Windows-style name.
  git_repo 'my proj (v2)_x.y'
  check "memory-dir: odd characters run" \
    eval 'ts memory-dir "$TMP/mc" "$TMP/my proj (v2)_x.y" > "$TMP/md4.out"'
  check "memory-dir: odd characters become dashes" grep -q -- '-my-proj--v2--x-y/memory$' "$TMP/md4.out"
  check "memory-dir: without a folder: none" grep -q '^none	absent	own	' "$TMP/md4.out"
  git_repo 'C:\Users\demo'
  check "memory-dir: Windows-style name runs" \
    eval 'ts memory-dir "$TMP/mc" "$TMP/C:\\Users\\demo" > "$TMP/md5.out"'
  check "memory-dir: colon and backslash become dashes" grep -q -- '-C--Users-demo/memory$' "$TMP/md5.out"

  # A transcript names the path when the name differs (umlauts, another path form).
  git_repo mt
  mt_phys=$(cd "$TMP/mt" && pwd -P)
  put mc/projects/other-name/session.jsonl "{\"type\":\"user\",\"cwd\":\"$mt_phys/src\"}\n"
  check "memory-dir: by transcript runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md6.out"'
  check "memory-dir: folder by transcript" file_is md6.out \
    "transcript\tabsent\town\t$TMP/mc/projects/other-name/memory\n"
  put mc/projects/third/a.jsonl "{\"cwd\":\"$mt_phys\"}\n"
  check "memory-dir: two transcripts run" eval 'ts memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md7.out"'
  check "memory-dir: two folders listed" test "$(grep -c '^transcript' "$TMP/md7.out")" -eq 2
  put mc/projects/fourth/b.jsonl "{\"cwd\":\"$mt_phys-other\"}\n"
  check "memory-dir: with a longer path runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md7b.out"'
  check "memory-dir: a longer path is no match" eval '! grep -q fourth "$TMP/md7b.out"'
  check "memory-dir: still the two folders" test "$(grep -c '^transcript' "$TMP/md7b.out")" -eq 2
  put mc/projects/-elsewhere-mt/d.jsonl "{\"cwd\":\"$mt_phys\"}\n{\"cwd\":\"/elsewhere/mt\"}\n"
  check "memory-dir: a twin transcript runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md7c.out"'
  check "memory-dir: the twin's folder is shared" \
    grep -q "^transcript	absent	shared	$TMP/mc/projects/-elsewhere-mt/memory\$" "$TMP/md7c.out"
  check "memory-dir: the other folders stay own" \
    test "$(grep -c '^transcript	absent	own	' "$TMP/md7c.out")" -eq 2

  # autoMemoryDirectory: local before project before user; ~/ follows HOME.
  put mp/.claude/settings.json '{"autoMemoryDirectory": "~/mem-project"}\n'
  check "memory-dir: project setting runs" \
    eval 'ts_env HOME="$TMP/userhome" memory-dir "$TMP/mc" "$TMP/mp" > "$TMP/md8.out"'
  check "memory-dir: project setting, ~/ expanded" file_is md8.out \
    "setting\tabsent\town\t$TMP/userhome/mem-project\n"
  put mp/.claude/settings.local.json '{"autoMemoryDirectory": "/abs/mem-local"}\n'
  check "memory-dir: local setting runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mp" > "$TMP/md9.out"'
  check "memory-dir: local setting wins" file_is md9.out "setting\tabsent\town\t/abs/mem-local\n"
  put mc/settings.json '{"autoMemoryDirectory": "/abs/mem-all"}\n'
  check "memory-dir: user setting runs" eval 'ts memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md10.out"'
  check "memory-dir: user setting is shared" file_is md10.out "setting\tabsent\tshared\t/abs/mem-all\n"
  put mt/.claude/settings.json '{"autoMemoryDirectory": "relative/path"'
  check "memory-dir: invalid project settings run" \
    eval 'ts memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md11.out" 2> "$TMP/md11.err"'
  check "memory-dir: invalid project settings skipped" grep -q 'not valid JSON' "$TMP/md11.err"
  check "memory-dir: then the user setting" file_is md11.out "setting\tabsent\tshared\t/abs/mem-all\n"
  put mt/.claude/settings.json '{"autoMemoryDirectory": "relative/path"}\n'
  check "memory-dir: relative setting runs" \
    eval 'ts memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md12.out" 2> "$TMP/md12.err"'
  check "memory-dir: relative setting skipped with a note" grep -q 'no absolute' "$TMP/md12.err"
  rm -f "$TMP/mc/settings.json"

  # A folder name of one's own for every project: shared.
  check "memory-dir: env name runs" \
    eval 'ts_env CLAUDE_CODE_PROJECT_DIR_NAME=all memory-dir "$TMP/mc" "$TMP/mt" > "$TMP/md13.out" 2> /dev/null'
  check "memory-dir: env name is shared" file_is md13.out \
    "env\tabsent\tshared\t$TMP/mc/projects/all/memory\n"
  refute "memory-dir: missing project refused" ts memory-dir "$TMP/mc" "$TMP/nope"
}
