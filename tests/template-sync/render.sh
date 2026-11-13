# Render cases for tests/template-sync/run.sh — sourced, uses its helpers.

run_render_cases() {
  M=$TEMPLATE/modules

  # docs-only, private, managed targets only
  check "docs-only renders" render docs docs-only private
  check "docs-only: listing matches the files" listing_matches docs
  check "docs-only: no placeholder left" no_placeholders docs
  check "docs-only: every managed core target" all_core_present docs private
  check "docs-only: managed only, no seed row" no_seed_rows docs
  refute "docs-only: no seed file" has docs/CLAUDE.md
  refute "private: no public-only file" has docs/CODE_OF_CONDUCT.md
  refute "docs-only: no CodeQL workflow" has docs/.github/workflows/codeql.yml
  check "docs-only: core justfile" same_but_first_line docs/justfile "$TEMPLATE/core/justfile"
  for_host "$TEMPLATE/core/CODING-STANDARDS.md" github cs.github
  check "docs-only: slot keeps its placeholder text" same_but_first_line docs/CODING-STANDARDS.md "$TMP/cs.github"

  # docs-only, public: public-only files, still no CodeQL (no language)
  check "docs-only public renders" render docs-pub docs-only public
  check "public: public-only file" has docs-pub/CODE_OF_CONDUCT.md
  check "docs-only public: every core target but CodeQL" all_core_present docs-pub public .github/workflows/codeql.yml
  refute "docs-only public: no CodeQL workflow" has docs-pub/.github/workflows/codeql.yml

  # ts-node, public
  check "ts-node renders" render ts ts-node public
  check "ts-node: listing matches the files" listing_matches ts
  check "ts-node: no placeholder left" no_placeholders ts
  check "ts-node: markers paired" markers_paired ts
  check "ts-node: every managed core target" all_core_present ts public
  check "ts-node: CodeQL language" contains ts/.github/workflows/codeql.yml "'javascript-typescript'"
  for t_f in biome.json tsconfig.json tsconfig.build.json vitest.config.ts; do
    check "ts-node: managed module file $t_f" has "ts/$t_f"
  done
  refute "ts-node: seed module file left out" has ts/package.json
  check "ts-node: module justfile replaces the core one" same_but_first_line ts/justfile "$M/ts-node/justfile"
  check "ts-node: project name in the justfile head" contains ts/justfile demo-app
  check "ts-node: tools follow the core tools" tools_follow ts ts-node
  check "ts-node: gitignore part below its marker" line_after ts/.gitignore "# module:gitignore" "$(first_line "$M/ts-node/gitignore.part")"
  check "ts-node: module fragment opens the slot" line_after ts/CODING-STANDARDS.md "<!-- module:coding-standards -->" "<!-- fragment:ts-node -->"
  check "ts-node: language fragment closes the slot" line_before ts/CODING-STANDARDS.md "<!-- /module:coding-standards -->" "<!-- /fragment:typescript-lang -->"
  check "ts-node: module fragment, then language fragment" slot_order ts/CODING-STANDARDS.md "ts-node typescript-lang"

  # go, public: the license gate runs in just check, not as an extra CI job (F-057)
  check "go renders" render go go public
  check "go: no placeholder left" no_placeholders go
  refute "go: no license job in the CI" contains go/.github/workflows/ci.yml 'license-check'
  check "go: check runs the license gate" contains go/justfile 'just license-check'
  refute "go: no @latest in the module" grep -rqF '@latest' "$M/go"
  check "go: CodeQL language" contains go/.github/workflows/codeql.yml "'go'"
  check "go: managed module file" has go/.golangci.yml
  refute "go: seed module file left out" has go/go.mod
  check "go: tools follow the core tools" tools_follow go go
  check "go: module fragment, then language fragment" slot_order go/CODING-STANDARDS.md "go go-lang"

  # python with seeds, graphiti kept, a characteristic fragment
  check "python with seeds renders" render py python private --seeds OPTIONAL=graphiti FRAGMENTS=audit-logging
  check "python: listing matches the files" listing_matches py
  check "python: no placeholder left" no_placeholders py
  check "python: markers paired" markers_paired py
  check "python: seed rows listed" has_seed_rows py
  check "python: package dir renamed" has py/src/demo_app/__init__.py
  check "python: empty marker file kept" has py/src/demo_app/py.typed
  refute "python: marker file stays empty" test -s "$TMP/py/src/demo_app/py.typed"
  check "python: seed file" has py/pyproject.toml
  check "python: graphiti zone kept" contains py/CLAUDE.md "<!-- section:claude-graphiti -->"
  check "python: auto memory off" contains py/.claude/settings.json '"autoMemoryEnabled": false'
  check "python: project notes" contains py/docs/notes.md "<!-- section:notes-head -->"
  check "python: CLAUDE.md imports the project notes" contains py/CLAUDE.md "@docs/notes.md"
  refute "python: optional markers removed" grep -rq "template:optional" "$TMP/py"
  check "python: description taken literally" contains py/README.md 'Demo & tools / a\b | c'
  check "python: blank line between fragments" line_after py/CODING-STANDARDS.md "<!-- /fragment:python -->" ""
  check "python: characteristic fragment follows" line_before py/CODING-STANDARDS.md "<!-- fragment:audit-logging -->" ""
  check "python: characteristic fragment closes the slot" line_before py/CODING-STANDARDS.md "<!-- /module:coding-standards -->" "<!-- /fragment:audit-logging -->"
  check "python: module, language, then FRAGMENTS" slot_order py/CODING-STANDARDS.md "python python-lang audit-logging"

  # a declared fragment in FRAGMENTS comes once; a tool language gets its language fragment
  check "declared fragment in FRAGMENTS renders" render pyd python private FRAGMENTS=python-lang
  check "declared fragment in FRAGMENTS: only once" slot_order pyd/CODING-STANDARDS.md "python python-lang"
  check "tool language renders" render tl docs-only private FRAGMENTS=python-lang
  check "tool language: language fragment alone" slot_order tl/CODING-STANDARDS.md "python-lang"
  refute "tool language: placeholder text replaced" contains tl/CODING-STANDARDS.md "No stack module instantiated"

  # determinism
  check "same answers render again" render py2 python private --seeds OPTIONAL=graphiti FRAGMENTS=audit-logging
  check "rendering is deterministic (files)" diff -r "$TMP/py" "$TMP/py2"
  check "rendering is deterministic (listing)" cmp -s "$TMP/py.tsv" "$TMP/py2.tsv"

  # graphiti dropped: its zone goes, GROUP_ID is no longer needed
  check "without graphiti renders (no GROUP_ID)" render nog docs-only private --seeds -GROUP_ID
  refute "without graphiti: zone dropped" contains nog/CLAUDE.md "section:claude-graphiti"
  check "without graphiti: no placeholder left" no_placeholders nog
  check "without graphiti: auto memory off" contains nog/.claude/settings.json '"autoMemoryEnabled": false'
  check "without graphiti: project notes" contains nog/docs/notes.md "<!-- section:notes-head -->"
  check "without graphiti: CLAUDE.md imports the project notes" contains nog/CLAUDE.md "@docs/notes.md"

  # license blocks follow LICENSE_SPDX
  check "license chosen: license sentence" contains docs/CONTRIBUTING.md 'licensed under **Apache-2.0** (see `LICENSE`)'
  refute "license chosen: no TBD sentence" contains docs/CONTRIBUTING.md "No license has been chosen"
  check "TBD license renders" render tbd docs-only private -LICENSE_SPDX LICENSE_SPDX=TBD
  check "TBD license: TBD sentence" contains tbd/CONTRIBUTING.md "No license has been chosen yet (TBD)"
  refute "TBD license: no pointer to a LICENSE file" contains tbd/CONTRIBUTING.md '(see `LICENSE`)'
  refute "license blocks in OPTIONAL refused" render e9 docs-only private OPTIONAL=license

  # a stub module renders on docs-only level
  check "stub module renders" render java java private
  refute "stub module: no module files" has_module_rows java

  # warnings and refusals
  check "unknown key renders" render typo docs-only private LANG_COMENTS=x
  check "unknown key: warning" err_mentions typo LANG_COMENTS
  refute "missing MODULE refused" render e1 docs-only private -MODULE
  check "missing MODULE: message" err_mentions e1 MODULE
  refute "unknown module refused" render e2 nope private
  refute "invalid visibility refused" render e3 docs-only internal
  refute "duplicate key refused" render e4 docs-only private OWNER=other
  refute "braces in a value refused" render e5 docs-only private -PROJECT_DESCRIPTION "PROJECT_DESCRIPTION=bad {{ x"
  refute "missing value refused" render e6 docs-only private -OWNER
  check "missing value: names the placeholder" err_mentions e6 OWNER
  refute "unknown fragment refused" render e7 docs-only private FRAGMENTS=nope
  refute "invalid optional name refused" render e8 docs-only private OPTIONAL=Bad_Name
  mkdir -p "$TMP/full" && : > "$TMP/full/x"
  answers "$TMP/full.answers" docs-only private
  refute "non-empty output dir refused" $SH "$SCRIPT" render "$TEMPLATE" "$TMP/full.answers" "$TMP/full"
  $SH "$SCRIPT" > /dev/null 2>&1
  check "no command: usage exit 2" test $? -eq 2
  $SH "$SCRIPT" render "$TEMPLATE" "$TMP/full.answers" > /dev/null 2>&1
  check "missing argument: usage exit 2" test $? -eq 2

  # --- host: targets and blocks per HOST (MANIFEST § Hosts, § Policies) --------------
  check "host github renders" render hgh go public --seeds HOST=github
  check "host missing renders" render hno go public --seeds
  check "host: missing HOST renders like github" diff -r "$TMP/hgh" "$TMP/hno"
  check "host github: exactly the github targets" core_exactly hgh public github
  check "host github: Go module path" grep -qx 'module github.com/octo/demo-app' "$TMP/hgh/go.mod"
  refute "host github: no target keeps the .tmpl suffix" tmpl_left hgh
  check "host github: noreply rule kept" contains hgh/CONTRIBUTING.md 'users.noreply.github.com'
  refute "host github: no block markers left" grep -rq template:optional "$TMP/hgh"

  # .tmpl: a source next to its suffixed twin has the same target — the render stops
  cp -R "$TEMPLATE" "$TMP/tpl-dup"
  cp "$TEMPLATE/modules/go/files/go.mod.tmpl" "$TMP/tpl-dup/modules/go/files/go.mod"
  awk '{ print } /^\| `go\.mod\.tmpl` \|/ { print "| `go.mod` | seed |" }' \
    "$TEMPLATE/modules/go/MODULE.md" > "$TMP/tpl-dup/modules/go/MODULE.md"
  t_template=$TEMPLATE
  TEMPLATE=$TMP/tpl-dup
  refute "tmpl twin renders" render tdup go public --seeds
  TEMPLATE=$t_template
  check "tmpl twin: names the target" err_mentions tdup 'two sources render to go.mod'

  # ci.part.yml: no shipped module uses it now, a test module keeps the mechanism checked
  cp -R "$TEMPLATE" "$TMP/tpl-ci"
  printf '%s\n' '  extra-job:' '    runs-on: ubuntu-latest' > "$TMP/tpl-ci/modules/docs-only/ci.part.yml"
  t_template=$TEMPLATE
  TEMPLATE=$TMP/tpl-ci
  check "ci part renders" render tci docs-only public
  TEMPLATE=$t_template
  check "ci part: job below its marker" line_after tci/.github/workflows/ci.yml "# module:ci-jobs" '  extra-job:'

  check "host git renders without OWNER" render hgit go public --seeds HOST=git -OWNER
  check "host git: listing matches the files" listing_matches hgit
  check "host git: exactly the git targets" core_exactly hgit public git
  refute "host git: no .github" test -e "$TMP/hgit/.github"
  refute "host git: no renovate.json" has hgit/renovate.json
  check "host git: public-only files still there" has hgit/CODE_OF_CONDUCT.md
  check "host git: no placeholder left" no_placeholders hgit
  check "host git: bare Go module" grep -qx 'module demo-app' "$TMP/hgit/go.mod"
  refute "host git: no block markers left" grep -rq template:optional "$TMP/hgit"
  refute "host git: no GitHub noreply rule" grep -rqF 'users.noreply.github.com' \
    "$TMP/hgit/CONTRIBUTING.md" "$TMP/hgit/CODING-STANDARDS.md" "$TMP/hgit/CLAUDE.md" \
    "$TMP/hgit/HOW-TO-CODE-WITH-CLAUDE.md"
  refute "host git: no GitHub security tab" grep -qF 'Security tab' \
    "$TMP/hgit/SECURITY.md" "$TMP/hgit/CODE_OF_CONDUCT.md"
  refute "host git: no CI gate" grep -qF 'CI must be green' \
    "$TMP/hgit/CONTRIBUTING.md" "$TMP/hgit/CODING-STANDARDS.md"
  check "host git: just check is the gate" contains hgit/CONTRIBUTING.md '`just check` must be green'
  check "host git: private reporting channel to adapt" contains hgit/SECURITY.md 'contact the maintainer privately'
  for_host "$TEMPLATE/core/SECURITY.md" git sec.git
  check "host git: SECURITY is the git variant" cmp -s "$TMP/hgit/SECURITY.md" "$TMP/sec.git"

  # azure: commit address and private reporting like git, pull requests and CI like
  # GitHub (F-052 R5); the pipeline, the PR template and renovate.json, no .github.
  check "host azure renders without OWNER" render haz go private --seeds HOST=azure -OWNER
  check "host azure: listing matches the files" listing_matches haz
  check "host azure: exactly the azure targets" core_exactly haz private azure
  refute "host azure: no .github" test -e "$TMP/haz/.github"
  check "host azure: pipeline is the template's" \
    cmp -s "$TMP/haz/azure-pipelines.yml" "$TEMPLATE/core/azure-pipelines.yml"
  check "host azure: PR template from the GitHub source" \
    cmp -s "$TMP/haz/.azuredevops/pull_request_template.md" "$TEMPLATE/core/.github/PULL_REQUEST_TEMPLATE.md"
  check "host azure: renovate.json" cmp -s "$TMP/haz/renovate.json" "$TEMPLATE/core/renovate.json"
  check "host azure: no placeholder left" no_placeholders haz
  check "host azure: bare Go module" grep -qx 'module demo-app' "$TMP/haz/go.mod"
  refute "host azure: no block markers left" grep -rq template:optional "$TMP/haz"
  refute "host azure: no GitHub noreply rule" grep -rqF 'users.noreply.github.com' \
    "$TMP/haz/CONTRIBUTING.md" "$TMP/haz/CODING-STANDARDS.md" "$TMP/haz/CLAUDE.md" \
    "$TMP/haz/HOW-TO-CODE-WITH-CLAUDE.md"
  check "host azure: commit address set for the project" \
    contains haz/CODING-STANDARDS.md 'Commit email = the address set for this project'
  check "host azure: CI is the gate" contains haz/CONTRIBUTING.md 'CI must be green'
  check "host azure: pull requests section" contains haz/CONTRIBUTING.md '## Pull requests'
  for_host "$TEMPLATE/core/SECURITY.md" azure sec.azure
  check "host azure: SECURITY is the azure variant" cmp -s "$TMP/haz/SECURITY.md" "$TMP/sec.azure"
  check "host azure: private reporting like git" cmp -s "$TMP/sec.azure" "$TMP/sec.git"
  check "host azure docs-only renders" render hazd docs-only private HOST=azure -OWNER
  check "host azure: same pipeline for go and docs-only" \
    cmp -s "$TMP/haz/azure-pipelines.yml" "$TMP/hazd/azure-pipelines.yml"
  refute "host azure public refused" render hazp docs-only public --seeds HOST=azure -OWNER
  check "host azure public: refusal names the reason" err_mentions hazp 'no public projects'

  refute "host: unknown HOST refused" render hx1 docs-only private HOST=gitlab
  check "host: refusal lists the hosts" err_mentions hx1 'github azure git'
  refute "host: empty HOST refused" render hx2 docs-only private HOST=
  refute "host: host block in OPTIONAL refused" render hx3 docs-only private OPTIONAL=host-git
  check "host: OPTIONAL refusal names the derivation" err_mentions hx3 'derived from HOST'
}
