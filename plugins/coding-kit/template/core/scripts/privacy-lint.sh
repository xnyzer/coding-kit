#!/bin/sh
# Privacy lint — blocks commits that would leak private identifiers.
#
# Usage:
#   sh scripts/privacy-lint.sh FILE...   scan the given files (lefthook passes staged files)
#   sh scripts/privacy-lint.sh --all     scan every tracked file (manual audit)
#
# Every file it gets is scanned, also below private/: a staged or tracked file there
# becomes public like any other. Binary and empty files are skipped. Generic patterns:
#   - Absolute local paths (/Users/…, /home/…), when no letter, digit, ".", "_" or "-"
#     stands right before the first slash of the path — "Name/Users/…" in a word list
#     is not a path.
#   - IPv4 addresses: four numbers of at most 255, with no further digit or ".digit"
#     next to them. Not after "§" (a section number), not right after a product name
#     with a slash (the four numbers after Chrome/ are a browser version) and, in lock
#     files and pin lists (see is_lock_file), only as the host of a URL — after :// or @.
#   - Email addresses.
# Allowed are documentation values: 0.0.0.0, 127.0.0.1, 255.255.255.255 and the RFC 5737
# ranges; example.com, example.net, example.org with their subdomains, the reserved
# top-level domains .example, .test, .invalid and .localhost; GitHub noreply addresses
# and anthropic.com (the Co-Authored-By trailer of commits).
# A gitignored private/blocklist.txt (one term per line, `#` starts a comment) adds
# project-private terms — when the file is absent (e.g. in CI), only the generic
# patterns run. The versioned privacy-allowlist.txt frees exact values of this project,
# one per line (`allow <value> <reason…>`, see the file); a line it cannot read is a
# finding. A file that cannot be scanned counts as a finding too (fail closed).
# Exit code: 0 clean, 1 findings. POSIX sh, grep and awk only, no other toolchain.
# Windows: run hooks from Git Bash or WSL (both ship sh, grep and awk); a plain
# cmd/PowerShell setup without Git's sh on PATH fails loudly, never silently.

set -u

BLOCKLIST='private/blocklist.txt'
ALLOWLIST='privacy-allowlist.txt'

# --all: re-invoke over every tracked file (NUL-safe for unusual file names). xargs may
# split the list and reports a failed run in its own way (GNU xargs: 123), so any
# failure becomes 1.
if [ "${1:-}" = "--all" ]; then
  if git ls-files -z | xargs -0 sh "$0"; then exit 0; fi
  exit 1
fi

