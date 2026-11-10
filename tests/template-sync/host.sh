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

# commit-email with the personal config $TMP/ENV for $TMP/NAME; the output is FORMAT.
ce_is() {  # NAME ENV FORMAT
  ts commit-email "$TMP/$2" "$TMP/$1" > "$TMP/$1.ce" 2> "$TMP/$1.ce.err" || return 1
  file_is "$1.ce" "$3"
}

# remote-check URL from $TMP with extra environment (VAR=value…), its output in
# $TMP/NAME.rc and the ssh stand-in's log in $TMP/NAME.ssh; then the output is FORMAT.
# GIT_SSH_VARIANT makes git treat the stand-in as OpenSSH: it passes stderr through as
# it comes (for an unknown ssh command only at its end) and accepts a port.
rc_is() {  # NAME URL FORMAT [VAR=value…]
  rc_name=$1 rc_url=$2 rc_want=$3
  shift 3
  # $SH is one word, so it stays unquoted.
  (cd "$TMP" && env GIT_SSH_VARIANT=ssh FAKE_SSH_LOG="$TMP/$rc_name.ssh" "$@" \
    $SH "$SCRIPT" remote-check "$rc_url") \
    > "$TMP/$rc_name.rc" 2> "$TMP/$rc_name.rc.err" || return 1
  file_is "$rc_name.rc" "$rc_want"
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

  # Azure DevOps Services in every form of its clone URLs.
  check "host: Azure DevOps over HTTPS" \
    remote_is hz1 https://dev.azure.com/org/proj/_git/r azure dev.azure.com azure
  check "host: an Azure DevOps remote is the whole output" \
    file_is hz1.out 'host\tazure\tremote\nremote\tazure\tdev.azure.com\n'
  check "host: Azure DevOps over HTTPS with the organization as user" \
    remote_is hz2 https://org@dev.azure.com/org/proj/_git/r azure dev.azure.com azure
  refute "host: the organization user is not printed" grep -q 'org@' "$TMP/hz2.out"
  check "host: Azure DevOps over SSH" \
    remote_is hz3 git@ssh.dev.azure.com:v3/org/proj/r azure ssh.dev.azure.com azure
  check "host: Azure DevOps on visualstudio.com" \
    remote_is hz4 https://org.visualstudio.com/proj/_git/r azure org.visualstudio.com azure
  check "host: Azure DevOps over SSH on visualstudio.com" \
    remote_is hz5 org@vs-ssh.visualstudio.com:v3/org/proj/r azure vs-ssh.visualstudio.com azure
  check "host: Azure DevOps with a token in the URL" \
    remote_is hz6 https://org:t0ken42@dev.azure.com/org/proj/_git/r azure dev.azure.com azure
  refute "host: the Azure token is never printed" grep -q t0ken42 "$TMP/hz6.out"
  check "host: Azure DevOps Server on its own host name is plain git" \
    remote_is hz7 https://tfs.example.com/coll/proj/_git/r other tfs.example.com git

  # Recognized hosts the kit does not support yet run as git.
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
  host_repo ha8 https://dev.azure.com/org/proj/_git/r
  put ha8/.claude/template-answers 'HOST=git\n'
  check "host: git on an Azure remote is a mismatch" \
    host_is ha8 'host\tgit\tanswers\nremote\tazure\tdev.azure.com\nmismatch\tgit\tazure\n'
  host_repo ha9 git@ssh.dev.azure.com:v3/org/proj/r
  put ha9/.claude/template-answers 'HOST=azure\n'
  check "host: azure in the answers" \
    host_is ha9 'host\tazure\tanswers\nremote\tazure\tssh.dev.azure.com\n'
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

  # --- commit-email: the address of the project's host -------------------------------
  CE_GH='1+octo@users.noreply.github.com'
  put ce.env "CODING_KIT_EMAIL_GITHUB=\"$CE_GH\"\nCODING_KIT_EMAIL_GIT=me@example.org\n"
  host_repo ce1 https://github.com/o/r.git
  check "commit-email: GitHub project gets the GitHub address" \
    ce_is ce1 ce.env "host\tgithub\tremote\nemail\tconfig\tCODING_KIT_EMAIL_GITHUB\t$CE_GH\n"
  host_repo ce2 -
  check "commit-email: plain-git project gets the git address" \
    ce_is ce2 ce.env 'host\tgit\tnone\nemail\tconfig\tCODING_KIT_EMAIL_GIT\tme@example.org\n'
  put ce-gh.env "CODING_KIT_EMAIL_GITHUB=$CE_GH\n"
  check "commit-email: never the address of another host" \
    ce_is ce2 ce-gh.env 'host\tgit\tnone\nemail\tmissing\tCODING_KIT_EMAIL_GIT\t-\n'
  put ce-old.env "CODING_KIT_GIT_NOREPLY_EMAIL=\"$CE_GH\"\n"
  check "commit-email: the old key counts for GitHub" \
    ce_is ce1 ce-old.env "host\tgithub\tremote\nemail\tlegacy\tCODING_KIT_GIT_NOREPLY_EMAIL\t$CE_GH\n"
  check "commit-email: the old key never counts for git" \
    ce_is ce2 ce-old.env 'host\tgit\tnone\nemail\tmissing\tCODING_KIT_EMAIL_GIT\t-\n'
  put ce-both.env "CODING_KIT_GIT_NOREPLY_EMAIL=old@example.org\nCODING_KIT_EMAIL_GITHUB=$CE_GH\n"
  check "commit-email: the new key wins over the old one" \
    ce_is ce1 ce-both.env "host\tgithub\tremote\nemail\tconfig\tCODING_KIT_EMAIL_GITHUB\t$CE_GH\n"
  put ce-empty.env "CODING_KIT_EMAIL_GITHUB=\"\"\nCODING_KIT_GIT_NOREPLY_EMAIL=$CE_GH\n"
  check "commit-email: an empty key falls back to the old one" \
    ce_is ce1 ce-empty.env "host\tgithub\tremote\nemail\tlegacy\tCODING_KIT_GIT_NOREPLY_EMAIL\t$CE_GH\n"
  check "commit-email: no personal config" \
    ce_is ce1 ce-none.env 'host\tgithub\tremote\nemail\tmissing\tCODING_KIT_EMAIL_GITHUB\t-\n'
  put ce-bad.env 'CODING_KIT_EMAIL_GIT="not an address"\n'
  check "commit-email: no address form is invalid" \
    ce_is ce2 ce-bad.env 'host\tgit\tnone\nemail\tinvalid\tCODING_KIT_EMAIL_GIT\tnot an address\n'
  put ce-sub.env 'CODING_KIT_EMAIL_GIT="$(id)@example.org"\n'
  check "commit-email: a command substitution is invalid" \
    ce_is ce2 ce-sub.env 'host\tgit\tnone\nemail\tinvalid\tCODING_KIT_EMAIL_GIT\t$(id)@example.org\n'
  put ce-tick.env "CODING_KIT_EMAIL_GIT='\`id\`@example.org'\n"
  check "commit-email: a backtick is invalid" \
    ce_is ce2 ce-tick.env "host\tgit\tnone\nemail\tinvalid\tCODING_KIT_EMAIL_GIT\t\`id\`@example.org\n"
  put ce-nodot.env 'CODING_KIT_EMAIL_GIT=me@localhost\n'
  check "commit-email: a domain without a dot is invalid" \
    ce_is ce2 ce-nodot.env 'host\tgit\tnone\nemail\tinvalid\tCODING_KIT_EMAIL_GIT\tme@localhost\n'
  put ce-run.env 'CODING_KIT_EMAIL_GIT="$(touch ce-ran)@example.org"\n'
  check "commit-email: the personal config is never executed" \
    eval '(cd "$TMP" && ts commit-email "$TMP/ce-run.env" "$TMP/ce2" > /dev/null)'
  refute "commit-email: no command ran" test -e "$TMP/ce-ran"
  host_repo ce3 https://github.com/o/r.git
  put ce3/.claude/template-answers 'HOST=git\n'
  check "commit-email: HOST of the answers decides" \
    ce_is ce3 ce.env 'host\tgit\tanswers\nemail\tconfig\tCODING_KIT_EMAIL_GIT\tme@example.org\n'
  put ce4.answers 'HOST=git\n'
  check "commit-email: --answers names a stand-in" \
    eval 'ts commit-email --answers "$TMP/ce4.answers" "$TMP/ce.env" "$TMP/ce1" > "$TMP/ce4.out"'
  check "commit-email: the stand-in counts" grep -qx 'host	git	answers' "$TMP/ce4.out"
  host_repo ce5 https://dev.azure.com/org/proj/_git/r
  put ce-az.env "CODING_KIT_EMAIL_GITHUB=$CE_GH\nCODING_KIT_EMAIL_AZURE=me@work.example.com\nCODING_KIT_EMAIL_GIT=me@example.org\n"
  check "commit-email: Azure project gets the Azure address" \
    ce_is ce5 ce-az.env 'host\tazure\tremote\nemail\tconfig\tCODING_KIT_EMAIL_AZURE\tme@work.example.com\n'
  check "commit-email: Azure without its address is missing" \
    ce_is ce5 ce.env 'host\tazure\tremote\nemail\tmissing\tCODING_KIT_EMAIL_AZURE\t-\n'
  check "commit-email: the old GitHub key never counts for Azure" \
    ce_is ce5 ce-old.env 'host\tazure\tremote\nemail\tmissing\tCODING_KIT_EMAIL_AZURE\t-\n'
  put ce-broken.env 'CODING_KIT_EMAIL_GIT="open\n'
  refute "commit-email: invalid personal config refused" ts commit-email "$TMP/ce-broken.env" "$TMP/ce2"
  refute "commit-email: missing project refused" ts commit-email "$TMP/ce.env" "$TMP/nope"
  refute "commit-email: missing operand refused" ts commit-email "$TMP/ce.env"

  # --- default-host: the host a new project starts on ---------------------------------
  put dh-git.env 'CODING_KIT_DEFAULT_HOST=git\n'
  check "default-host: the key counts" \
    eval 'ts default-host "$TMP/dh-git.env" > "$TMP/dh1.out" && file_is dh1.out "default-host\tgit\tconfig\n"'
  check "default-host: without the key github" \
    eval 'ts default-host "$TMP/ce.env" > "$TMP/dh2.out" && file_is dh2.out "default-host\tgithub\tnone\n"'
  check "default-host: without a personal config github" \
    eval 'ts default-host "$TMP/dh-none.env" > "$TMP/dh3.out" && file_is dh3.out "default-host\tgithub\tnone\n"'
  put dh-az.env 'CODING_KIT_DEFAULT_HOST=azure\n'
  check "default-host: azure counts" \
    eval 'ts default-host "$TMP/dh-az.env" > "$TMP/dh6.out" && file_is dh6.out "default-host\tazure\tconfig\n"'
  put dh-bad.env 'CODING_KIT_DEFAULT_HOST=gitlab\n'
  check "default-host: an unknown host is reported" \
    eval 'ts default-host "$TMP/dh-bad.env" > "$TMP/dh4.out" && file_is dh4.out "default-host\tgithub\tinvalid\tgitlab\n"'
  put dh-empty.env 'CODING_KIT_DEFAULT_HOST=""\n'
  check "default-host: an empty key counts as none" \
    eval 'ts default-host "$TMP/dh-empty.env" > "$TMP/dh5.out" && file_is dh5.out "default-host\tgithub\tnone\n"'
  refute "default-host: missing operand refused" ts default-host

  # --- remote-check: may a project connect to a clone URL? --------------------------
  # Offline: local repositories, and a stand-in for ssh that logs its arguments and
  # either fails with the message the spike saw on Azure or serves a local repository
  # after the warning OpenSSH writes to stderr on success.
  git init -q --bare "$TMP/rc-empty.git"
  git init -q "$TMP/rc-full"
  tgit "$TMP/rc-full" commit -q --allow-empty -m init
  # FAKE_SSH_ERR is the message it fails with; FAKE_SSH_SLEEP holds the connection open
  # that many seconds first, as Azure does after TF401019. Without FAKE_SSH_ERR it runs
  # the command git asks for (its last argument) on the local repository.
  cat > "$TMP/rc-ssh" << 'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_SSH_LOG"
if [ -n "${FAKE_SSH_ERR:-}" ]; then printf '%s\n' "$FAKE_SSH_ERR" >&2; fi
if [ -n "${FAKE_SSH_SLEEP:-}" ]; then sleep "$FAKE_SSH_SLEEP"; fi
if [ -n "${FAKE_SSH_ERR:-}" ]; then exit 255; fi
echo '** WARNING: connection is not using a post-quantum key exchange algorithm.' >&2
for a; do last=$a; done
eval "$last"
EOF
  chmod +x "$TMP/rc-ssh"
  mkdir -p "$TMP/rc-bin"
  cp "$TMP/rc-ssh" "$TMP/rc-bin/ssh"
  RC_SSH="GIT_SSH_COMMAND=sh $TMP/rc-ssh"
  RC_TF='remote: TF401019: The Git repository with name or identifier r does not exist or you do not have permissions for the operation you are attempting.'
  RC_AZ='remote\tazure\tssh.dev.azure.com\n'

  check "remote-check: empty repository" rc_is rc1 "$TMP/rc-empty.git" 'remote\tlocal\t-\nreach\tempty\n'
  check "remote-check: repository with refs" rc_is rc2 "$TMP/rc-full" 'remote\tlocal\t-\nreach\trefs\t2\n'
  check "remote-check: missing repository" rc_is rc3 "$TMP/nope.git" 'remote\tlocal\t-\nreach\tnot-found\n'
  check "remote-check: ssh warning on success is no failure" \
    rc_is rc4 "fakehost:$TMP/rc-empty.git" 'remote\tother\tfakehost\nreach\tempty\n' "$RC_SSH"
  check "remote-check: Azure TF401019" \
    rc_is rc5 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\tnot-found\n" "$RC_SSH" "FAKE_SSH_ERR=$RC_TF"
  refute "remote-check: the URL is never printed" grep -q 'v3/org' "$TMP/rc5.rc"
  refute "remote-check: git's messages are never printed" grep -q TF401019 "$TMP/rc5.rc"
  refute "remote-check: the user's ssh command stays as it is" grep -q BatchMode "$TMP/rc5.ssh"
  rc_start=$(date +%s)
  check "remote-check: TF401019 on a connection Azure keeps open" \
    rc_is rc16 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\tnot-found\n" "$RC_SSH" \
    "FAKE_SSH_ERR=$RC_TF" FAKE_SSH_SLEEP=20
  check "remote-check: stops at TF401019 without waiting" test $(($(date +%s) - rc_start)) -lt 10
  check "remote-check: no answer within the limit" \
    rc_is rc17 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\ttimeout\n" "$RC_SSH" \
    FAKE_SSH_SLEEP=20 REMOTE_CHECK_SECONDS=1
  refute "remote-check: a limit that is no number is refused" \
    rc_is rc18 "$TMP/rc-empty.git" 'x' REMOTE_CHECK_SECONDS=soon
  check "remote-check: unknown host key" \
    rc_is rc6 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\thost-key\n" "$RC_SSH" \
    'FAKE_SSH_ERR=Host key verification failed.'
  check "remote-check: timeout" \
    rc_is rc7 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\ttimeout\n" "$RC_SSH" \
    'FAKE_SSH_ERR=ssh: connect to host ssh.dev.azure.com port 22: Operation timed out'
  check "remote-check: key not accepted" \
    rc_is rc8 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\tdenied\n" "$RC_SSH" \
    'FAKE_SSH_ERR=git@ssh.dev.azure.com: Permission denied (publickey).'
  check "remote-check: anything else failed" \
    rc_is rc9 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\tfailed\n" "$RC_SSH" \
    'FAKE_SSH_ERR=kex_exchange_identification: read: Connection reset by peer'
  check "remote-check: ssh asks nothing without an own ssh command" \
    rc_is rc10 git@ssh.dev.azure.com:v3/org/proj/r "${RC_AZ}reach\tfailed\n" \
    GIT_SSH_COMMAND= GIT_SSH= GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
    "PATH=$TMP/rc-bin:$PATH" FAKE_SSH_ERR=x
  check "remote-check: ssh in batch mode" grep -q 'BatchMode=yes' "$TMP/rc10.ssh"
  check "remote-check: password in an HTTPS URL" \
    rc_is rc11 https://org:t0ken42@dev.azure.com/org/proj/_git/r \
    'remote\tazure\tdev.azure.com\ncredentials\n'
  refute "remote-check: the token is never printed" grep -q t0ken42 "$TMP/rc11.rc"
  check "remote-check: password in an SSH URL" \
    rc_is rc12 ssh://u:t0ken42@fakehost/r.git 'remote\tother\tfakehost\ncredentials\n' "$RC_SSH"
  refute "remote-check: with credentials nothing is contacted" test -e "$TMP/rc12.ssh"
  check "remote-check: the organization as user is no credential" \
    rc_is rc13 org@vs-ssh.visualstudio.com:v3/org/proj/r \
    'remote\tazure\tvs-ssh.visualstudio.com\nreach\tnot-found\n' "$RC_SSH" "FAKE_SSH_ERR=$RC_TF"
  check "remote-check: a port is no credential" \
    rc_is rc14 "ssh://git@fakehost:22$TMP/rc-empty.git" 'remote\tother\tfakehost\nreach\tempty\n' \
    "$RC_SSH"
  # A tab or line break in the host name must not forge a line of the output.
  RC_FORGED=$(printf 'https://a\nreach\tempty/x')
  check "remote-check: forged host name runs" \
    eval 'ts remote-check "$RC_FORGED" > "$TMP/rc19.rc" 2> /dev/null'
  check "remote-check: forged host name is not printed" \
    eval 'sed -n 1p "$TMP/rc19.rc" | grep -qx "remote	other	-"'
  check "remote-check: forged host name gives two lines" \
    test "$(wc -l < "$TMP/rc19.rc" | tr -d ' ')" -eq 2
  refute "remote-check: no forged result line" grep -qx 'reach	empty' "$TMP/rc19.rc"
  host_repo hf1 "$RC_FORGED"
  check "host: forged host name of origin is not printed" \
    host_is hf1 'host\tgit\tremote\nremote\tother\t-\n'
  rc_is rc15 "ext::sh -c touch% $TMP/rc-ext" 'remote\tother\text\nreach\tfailed\n' > /dev/null 2>&1
  refute "remote-check: the ext transport never runs" test -e "$TMP/rc-ext"
  refute "remote-check: empty URL refused" ts remote-check ''
  refute "remote-check: URL as an option refused" ts remote-check -oProxyCommand=x
  refute "remote-check: long option refused" ts remote-check --upload-pack=x
  refute "remote-check: missing operand refused" ts remote-check
  refute "remote-check: two operands refused" ts remote-check "$TMP/rc-empty.git" x
  refute "remote-check: --answers refused" ts remote-check --answers "$TMP/ha7.answers" x

  # --- refused ---------------------------------------------------------------------
  host_repo hx1 -
  put hx1/.claude/template-answers 'HOST=bitbucket\n'
  refute "host: unknown HOST refused" ts host "$TMP/hx1"
  ts host "$TMP/hx1" > /dev/null 2> "$TMP/hx1.err" || true
  check "host: refusal lists the valid hosts" grep -qF 'github azure git' "$TMP/hx1.err"
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
