# Privacy lint cases for tests/template-sync/run.sh — sourced, uses its helpers. They
# test the template script scripts/privacy-lint.sh along the rule table of F-069 (R1 to
# R8). Values the kit's own validator would report as leaks (IP addresses, local paths,
# email addresses) are put together at run time, so this file holds none of them.

PL=$TEMPLATE/core/scripts/privacy-lint.sh

# Pieces of the test values.
PL_AT=@
PL_USERS=/Users
PL_HOME=/home

pl_ip() {  # A B C D → A.B.C.D
  printf '%s.%s.%s.%s' "$1" "$2" "$3" "$4"
}

# pl_put PATH LINE… — writes LINE… into $TMP/pl-files/PATH.
pl_put() {
  pp_path=$TMP/pl-files/$1
  shift
  mkdir -p "$(dirname "$pp_path")"
  printf '%s\n' "$@" > "$pp_path"
}

# pl_scan FILE… — runs the lint in $TMP/pl-files; output in $TMP/pl-out, exit code in
# PL_RC.
pl_scan() {
  (cd "$TMP/pl-files" && $SH "$PL" "$@") > "$TMP/pl-out" 2>&1
  PL_RC=$?
}

# pl_finds FILE VALUE — scanning FILE fails and names VALUE.
pl_finds() {
  pl_scan "$1"
  [ "$PL_RC" = 1 ] && grep -qF -- " leaked — $2" "$TMP/pl-out"
}

# pl_clean FILE… — scanning FILE… passes without a finding.
pl_clean() {
  pl_scan "$@"
  [ "$PL_RC" = 0 ] && [ ! -s "$TMP/pl-out" ]
}

# pl_bad_line LINE — with LINE as line 2 of privacy-allowlist.txt, scanning a clean file
# fails and names that line.
pl_bad_line() {
  pl_put privacy-allowlist.txt '# project allowlist' "$1"
  pl_put clean.md 'nothing to report'
  pl_scan clean.md
  [ "$PL_RC" = 1 ] && grep -q '^privacy-allowlist.txt:2: invalid allow line' "$TMP/pl-out"
}

# pl_count FILE VALUE N — scanning FILE names VALUE exactly N times.
pl_count() {
  pl_scan "$1"
  [ "$(grep -cF -- " leaked — $2" "$TMP/pl-out")" = "$3" ]
}

