# Runner cases for tests/template-sync/run.sh — sourced, uses its helpers. They ask the
# runner itself for its plan (--plan prints the jobs and how many run at once, without
# testing), with stand-ins for getconf and nproc that report the cores.

# ru_bin NAME GETCONF NPROC — a folder $TMP/runner/NAME with stand-ins for getconf and
# nproc: each prints its value, or fails for the value "fail".
ru_bin() {
  rb_dir=$TMP/runner/$1
  mkdir -p "$rb_dir"
  for rb_tool in getconf nproc; do
    if [ "$rb_tool" = getconf ]; then rb_value=$2; else rb_value=$3; fi
    if [ "$rb_value" = fail ]; then
      printf '#!/bin/sh\nexit 1\n' > "$rb_dir/$rb_tool"
    else
      printf '#!/bin/sh\necho %s\n' "$rb_value" > "$rb_dir/$rb_tool"
    fi
    chmod +x "$rb_dir/$rb_tool"
  done
}

# ru_plan NAME JOBS [ARG…] — the plan of run.sh with the stand-ins of NAME and TEST_JOBS
# set to JOBS (empty: not set), in $TMP/runner/NAME.out and .err; fails with run.sh.
ru_plan() {
  rp_name=$1 rp_jobs=$2
  shift 2
  PATH="$TMP/runner/$rp_name:$PATH" TEST_JOBS=$rp_jobs \
    $SH "$ROOT/tests/template-sync/run.sh" --plan "$@" \
    > "$TMP/runner/$rp_name.out" 2> "$TMP/runner/$rp_name.err"
}

# ru_at_once NAME JOBS WANT — the plan of all groups lets WANT jobs run at once.
ru_at_once() {
  ru_plan "$1" "$2" || return 1
  sed -n 1p "$TMP/runner/$1.out" | grep -qE "^jobs: [0-9]+, at once: $3\$"
}

# ru_capped NAME JOBS GROUP… — with more TEST_JOBS than jobs, as many run at once as
# there are jobs.
ru_capped() {
  ru_plan "$@" || return 1
  rc_line=$(sed -n 1p "$TMP/runner/$1.out")
  rc_jobs=${rc_line#jobs: }
  rc_jobs=${rc_jobs%%,*}
  [ "$rc_line" = "jobs: $rc_jobs, at once: $rc_jobs" ]
}

# ru_refused NAME JOBS — run.sh stops with 2 and names TEST_JOBS and its range, before
# any job.
ru_refused() {
  ru_plan "$1" "$2"
  [ $? -eq 2 ] || return 1
  grep -q 'TEST_JOBS must be a number from 1 to 9999' "$TMP/runner/$1.err" &&
    ! grep -q '^jobs:' "$TMP/runner/$1.out"
}

# ru_lists NAME — the plan lists as many jobs as its first line counts.
ru_lists() {
  rl_count=$(sed -n '1s/^jobs: \([0-9]*\),.*/\1/p' "$TMP/runner/$1.out")
  [ -n "$rl_count" ] && [ "$(sed 1d "$TMP/runner/$1.out" | wc -l)" -eq "$rl_count" ]
}

run_runner_cases() {
  # The cores minus one run at once, at least one; getconf first, then nproc.
  ru_bin eight 8 fail
  check "runner: 8 cores run 7 jobs at once" ru_at_once eight '' 7
  ru_bin one 1 fail
  check "runner: 1 core runs 1 job at once" ru_at_once one '' 1
  ru_bin by-nproc fail 4
  check "runner: without getconf nproc counts the cores" ru_at_once by-nproc '' 3
  ru_bin odd x 4
  check "runner: a getconf answer that is no number falls back to nproc" \
    ru_at_once odd '' 3
  ru_bin none fail fail
  check "runner: without a core count 1 job runs at once" ru_at_once none '' 1

  # TEST_JOBS sets the number; never more than there are jobs.
  check "runner: TEST_JOBS sets how many run at once" ru_at_once eight 5 5
  check "runner: TEST_JOBS=1 runs one job at a time" ru_at_once eight 1 1
  check "runner: no more lanes than jobs" ru_capped eight 500 release-notes
  for ru_bad in 0 07 abc -2 10000 '3 4'; do
    check "runner: TEST_JOBS=$ru_bad stops the run" ru_refused eight "$ru_bad"
  done

  # The jobs: one per group and shell (and extra awk), in the order of ALL_GROUPS.
  check "runner: the plan lists each job" eval \
    'ru_plan eight "" release-notes install && ru_lists eight'
  check "runner: the jobs keep the order of the groups" eval \
    'sed -n 2p "$TMP/runner/eight.out" | grep -q "^install/" &&
     sed -n "\$p" "$TMP/runner/eight.out" | grep -q "^release-notes/"'
  check "runner: --plan with an unknown group ends with 2" eval \
    'ru_plan eight "" no-such-group; [ $? -eq 2 ]'
}