[ $# -eq 0 ] && exit 0

blocklist_terms=''
if [ -f "$BLOCKLIST" ]; then
  blocklist_terms=$(sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    "$BLOCKLIST" | grep -v '^$' || true)
fi

# privacy-allowlist.txt → "value <v>" for each allowed value (emails in lower case) and
# "error <finding>" for each line it cannot read. A value must be exactly what the lint
# reports — one IP address, email address or local path — so ranges, prefix lengths and
# patterns are refused.
read_allowlist() {
  LC_ALL=C awk -v list="$ALLOWLIST" '
    function bad(msg) {
      printf "error %s:%d: invalid allow line — %s\n", list, FNR, msg
    }
    function is_ip(v,    n, part, i) {
      if (v !~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) return 0
      n = split(v, part, ".")
      for (i = 1; i <= n; i++) {
        if (length(part[i]) > 3 || part[i] + 0 > 255) return 0
      }
      return 1
    }
    { sub(/\r$/, "") }
    /^[ \t]*(#|$)/ { next }
    $1 != "allow" { bad("unknown keyword " $1 " (use: allow <value> <reason>)"); next }
    NF < 3 { bad("allow needs a value and a reason"); next }
    {
      if (is_ip($2) || $2 ~ /^\/(Users|home)\/[A-Za-z0-9_.-]+$/) {
        print "value " $2
      } else if ($2 ~ /^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z][A-Za-z]+$/) {
        print "value " tolower($2)
      } else {
        bad($2 " is no single IP address, email address or local path")
      }
    }' "$ALLOWLIST"
}

allowed=''
allow_errors=''
if [ -f "$ALLOWLIST" ]; then
  parsed=$(read_allowlist) || parsed="error $ALLOWLIST: could not be read"
  allowed=$(printf '%s\n' "$parsed" | sed -n 's/^value //p')
  allow_errors=$(printf '%s\n' "$parsed" | sed -n 's/^error //p')
fi

# Lock files and pin lists, by name: their four-part versions look like IP addresses,
# so an IP counts there only as the host of a URL.
is_lock_file() {  # FILE
  case ${1##*/} in
    *.lock | *-lock.json | *-lock.yaml | *.lockfile | packages.lock.json | \
      npm-shrinkwrap.json | go.sum | Package.resolved | requirements*.txt | \
      constraints*.txt)
      return 0 ;;
  esac
  return 1
}

# Paths, IPs and emails in FILE (read from stdin) → one finding per line, except values
# of the allowlist. The file name comes through the environment: awk would treat an
# operand like a=b as an assignment.
scan_patterns() {  # FILE LOCK (1 for a lock file or pin list, else 0)
  PL_FILE=$1 PL_ALLOWED=$allowed LC_ALL=C awk -v lock="$2" -v sq="'" '
    BEGIN {
      file = ENVIRON["PL_FILE"]
      n = split(ENVIRON["PL_ALLOWED"], list, "\n")
      for (i = 1; i <= n; i++) {
        if (list[i] != "") allowed[list[i]] = 1
      }
      # Characters that may stand before a product name such as Chrome/.
      openers = " \t([{\"`" sq
    }

    function report(kind, value,    key) {
      key = (kind == "email address") ? tolower(value) : value
      if (key in allowed) return
      printf "%s:%d: %s leaked — %s\n", file, FNR, kind, value
    }

    # The character at position I of S, empty outside it.
    function char_at(s, i) {
      return (i < 1) ? "" : substr(s, i, 1)
    }

    # Absolute local path: walk back from /Users/ or /home/ over the characters of the
    # path to its first slash; a letter, digit, ".", "_" or "-" before that slash means
    # a word list or a relative path.
    function scan_paths(line,    rest, off, start, k, first) {
      rest = line
      off = 0
      while (match(rest, /\/(Users|home)\/[A-Za-z0-9_.-]+/)) {
        start = off + RSTART
        first = start
        for (k = start - 1; k >= 1 && char_at(line, k) ~ /[A-Za-z0-9._~\/-]/; k--) {
          if (char_at(line, k) == "/") first = k
        }
        if (char_at(line, first - 1) !~ /[A-Za-z0-9._-]/) {
          report("absolute local path", substr(rest, RSTART, RLENGTH))
        }
        off += RSTART + RLENGTH - 1
        rest = substr(rest, RSTART + RLENGTH)
      }
    }

    function allowed_ip(ip) {
      return ip ~ /^(0\.0\.0\.0|127\.0\.0\.1|255\.255\.255\.255)$/ ||
        ip ~ /^(192\.0\.2|198\.51\.100|203\.0\.113)\.[0-9]+$/
    }

    # Whether the four numbers CAND, from START to before END in LINE, are an IP address.
    function is_ip(line, cand, start, end,    n, part, i, before) {
      n = split(cand, part, ".")
      for (i = 1; i <= n; i++) {
        if (length(part[i]) > 3 || part[i] + 0 > 255) return 0
      }
      if (char_at(line, start - 1) == "." && char_at(line, start - 2) ~ /[0-9]/) return 0
      if (char_at(line, end) == "." && char_at(line, end + 1) ~ /[0-9]/) return 0
      if (allowed_ip(cand)) return 0
      before = substr(line, 1, start - 1)
      if (lock) return before ~ /(:\/\/|@)$/
      if (before ~ /§[ \t]*$/) return 0
      if (match(before, /[A-Za-z][A-Za-z0-9_-]*\/$/)) {
        if (RSTART == 1 || index(openers, char_at(before, RSTART - 1)) > 0) return 0
      }
      return 1
    }

    function scan_ips(line,    rest, off, at, len, start, cand) {
      rest = line
      off = 0
      while (match(rest, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
        # Kept apart: is_ip calls match() itself, which resets RSTART and RLENGTH.
        at = RSTART
        len = RLENGTH
        start = off + at
        cand = substr(rest, at, len)
        if (is_ip(line, cand, start, start + len)) report("IP address", cand)
        off += at + len - 1
        rest = substr(rest, at + len)
      }
    }

    function allowed_mail(mail) {
      mail = tolower(mail)
      return mail ~ /@(users\.noreply\.github\.com|anthropic\.com)$/ ||
        mail ~ /[@.]example\.(com|net|org)$/ ||
        mail ~ /\.(example|test|invalid|localhost)$/
    }

    function scan_emails(line,    rest, mail) {
      rest = line
      while (match(rest, /[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z][A-Za-z]+/)) {
        mail = substr(rest, RSTART, RLENGTH)
        if (!allowed_mail(mail)) report("email address", mail)
        rest = substr(rest, RSTART + RLENGTH)
      }
    }

    {
      sub(/\r$/, "")
      scan_paths($0)
      scan_ips($0)
      scan_emails($0)
    }'
}

# The findings for FILE…, one per line. A file that cannot be scanned gets a line too, so
# the commit stays blocked. `-e` and `--` keep a file name or term that starts with "-"
# from being read as an option.
scan() {
  for f in "$@"; do
    [ -f "$f" ] || continue
    # Binary and empty files have no text line (grep: 1); 2 is an error.
    grep -qI -e . -- "$f" 2>/dev/null
    case $? in
      0) ;;
      1) continue ;;
      *)
        printf '%s: could not be scanned\n' "$f"
        continue
        ;;
    esac

    if is_lock_file "$f"; then lock=1; else lock=0; fi
    scan_patterns "$f" "$lock" < "$f" || printf '%s: could not be scanned\n' "$f"

    [ -n "$blocklist_terms" ] || continue
    printf '%s\n' "$blocklist_terms" | while IFS= read -r term; do
      hits=$(grep -inF -e "$term" -- "$f" 2>/dev/null)
      case $? in
        0)
          printf '%s\n' "$hits" | cut -d: -f1 | while read -r ln; do
            printf '%s:%s: blocklisted term leaked — %s\n' "$f" "$ln" "$term"
          done
          ;;
        1) ;;
        *) printf '%s: could not be scanned for blocklisted terms\n' "$f" ;;
      esac
    done
  done
}

findings=$(
  if [ -n "$allow_errors" ]; then printf '%s\n' "$allow_errors"; fi
  scan "$@"
)
if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  printf 'privacy-lint: %s finding(s) — fix or move to private/ before committing\n' \
    "$(printf '%s\n' "$findings" | wc -l | tr -d ' ')" >&2
  exit 1
fi
exit 0
