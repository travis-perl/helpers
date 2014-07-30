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
  local log_file="$(mktemp -t log-XXXXXX)"
  ( exec "$@" > "$log_file" 2>&1 < /dev/null ) &
  local child="$!"
  local start=$(date +%s)
  local timeout="$TIMEOUT"
  [ -z "$timeout"] && timeout=$(( 30*60 ))
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
  else
    echo ' Failed!'
    cat "$log_file" 1>&2
  fi
  rm -f "$log_file"
  return "$status"
}
