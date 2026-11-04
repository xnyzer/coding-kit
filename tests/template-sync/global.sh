# render-global cases (the kit's global rules with the personal config) and zones on a
# stand-in Claude config folder, for tests/template-sync/run.sh — sourced after sync.sh
# and zones.sh, uses their fixture helpers.

KIT=$ROOT/plugins/coding-kit/global/coding-kit.md
G=rules/coding-kit.md

# envfile NAME LINE… — writes $TMP/NAME.env, one LINE per argument, verbatim.
envfile() {
  ef_name=$1
  shift
  printf '%s\n' "$@" > "$TMP/$ef_name.env"
}

# rglobal NAME [KIT] — renders KIT (default: the plugin's) with $TMP/NAME.env (no file =
# no values) into $TMP/NAME; listing in $TMP/NAME.tsv, stderr in $TMP/NAME.err.
rglobal() {
  ts render-global "${2:-$KIT}" "$TMP/$1.env" "$TMP/$1" > "$TMP/$1.tsv" 2> "$TMP/$1.err"
}

key_is() {  # NAME KEY STATE
  grep -qxF -- "key${TABC}CODING_KIT_$2${TABC}$3" "$TMP/$1.tsv"
}

rendered_line() {  # NAME
  grep -qxF -- "rendered${TABC}$G" "$TMP/$1.tsv"
}

# The render of NAME holds exactly one level block, the one of LEVEL.
one_level() {  # NAME LEVEL
  [ "$(grep -c '^- \*\*Stufe ' "$TMP/$1/$G")" -eq 1 ] && contains "$1/$G" "- **Stufe $2:**"
}

only_target() {  # NAME — OUT holds the rules file and nothing else
  [ "$(cd "$TMP/$1" && find . -type f)" = "./$G" ]
}

# sglobal NAME ARG… — set-global with $TMP/NAME.env (no file = empty) into $TMP/NAME;
# listing in $TMP/NAME.tsv, stderr in $TMP/NAME.err.
sglobal() {
  sg_name=$1
  shift
  ts set-global "$KIT" "$TMP/$sg_name.env" "$TMP/$sg_name" "$@" \
    > "$TMP/$sg_name.tsv" 2> "$TMP/$sg_name.err"
}

# The comment of KEY in the key comment of the kit file, read independently of the script.
kit_c() {  # KEY
  sed -n "s/^$1=\"\" *# //p" "$KIT"
}

set_is() {  # NAME KEY STATE
  grep -qxF -- "set${TABC}CODING_KIT_$2${TABC}$3" "$TMP/$1.tsv"
}

# The values the shell sees when it reads the written file: reply|level|note.
sourced_values() {  # NAME
  $SH -c '. "$1"; printf "%s|%s|%s" "$CODING_KIT_REPLY_LANGUAGE" "$CODING_KIT_EXPLAIN_LEVEL" "$CODING_KIT_EXPLAIN_NOTE"' \
    sh "$TMP/$1/coding-kit.env"
}

# copy_rules FROM TO — the rendered rules of FROM as the installed file of config folder TO.
copy_rules() {
  mkdir -p "$TMP/$2/rules"
  cp "$TMP/$1/$G" "$TMP/$2/$G"
}

# edit_rules DIR AWK-PROGRAM — rewrites DIR's rules file through awk.
edit_rules() {
  awk "$2" "$TMP/$1/$G" > "$TMP/$1/$G.tmp" && mv "$TMP/$1/$G.tmp" "$TMP/$1/$G"
}

