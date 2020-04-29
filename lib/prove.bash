function prove {
  local perl="$("$(which perl)" -e'print $^X')"
  local p5l="$PERL5LIB"
  local prove
  local proveperl
  local -a args
  local old_IFS="$IFS"
  local IFS=":"
  local -a libs=($p5l)
  IFS="$old_IFS"
  local PERL5LIB="$p5l"

  for prove in $(which -a prove); do
    proveperl="$(head -1 "$prove" | awk '{ if (substr($1,1,2)=="#!") print substr($1,3) }')"
    local oldprove
    if [ "$proveperl" == "$perl" ]; then
      PERL5LIB="$p5l"
    else
      PERL5LIB=""
    fi
    # support for -j option
    "$proveperl" -M'App::Prove 2.99_03' -e1 2>/dev/null && break
  done

  if [ "$proveperl" == "$perl" ]; then
    PERL5LIB="$p5l"
  else
    for lib in "${libs[@]}"; do
      args+=(-I"$lib")
    done
    if [ -z "$HARNESS_PERL" ]; then
      local HARNESS_PERL="$perl"
      export HARNESS_PERL
    fi
    PERL5LIB=
  fi

  if [ -n "$HARNESS_VERBOSE" ] && [ "$HARNESS_VERBOSE" != "0" ]; then
    args+=(-v)
  fi

  command $prove "${args[@]}" "$@"
}