run_privacy_cases() {
  mkdir -p "$TMP/pl-files"
  pl_mail=jane.roe${PL_AT}mailbox.org
  pl_host=$(pl_ip 10 1 2 3)
  pl_version=$(pl_ip 7 1 3 4)

  # R1 — every file it gets is scanned, also below private/.
  pl_put private/README.md "Notes: $pl_mail"
  check "privacy R1: a staged private/README.md is scanned" pl_finds private/README.md "$pl_mail"
  pl_put abs/private/tmp/x.md "$pl_mail"
  check "privacy R1: a file below /private/ given by its absolute path is scanned" \
    pl_finds "$TMP/pl-files/abs/private/tmp/x.md" "$pl_mail"
  check "privacy R1: the template's private/README.md passes" \
    pl_clean "$TEMPLATE/core/private/README.md"
  pl_put mise.lock '[tools.x]' "maintainer = \"$pl_mail\"" "path = \"$PL_HOME/jane/.local\""
  check "privacy R1: mise.lock is scanned for emails" pl_finds mise.lock "$pl_mail"
  check "privacy R3: a local path in mise.lock is found" pl_finds mise.lock "$PL_HOME/jane"
  check "privacy R3: the kit's own mise.lock passes" pl_clean "$ROOT/mise.lock"

  # R2 — four numbers of at most 255, nothing digit-like next to them.
  pl_put r2-found.md "host $pl_host, port $pl_host:8080 and at the end $pl_host."
  check "privacy R2: an address in text, with a port and at a sentence end" \
    pl_count r2-found.md "$pl_host" 3
  pl_put r2-clean.md "dated 2024.1.1.1, five parts $(pl_ip 1 2 3 4).5," \
    "pinned 2.31.0.20240406, too big $(pl_ip 1 2 3 256)"
  check "privacy R2: date versions, five parts, long and too big numbers pass" pl_clean r2-clean.md

  # R3 — in lock files and pin lists an address counts only as the host of a URL.
  pl_put uv.lock "url = \"https://$(pl_ip 10 9 8 7)/simple\"" \
    "source = \"git${PL_AT}$(pl_ip 10 9 8 6):repo\"" "version = \"$pl_version\""
  check "privacy R3: a URL host in a lock file is found" pl_finds uv.lock "$(pl_ip 10 9 8 7)"
  check "privacy R3: a host after @ in a lock file is found" pl_finds uv.lock "$(pl_ip 10 9 8 6)"
  check "privacy R3: a version in a lock file is not" eval '! grep -qF -- "$pl_version" "$TMP/pl-out"'
  pl_put Gemfile.lock "    rails ($pl_version)"
  check "privacy R3: Gemfile.lock versions pass" pl_clean Gemfile.lock
  pl_put requirements.txt "opencv-python==$(pl_ip 4 10 0 84)"
  check "privacy R3: requirements.txt pins pass" pl_clean requirements.txt
  pl_put notes.md "upgrade rails to $pl_version"
  check "privacy R3: the same version outside a lock file is found" pl_finds notes.md "$pl_version"

  # R4 — a number after § is a section number.
  pl_put r4.md "see § $(pl_ip 4 1 2 3) and §$(pl_ip 4 1 2 3) of the RFC"
  check "privacy R4: section numbers pass" pl_clean r4.md

  # R5 — four numbers right after a product name with a slash are a version.
  pl_put r5-clean.ts \
    "ua = \"Mozilla/5.0 (X11) AppleWebKit/537.36 Chrome/$(pl_ip 131 0 0 0) Safari/537.36\"" \
    "edge = \"Edg/$(pl_ip 131 0 0 0)\""
  check "privacy R5: browser versions pass" pl_clean r5-clean.ts
  pl_put r5-found.md "/srv/$(pl_ip 10 1 2 4) and example.com/$(pl_ip 10 1 2 5)"
  check "privacy R5: an address in a path is found" pl_finds r5-found.md "$(pl_ip 10 1 2 4)"
  check "privacy R5: an address in a URL path is found" pl_finds r5-found.md "$(pl_ip 10 1 2 5)"

  # R6 — a path counts when nothing word-like stands before its first slash.
  pl_put r6-found.md "at $PL_USERS/jane, C:$PL_USERS/bob, \"$PL_HOME/eve/x\"," \
    "on a disk /Volumes/Data$PL_USERS/joe"
  check "privacy R6: a path in text is found and named" pl_finds r6-found.md "$PL_USERS/jane"
  check "privacy R6: a Windows path with a slash is found" pl_finds r6-found.md "$PL_USERS/bob"
  check "privacy R6: a quoted path is found" pl_finds r6-found.md "$PL_HOME/eve"
  check "privacy R6: a deeper path is found" pl_finds r6-found.md "$PL_USERS/joe"
  pl_put r6-clean.md "Columns: Name$PL_USERS/Groups" "relative: src$PL_HOME/x"
  check "privacy R6: a word list and a relative path pass" pl_clean r6-clean.md

  # R7 — reserved example domains pass, look-alikes do not.
  pl_put r7-found.md "jane${PL_AT}example.co and jane${PL_AT}example.com.evil.de"
  check "privacy R7: a look-alike domain is found" pl_finds r7-found.md "jane${PL_AT}example.co"
  check "privacy R7: example.com inside a longer domain is found" \
    pl_finds r7-found.md "jane${PL_AT}example.com.evil.de"
  pl_put r7-clean.md "admin${PL_AT}mail.example.com jane${PL_AT}x.example jane${PL_AT}example.net" \
    "jane${PL_AT}ci.test jane${PL_AT}host.invalid jane${PL_AT}box.localhost JANE${PL_AT}EXAMPLE.ORG" \
    "1+octo${PL_AT}users.noreply.github.com noreply${PL_AT}anthropic.com" \
    "$(pl_ip 192 0 2 7) $(pl_ip 198 51 100 7) $(pl_ip 203 0 113 7) $(pl_ip 127 0 0 1)"
  check "privacy R7: documentation domains and addresses pass" pl_clean r7-clean.md

  # Files the lint cannot misread: names awk would take as an assignment, spaces, binary.
  pl_put 'a=b.md' "$pl_mail"
  check "privacy: a file name with = is scanned" pl_finds 'a=b.md' "$pl_mail"
  pl_put 'with space.md' "$pl_mail"
  check "privacy: a file name with a space is scanned" pl_finds 'with space.md' "$pl_mail"
  pl_put '-dash.md' "$pl_mail"
  check "privacy: a file name that starts with - is scanned" pl_finds '-dash.md' "$pl_mail"
  printf 'x\000%s\n' "$pl_mail" > "$TMP/pl-files/binary.bin"
  : > "$TMP/pl-files/empty.md"
  check "privacy: binary, empty and missing files are skipped" \
    pl_clean binary.bin empty.md missing.md
  check "privacy: no file, no finding" pl_clean

  # The blocklist still applies; it lives in the working folder.
  pl_put private/blocklist.txt '# private names' 'Codename Falcon' '-inner-name'
  pl_put bl.md 'the codename falcon release' 'host -inner-name'
  check "privacy: a blocklisted term is found" pl_finds bl.md 'Codename Falcon'
  check "privacy: a blocklisted term that starts with - is found" pl_finds bl.md '-inner-name'
  rm "$TMP/pl-files/private/blocklist.txt"

  # Fail closed: a file that cannot be scanned blocks the commit.
  mkdir -p "$TMP/pl-noawk"
  printf '#!/bin/sh\nexit 2\n' > "$TMP/pl-noawk/awk"
  chmod +x "$TMP/pl-noawk/awk"
  check "privacy: a file awk cannot scan is a finding" \
    eval '(cd "$TMP/pl-files" && PATH="$TMP/pl-noawk:$PATH" $SH "$PL" r6-clean.md) > "$TMP/pl-out" 2>&1; [ $? = 1 ] && grep -q "^r6-clean.md: could not be scanned" "$TMP/pl-out"'
  pl_put locked.md 'text'
  chmod 000 "$TMP/pl-files/locked.md"
  # Only where the file really is unreadable (not as root).
  if [ ! -r "$TMP/pl-files/locked.md" ]; then
    check "privacy: an unreadable file is a finding" \
      eval 'pl_scan locked.md; [ "$PL_RC" = 1 ] && grep -q "^locked.md: could not be scanned" "$TMP/pl-out"'
  fi
  chmod 644 "$TMP/pl-files/locked.md"

  # R8 — exact values of privacy-allowlist.txt pass in every file; a broken line blocks.
  pl_range=$(pl_ip 10 0 0 0)
  pl_put privacy-allowlist.txt '# project allowlist' '' \
    "allow $pl_range SSRF block list in the docs" \
    "allow JANE.ROE${PL_AT}MAILBOX.ORG public contact" \
    "allow $PL_HOME/user placeholder in the install guide"
  pl_put r8.md "blocked: $pl_range/8" "mail $pl_mail" "path $PL_HOME/user/project"
  check "privacy R8: allowed values pass, emails in any case" pl_clean r8.md privacy-allowlist.txt
  pl_put r8-found.md "next $(pl_ip 10 0 0 1) and $PL_HOME/eve"
  check "privacy R8: the next address of the range is still found" \
    pl_finds r8-found.md "$(pl_ip 10 0 0 1)"
  check "privacy R8: another path is still found" pl_finds r8-found.md "$PL_HOME/eve"
  check "privacy R8: a line without a reason is an error" pl_bad_line "allow $pl_range"
  check "privacy R8: a prefix length is an error" pl_bad_line "allow $pl_range/8 the whole range"
  check "privacy R8: a pattern is an error" pl_bad_line 'allow 10.* every host'
  check "privacy R8: an unknown keyword is an error" pl_bad_line 'permit something because'
  rm "$TMP/pl-files/privacy-allowlist.txt"
  check "privacy R8: without the file only the built-in values pass" pl_finds r8.md "$pl_range"
  # The lint reads a line as an entry once its first field is allow, indented or not.
  check "privacy R8: the template's allowlist frees nothing" \
    eval '! grep -Eq "^[[:space:]]*allow[[:space:]]" "$TEMPLATE/core/privacy-allowlist.txt"'

  # --all scans the tracked files only.
  mkdir -p "$TMP/pl-git/private"
  printf 'Notes: %s\n' "$pl_mail" > "$TMP/pl-git/private/README.md"
  printf 'clean\n' > "$TMP/pl-git/a.md"
  tgit "$TMP/pl-git" init -q
  tgit "$TMP/pl-git" add -A
  tgit "$TMP/pl-git" commit -q -m base
  printf 'Untracked: %s\n' "$pl_mail" > "$TMP/pl-git/untracked.md"
  check "privacy --all: a tracked private/README.md is found" \
    eval '(cd "$TMP/pl-git" && $SH "$PL" --all) > "$TMP/pl-all" 2>&1; [ $? = 1 ] && grep -q "^private/README.md:1:" "$TMP/pl-all"'
  check "privacy --all: untracked files are left out" eval '! grep -q untracked.md "$TMP/pl-all"'

  # The template itself has nothing to report. Run where no blocklist lies — the kit's
  # own private blocklist must not reach the test output.
  check "privacy: every template file passes" \
    eval '(cd "$TMP/pl-files" && find "$TEMPLATE" -type f -exec $SH "$PL" {} +) > "$TMP/pl-template" 2>&1'
}
