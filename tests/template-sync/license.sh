# License check cases for tests/template-sync/run.sh — sourced, uses its helpers.
# They test the template script scripts/license-check.sh against the template's
# license-policy.txt and small policies of their own.

LC=$TEMPLATE/core/scripts/license-check.sh
LP=$TEMPLATE/core/license-policy.txt

# lc_run NAME POLICY LINE… — writes LINE… as the list $TMP/lic/NAME.tsv (a LINE is
# `package<TAB>license`), runs the script on it; output in $TMP/lic/NAME.out.
lc_run() {
  lr_name=$1 lr_policy=$2
  shift 2
  printf '%s\n' "$@" > "$TMP/lic/$lr_name.tsv"
  $SH "$LC" "$TMP/lic/$lr_name.tsv" "$lr_policy" > "$TMP/lic/$lr_name.out" 2>&1
}

# lc_says NAME TEXT — the output of NAME contains TEXT.
lc_says() { grep -qF -- "$2" "$TMP/lic/$1.out"; }

# lc_rc NAME RC POLICY LINE… — the script exits with RC.
lc_rc() {
  lx_name=$1 lx_rc=$2
  shift 2
  lc_run "$lx_name" "$@" && lx_got=0 || lx_got=$?
  [ "$lx_got" = "$lx_rc" ]
}

T='	'

run_license_cases() {
  mkdir -p "$TMP/lic"
  printf '%s\n' '# test policy' '' 'allow MIT' 'allow Apache-2.0' 'allow BSD-3-Clause' \
    'allow Zlib' 'allow Apache Software License' \
    'except special-pkg vendored copy, reviewed by legal' > "$TMP/lic/policy.txt"
  LT=$TMP/lic/policy.txt

  check "license: allowed SPDX id passes" lc_run ok "$LT" "a${T}MIT"
  check "license: summary counts the packages" lc_says ok "1 package(s) checked, 0 not allowed"
  check "license: empty list passes" lc_run empty "$LT"
  check "license: older name passes when allowed" lc_run classic "$LT" "a${T}Apache Software License"
  refute "license: GPL fails" lc_run gpl "$LT" "g${T}GPL-3.0-or-later"
  check "license: GPL finding names package and license" lc_says gpl "not allowed: g (GPL-3.0-or-later)"
  refute "license: LGPL fails" lc_run lgpl "$LT" "l${T}LGPL-2.1"
  refute "license: Unknown fails" lc_run unknown "$LT" "u${T}Unknown"
  refute "license: empty license fails" lc_run nolic "$LT" "n${T}"
  check "license: empty license is reported as such" lc_says nolic "not allowed: n (no license)"
  refute "license: list with two findings fails" lc_run many "$LT" "x${T}GPL-2.0" "y${T}MIT" "z${T}AGPL-3.0"
  check "license: first finding is reported" lc_says many "not allowed: x (GPL-2.0)"
  check "license: second finding is reported" lc_says many "not allowed: z (AGPL-3.0)"
  check "license: summary counts all findings" lc_says many "3 package(s) checked, 2 not allowed"
  check "license: OR passes with one allowed alternative" lc_run or "$LT" "o${T}MIT OR GPL-3.0-or-later"
  check "license: bracketed OR passes" lc_run or2 "$LT" "o${T}(BSD-3-Clause OR GPL-2.0)"
  refute "license: OR without an allowed alternative fails" lc_run or3 "$LT" "o${T}GPL-2.0 OR LGPL-2.1"
  check "license: AND passes when all parts are allowed" lc_run and "$LT" "p${T}(MIT AND Zlib)"
  refute "license: AND fails on one part" lc_run and2 "$LT" "p${T}MIT AND GPL-3.0"
  check "license: semicolon list passes when all are allowed" lc_run semi "$LT" "s${T}MIT; Apache Software License"
  refute "license: semicolon list fails on one part" lc_run semi2 "$LT" "s${T}MIT; GPL"
  refute "license: WITH clause fails" lc_run with "$LT" "w${T}GPL-2.0-only WITH Classpath-exception-2.0"
  refute "license: nested brackets fail even with allowed parts" lc_run nest "$LT" "n${T}(MIT OR Apache-2.0) AND BSD-3-Clause"
  check "license: exception passes any license" lc_run exc "$LT" "special-pkg${T}GPL-3.0"
  check "license: exception counts as checked" lc_says exc "1 package(s) checked, 0 not allowed"
  check "license: list line with CRLF passes" lc_run crlf "$LT" "c${T}MIT$(printf '\r')"
  check "license: missing tab exits 1" lc_rc notab 1 "$LT" "no-tab-here"
  check "license: missing tab is reported" lc_says notab "has no tab"

  printf '%s\n' 'allow MIT' 'except lonely-pkg' > "$TMP/lic/noreason.txt"
  check "license: exception without reason exits 1" lc_rc noreason 1 "$TMP/lic/noreason.txt" "a${T}MIT"
  check "license: exception without reason is reported" lc_says noreason "exception without a reason: except lonely-pkg"
  printf '%s\n' 'allow MIT' 'permit Apache-2.0' > "$TMP/lic/unknown.txt"
  check "license: unknown policy line exits 1" lc_rc unknownline 1 "$TMP/lic/unknown.txt" "a${T}MIT"
  check "license: unknown policy line is reported" lc_says unknownline "unknown line: permit Apache-2.0"
  check "license: missing policy exits 2" lc_rc nopolicy 2 "$TMP/lic/missing.txt" "a${T}MIT"
  check "license: missing list exits 2" eval '$SH "$LC" "$TMP/lic/none.tsv" "$LT" > /dev/null 2>&1; [ $? = 2 ]'
  check "license: list from standard input" eval 'printf "a\tMIT\n" | $SH "$LC" - "$LT" > /dev/null'

  check "license: template policy allows MIT" lc_run tmit "$LP" "a${T}MIT"
  check "license: template policy allows MPL-2.0" lc_run tmpl "$LP" "a${T}MPL-2.0"
  check "license: template policy allows the classic MPL name" lc_run tmpl2 "$LP" "a${T}Mozilla Public License 2.0 (MPL 2.0)"
  check "license: template policy allows a semicolon list with bracketed names" lc_run tsemi "$LP" "a${T}MIT License; Mozilla Public License 2.0 (MPL 2.0)"
  refute "license: semicolon list with a bracketed copyleft name fails" lc_run tsemi2 "$LP" "a${T}MIT License; GNU Lesser General Public License v3 (LGPLv3)"
  refute "license: template policy blocks LGPL" lc_run tlgpl "$LP" "a${T}LGPL-3.0-or-later"
  refute "license: template policy blocks GPL" lc_run tgpl "$LP" "a${T}GPL-2.0-or-later"
  refute "license: template policy blocks AGPL" lc_run tagpl "$LP" "a${T}AGPL-3.0-only"
  check "license: template policy has no exceptions" eval '! grep -q "^except" "$LP"'
}
