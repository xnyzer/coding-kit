# Zones cases (section zones of seed files, fragments in the standards slot) for
# tests/template-sync/run.sh — sourced after sync.sh, uses its fixture helpers.

# Field check on a zones line: the line for KIND/BLOCK in $TMP/NAME.tsv exists once and
# has STATE (and STAT, when given).
zone_is() {  # NAME KIND BLOCK STATE [STAT]
  awk -F'\t' -v k="$2" -v n="$3" -v s="$4" -v d="${5:-}" '
    $2 == k && $3 == n { found++; ok = ($4 == s) && (d == "" || $5 == d) }
    END { exit !(found == 1 && ok) }' "$TMP/$1.tsv"
}

no_zone() {  # NAME BLOCK
  ! cut -f3 "$TMP/$1.tsv" | grep -qxF -- "$2"
}

# Every line of $TMP/NAME.tsv has STATE.
all_zones() {  # NAME STATE
  [ -s "$TMP/$1.tsv" ] && ! cut -f4 "$TMP/$1.tsv" | grep -vqxF -- "$2"
}

# OUT holds nothing but the block files below .zones/.
only_block_files() {  # OUT
  [ -z "$(cd "$TMP/$1" && find . -type f ! -path './.zones/*')" ]
}

run_zones_cases() {
  S='<!-- module:coding-standards -->'
  E='<!-- /module:coding-standards -->'
  FMOD="<!-- fragment:mod -->\nM1\n<!-- /fragment:mod -->"
  FLANG="<!-- fragment:lang -->\nL1\n<!-- /fragment:lang -->"
  FEXTRA="<!-- fragment:extra -->\nX1\n<!-- /fragment:extra -->"
  FMINE="<!-- fragment:mine -->\nY\n<!-- /fragment:mine -->"
  FOV_P="<!-- fragment:ov -->\n<!-- override: kept -->\nO0\n<!-- /fragment:ov -->"

  # --- one project, every state ---------------------------------------------------
  put zp.seeds/DOC.md 'head\n<!-- section:alpha -->\nA1\n<!-- /section:alpha -->\n<!-- section:beta -->\nB1\n<!-- /section:beta -->\n<!-- section:gamma -->\nG1\n<!-- /section:gamma -->\n<!-- section:delta -->\nD1\n<!-- /section:delta -->\n<!-- section:eps -->\nE1\n<!-- /section:eps -->\n'
  put zp/DOC.md 'head\r\n<!-- section:alpha -->\r\nA1\r\n<!-- /section:alpha -->\r\n<!-- section:beta -->\nB0\n<!-- /section:beta -->\n<!-- section:gamma -->\n  <!-- override: ours -->\nG0\n<!-- /section:gamma -->\n<!-- section:eps -->\nE0 <!-- override: not a marker -->\n<!-- /section:eps -->\n<!-- section:extra -->\nX\n<!-- /section:extra -->\nprose about <!-- section:zeta -->\n<!-- section:eta --> in prose\ntail\n'
  put zp.seeds/STD.md "intro\n$S\n$FMOD\n\n$FLANG\n\n<!-- fragment:ov -->\nO2\n<!-- /fragment:ov -->\n\n$FEXTRA\n$E\ntail\n"
  put zp/STD.md "intro\n$S\n<!-- fragment:mod -->\nM0\n<!-- /fragment:mod -->\n\n$FOV_P\n\n$FMINE\nsee <!-- fragment:zfrag -->\n$E\ntail\nproject text\n"
  put zp.seeds/PH.md "x\n$S\n<!-- fragment:pa -->\nA\n<!-- /fragment:pa -->\n\n<!-- fragment:pb -->\nB\n<!-- /fragment:pb -->\n$E\n"
  put zp/PH.md "x\n$S\n_No fragments yet._\n$E\n"
  put zp.seeds/START.md "$S\n<!-- fragment:first -->\nF\n<!-- /fragment:first -->\n\n<!-- fragment:second -->\nS2\n<!-- /fragment:second -->\n$E\n"
  put zp/START.md "$S\n<!-- fragment:second -->\nS2\n<!-- /fragment:second -->\n$E\n"
  put zp.seeds/NOSLOT.md "$S\n<!-- fragment:ns -->\nN\n<!-- /fragment:ns -->\n$E\n"
  put zp/NOSLOT.md 'written by hand\n'
  put zp.seeds/PLAIN.md '<!-- section:solo -->\nS1\n<!-- /section:solo -->\n'
  put zp/PLAIN.md 'written by hand\n'
  put zp.seeds/GONE.md '<!-- section:gone -->\nG\n<!-- /section:gone -->\n'
  put zp.seeds/BROKEN.md '<!-- section:brk -->\nB\n<!-- /section:brk -->\n'
  put zp/BROKEN.md '<!-- section:brk -->\nB\n'
  put zp.seeds/SKIP.md '<!-- section:sk -->\nnew\n<!-- /section:sk -->\n'
  put zp/SKIP.md '<!-- section:sk -->\nold\n<!-- /section:sk -->\n'
  put zp.seeds/none.md 'no markers\n'
  registry zp '| `SKIP.md` | skip | written by hand | 2026-10-26 |'
  check "zones runs" eval 'ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zo" > "$TMP/z.tsv" 2> "$TMP/z.err"'
  check "zones: same content (CRLF) is identical" zone_is z section alpha identical -
  check "zones: different content differs" zone_is z section beta differs "+1 -1"
  check "zones: override line protects the zone" zone_is z section gamma override -
  check "zones: override text inside a line does not protect" zone_is z section eps differs
  check "zones: missing zone without a base is unconfirmed" zone_is z section delta unconfirmed "+1 -0"
  check "zones: zone only in the project is local" zone_is z section extra local
  check "zones: marker with text before it is prose" no_zone z zeta
  check "zones: marker with text behind it is prose" no_zone z eta
  check "zones: file without zone markers is unmarked" zone_is z section solo unmarked
  check "zones: project without the file" zone_is z section gone no-file
  check "zones: unclosed zone is broken" zone_is z section brk broken
  check "zones: skip row" zone_is z section sk skipped
  check "zones: fragment differs" zone_is z fragment mod differs "+1 -1"
  check "zones: fragment only in the render is new" zone_is z fragment lang new "+1 -0"
  check "zones: override fragment without base: no count" zone_is z fragment ov override -
  check "zones: fragment only in the project is local" zone_is z fragment mine local
  check "zones: fragment marker with text before it is prose" no_zone z zfrag
  check "zones: file without slot is unmarked" zone_is z fragment ns unmarked
  check "zones: lines in file order" test "$(cut -f3 "$TMP/z.tsv" | tr '\n' ' ')" = \
    "brk alpha beta gamma delta eps extra gone ns pa pb solo sk first second mod lang ov extra mine "
  check "zones: section result replaces the differing zones only" file_is zo/DOC.md \
    'head\n<!-- section:alpha -->\nA1\n<!-- /section:alpha -->\n<!-- section:beta -->\nB1\n<!-- /section:beta -->\n<!-- section:gamma -->\n  <!-- override: ours -->\nG0\n<!-- /section:gamma -->\n<!-- section:eps -->\nE1\n<!-- /section:eps -->\n<!-- section:extra -->\nX\n<!-- /section:extra -->\nprose about <!-- section:zeta -->\n<!-- section:eta --> in prose\ntail\n'
  check "zones: new fragments behind their predecessor, override and local kept" file_is zo/STD.md \
    "intro\n$S\n$FMOD\n\n$FLANG\n\n$FOV_P\n\n$FEXTRA\n\n$FMINE\nsee <!-- fragment:zfrag -->\n$E\ntail\nproject text\n"
  check "zones: new fragments replace the placeholder text" file_is zo/PH.md \
    "x\n$S\n<!-- fragment:pa -->\nA\n<!-- /fragment:pa -->\n\n<!-- fragment:pb -->\nB\n<!-- /fragment:pb -->\n$E\n"
  check "zones: new fragment without predecessor goes to the slot start" file_is zo/START.md \
    "$S\n<!-- fragment:first -->\nF\n<!-- /fragment:first -->\n\n<!-- fragment:second -->\nS2\n<!-- /fragment:second -->\n$E\n"
  refute "zones: skipped file not written" test -e "$TMP/zo/SKIP.md"
  refute "zones: file without applied blocks not written" test -e "$TMP/zo/PLAIN.md"
  refute "zones: file without markers not listed" grep -q '^none.md' "$TMP/z.tsv"
  check "zones: block files for the diff" file_is zo/.zones/section/beta.project 'B0\n'
  check "zones: block file of the template" file_is zo/.zones/section/beta.template 'B1\n'
  check "zones: block file of a new fragment" file_is zo/.zones/fragment/lang.template 'L1\n'
  check "zones: block file of a local fragment" file_is zo/.zones/fragment/mine.project 'Y\n'
  check "zones: template block of an unconfirmed zone" file_is zo/.zones/section/delta.template 'D1\n'
  refute "zones: no base file without a base" test -e "$TMP/zo/.zones/fragment/ov.base"
  refute "zones: into a non-empty dir refused" ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zo"

  # --- the base: snapshot stand-in, --base ----------------------------------------
  put zp.snap/STD.md.base "intro\n$S\n<!-- fragment:ov -->\nO1\n<!-- /fragment:ov -->\n$E\n"
  check "zones --snapshot runs" \
    eval 'ts zones --snapshot "$TMP/zp.snap" "$TMP/zp" "$TMP/zp.seeds" "$TMP/zs" > "$TMP/zs.tsv"'
  check "zones: override fragment counts the template change since the base" \
    zone_is zs fragment ov override "+1 -1"
  check "zones: base block file" file_is zs/.zones/fragment/ov.base 'O1\n'
  put zp.base/STD.md "intro\n$S\n<!-- fragment:ov -->\nO2\n<!-- /fragment:ov -->\n$E\n"
  check "zones --base runs" eval 'ts zones --base "$TMP/zp.base" "$TMP/zp" "$TMP/zp.seeds" "$TMP/zb" > "$TMP/zb.tsv"'
  check "zones: template unchanged since the base: no count" zone_is zb fragment ov override -

  # --- selection by name ------------------------------------------------------------
  check "zones with names runs" \
    eval 'ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zn" beta lang > "$TMP/zn.tsv"'
  check "zones: only the named zone applied" file_is zn/DOC.md \
    'head\n<!-- section:alpha -->\nA1\n<!-- /section:alpha -->\n<!-- section:beta -->\nB1\n<!-- /section:beta -->\n<!-- section:gamma -->\n  <!-- override: ours -->\nG0\n<!-- /section:gamma -->\n<!-- section:eps -->\nE0 <!-- override: not a marker -->\n<!-- /section:eps -->\n<!-- section:extra -->\nX\n<!-- /section:extra -->\nprose about <!-- section:zeta -->\n<!-- section:eta --> in prose\ntail\n'
  check "zones: only the named fragment inserted" file_is zn/STD.md \
    "intro\n$S\n<!-- fragment:mod -->\nM0\n<!-- /fragment:mod -->\n\n$FLANG\n\n$FOV_P\n\n$FMINE\nsee <!-- fragment:zfrag -->\n$E\ntail\nproject text\n"
  refute "zones: file without a named block not written" test -e "$TMP/zn/PH.md"
  check "zones: the report lists every block" zone_is zn section eps differs
  check "zones: an inserted predecessor anchors the next new fragment" \
    eval 'ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zn2" extra > /dev/null'
  check "zones: named fragment behind its present predecessor" file_is zn2/STD.md \
    "intro\n$S\n<!-- fragment:mod -->\nM0\n<!-- /fragment:mod -->\n\n$FOV_P\n\n$FEXTRA\n\n$FMINE\nsee <!-- fragment:zfrag -->\n$E\ntail\nproject text\n"
  refute "zones: names in one argument refused" ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zn3" "beta lang"
  refute "zones: a protected block cannot be applied" ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zn4" gamma
  refute "zones: unknown name refused" ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zn5" nope
  check "zones: a named unconfirmed zone is applied" \
    eval 'ts zones "$TMP/zp" "$TMP/zp.seeds" "$TMP/zn6" delta > /dev/null'
  check "zones: unconfirmed zone behind its predecessor" file_is zn6/DOC.md \
    'head\n<!-- section:alpha -->\nA1\n<!-- /section:alpha -->\n<!-- section:beta -->\nB0\n<!-- /section:beta -->\n<!-- section:gamma -->\n  <!-- override: ours -->\nG0\n<!-- /section:gamma -->\n\n<!-- section:delta -->\nD1\n<!-- /section:delta -->\n<!-- section:eps -->\nE0 <!-- override: not a marker -->\n<!-- /section:eps -->\n<!-- section:extra -->\nX\n<!-- /section:extra -->\nprose about <!-- section:zeta -->\n<!-- section:eta --> in prose\ntail\n'

  # --- seed bases: new, opted-out and removed zones -----------------------------------
  put zq.seeds/DOC.md 'head\n<!-- section:a -->\nA\n<!-- /section:a -->\n\n<!-- section:b -->\nB\n<!-- /section:b -->\n\n<!-- section:c -->\nC\n<!-- /section:c -->\n\n<!-- section:d -->\nD\n<!-- /section:d -->\n\n<!-- section:n2 -->\nN2\n<!-- /section:n2 -->\n\n<!-- section:ov -->\nOV2\n<!-- /section:ov -->\ntail\n'
  put zq/DOC.md 'head\n<!-- section:a -->\nA\n<!-- /section:a -->\nmine\n<!-- section:c -->\nC\n<!-- /section:c -->\n\n<!-- section:old -->\nO\n<!-- /section:old -->\n\n<!-- section:ov -->\n<!-- override: ours -->\nOV0\n<!-- /section:ov -->\n<!-- section:kept -->\n<!-- override: still ours -->\nK\n<!-- /section:kept -->\nend\n'
  put zq/.claude/template-base/DOC.md.seed '<!-- section:a -->\nA\n<!-- /section:a -->\n<!-- section:c -->\nC\n<!-- /section:c -->\n<!-- section:d -->\nD\n<!-- /section:d -->\n<!-- section:old -->\nO\n<!-- /section:old -->\n<!-- section:ov -->\nOV1\n<!-- /section:ov -->\n<!-- section:kept -->\nK0\n<!-- /section:kept -->\n'
  put zq.seeds/FIRST.md '<!-- section:f1 -->\nF1\n<!-- /section:f1 -->\n\n<!-- section:f2 -->\nF2\n<!-- /section:f2 -->\n'
  put zq/FIRST.md 'title\n<!-- section:f2 -->\nF2\n<!-- /section:f2 -->\n'
  put zq/.claude/template-base/FIRST.md.seed '<!-- section:f2 -->\nF2\n<!-- /section:f2 -->\n'
  put zq.seeds/LONE.md '<!-- section:l1 -->\nL1\n<!-- /section:l1 -->\n<!-- section:l2 -->\nL2\n<!-- /section:l2 -->\n'
  put zq/LONE.md 'text\n<!-- section:mine2 -->\nM\n<!-- /section:mine2 -->\n'
  put zq/.claude/template-base/LONE.md.seed 'no zones yet\n'
  check "zones with seed bases runs" \
    eval 'ts zones "$TMP/zq" "$TMP/zq.seeds" "$TMP/zqo" > "$TMP/zq.tsv" 2> "$TMP/zq.err"'
  check "seed base: zone in both stays identical" zone_is zq section a identical -
  check "seed base: zone missing in project and base is new" zone_is zq section b new "+1 -0"
  check "seed base: zone missing in the project only is an opt-out" zone_is zq section d opted-out -
  check "seed base: a renamed zone arrives as new" zone_is zq section n2 new "+1 -0"
  check "seed base: the old name is removed" zone_is zq section old removed "+0 -1"
  check "seed base: removed zone with an override stays local" zone_is zq section kept local -
  check "seed base: override zone counts the template change since the base" \
    zone_is zq section ov override "+1 -1"
  check "seed base: base block file of a zone" file_is zqo/.zones/section/ov.base 'OV1\n'
  check "seed base: project block of a removed zone" file_is zqo/.zones/section/old.project 'O\n'
  check "seed base: new zones behind their predecessors, removed zone gone" file_is zqo/DOC.md \
    'head\n<!-- section:a -->\nA\n<!-- /section:a -->\n\n<!-- section:b -->\nB\n<!-- /section:b -->\nmine\n<!-- section:c -->\nC\n<!-- /section:c -->\n\n<!-- section:n2 -->\nN2\n<!-- /section:n2 -->\n\n<!-- section:ov -->\n<!-- override: ours -->\nOV0\n<!-- /section:ov -->\n<!-- section:kept -->\n<!-- override: still ours -->\nK\n<!-- /section:kept -->\nend\n'
  check "seed base: new zone without predecessor before its successor" file_is zqo/FIRST.md \
    'title\n\n<!-- section:f1 -->\nF1\n<!-- /section:f1 -->\n\n<!-- section:f2 -->\nF2\n<!-- /section:f2 -->\n'
  check "seed base: new zones without neighbours at the end, in render order" file_is zqo/LONE.md \
    'text\n<!-- section:mine2 -->\nM\n<!-- /section:mine2 -->\n\n<!-- section:l1 -->\nL1\n<!-- /section:l1 -->\n\n<!-- section:l2 -->\nL2\n<!-- /section:l2 -->\n'
  check "seed base: opted-out zone taken back by name" \
    eval 'ts zones "$TMP/zq" "$TMP/zq.seeds" "$TMP/zqd" d > "$TMP/zqd.tsv"'
  check "seed base: named opt-out goes behind its predecessor, nothing else applied" file_is zqd/DOC.md \
    'head\n<!-- section:a -->\nA\n<!-- /section:a -->\nmine\n<!-- section:c -->\nC\n<!-- /section:c -->\n\n<!-- section:d -->\nD\n<!-- /section:d -->\n\n<!-- section:old -->\nO\n<!-- /section:old -->\n\n<!-- section:ov -->\n<!-- override: ours -->\nOV0\n<!-- /section:ov -->\n<!-- section:kept -->\n<!-- override: still ours -->\nK\n<!-- /section:kept -->\nend\n'
  check "seed base: a removed zone only by name" \
    eval 'ts zones "$TMP/zq" "$TMP/zq.seeds" "$TMP/zqr" old > /dev/null'
  check "seed base: only the named zone removed" file_is zqr/DOC.md \
    'head\n<!-- section:a -->\nA\n<!-- /section:a -->\nmine\n<!-- section:c -->\nC\n<!-- /section:c -->\n\n<!-- section:ov -->\n<!-- override: ours -->\nOV0\n<!-- /section:ov -->\n<!-- section:kept -->\n<!-- override: still ours -->\nK\n<!-- /section:kept -->\nend\n'
  refute "seed base: a local zone cannot be applied" ts zones "$TMP/zq" "$TMP/zq.seeds" "$TMP/zqk" kept
  check "seed base: --base names files without suffix, seed bases unused" \
    eval 'ts zones --base "$TMP/zp.base" "$TMP/zq" "$TMP/zq.seeds" "$TMP/zqb" > "$TMP/zqb.tsv"'
  check "seed base: without its base the missing zone is unconfirmed" zone_is zqb section d unconfirmed

  # --- text without markers ------------------------------------------------------------
  put zw.seeds/A.md '<!-- section:s1 -->\nS1\n<!-- /section:s1 -->\n<!-- section:s2 -->\nT1\nT2\n<!-- /section:s2 -->\n'
  put zw/A.md '<!-- section:s1 -->\nS1\n<!-- /section:s1 -->\nmine\nT1\nT2\nend\n'
  put zw.seeds/NOM.md '<!-- section:s3 -->\nN3\n<!-- /section:s3 -->\n'
  put zw/NOM.md 'intro\nN3\noutro\n'
  put zw.seeds/OPT.md '<!-- section:s5 -->\nF5\n<!-- /section:s5 -->\n<!-- section:s4 -->\nO4\n<!-- /section:s4 -->\n'
  put zw/OPT.md '<!-- section:s5 -->\nF5\n<!-- /section:s5 -->\nO4\n'
  put zw/.claude/template-base/OPT.md.seed '<!-- section:s5 -->\nF5\n<!-- /section:s5 -->\n<!-- section:s4 -->\nO4\n<!-- /section:s4 -->\n'
  put zw.seeds/ALL.md '<!-- section:s6 -->\nA6\n<!-- /section:s6 -->\n'
  put zw/ALL.md 'x\nA6\n'
  put zw/.claude/template-base/ALL.md.seed '<!-- section:s6 -->\nA6\n<!-- /section:s6 -->\n'
  put zw.seeds/CHG.md '<!-- section:sx -->\nX\n<!-- /section:sx -->\n<!-- section:s7 -->\nC7\nC8\n<!-- /section:s7 -->\n'
  put zw/CHG.md '<!-- section:sx -->\nX\n<!-- /section:sx -->\nC7\nC9\n'
  put zw.seeds/EMP.md '<!-- section:sy -->\nY\n<!-- /section:sy -->\n<!-- section:s8 -->\n\n<!-- /section:s8 -->\n'
  put zw/EMP.md '<!-- section:sy -->\nY\n<!-- /section:sy -->\n\n\n'
  put zw.seeds/TWO.md '<!-- section:sz -->\nZ\n<!-- /section:sz -->\n<!-- section:s9 -->\nSAME\n<!-- /section:s9 -->\n<!-- section:s10 -->\nSAME\n<!-- /section:s10 -->\n'
  put zw/TWO.md '<!-- section:sz -->\nZ\n<!-- /section:sz -->\nSAME\n'
  put zw.seeds/IN.md '<!-- section:s11 -->\nIN\n<!-- /section:s11 -->\n'
  put zw/IN.md '<!-- section:loc -->\nIN\n<!-- /section:loc -->\n'
  put zw.seeds/CH.md '<!-- section:s14 -->\nZ\n<!-- /section:s14 -->\n<!-- section:s12 -->\nW12\n<!-- /section:s12 -->\n<!-- section:s13 -->\nW13\n<!-- /section:s13 -->\n'
  put zw/CH.md '<!-- section:s14 -->\nZ\n<!-- /section:s14 -->\nW12\ntail\n'
  put zw/.claude/template-base/CH.md.seed '<!-- section:s14 -->\nZ\n<!-- /section:s14 -->\n'
  check "zones with unmarked text runs" \
    eval 'ts zones "$TMP/zw" "$TMP/zw.seeds" "$TMP/zwo" > "$TMP/zw.tsv" 2> "$TMP/zw.err"'
  check "bare: zone text without markers, no base" zone_is zw section s2 bare -
  check "bare: file without any marker" zone_is zw section s3 bare -
  check "bare: an opt-out with its text stays opted-out" zone_is zw section s4 opted-out -
  check "bare: all markers gone, the base has the zone: opted-out" zone_is zw section s6 opted-out -
  check "bare: changed text is not bare" zone_is zw section s7 unconfirmed
  check "bare: a zone without text is never searched" zone_is zw section s8 unconfirmed
  check "bare: the first of two zones with the same text takes it" zone_is zw section s9 bare -
  check "bare: text taken once, the second zone is not bare" zone_is zw section s10 unconfirmed
  check "bare: text inside another zone is not taken" zone_is zw section s11 unconfirmed
  check "bare: a zone the base lacks with its text standing" zone_is zw section s12 bare -
  check "bare: template block file" file_is zwo/.zones/section/s2.template 'T1\nT2\n'
  refute "bare: not applied without a name" test -e "$TMP/zwo/A.md"
  check "bare zones applied by name" \
    eval 'ts zones "$TMP/zw" "$TMP/zw.seeds" "$TMP/zwn" s2 s3 s4 s6 s12 s13 > /dev/null'
  check "bare: markers around the text" file_is zwn/A.md \
    '<!-- section:s1 -->\nS1\n<!-- /section:s1 -->\nmine\n<!-- section:s2 -->\nT1\nT2\n<!-- /section:s2 -->\nend\n'
  check "bare: markers around the text of a file without markers" file_is zwn/NOM.md \
    'intro\n<!-- section:s3 -->\nN3\n<!-- /section:s3 -->\noutro\n'
  check "bare: an opt-out taken back gets markers only" file_is zwn/OPT.md \
    '<!-- section:s5 -->\nF5\n<!-- /section:s5 -->\n<!-- section:s4 -->\nO4\n<!-- /section:s4 -->\n'
  check "bare: markers in a file without any" file_is zwn/ALL.md \
    'x\n<!-- section:s6 -->\nA6\n<!-- /section:s6 -->\n'
  check "bare: a new zone goes behind a wrapped predecessor" file_is zwn/CH.md \
    '<!-- section:s14 -->\nZ\n<!-- /section:s14 -->\n<!-- section:s12 -->\nW12\n<!-- /section:s12 -->\n\n<!-- section:s13 -->\nW13\n<!-- /section:s13 -->\ntail\n'

  # --- snapshot --seeds ----------------------------------------------------------------
  mkdir -p "$TMP/zq2" "$TMP/zq.none"
  check "snapshot --seeds runs" \
    eval 'ts snapshot --seeds "$TMP/zq2" "$TMP/zq.seeds" DOC.md > "$TMP/zq2.tsv"'
  check "snapshot --seeds: line" row_is zq2 DOC.md set
  check "snapshot --seeds: base is the rendered seed file" \
    cmp -s "$TMP/zq2/.claude/template-base/DOC.md.seed" "$TMP/zq.seeds/DOC.md"
  refute "snapshot --seeds: no managed base written" test -e "$TMP/zq2/.claude/template-base/DOC.md.base"
  check "status ignores seed bases" eval '[ -z "$(ts status "$TMP/zq")" ]'
  check "merge ignores seed bases" eval '[ -z "$(ts merge "$TMP/zq" "$TMP/zq.none" "$TMP/zqm")" ]'
  put zq2/.claude/template-base/STD.md.base 'managed\n'
  put zq.seeds/STD.md 'managed\n'
  refute "snapshot --seeds: a target with a managed base is refused" \
    ts snapshot --seeds "$TMP/zq2" "$TMP/zq.seeds" STD.md
  refute "snapshot --seeds: nothing written for a refused target" \
    test -e "$TMP/zq2/.claude/template-base/STD.md.seed"
  check "snapshot --seeds: a target no longer rendered loses its seed base" \
    eval 'ts snapshot --seeds "$TMP/zq2" "$TMP/zq.none" DOC.md > "$TMP/zq3.tsv"'
  check "snapshot --seeds: removed line" row_is zq3 DOC.md removed
  refute "snapshot --seeds: seed base gone" test -e "$TMP/zq2/.claude/template-base/DOC.md.seed"
  refute "--seeds is no option of zones" ts zones --seeds "$TMP/zq" "$TMP/zq.seeds" "$TMP/zqx"

  # --- broken markers in the render ---------------------------------------------------
  put zx.seeds/A.md '<!-- section:a -->\nx\n'
  mkdir -p "$TMP/zx"
  refute "zones: broken render refused" ts zones "$TMP/zx" "$TMP/zx.seeds" "$TMP/zxo"
  refute "zones: missing seeds dir refused" ts zones "$TMP/zx" "$TMP/nope.seeds" "$TMP/zxo2"

  # --- real renders: a fresh project has nothing to sync -------------------------------
  render zr docs-only private --seeds
  render zr.seeds docs-only private --seeds
  check "zones on a fresh docs-only render" eval 'ts zones "$TMP/zr" "$TMP/zr.seeds" "$TMP/zro" > "$TMP/zr1.tsv"'
  check "fresh docs-only: every zone identical" all_zones zr1 identical
  check "fresh docs-only: registry head listed" zone_is zr1 section overrides-head identical
  check "fresh docs-only: no graphiti zone without graphiti" no_zone zr1 claude-graphiti
  check "fresh docs-only: nothing written" only_block_files zro
  render zg docs-only private --seeds OPTIONAL=graphiti
  render zg.seeds docs-only private --seeds OPTIONAL=graphiti
  check "zones with graphiti" eval 'ts zones "$TMP/zg" "$TMP/zg.seeds" "$TMP/zgo" > "$TMP/zg1.tsv"'
  check "graphiti zone identical" zone_is zg1 section claude-graphiti identical
  # Graphiti switched on later: the seed base of the old answers lacks its zone.
  cp -R "$TMP/zr" "$TMP/zgp"
  check "seed base of a project without graphiti" \
    eval 'ts snapshot --seeds "$TMP/zgp" "$TMP/zr.seeds" CLAUDE.md > /dev/null'
  check "zones after switching graphiti on" \
    eval 'ts zones "$TMP/zgp" "$TMP/zg.seeds" "$TMP/zgn" > "$TMP/zgn.tsv"'
  check "graphiti switched on: its zone is new" zone_is zgn section claude-graphiti new
  check "graphiti switched on: other zones identical" zone_is zgn section claude-startup identical -
  cp "$TMP/zgn/CLAUDE.md" "$TMP/zgp/CLAUDE.md"
  check "zones after inserting the graphiti zone" \
    eval 'ts zones "$TMP/zgp" "$TMP/zg.seeds" "$TMP/zgn2" > "$TMP/zgn2.tsv"'
  check "graphiti inserted: its zone is identical" zone_is zgn2 section claude-graphiti identical -
  # The head zone of features/INDEX.md opted out by deleting its markers, without a seed
  # base, next to a zone of the project's own: its text stands, so it is bare.
  mkdir -p "$TMP/zph/features"
  awk '$0 != "<!-- section:index-head -->" && $0 != "<!-- /section:index-head -->"' \
    "$TMP/zr/features/INDEX.md" > "$TMP/zph/features/INDEX.md"
  printf '\n<!-- section:index-notes -->\nOwn.\n<!-- /section:index-notes -->\n' >> "$TMP/zph/features/INDEX.md"
  { cat "$TMP/zr/features/INDEX.md"; printf '\n<!-- section:index-notes -->\nOwn.\n<!-- /section:index-notes -->\n'; } \
    > "$TMP/zph.expected"
  check "zones on a head zone without markers" \
    eval 'ts zones "$TMP/zph" "$TMP/zr.seeds" "$TMP/zpho" index-head > "$TMP/zph.tsv"'
  check "head zone without markers is bare" zone_is zph section index-head bare -
  check "head zone by name: its markers back around the text, nothing else" \
    cmp -s "$TMP/zpho/features/INDEX.md" "$TMP/zph.expected"
  check "graphiti inserted: before the startup zone" eval 'awk "
    /^<!-- section:claude-graphiti -->\$/ { g = NR }
    /^<!-- section:claude-startup -->\$/ { s = NR }
    END { exit !(g && g < s) }" "$TMP/zgp/CLAUDE.md"'
  render zt ts-node private --seeds
  render zt.seeds ts-node private --seeds
  check "zones on a fresh ts-node render" eval 'ts zones "$TMP/zt" "$TMP/zt.seeds" "$TMP/zto" > "$TMP/zt1.tsv"'
  check "fresh ts-node: every block identical" all_zones zt1 identical
  check "fresh ts-node: module fragment listed" zone_is zt1 fragment ts-node identical
  check "fresh ts-node: language fragment listed" zone_is zt1 fragment typescript-lang identical

  # A registry head that mentions the override comment inside a line is not protected.
  awk '/<!-- \/section:overrides-head -->/ { print "Inside a zone, `<!-- override: reason -->` protects it." } { print }' \
    "$TMP/zr/.claude/convention-overrides.md" > "$TMP/zr-head" \
    && mv "$TMP/zr-head" "$TMP/zr/.claude/convention-overrides.md"
  check "zones after editing the registry head" \
    eval 'ts zones "$TMP/zr" "$TMP/zr.seeds" "$TMP/zro2" > "$TMP/zr2.tsv"'
  check "old registry head: differs, not override" zone_is zr2 section overrides-head differs "+0 -1"
  check "old registry head: result is the rendered file" \
    cmp -s "$TMP/zro2/.claude/convention-overrides.md" "$TMP/zr.seeds/.claude/convention-overrides.md"
}
