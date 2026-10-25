# Detect cases for tests/template-sync/run.sh — sourced after sync.sh, uses the helpers
# of both (put, tgit, answers, render). Projects are git repositories below $TMP and are
# matched against the bundled template.

# dt NAME [--changed] [--answers FILE] [--registry FILE] PROJECT [SIGNAL…] — output in
# $TMP/NAME.tsv, stderr in NAME.err.
dt() {
  d_name=$1
  shift
  d_opts=
  while :; do
    case ${1:-} in
      --changed)
        d_opts="$d_opts $1"
        shift
        ;;
      --answers | --registry)
        d_opts="$d_opts $1 $2"
        shift 2
        ;;
      *) break ;;
    esac
  done
  d_project=$TMP/$1
  shift
  # The options are split on purpose; temp paths carry no spaces.
  $SH "$SCRIPT" detect $d_opts "$TEMPLATE" "$d_project" "$@" \
    > "$TMP/$d_name.tsv" 2> "$TMP/$d_name.err"
}

# The hit KIND ITEM exists and has STATE.
hit_is() {  # NAME KIND ITEM STATE
  awk -F'\t' -v k="$2" -v i="$3" -v s="$4" '
    $1 == k && $2 == i { found = 1; ok = ($3 == s) }
    END { exit !(found && ok) }' "$TMP/$1.tsv"
}

no_hit() {  # NAME KIND ITEM
  ! awk -F'\t' -v k="$2" -v i="$3" '$1 == k && $2 == i { f = 1 } END { exit !f }' "$TMP/$1.tsv"
}

# The evidence of hit KIND ITEM contains TEXT.
evidence_has() {  # NAME KIND ITEM TEXT
  awk -F'\t' -v k="$2" -v i="$3" -v t="$4" '
    $1 == k && $2 == i && index($4, t) { f = 1 }
    END { exit !f }' "$TMP/$1.tsv"
}

no_state() {  # NAME STATE — no hit has STATE
  ! cut -f3 "$TMP/$1.tsv" | grep -qx -- "$2"
}

# A complete result line, fields joined by tabs.
line_is() {  # NAME KIND ITEM STATE EVIDENCE
  grep -qxF -- "$(printf '%s\t%s\t%s\t%s' "$2" "$3" "$4" "$5")" "$TMP/$1.tsv"
}

# Answers for a project at its usual place.
project_answers() {  # PROJECT MODULE
  mkdir -p "$TMP/$1/.claude"
  answers "$TMP/$1/.claude/template-answers" "$2" private
}

