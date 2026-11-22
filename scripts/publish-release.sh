#!/bin/sh
# Publishes the GitHub release of one tag vX.Y.Z, the same way for the release workflow
# (.github/workflows/release.yml) and by hand (`just publish-release vX.Y.Z`). Run it in
# the repo, with the tags fetched and gh logged in (in the workflow: GH_TOKEN).
#
#   sh scripts/publish-release.sh vX.Y.Z
#
# 1. The tag must be named vX.Y.Z and exist.
# 2. If its release exists already, it says so and stops: an existing release is never
#    changed.
# 3. The text is the version's section from the CHANGELOG of the tagged commit, not of
#    the working tree (scripts/release-notes.sh); a missing or undated version stops it.
# 4. The release is "Latest" only when the tag is the highest version among all vX.Y.Z
#    tags, so a later patch on an older line is not.
# 5. gh release create without a title of its own: GitHub shows the tag name.
#
# Exit code: 0 when the release was created or exists already; 1 when the tag is
# missing, its CHANGELOG has no dated section for it or gh fails; 2 for wrong arguments
# or a name that is not vX.Y.Z.

set -u

usage() {
  printf 'usage: sh scripts/publish-release.sh vX.Y.Z\n' >&2
  exit 2
}

fail() {
  printf 'publish-release: %s\n' "$1" >&2
  exit 1
}

[ $# -eq 1 ] || usage
tag=$1

# Only digits and dots after the v, on one line: the name goes into git and gh calls.
if ! printf '%s\n' "$tag" | awk '!/^v[0-9]+\.[0-9]+\.[0-9]+$/ { bad = 1 } END { exit bad || NR != 1 }'; then
  printf 'publish-release: not a tag vX.Y.Z: %s\n' "$tag" >&2
  exit 2
fi
version=${tag#v}

git rev-parse --verify --quiet "refs/tags/$tag^{commit}" > /dev/null || fail "no tag $tag"

if gh release view "$tag" > /dev/null 2>&1; then
  printf 'publish-release: %s skipped, the release exists already\n' "$tag"
  exit 0
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/publish-release.XXXXXX") ||
  fail "cannot create a temporary directory"
trap 'rm -rf "${tmp:?}"' EXIT

git show "$tag:plugins/coding-kit/CHANGELOG.md" > "$tmp/CHANGELOG.md" 2> /dev/null ||
  fail "$tag has no plugins/coding-kit/CHANGELOG.md"
# release-notes.sh names the reason when the version is no release.
sh "$(dirname "$0")/release-notes.sh" "$version" "$tmp/CHANGELOG.md" > "$tmp/notes.md" ||
  exit 1

highest=$(git tag -l 'v*' |
  awk '/^v[0-9]+\.[0-9]+\.[0-9]+$/ { print substr($0, 2) }' |
  sort -t . -k 1,1n -k 2,2n -k 3,3n |
  tail -n 1)
if [ "$version" = "$highest" ]; then
  latest=true
else
  latest=false
fi

gh release create "$tag" --verify-tag --notes-file "$tmp/notes.md" --latest="$latest" ||
  fail "gh release create $tag failed"
printf 'publish-release: %s published (latest: %s)\n' "$tag" "$latest"
