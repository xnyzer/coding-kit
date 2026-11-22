# Release notes cases for tests/template-sync/run.sh — sourced, uses its helpers.
# They test the kit script scripts/release-notes.sh against a small CHANGELOG of their
# own, and once against the plugin CHANGELOG.

RN=$ROOT/scripts/release-notes.sh

# rn_run NAME ARG… — runs the script; stdout in $TMP/NAME.out, stderr in $TMP/NAME.err,
# succeeds when the script does.
rn_run() {
  rn_name=$1
  shift
  $SH "$RN" "$@" > "$TMP/$rn_name.out" 2> "$TMP/$rn_name.err"
}

# rn_fails NAME CODE ARG… — the script ends with CODE, prints nothing on stdout and a
# message on stderr.
rn_fails() {
  rf_name=$1 rf_code=$2
  shift 2
  rn_run "$rf_name" "$@"
  rf_status=$?
  [ "$rf_status" -eq "$rf_code" ] && [ ! -s "$TMP/$rf_name.out" ] && [ -s "$TMP/$rf_name.err" ]
}

# rn_prints NAME EXPECTED-FILE — the output of run NAME is exactly that file.
rn_prints() { cmp -s "$TMP/$1.out" "$2"; }

run_release_notes_cases() {
  rn_log=$TMP/rn-changelog.md
  printf '%s\n' '# Changelog' '' 'Head paragraph, never printed.' '' \
    '## 13.2.0 — 2026-02-01' '' 'Thirteen.' '' \
    '## 3.2.0-rc — 2026-01-20' '' 'Candidate.' '' \
    '## 4.0.0 — unveröffentlicht' '' 'Not yet.' '' \
    '## 3.2.0 — 2026-01-15' '' '' 'Body line one.' '' '### Template' '' '- item' '' '' \
    '## 3.1.0 — 2026-01-01' '' 'Last before frozen.' '' \
    '## Eingefroren: old series' '' \
    '## 0.5.0 — 2025-01-01' '' 'Frozen.' > "$rn_log"
  printf '%s\n' 'Body line one.' '' '### Template' '' '- item' > "$TMP/rn-3.2.0.expected"
  printf '%s\n' 'Last before frozen.' > "$TMP/rn-3.1.0.expected"
  printf '%s\n' 'Thirteen.' > "$TMP/rn-13.2.0.expected"

  # A dated version: its section without heading and outer blank lines.
  check "release-notes: prints a dated section" rn_run rn-notes 3.2.0 "$rn_log"
  check "release-notes: section without heading and outer blank lines" \
    rn_prints rn-notes "$TMP/rn-3.2.0.expected"

  # The last release before the frozen series ends there; similar numbers stay apart.
  check "release-notes: last section before the frozen series" rn_run rn-last 3.1.0 "$rn_log"
  check "release-notes: last section ends before the frozen series" \
    rn_prints rn-last "$TMP/rn-3.1.0.expected"
  check "release-notes: 13.2.0 is its own version" rn_run rn-13 13.2.0 "$rn_log"
  check "release-notes: 13.2.0 prints only its section" rn_prints rn-13 "$TMP/rn-13.2.0.expected"

  # No release: undated, frozen, missing — exit 1, nothing on stdout.
  check "release-notes: undated version fails" rn_fails rn-undated 1 4.0.0 "$rn_log"
  check "release-notes: undated version is named so" err_mentions rn-undated "not dated"
  check "release-notes: frozen version fails" rn_fails rn-frozen 1 0.5.0 "$rn_log"
  check "release-notes: missing version fails" rn_fails rn-missing 1 9.9.9 "$rn_log"
  check "release-notes: unreadable file fails" rn_fails rn-nofile 1 3.2.0 "$TMP/rn-none.md"

  # Not X.Y.Z, or wrong arguments — exit 2, nothing on stdout.
  check "release-notes: rc suffix is no version" rn_fails rn-rc 2 3.2.0-rc "$rn_log"
  check "release-notes: x instead of dots is no version" rn_fails rn-x 2 3x2x0 "$rn_log"
  check "release-notes: two parts are no version" rn_fails rn-short 2 3.2 "$rn_log"
  check "release-notes: no argument is a usage error" rn_fails rn-none 2
  check "release-notes: three arguments are a usage error" \
    rn_fails rn-many 2 3.2.0 "$rn_log" extra
  check "release-notes: an option is a usage error" rn_fails rn-option 2 --title 3.2.0
  check "release-notes: an option after the version is a usage error" \
    rn_fails rn-late 2 3.2.0 --title

  # The plugin CHANGELOG by default: the section of 3.7.0, a released version.
  check "release-notes: reads the plugin CHANGELOG by default" rn_run rn-real 3.7.0
  check "release-notes: section of 3.7.0 from the plugin CHANGELOG" \
    contains rn-real.out "Die Startwerte im Template stehen wieder auf aktuellen Versionen"
  refute "release-notes: section of 3.7.0 stops before 3.6.0" \
    contains rn-real.out "## 3.6.0"
}