run_detect_cases() {
  DS='<!-- module:coding-standards -->'
  DE='<!-- /module:coding-standards -->'

  # --- every reader, hits and non-hits ---------------------------------------------
  put dp/package.json '{\n  "name": "demo",\n  "scripts": { "express": "node x" },\n  "dependencies": {\n    "react": "^19.0.0",\n    "next": "15.0.0"\n  },\n  "devDependencies": { "prisma": "6.0.0" }\n}\n'
  put dp/apps/web/package.json '{"name":"web","dependencies":{"react-dom":"19","@prisma/client":"6"},"peerDependencies":{"hono":"4"}}'
  put dp/ignored/package.json '{"dependencies":{"koa":"2"}}\n'
  put dp/.gitignore 'ignored/\n'
  put dp/pyproject.toml '[project]\nname = "demo"\ndependencies = [\n  "FastAPI[standard]>=0.115",  # web\n  # "flask>=3",\n]\n\n[dependency-groups]\ndev = ["pytest", {include-group = "django"}]\n\n[tool.poetry.dependencies]\npython = "^3.12"\nLitestar = "^2"\n'
  put dp/requirements.txt '# pinned\n-r base.txt\nDjango>=5.1  # web\nhttps://example.com/pkg.whl\ngit+https://example.com/repo.git\n'
  put dp/go.mod 'module example.com/demo\n\ngo 1.23\n\nrequire github.com/go-chi/chi/v5 v5.1.0\n\nrequire (\n\tgithub.com/labstack/echo/v4 v4.12.0\n\tgithub.com/gin-gonic/gin v1.10.0 // indirect\n)\n'
  put dp/mise.toml '[tools]\njust = "1"\n"node" = "22"\npython = "3.14"\n\n[tools.go]\nversion = "1.23"\n\n[settings]\nlockfile = true\n'
  put dp/Dockerfile.prod 'FROM scratch\n'
  put dp/deploy/nginx/site.conf 'server {}\n'
  put dp/docs/compose-notes.md 'notes\n'
  put dp/.claude/template-base/compose.yaml 'services: {}\n'
  put dp/CODING-STANDARDS.md "# Standards\n$DS\n<!-- fragment:ts-node -->\nx\n<!-- /fragment:ts-node -->\n\n<!-- fragment:react -->\ny\n<!-- /fragment:react -->\n$DE\n<!-- fragment:nextjs -->\n"
  put dp/.claude/convention-overrides.md '# Convention Overrides\n\n## Files\n\n| Path | Kind | Reason | Since |\n|------|------|--------|-------|\n\n## Rules\n\n| Rule | Deviation | Reason | Since |\n|------|-----------|--------|-------|\n| `module:go` | Go only for one helper | reason | 2026-10-25 |\n| fragment:docker | images built elsewhere | reason | 2026-10-25 |\n| Living docs | other rule | reason | 2026-10-25 |\n'
  project_answers dp ts-node
  tgit "$TMP/dp" init -q
  tgit "$TMP/dp" add -A
  tgit "$TMP/dp" commit -q -m base
  put dp/compose.yaml 'services: {}\n'
  check "detect runs" dt d dp
  check "module of the answers: covered" hit_is d module ts-node covered
  check "several paths: first one plus count" \
    evidence_has d module ts-node 'file:package.json (apps/web/package.json +1)'
  check "missing module with every signal" line_is d module python missing \
    'file:pyproject.toml (pyproject.toml), file:requirements*.txt (requirements.txt), tool:python (mise.toml)'
  check "module declined by a Rules row" hit_is d module go declined
  check "[tools.NAME] table counts" evidence_has d module go 'tool:go (mise.toml)'
  check "modules come first" test "$(sed -n 1p "$TMP/d.tsv" | cut -f1)" = module
  check "fragment marker in the slot: covered" hit_is d fragment react covered
  check "fragment marker outside the slot does not count" hit_is d fragment nextjs missing
  check "minified JSON and scoped names" evidence_has d fragment prisma 'npm:@prisma/client (apps/web/package.json)'
  check "peerDependencies count" evidence_has d fragment api-design 'npm:hono (apps/web/package.json)'
  refute "keys outside the dependency tables do not count" evidence_has d fragment api-design 'npm:express'
  refute "ignored files do not count" evidence_has d fragment api-design 'npm:koa'
  check "pyproject: extras dropped, name normalized" evidence_has d fragment api-design 'pypi:fastapi (pyproject.toml)'
  refute "pyproject: commented entry ignored" evidence_has d fragment api-design 'pypi:flask'
  check "inline table strings are not names; requirements read" \
    evidence_has d fragment api-design 'pypi:django (requirements.txt)'
  check "poetry keys count" evidence_has d fragment api-design 'pypi:litestar (pyproject.toml)'
  check "go.mod: single require with major suffix" evidence_has d fragment api-design 'go:github.com/go-chi/chi (go.mod)'
  check "go.mod: require block" evidence_has d fragment api-design 'go:github.com/labstack/echo (go.mod)'
  refute "go.mod: indirect requirement ignored" evidence_has d fragment api-design 'gin-gonic'
  check "fragment declined, backticks optional" hit_is d fragment docker declined
  check "file glob on the name" evidence_has d fragment docker 'file:Dockerfile* (Dockerfile.prod)'
  check "untracked file counts, snapshot does not" evidence_has d fragment docker 'file:compose.y*ml (compose.yaml)'
  check "file glob with a slash matches the path" line_is d fragment nginx missing 'file:*nginx/* (deploy/nginx/site.conf)'
  check "no signal, no hit" no_hit d fragment astro
  check "characteristic triggers are never detected" no_hit d fragment audit-logging

  # --- --changed: only signals HEAD does not have ----------------------------------
  put dc/package.json '{\n  "dependencies": { "react": "19" }\n}\n'
  put dc/Dockerfile 'FROM scratch\n'
  put dc/go.mod 'module example.com/c\n\nrequire github.com/labstack/echo/v4 v4.12.0\n'
  project_answers dc docs-only
  tgit "$TMP/dc" init -q
  tgit "$TMP/dc" add -A
  tgit "$TMP/dc" commit -q -m base
  put dc/package.json '{\n  "dependencies": { "react": "19", "next": "15" }\n}\n'
  put dc/svc/Dockerfile.dev 'FROM scratch\n'
  put dc/go.mod 'module example.com/c\n\nrequire github.com/labstack/echo/v5 v5.0.0\n'
  put dc/pyproject.toml '[project]\ndependencies = ["flask"]\n'
  check "detect --changed runs" dt c --changed dc
  check "--changed: added dependency" line_is c fragment nextjs missing 'npm:next (package.json)'
  check "--changed: dependency HEAD had" no_hit c fragment react
  check "--changed: file signal HEAD had" no_hit c fragment docker
  check "--changed: new major of a known module path is not new" refute_go_evidence
  check "--changed: new untracked manifest" evidence_has c fragment api-design 'pypi:flask (pyproject.toml)'
  check "--changed: new module signal" line_is c module python missing 'file:pyproject.toml (pyproject.toml)'
  check "--changed: module signal HEAD had" no_hit c module ts-node
  put dn/package.json '{"dependencies":{"react":"19"}}\n'
  tgit "$TMP/dn" init -q
  check "--changed without HEAD: everything is new" dt n --changed dn
  check "--changed without HEAD: hit" hit_is n fragment react missing
  check "no answers: no module rows" no_hit n module ts-node
  check "no answers: note on stderr" err_mentions n 'module check skipped'

  # --- given signals ------------------------------------------------------------------
  check "detect with signals runs" dt g dp npm:next file:infra/Dockerfile pypi:Flask \
    go:github.com/labstack/echo/v5 tool:node
  check "given: dependency" line_is g fragment nextjs missing 'npm:next (given)'
  check "given: planned file matched by glob" line_is g fragment docker declined 'file:Dockerfile* (infra/Dockerfile)'
  check "given: PyPI name normalized" evidence_has g fragment api-design 'pypi:flask (given)'
  check "given: major suffix" evidence_has g fragment api-design 'go:github.com/labstack/echo (given)'
  check "given: module state from the answers" hit_is g module ts-node covered
  check "given: the tree is not read" no_hit g fragment react
  mkdir -p "$TMP/plain"
  check "given: no git needed" dt p plain npm:react
  check "given: hit in a plain folder" hit_is p fragment react missing
  refute "unknown signal type refused" dt x dp nmp:next
  refute "signal without type refused" dt x dp react
  refute "signal without value refused" dt x dp npm:
  refute "--changed with signals refused" dt x --changed dp npm:next
  refute "scan outside git refused" dt x plain

  # --- stand-ins: answers and registry prepared outside .claude/ -----------------------
  put do/mise.toml '[tools]\npython = "3.14"\n'
  tgit "$TMP/do" init -q
  answers "$TMP/do.answers" docs-only private
  put do.reg '## Rules\n\n| Rule | Deviation | Reason | Since |\n|---|---|---|---|\n| `module:python` | tool language | stdlib scripts | 2026-10-25 |\n'
  check "detect with stand-ins runs" dt o --answers "$TMP/do.answers" --registry "$TMP/do.reg" do
  check "stand-ins: module check runs, decline read" hit_is o module python declined
  check "without stand-ins: no answers, no module rows" dt o2 do
  check "without stand-ins: module check skipped" no_hit o2 module python
  refute "detect takes no --snapshot" ts detect --snapshot "$TMP/op.snap" "$TEMPLATE" "$TMP/do"

  # --- a fresh render detects only its own module ------------------------------------
  for f_m in ts-node python go docs-only; do
    render "fr-$f_m" "$f_m" private --seeds
    mkdir -p "$TMP/fr-$f_m/.claude"
    cp "$TMP/fr-$f_m.answers" "$TMP/fr-$f_m/.claude/template-answers"
    tgit "$TMP/fr-$f_m" init -q
    check "fresh $f_m: detect runs" dt "fr-$f_m.d" "fr-$f_m"
    check "fresh $f_m: nothing missing" no_state "fr-$f_m.d" missing
    if [ "$f_m" = docs-only ]; then
      check "fresh docs-only: no hit at all" test ! -s "$TMP/fr-docs-only.d.tsv"
    else
      check "fresh $f_m: own module covered" hit_is "fr-$f_m.d" module "$f_m" covered
    fi
  done
}

# No go: signal in the evidence of api-design in the --changed run (echo/v4 → echo/v5).
refute_go_evidence() {
  ! evidence_has c fragment api-design 'go:'
}
