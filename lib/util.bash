function clean-up {
  for pid; do
    kill "$pid" >/dev/null 2>&1 || continue
    wait "$pid" >/dev/null 2>&1 || true
  done
}

function show-verbose {
  "$@"
}

function show-on-fail {
  local log_file
  log_file="$(mktemp -t log-XXXXXX)"
  (
    set -e
    if [ "$(type -t "$1")" == "file" ]; then
      exec "$@" > "$log_file" 2>&1 < /dev/null
    else
      "$@" > "$log_file" 2>&1 < /dev/null
    fi
  ) &
  local child="$!"
  local start
  start="$(date +%s)"
  local timeout="$TIMEOUT"
  [ -z "$timeout" ] && timeout=$(( 30*60 ))
  local expire=$((start + timeout))
  (
    now="$start"
    while (( now < expire )); do
      sleep 5
      printf '.'
      now=$(date +%s)
    done
    kill "$child" >/dev/null 2>&1
  ) &
  local prog="$!"
  local status=0
  trap "clean-up $prog $child" SIGHUP SIGINT SIGTERM
  wait "$child" || status="$?"
  clean-up "$prog"
  trap - SIGHUP SIGINT SIGTERM
  if [ "$status" == 0 ]; then
    echo ' Done.'
  elif [ "$status" == "143" ]; then
    echo " Timeout! $((expire - start))s"
    cat "$log_file" 1>&2
  elif (( status > 128 )); then
    echo " Killed! (signal $((status - 128)))"
    cat "$log_file" 1>&2
  else
    echo ' Failed!'
    cat "$log_file" 1>&2
  fi
  rm -f "$log_file"
  return "$status"
}

function run-with-progress {
  if [ -n "$VERBOSE" ] && [ "$VERBOSE" -eq 1 ]; then
    show-verbose "$@"
  else
    show-on-fail "$@"
  fi
}

if [ "$(type -t perlbrew || true)" != "function" ]; then
  function perlbrew {
    if [ -z "$PERLBREW_ROOT" ]; then
      if [ -e "$HOME/perl5/perlbrew/etc/bashrc" ]; then
        export PERLBREW_ROOT="$HOME/perl5/perlbrew"
      fi
    fi
    unset -f perlbrew
    source "$PERLBREW_ROOT/etc/bashrc"
    perlbrew "$@"
  }
fi

function system-cores {
  local cores="$SYSTEM_CORES"
  if [ -z "$SYSTEM_CORES" ]; then
    cores="$(grep -c ^processor /proc/cpuinfo 2>/dev/null || sysctl -n hw.ncpu || echo 1)"
  fi
  echo "$((cores $@))"
}
