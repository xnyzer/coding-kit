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

  # --- zones on a stand-in config folder --------------------------------------------
  copy_rules ga gzc
  edit_rules gzc '{ sub(/Conventional Commits, englisch/, "Conventional Commits, deutsch"); print }'
  edit_rules gzc '{ print } $0 == "<!-- section:global-graphiti -->" { print "<!-- override: own wording -->" }'
  edit_rules gzc '$0 != "<!-- section:global-workflow -->" && $0 != "<!-- /section:global-workflow -->"'
  check "zones runs on a config folder" \
    eval 'ts zones "$TMP/gzc" "$TMP/ga" "$TMP/gzco" > "$TMP/gzc.tsv" 2> "$TMP/gzc.err"'
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
  check "zones: config folder without the rules file is no-file" all_zones gzn no-file
}
