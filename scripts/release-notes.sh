#!/bin/sh
# Prints what a GitHub release of one version shows, taken from the plugin CHANGELOG:
# the section below the version's heading, or with --title the heading text itself
# (e.g. "3.7.0 — 2026-11-22"). The release flow that uses it is in CLAUDE.md
# (Konventionen).
#
#   sh scripts/release-notes.sh [--title] X.Y.Z [CHANGELOG]
#
# A release is a heading "## X.Y.Z — YYYY-MM-DD" above the first "## Eingefroren"
# heading: an undated version ("— unveröffentlicht") or one of the frozen series below
# is none. The section ends before the next "## " heading; blank lines at its start and
# end are dropped. CHANGELOG defaults to plugins/coding-kit/CHANGELOG.md.
#
# Exit code: 0 with the text on stdout; 1 when the version is no release or the file
# cannot be read; 2 for wrong arguments or a version that is not X.Y.Z. On an error the
# message goes to stderr and nothing to stdout.

set -u

usage() {
  printf 'usage: sh scripts/release-notes.sh [--title] X.Y.Z [CHANGELOG]\n' >&2
  exit 2
}

mode=notes
if [ "${1:-}" = --title ]; then
  mode=title
  shift
fi
[ $# -eq 1 ] || [ $# -eq 2 ] || usage
# --title only comes first; an option anywhere else is a wrong call, not a version or file.
case $1 in -*) usage ;; esac
case ${2:-} in -*) usage ;; esac

changelog=${2:-$(dirname "$0")/../plugins/coding-kit/CHANGELOG.md}
if [ ! -r "$changelog" ]; then
  printf 'release-notes: cannot read %s\n' "$changelog" >&2
  exit 1
fi

exec awk -v want="$1" -v mode="$mode" '
  function fail(code, message) {
    print "release-notes: " message | "cat 1>&2"
    status = code
    exit code
  }

  BEGIN {
    if (want !~ /^[0-9]+\.[0-9]+\.[0-9]+$/) fail(2, "not a version X.Y.Z: " want)
    # What follows the number in a dated heading.
    dated = "^ — [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$"
  }

  # The frozen series start here; nothing below is a release.
  /^## Eingefroren/ { exit }

  /^## / {
    if (found) exit
    heading = substr($0, 4)
    # The heading must start with the number itself: "13.2.0 —" and "3.2.0-rc —" are
    # not 3.2.0.
    if (heading != want && index(heading, want " ") != 1) next
    if (substr(heading, length(want) + 1) !~ dated) fail(1, want " is not dated yet: " $0)
    found = 1
    title = heading
    next
  }

  found { lines[++count] = $0 }

  END {
    if (status) exit status
    if (!found) fail(1, want " is no release in " FILENAME)
    if (mode == "title") {
      print title
      exit
    }
    first = 1
    while (first <= count && lines[first] ~ /^[ \t]*$/) first++
    last = count
    while (last >= first && lines[last] ~ /^[ \t]*$/) last--
    for (i = first; i <= last; i++) print lines[i]
  }
' "$changelog"
