_tap_tests=0
_tap_failed=0
_tap_planned=
_tap_done=
_tap_error=

function plan {
  if [ -n "$_tap_planned" ]; then
    echo "test already planned!" 1>&2
  elif [ "$_tap_tests" -gt 0 ]; then
    echo "can't plan after tests run!" 1>&2
  elif [ -z "$1" ]; then
    echo "need a plan" 1>&2
  elif [ "$1" == "no" ]; then
    _tap_planned="$1"
    return 0
  elif [ "$1" == "0" ]; then
    _tap_planned="0"
    echo "1..0 # SKIP $2"
    trap EXIT
    exit 0
  else
    _tap_planned="$1"
    echo "1..$1"
    return 0
  fi
  _tap_error=1
  return 1
}

function done_testing {
  if [ -n "$_tap_done" ]; then
    echo "done_testing already called" 1>&2
  elif [ -n "$_tap_planned" ] && [ "$_tap_tests" != "$_tap_planned" ]; then
    echo "$1 tests planned but $_tap_tests run" 1>&2
  elif [ -n "$1" ] && [ "$_tap_tests" != "$1" ]; then
    echo "$1 tests expected but $_tap_tests run" 1>&2
  else
    _tap_done=1
    echo "1..$_tap_tests"
    return 0
  fi
  _tap_error=1
  return 1
}

function ok {
  (( _tap_tests++ ))
  local message="ok $_tap_tests"
  [ -n "$2" ] && message="$message - $2"
  if [ "$1" != "0" ]; then
    (( _tap_failed++ ))
    message="not $message"
  fi
  echo "$message"
  return "$1"
}

function note {
  local IFS=
  while read line; do
    echo "# $line"
  done
}

function _tap_cleanup {
  if [ -n "$_tap_error" ]; then
    exit 1
  fi
  if [ -z "$_tap_done" ] && [ -n "$_tap_planned" ]; then
    if [ "$_tap_planned" == "no" ]; then
      echo "1..$_tap_tests"
    elif [ "$_tap_planned" != "$_tap_tests" ]; then
      echo "$_tap_planned tests planned but $_tap_tests run" 1>&2
      exit 1
    fi
    _tap_done=1
  fi
  if [ -z "$_tap_done" ]; then
    echo "no test plan and done_testing not seen" 1>&2
    exit 1
  fi
  exit "$_tap_failed"
}

trap _tap_cleanup EXIT

while [ "$#" != 0 ]; do
  case "$1" in
    --tests)
      plan $2
      shift
    ;;
    --tests=*)
      plan ${2:8}
      shift
    ;;
    --noplan)
      plan no
      shift
    ;;
    *)
      echo "bad argument: $1" 1>&2
      exit 1
    ;;
  esac
  shift
done
