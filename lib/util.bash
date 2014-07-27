function clean-up {
  kill "$1" || true
  wait "$1" 2>/dev/null || true
}

function show-verbose {
  "$@"
}

function show-on-fail {
  (
    while true; do
      sleep 5
      printf '.'
    done
  ) &
  local prog="$!"
  trap "clean-up $prog; echo 'Aborted.'; exit 1" SIGHUP SIGINT SIGTERM
  local log_file="$(mktemp -t log-XXXXXX)"
  local status
  if "$@" > "$log_file" 2>&1; then
    status="$?"
  else
    status="$?"
  fi
  clean-up $prog
  trap - SIGHUP SIGINT SIGTERM
  if [ "$status" != 0 ]; then
    echo ' Failed!'
    cat "$log_file" 1>&2
  else
    echo ' Done.'
  fi
  rm "$log_file"
  return "$status"
}
