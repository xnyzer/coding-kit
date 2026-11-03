# The project's git host (host) for tests/template-sync/run.sh — sourced after sync.sh,
# uses its fixture helpers.

# A git repository at $TMP/NAME whose remote origin is URL ("-" for none).
host_repo() {  # NAME URL
  mkdir -p "$TMP/$1"
  git -C "$TMP/$1" init -q
  if [ "$2" != - ]; then git -C "$TMP/$1" remote add origin "$2"; fi
}

# host for $TMP/NAME into $TMP/NAME.out; then the output is exactly FORMAT.
host_is() {  # NAME FORMAT
  ts host "$TMP/$1" > "$TMP/$1.out" 2> "$TMP/$1.err" || return 1
  file_is "$1.out" "$2"
}

# The remote line for URL is "remote KIND NAME" and the host line names HOST.
remote_is() {  # NAME URL KIND NAME HOST
  host_repo "$1" "$2"
  ts host "$TMP/$1" > "$TMP/$1.out" 2> "$TMP/$1.err" || return 1
  grep -qx "remote	$3	$4" "$TMP/$1.out" && grep -qx "host	$5	remote" "$TMP/$1.out"
}

run_host_cases() {
  # --- the remote suggests the host -------------------------------------------------
  check "host: GitHub over HTTPS" remote_is hr1 https://github.com/o/r.git github github.com github
  check "host: GitHub in scp form" remote_is hr2 git@github.com:o/r.git github github.com github
  check "host: GitHub over SSH with a port" \
    remote_is hr3 ssh://git@ssh.github.com:443/o/r.git github ssh.github.com github
  check "host: host name in capitals" remote_is hr4 https://GitHub.COM/o/r github github.com github
  check "host: credentials in the URL" \
    remote_is hr5 https://user:s3cret@example.com/o/r.git other example.com git
  refute "host: credentials never printed" grep -q s3cret "$TMP/hr5.out"
  check "host: a GitHub remote is the whole output" \
    file_is hr1.out 'host\tgithub\tremote\nremote\tgithub\tgithub.com\n'

  # Recognized hosts the kit does not support yet run as git.
  check "host: Azure DevOps over HTTPS" \
    remote_is hu1 https://dev.azure.com/org/proj/_git/r azure dev.azure.com git
  check "host: Azure DevOps reported unsupported" grep -qx 'unsupported	azure' "$TMP/hu1.out"
  check "host: Azure DevOps over SSH" \
    remote_is hu2 git@ssh.dev.azure.com:v3/org/proj/r azure ssh.dev.azure.com git
  check "host: Azure DevOps on visualstudio.com" \
    remote_is hu3 https://org.visualstudio.com/proj/_git/r azure org.visualstudio.com git
  check "host: GitLab" remote_is hu4 https://gitlab.com/o/r.git gitlab gitlab.com git
  check "host: GitLab reported unsupported" grep -qx 'unsupported	gitlab' "$TMP/hu4.out"
  check "host: GitLab in scp form" remote_is hu6 git@gitlab.com:o/r.git gitlab gitlab.com git
  check "host: Forgejo on Codeberg" remote_is hu5 git@codeberg.org:o/r.git forgejo codeberg.org git
  check "host: Forgejo reported unsupported" grep -qx 'unsupported	forgejo' "$TMP/hu5.out"

  # Any other server, and a remote on disk, are plain git.
  check "host: unknown server (GitHub Enterprise)" \
    remote_is ho1 https://ghe.example.com/o/r.git other ghe.example.com git
  refute "host: unknown server is not unsupported" grep -q '^unsupported' "$TMP/ho1.out"
  check "host: unknown server in scp form (NAS over SSH)" \
    remote_is ho2 nas:repos/r.git other nas git
  check "host: absolute path" remote_is ho3 /srv/git/r.git local - git
  check "host: file URL" remote_is ho4 file:///srv/git/r.git local - git
  check "host: relative path" remote_is ho5 ../r.git local - git
  check "host: Windows drive" remote_is ho6 C:/repos/r.git local - git
  check "host: path with a colon after a slash" remote_is ho7 ./a:b/r.git local - git

  # --- no remote -------------------------------------------------------------------
  host_repo hn1 -
  check "host: no remote" host_is hn1 'host\tgit\tnone\nremote\tnone\t-\n'
  mkdir -p "$TMP/hn2"
  check "host: no git repository" host_is hn2 'host\tgit\tnone\nremote\tnone\t-\n'
  host_repo hn3 -
  git -C "$TMP/hn3" remote add backup https://github.com/o/r.git
  git -C "$TMP/hn3" remote add nas /srv/git/r.git
  check "host: other remotes but no origin" \
    host_is hn3 'host\tgit\tnone\nremote\tnone\t-\nno-origin\tbackup,nas\n'

  host_repo hn4 /srv/git/r.git
  git -C "$TMP/hn4" remote add github https://github.com/o/r.git
  check "host: with several remotes origin counts" \
    host_is hn4 'host\tgit\tremote\nremote\tlocal\t-\n'

  # --- HOST in the answers ---------------------------------------------------------
  host_repo ha1 https://github.com/o/r.git
  put ha1/.claude/template-answers 'PROJECT_NAME=r\nHOST=github\n'
  check "host: answers and remote agree" \
    host_is ha1 'host\tgithub\tanswers\nremote\tgithub\tgithub.com\n'
  host_repo ha2 https://github.com/o/r.git
  put ha2/.claude/template-answers 'HOST=git\n'
  check "host: answers win over the remote" \
    host_is ha2 'host\tgit\tanswers\nremote\tgithub\tgithub.com\nmismatch\tgit\tgithub\n'
  host_repo ha3 https://gitlab.com/o/r.git
  put ha3/.claude/template-answers 'HOST=github\n'
  ha3_want='host\tgithub\tanswers\nremote\tgitlab\tgitlab.com\n'
  ha3_want="${ha3_want}unsupported\tgitlab\nmismatch\tgithub\tgitlab\n"
  check "host: move reported as mismatch" host_is ha3 "$ha3_want"
  host_repo ha4 https://gitlab.com/o/r.git
  put ha4/.claude/template-answers 'HOST=git\n'
  check "host: git on an unsupported host is no mismatch" \
    host_is ha4 'host\tgit\tanswers\nremote\tgitlab\tgitlab.com\nunsupported\tgitlab\n'
  host_repo ha5 -
  put ha5/.claude/template-answers 'HOST=github\n'
  check "host: GitHub project without a remote" \
    host_is ha5 'host\tgithub\tanswers\nremote\tnone\t-\nmismatch\tgithub\tnone\n'
  host_repo ha6 https://github.com/o/r.git
  put ha6/.claude/template-answers 'PROJECT_NAME=r\n'
  check "host: answers without HOST fall back to the remote" \
    host_is ha6 'host\tgithub\tremote\nremote\tgithub\tgithub.com\n'
  put ha7.answers 'HOST=git\n'
  check "host: --answers names a stand-in" \
    eval 'ts host --answers "$TMP/ha7.answers" "$TMP/ha1" > "$TMP/ha7.out"'
  check "host: the stand-in counts" grep -qx 'host	git	answers' "$TMP/ha7.out"

  # --- refused ---------------------------------------------------------------------
  host_repo hx1 -
  put hx1/.claude/template-answers 'HOST=bitbucket\n'
  refute "host: unknown HOST refused" ts host "$TMP/hx1"
  ts host "$TMP/hx1" > /dev/null 2> "$TMP/hx1.err" || true
  check "host: refusal lists the valid hosts" grep -qF 'github git' "$TMP/hx1.err"
  host_repo hx3 https://github.com/o/r.git
  put hx3/.claude/template-answers 'HOST=\n'
  refute "host: empty HOST refused" ts host "$TMP/hx3"
  put hx4.answers 'HOST=github git\n'
  refute "host: a list of hosts refused" ts host --answers "$TMP/hx4.answers" "$TMP/hx3"
  host_repo hx2 -
  put hx2/.claude/template-answers 'HOST\n'
  refute "host: invalid answers refused" ts host "$TMP/hx2"
  refute "host: missing project refused" ts host "$TMP/nope"
  refute "host: missing operand refused" ts host
  refute "host: --seeds refused" ts host --seeds "$TMP/hn1"
}
