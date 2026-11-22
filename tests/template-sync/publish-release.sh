# Publish release cases for tests/template-sync/run.sh — sourced, uses its helpers (tgit
# and put from sync.sh). They test the kit script scripts/publish-release.sh in a
# throwaway repo with tags, each commit with a CHANGELOG of its own, and a fake gh on
# PATH: it logs every call, keeps the notes it is given and knows the releases listed in
# $PR_RELEASES.

PR=$ROOT/scripts/publish-release.sh

# pr_run NAME ARG… — runs the script in the repo; stdout in $TMP/NAME.out, stderr in
# $TMP/NAME.err, gh calls in $TMP/NAME.gh, the notes gh got in $TMP/NAME.notes.
pr_run() {
  pr_name=$1
  shift
  : > "$TMP/$pr_name.gh"
  (cd "$TMP/pr" && PATH=$TMP/pr-bin:$PATH PR_LOG=$TMP/$pr_name.gh \
    PR_NOTES=$TMP/$pr_name.notes PR_RELEASES=$TMP/pr-releases \
    $SH "$PR" "$@") > "$TMP/$pr_name.out" 2> "$TMP/$pr_name.err"
}

# pr_fails NAME CODE ARG… — the script ends with CODE and a message on stderr, and gh
# release create was never called.
pr_fails() {
  pf_name=$1 pf_code=$2
  shift 2
  pr_run "$pf_name" "$@"
  pf_status=$?
  [ "$pf_status" -eq "$pf_code" ] && [ -s "$TMP/$pf_name.err" ] &&
    ! grep -q '^release create' "$TMP/$pf_name.gh"
}

# pr_created NAME TAG LATEST — gh release create was called once, for TAG, with
# --verify-tag and --latest=LATEST, and without a title.
pr_created() {
  [ "$(grep -c '^release create' "$TMP/$1.gh")" -eq 1 ] &&
    grep -qx "release create $2 --verify-tag --notes-file .* --latest=$3" "$TMP/$1.gh" &&
    ! grep -q -- '--title' "$TMP/$1.gh"
}

pr_tag() {  # COMMIT-MESSAGE TAG CHANGELOG-TEXT — commit a CHANGELOG and tag it
  put pr/plugins/coding-kit/CHANGELOG.md "$3"
  tgit "$TMP/pr" add plugins/coding-kit/CHANGELOG.md
  tgit "$TMP/pr" commit -q -m "$1"
  tgit "$TMP/pr" -c tag.gpgSign=false tag "$2"
}

run_publish_release_cases() {
  # The fake gh.
  mkdir -p "$TMP/pr-bin"
  cat > "$TMP/pr-bin/gh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$PR_LOG"
case "$1 $2" in
  "release view")
    grep -qxF -- "$3" "$PR_RELEASES" ;;
  "release create")
    while [ $# -gt 0 ]; do
      if [ "$1" = --notes-file ]; then cp "$2" "$PR_NOTES"; fi
      shift
    done ;;
  *)
    exit 3 ;;
esac
EOF
  chmod +x "$TMP/pr-bin/gh"
  printf '%s\n' v1.0.0 > "$TMP/pr-releases"

  # The repo: v1.0.0 released, v1.1.0 undated in its own commit, v1.2.0 dated and the
  # highest, v1.0.1 a later patch on the 1.0 line; v2.0.0-rc is no vX.Y.Z tag and
  # v0.9.0 has no section in its CHANGELOG.
  rm -rf "${TMP:?}/pr"
  mkdir -p "$TMP/pr"
  git init -q "$TMP/pr"
  pr_tag one v1.0.0 '# Changelog\n\n## 1.0.0 — 2026-01-01\n\nFirst.\n'
  pr_tag two v1.1.0 '# Changelog\n\n## 1.1.0 — unveröffentlicht\n\nSecond.\n\n## 1.0.0 — 2026-01-01\n\nFirst.\n'
  pr_tag three v1.2.0 '# Changelog\n\n## 1.2.0 — 2026-03-01\n\nThird.\n\n## 1.1.0 — 2026-02-01\n\nSecond.\n'
  tgit "$TMP/pr" -c tag.gpgSign=false tag v2.0.0-rc
  tgit "$TMP/pr" -c tag.gpgSign=false tag v0.9.0
  tgit "$TMP/pr" checkout -q v1.0.0
  pr_tag patch v1.0.1 '# Changelog\n\n## 1.0.1 — 2026-04-01\n\nPatch.\n\n## 1.0.0 — 2026-01-01\n\nFirst.\n'
  # The working tree says something else than the tagged commit of v1.2.0.
  put pr/plugins/coding-kit/CHANGELOG.md '# Changelog\n\n## 1.2.0 — 2026-03-01\n\nWorking tree.\n'
  printf '%s\n' 'Third.' > "$TMP/pr-1.2.0.expected"
  printf '%s\n' 'Patch.' > "$TMP/pr-1.0.1.expected"

  # The highest version: created, Latest, notes from the tagged commit.
  check "publish-release: creates the release of the highest tag" pr_run pr-high v1.2.0
  check "publish-release: highest tag is created as Latest without title" \
    pr_created pr-high v1.2.0 true
  check "publish-release: notes come from the tagged commit" \
    cmp -s "$TMP/pr-high.notes" "$TMP/pr-1.2.0.expected"
  check "publish-release: says it published" contains pr-high.out "v1.2.0 published"

  # A later patch on an older line: created, not Latest.
  check "publish-release: creates the release of an older line" pr_run pr-patch v1.0.1
  check "publish-release: older line is not Latest" pr_created pr-patch v1.0.1 false
  check "publish-release: notes of the patch" cmp -s "$TMP/pr-patch.notes" "$TMP/pr-1.0.1.expected"

  # An existing release: skipped, nothing created.
  check "publish-release: existing release succeeds" pr_run pr-exists v1.0.0
  check "publish-release: existing release is skipped" contains pr-exists.out "skipped"
  refute "publish-release: existing release is not created again" \
    grep -q '^release create' "$TMP/pr-exists.gh"

  # No release: undated, no section, missing tag — exit 1, nothing created.
  check "publish-release: undated version in the tagged commit fails" pr_fails pr-undated 1 v1.1.0
  check "publish-release: undated version is named so" err_mentions pr-undated "not dated"
  check "publish-release: version without section fails" pr_fails pr-nosection 1 v0.9.0
  check "publish-release: missing tag fails" pr_fails pr-notag 1 v9.9.9

  # Not vX.Y.Z, or wrong arguments — exit 2, gh never called.
  check "publish-release: rc tag is no vX.Y.Z" pr_fails pr-rc 2 v2.0.0-rc
  check "publish-release: name without v is no tag" pr_fails pr-nov 2 1.2.0
  check "publish-release: injected command is rejected" pr_fails pr-inject 2 'v1.2.0; touch pwned'
  check "publish-release: two lines are rejected" pr_fails pr-lines 2 "v1.2.0
v1.0.0"
  check "publish-release: no argument is a usage error" pr_fails pr-none 2
  check "publish-release: two arguments are a usage error" pr_fails pr-two 2 v1.2.0 v1.0.0
  refute "publish-release: a rejected name reaches no command" has pr/pwned
  refute "publish-release: a rejected name never calls gh" grep -q . "$TMP/pr-inject.gh"
}