run_global_cases() {
  TABC=$(printf '\t')
  # Opening braces of a placeholder token, split so the validator sees no token here.
  TOK='{''{'

  # --- all values: comments, export, bare word, escapes, foreign lines -------------
  envfile ga '# personal config' 'CODING_KIT_GITHUB_LOGIN="octo"' 'NOT_OURS=1' 'echo hi' \
    'CODING_KIT_REPLY_LANGUAGE="Deutsch"   # Sprache der Antworten' \
    'export CODING_KIT_EXPLAIN_LEVEL=junior # bare word' \
    'CODING_KIT_EXPLAIN_NOTE="A & \"B\" / c\\d \$HOME \x"'
  check "render-global runs with all values" rglobal ga
  check "render-global: reply language set" key_is ga REPLY_LANGUAGE set
  check "render-global: level set" key_is ga EXPLAIN_LEVEL set
  check "render-global: note set" key_is ga EXPLAIN_NOTE set
  check "render-global: rendered line names the target" rendered_line ga
  check "render-global: OUT holds only the rules file" only_target ga
  check "render-global: identifier on the first line" \
    test "$(first_line "$TMP/ga/$G")" = '<!-- coding-kit:global-rules -->'
  check "render-global: reply language line" \
    contains "ga/$G" '- Antwortsprache: Deutsch (außer der Nutzer wechselt die Sprache).'
  check "render-global: explain heading" contains "ga/$G" '## Erklär-Niveau'
  check "render-global: only the chosen level" one_level ga junior
  check "render-global: note taken literally, escapes resolved" \
    contains "ga/$G" '  „A & "B" / c\d $HOME \x"'
  check "render-global: no block marker left" eval '! grep -q "template:optional" "$TMP/ga/$G"'
  check "render-global: no placeholder left" no_placeholders ga
  check "render-global: zone markers paired" markers_paired ga
  check "render-global: language rule of the template" \
    contains "ga/$G" 'einen **Languages-Block**, gewinnt der je Dimension'
  refute "render-global: no short language rule of old copies" \
    contains "ga/$G" 'Governance-Doku: Englisch. Die Sprache der lebenden'
  check "render-global: artifact rule" \
    contains "ga/$G" '**Nichts wird ohne ausdrückliche Erlaubnis als Artifact auf claude.ai veröffentlicht**'

  # --- no values ------------------------------------------------------------------
  check "render-global runs without a personal config" rglobal gn
  check "render-global: missing reply language" key_is gn REPLY_LANGUAGE missing
  check "render-global: missing level" key_is gn EXPLAIN_LEVEL missing
  check "render-global: missing note" key_is gn EXPLAIN_NOTE missing
  refute "render-global: no reply language line" contains "gn/$G" 'Antwortsprache'
  refute "render-global: no explain heading" contains "gn/$G" '## Erklär-Niveau'
  check "render-global: the explain zone stays, empty" \
    line_after "gn/$G" '<!-- section:global-explain -->' '<!-- /section:global-explain -->'
  check "render-global: zone markers paired without values" markers_paired gn
  check "render-global: no placeholder from dropped blocks" no_placeholders gn

  # --- empty values equal missing ones ----------------------------------------------
  envfile ge 'CODING_KIT_REPLY_LANGUAGE=""' "CODING_KIT_EXPLAIN_LEVEL=''" 'CODING_KIT_EXPLAIN_NOTE='
  check "render-global runs with empty values" rglobal ge
  check "render-global: empty reply language" key_is ge REPLY_LANGUAGE empty
  check "render-global: empty level" key_is ge EXPLAIN_LEVEL empty
  check "render-global: empty note" key_is ge EXPLAIN_NOTE empty
  check "render-global: empty values render like missing ones" cmp -s "$TMP/ge/$G" "$TMP/gn/$G"

  # --- note without level, level without note ---------------------------------------
  envfile gnote 'CODING_KIT_EXPLAIN_NOTE="nur eine Notiz"'
  check "render-global runs with a note only" rglobal gnote
  check "render-global: note only keeps the heading" contains "gnote/$G" '## Erklär-Niveau'
  refute "render-global: note only has no level" contains "gnote/$G" '- **Stufe '
  check "render-global: note only, blank line before the note" \
    line_before "gnote/$G" '- **Notiz des Nutzers**' ''
  envfile gl 'CODING_KIT_EXPLAIN_LEVEL=senior'
  check "render-global runs with a level only" rglobal gl
  check "render-global: level only" one_level gl senior
  refute "render-global: level only has no note" contains "gl/$G" 'Notiz des Nutzers'
  check "render-global: level only closes the zone after the level" \
    line_after "gl/$G" 'Trade-offs, Risiken' '<!-- /section:global-explain -->'
  for lv in einsteiger junior fortgeschritten; do
    envfile "gv-$lv" "CODING_KIT_EXPLAIN_LEVEL=$lv"
    check "render-global runs with level $lv" rglobal "gv-$lv"
    check "render-global: level $lv only" one_level "gv-$lv" "$lv"
  done

  # --- personal config syntax -------------------------------------------------------
  envfile gw 'CODING_KIT_REPLY_LANGUAGE="Deutsch"' 'CODING_KIT_REPLY_LANGUAGE=English'
  check "render-global: a later assignment wins" \
    eval 'rglobal gw && contains "gw/$G" "Antwortsprache: English ("'
  envfile gq "CODING_KIT_EXPLAIN_NOTE='a \"b\" \\n \$x'  # comment"
  check "render-global: single quotes are literal" \
    eval 'rglobal gq && contains "gq/$G" "  „a \"b\" \\n \$x\""'
  put gc.env 'CODING_KIT_REPLY_LANGUAGE="Deutsch"\r\n'
  check "render-global: CRLF line ends" \
    eval 'rglobal gc && contains "gc/$G" "Antwortsprache: Deutsch (außer"'
  envfile gt 'CODING_KIT_REPLY_LANGUAGE="Deutsch'
  refute "render-global: unterminated quote is refused" rglobal gt
  check "render-global: unterminated quote is named" err_mentions gt 'line 1: CODING_KIT_REPLY_LANGUAGE: unterminated quote'
  envfile gx 'CODING_KIT_REPLY_LANGUAGE="Deutsch" extra'
  refute "render-global: text after the value is refused" rglobal gx
  check "render-global: text after the value is named" err_mentions gx 'unexpected text after the value'
  envfile gs 'CODING_KIT_REPLY_LANGUAGE= Deutsch'
  refute "render-global: space after = is refused" rglobal gs
  envfile gb "CODING_KIT_EXPLAIN_NOTE=\"a${TABC}b\""
  refute "render-global: a tab in a value is refused" rglobal gb
  envfile gp "CODING_KIT_EXPLAIN_NOTE=\"${TOK}REPLY_LANGUAGE}}\""
  refute "render-global: {{ in a value is refused" rglobal gp
  check "render-global: {{ in a value is named" err_mentions gp 'value contains a tab or {{'

  # --- levels and the kit file contract ---------------------------------------------
  envfile gu 'CODING_KIT_EXPLAIN_LEVEL="Junior"'
  refute "render-global: unknown level is refused" rglobal gu
  check "render-global: unknown level names the known ones" \
    err_mentions gu "unknown level 'Junior' (known: einsteiger junior fortgeschritten senior)"
  check "render-global: nothing written for a refused level" test ! -e "$TMP/gu"
  put gk1.kit '<!-- template:optional:other -->\nx\n<!-- /template:optional:other -->\n'
  refute "render-global: unknown block is refused" rglobal gk1 "$TMP/gk1.kit"
  check "render-global: unknown block is named" err_mentions gk1 'unknown block template:optional:other'
  put gk2.kit "a ${TOK}OWNER}} b\n"
  refute "render-global: unresolved placeholder is refused" rglobal gk2 "$TMP/gk2.kit"
  check "render-global: unresolved placeholder is named" err_mentions gk2 "unresolved placeholder: ${TOK}OWNER}}"
  put gk3.kit '<!-- template:optional:explain -->\n<!-- template:optional:explain-note -->\nn\n<!-- /template:optional:explain-note -->\n<!-- /template:optional:explain -->\n'
  refute "render-global: nested blocks are refused" rglobal gk3 "$TMP/gk3.kit"
  put gf/x 'taken\n'
  refute "render-global: non-empty OUT is refused" rglobal gf
  refute "render-global: missing kit file is refused" rglobal gm "$TMP/no-such-kit.md"
  refute "render-global: missing operand is refused" ts render-global "$KIT" "$TMP/ga.env"
  refute "render-global takes no options" ts render-global --seeds "$KIT" "$TMP/ga.env" "$TMP/gz"

  # --- set-global -------------------------------------------------------------------
  NLC='
'
  NOTE='a "b" $c \d `e`'
  envfile gsa '# personal config' 'CODING_KIT_GITHUB_LOGIN="octo"' \
    'export CODING_KIT_EXPLAIN_LEVEL=senior # mine' 'NOT_OURS="x"  # stays' \
    'CODING_KIT_EXPLAIN_LEVEL=einsteiger'
  check "set-global runs" sglobal gsa CODING_KIT_EXPLAIN_LEVEL=junior \
    "CODING_KIT_EXPLAIN_NOTE=$NOTE" CODING_KIT_REPLY_LANGUAGE=Deutsch
  check "set-global: missing key added" set_is gsa REPLY_LANGUAGE added
  check "set-global: key behind export replaced" set_is gsa EXPLAIN_LEVEL replaced
  check "set-global: missing note added" set_is gsa EXPLAIN_NOTE added
  check "set-global: lines in key order, then written" \
    test "$(cut -f2 "$TMP/gsa.tsv" | tr '\n' ' ')" = \
    "CODING_KIT_REPLY_LANGUAGE CODING_KIT_EXPLAIN_LEVEL CODING_KIT_EXPLAIN_NOTE coding-kit.env "
  printf '%s\n' '# personal config' 'CODING_KIT_GITHUB_LOGIN="octo"' \
    "CODING_KIT_EXPLAIN_LEVEL=\"junior\"  # $(kit_c CODING_KIT_EXPLAIN_LEVEL)" \
    'NOT_OURS="x"  # stays' '' \
    "CODING_KIT_REPLY_LANGUAGE=\"Deutsch\"  # $(kit_c CODING_KIT_REPLY_LANGUAGE)" \
    "CODING_KIT_EXPLAIN_NOTE=\"a \\\"b\\\" \\\$c \\\\d \\\`e\\\`\"  # $(kit_c CODING_KIT_EXPLAIN_NOTE)" \
    > "$TMP/gsa.expected"
  check "set-global: replaced in place, later duplicate dropped, rest unchanged, new keys appended" \
    cmp -s "$TMP/gsa/coding-kit.env" "$TMP/gsa.expected"
  check "set-global: the file is private" \
    test "$(ls -l "$TMP/gsa/coding-kit.env" | cut -c1-10)" = '-rw-------'
  check "set-global: the shell reads the values literally" \
    test "$(sourced_values gsa)" = "Deutsch|junior|$NOTE"
  check "set-global: render-global reads the written file" \
    eval 'ts render-global "$KIT" "$TMP/gsa/coding-kit.env" "$TMP/gsar" > /dev/null'
  check "set-global: the note survives the round trip" contains "gsar/$G" "  „$NOTE\""
  check "set-global: the level survives the round trip" one_level gsar junior

  check "set-global without a personal config" sglobal gsn CODING_KIT_EXPLAIN_LEVEL=senior
  printf '%s\n' "CODING_KIT_EXPLAIN_LEVEL=\"senior\"  # $(kit_c CODING_KIT_EXPLAIN_LEVEL)" > "$TMP/gsn.expected"
  check "set-global: a new file holds only the new line" cmp -s "$TMP/gsn/coding-kit.env" "$TMP/gsn.expected"
  check "set-global: an empty value is written" \
    eval 'sglobal gse CODING_KIT_EXPLAIN_NOTE= && grep -q "^CODING_KIT_EXPLAIN_NOTE=\"\"  # " "$TMP/gse/coding-kit.env"'
  put gsc.env 'CODING_KIT_GITHUB_LOGIN="octo"\r\n'
  check "set-global with CRLF line ends" sglobal gsc CODING_KIT_REPLY_LANGUAGE=English
  printf 'CODING_KIT_GITHUB_LOGIN="octo"\r\n\r\nCODING_KIT_REPLY_LANGUAGE="English"  # %s\r\n' \
    "$(kit_c CODING_KIT_REPLY_LANGUAGE)" > "$TMP/gsc.expected"
  check "set-global: CRLF file gets CRLF lines" cmp -s "$TMP/gsc/coding-kit.env" "$TMP/gsc.expected"
  put gsm.env 'A=1'
  check "set-global without a final newline" sglobal gsm CODING_KIT_REPLY_LANGUAGE=x
  printf 'A=1\n\nCODING_KIT_REPLY_LANGUAGE="x"  # %s\n' "$(kit_c CODING_KIT_REPLY_LANGUAGE)" > "$TMP/gsm.expected"
  check "set-global: final newline added, blank line before new keys" \
    cmp -s "$TMP/gsm/coding-kit.env" "$TMP/gsm.expected"
  envfile gsb 'A=1' ''
  check "set-global behind a blank last line" sglobal gsb CODING_KIT_REPLY_LANGUAGE=x
  check "set-global: no second blank line" cmp -s "$TMP/gsb/coding-kit.env" "$TMP/gsm.expected"

  refute "set-global: unknown level is refused" sglobal gsl CODING_KIT_EXPLAIN_LEVEL=pro
  check "set-global: unknown level names the known ones" \
    err_mentions gsl "unknown level 'pro' (known: einsteiger junior fortgeschritten senior)"
  check "set-global: nothing written for a refused value" test ! -e "$TMP/gsl"
  refute "set-global: other personal keys are refused" sglobal gsk CODING_KIT_PROJECTS_DIR=/x
  check "set-global: other personal keys are named" \
    err_mentions gsk 'not a key of the personal config the kit writes'
  refute "set-global: the address of an unknown host is refused" \
    sglobal gshost CODING_KIT_EMAIL_GITLAB=me@example.org
  envfile gsaddr '# personal config' 'CODING_KIT_EMAIL_GIT="old@example.org"'
  check "set-global: addresses per host run" sglobal gsaddr \
    CODING_KIT_EMAIL_GIT=new@example.org CODING_KIT_EMAIL_GITHUB=1+octo@users.noreply.github.com \
    CODING_KIT_REPLY_LANGUAGE=Deutsch
  check "set-global: address keys after the rule values, then written" \
    test "$(cut -f2 "$TMP/gsaddr.tsv" | tr '\n' ' ')" = \
    "CODING_KIT_REPLY_LANGUAGE CODING_KIT_EMAIL_GITHUB CODING_KIT_EMAIL_GIT coding-kit.env "
  check "set-global: address replaced with its comment" grep -qxF \
    "CODING_KIT_EMAIL_GIT=\"new@example.org\"  # $(kit_c CODING_KIT_EMAIL_GIT)" "$TMP/gsaddr/coding-kit.env"
  check "set-global: address added" set_is gsaddr EMAIL_GITHUB added
  # --- the old commit address: reported by render-global, dropped by set-global ------
  envfile rgl 'CODING_KIT_GIT_NOREPLY_EMAIL="1+octo@users.noreply.github.com"'
  check "render-global: old address runs" rglobal rgl
  check "render-global: old address waits for the rename" grep -qxF \
    "legacy${TABC}CODING_KIT_GIT_NOREPLY_EMAIL${TABC}CODING_KIT_EMAIL_GITHUB${TABC}rename" "$TMP/rgl.tsv"
  envfile rgs 'CODING_KIT_GIT_NOREPLY_EMAIL=old@example.org' 'CODING_KIT_EMAIL_GITHUB=new@example.org'
  check "render-global: old and new address run" rglobal rgs
  check "render-global: old address superseded by the new one" grep -qxF \
    "legacy${TABC}CODING_KIT_GIT_NOREPLY_EMAIL${TABC}CODING_KIT_EMAIL_GITHUB${TABC}superseded" "$TMP/rgs.tsv"
  refute "render-global: no legacy line without the old address" grep -q '^legacy' "$TMP/ga.tsv"
  envfile gdrop '# personal config' 'CODING_KIT_GIT_NOREPLY_EMAIL="a@example.org"' 'OTHER=1' \
    'export CODING_KIT_GIT_NOREPLY_EMAIL=b@example.org'
  check "set-global: rename runs without a value" \
    eval 'ts set-global --rename-legacy "$KIT" "$TMP/gdrop.env" "$TMP/gdrop" > "$TMP/gdrop.tsv"'
  check "set-global: rename reports added and dropped" \
    test "$(cut -f1,2 "$TMP/gdrop.tsv" | tr '\t\n' ' |')" = \
    "set CODING_KIT_EMAIL_GITHUB|dropped CODING_KIT_GIT_NOREPLY_EMAIL|written coding-kit.env|"
  check "set-global: the last old value moves to the GitHub key" \
    grep -q '^CODING_KIT_EMAIL_GITHUB="b@example.org"  # ' "$TMP/gdrop/coding-kit.env"
  refute "set-global: no assignment of the old key left" \
    grep -q 'CODING_KIT_GIT_NOREPLY_EMAIL' "$TMP/gdrop/coding-kit.env"
  check "set-global: other lines stay" grep -qx 'OTHER=1' "$TMP/gdrop/coding-kit.env"
  envfile gdrops 'CODING_KIT_GIT_NOREPLY_EMAIL=old@example.org' 'CODING_KIT_EMAIL_GITHUB=new@example.org'
  check "set-global: rename with the new key set runs" \
    eval 'ts set-global --rename-legacy "$KIT" "$TMP/gdrops.env" "$TMP/gdrops" > "$TMP/gdrops.tsv"'
  check "set-global: a set GitHub key wins over the old value" \
    grep -qx 'CODING_KIT_EMAIL_GITHUB=new@example.org' "$TMP/gdrops/coding-kit.env"
  refute "set-global: the superseded old key is gone" \
    grep -q 'CODING_KIT_GIT_NOREPLY_EMAIL' "$TMP/gdrops/coding-kit.env"
  refute "set-global: without --rename-legacy a value is required" \
    ts set-global "$KIT" "$TMP/gdrop.env" "$TMP/gdropx"
  refute "render-global takes no --rename-legacy" \
    ts render-global --rename-legacy "$KIT" "$TMP/gdrop.env" "$TMP/gdropr"
  check "set-global: default host runs" sglobal gsdh CODING_KIT_DEFAULT_HOST=git
  check "set-global: default host written with its comment" grep -qxF \
    "CODING_KIT_DEFAULT_HOST=\"git\"  # $(kit_c CODING_KIT_DEFAULT_HOST)" "$TMP/gsdh/coding-kit.env"
  refute "set-global: an unknown default host is refused" sglobal gsdx CODING_KIT_DEFAULT_HOST=gitlab
  check "set-global: the refusal lists the hosts" err_mentions gsdx 'github git'
  refute "set-global: a repeated key is refused" sglobal gsr CODING_KIT_REPLY_LANGUAGE=a \
    CODING_KIT_REPLY_LANGUAGE=b
  refute "set-global: a name without prefix is refused" sglobal gsx REPLY_LANGUAGE=x
  refute "set-global: a tab in a value is refused" sglobal gst "CODING_KIT_EXPLAIN_NOTE=a${TABC}b"
  refute "set-global: a line break in a value is refused" sglobal gsw "CODING_KIT_EXPLAIN_NOTE=a${NLC}b"
  refute "set-global: {{ in a value is refused" sglobal gsp "CODING_KIT_EXPLAIN_NOTE=${TOK}X}}"
  refute "set-global: no value is a usage error" sglobal gsu
  put gso/x 'taken\n'
  refute "set-global: non-empty OUT is refused" sglobal gso CODING_KIT_REPLY_LANGUAGE=x
  refute "set-global: missing kit file is refused" \
    ts set-global "$TMP/no-such-kit.md" "$TMP/gsa.env" "$TMP/gsz" CODING_KIT_REPLY_LANGUAGE=x

  # --- zones on a stand-in config folder --------------------------------------------
  copy_rules ga gzc
  edit_rules gzc '{ sub(/Conventional Commits, englisch/, "Conventional Commits, deutsch"); print }'
  edit_rules gzc '{ print } $0 == "<!-- section:global-graphiti -->" { print "<!-- override: own wording -->" }'
  edit_rules gzc '$0 != "<!-- section:global-workflow -->" && $0 != "<!-- /section:global-workflow -->"'
  # The base of the last sync: the same render (update-conventions keeps it in the
  # plugin's data folder).
  mkdir -p "$TMP/gzc.base/rules"
  cp "$TMP/ga/$G" "$TMP/gzc.base/$G.base"
  check "zones runs on a config folder" \
    eval 'ts zones --snapshot "$TMP/gzc.base" "$TMP/gzc" "$TMP/ga" "$TMP/gzco" > "$TMP/gzc.tsv" 2> "$TMP/gzc.err"'
  check "zones: config folder, unchanged zone is identical" zone_is gzc section global-language identical -
  check "zones: config folder, explain zone is identical" zone_is gzc section global-explain identical -
  check "zones: config folder, edited zone differs" zone_is gzc section global-git differs "+1 -1"
  check "zones: config folder, override protects" zone_is gzc section global-graphiti override -
  check "zones: config folder, removed markers opt out" zone_is gzc section global-workflow opted-out
  check "zones: config folder, every line names the rules file" \
    eval '[ "$(cut -f1 "$TMP/gzc.tsv" | sort -u)" = "$G" ]'
  sed 's/Conventional Commits, deutsch/Conventional Commits, englisch/' "$TMP/gzc/$G" > "$TMP/gzc.expected"
  check "zones: config folder, result restores the differing zone only" \
    cmp -s "$TMP/gzco/$G" "$TMP/gzc.expected"

  check "zones: config folder without a base cannot tell an opt-out" \
    eval 'ts zones "$TMP/gzc" "$TMP/ga" "$TMP/gzcu" > "$TMP/gzcu.tsv" 2> "$TMP/gzcu.err"'
  check "zones: config folder without a base, the zone text without markers is bare" \
    zone_is gzcu section global-workflow bare -

  # A zone the kit gained since the last sync: neither the rules file nor the base has it.
  copy_rules ga gzw
  edit_rules gzw '$0 == "<!-- section:global-workflow -->" { skip = 1 } !skip { print } $0 == "<!-- /section:global-workflow -->" { skip = 0 }'
  mkdir -p "$TMP/gzw.base/rules"
  cp "$TMP/gzw/$G" "$TMP/gzw.base/$G.base"
  check "zones: a new kit zone runs" \
    eval 'ts zones --snapshot "$TMP/gzw.base" "$TMP/gzw" "$TMP/ga" "$TMP/gzwo" > "$TMP/gzw.tsv" 2> "$TMP/gzw.err"'
  check "zones: a new kit zone is new" zone_is gzw section global-workflow new
  check "zones: a new kit zone, the others identical" zone_is gzw section global-git identical -
  cp "$TMP/gzwo/$G" "$TMP/gzw/$G"
  check "zones: after inserting the new kit zone" \
    eval 'ts zones --snapshot "$TMP/gzw.base" "$TMP/gzw" "$TMP/ga" "$TMP/gzwo2" > "$TMP/gzw2.tsv"'
  check "zones: the inserted kit zone is identical" all_zones gzw2 identical

  copy_rules ga gzv
  check "zones: a changed value shows as a differing zone" \
    eval 'ts zones "$TMP/gzv" "$TMP/gl" "$TMP/gzvo" > "$TMP/gzv.tsv" 2> "$TMP/gzv.err"'
  check "zones: changed level and note differ" zone_is gzv section global-explain differs
  check "zones: dropped reply language differs" zone_is gzv section global-language differs
  check "zones: untouched zone stays identical" zone_is gzv section global-git identical -

  put gzf/rules/coding-kit.md 'my own rules\n'
  check "zones: foreign rules file runs" \
    eval 'ts zones "$TMP/gzf" "$TMP/ga" "$TMP/gzfo" > "$TMP/gzf.tsv" 2> "$TMP/gzf.err"'
  check "zones: foreign rules file is unmarked" all_zones gzf unmarked
  check "zones: foreign rules file is never rewritten" only_block_files gzfo

  mkdir -p "$TMP/gzn"
  check "zones: config folder without the rules file runs" \
    eval 'ts zones "$TMP/gzn" "$TMP/ga" "$TMP/gzno" > "$TMP/gzn.tsv" 2> "$TMP/gzn.err"'
  check "zones: config folder without the rules file is new-file" all_zones gzn new-file
}
