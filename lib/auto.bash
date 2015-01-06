function setup-auto {
  echo "$ build-perl" 1>&2
  build-perl || return $?
  echo "$ perl -V" 1>&2
  perl -V || return $?
  echo "$ build-dist" 1>&2
  build-dist || return $?
  echo "$ cd $BUILD_DIR" 1>&2
  cd $BUILD_DIR || return $?
  [ -n "$HELPERS_DEBUG" ] && echo "## overriding cpanm" 1>&2
  function cpanm {
    if [ "$*" == "--quiet --installdeps --notest ." ]; then
      cpan-install --deps --coverage
    else
      command cpanm "$@"
    fi
  }
  if [ -e 'Build.PL' ]; then
    [ -n "$HELPERS_DEBUG" ] && echo "## overriding perl (Build.PL)" 1>&2
    function perl {
      command perl "$@" || return $?
      if [ "$#" == 1 ] && [ "$1" == "Build.PL" ]; then
        coverage-setup
        ./Build || return $?
        local blib
        if [ "$(find blib/arch/ -type f ! -empty)" == "" ]; then
          blib="-l"
        else
          blib="-b"
        fi
        local coverage_cmd
        [ "$COVERAGE" -eq 0 ] || coverage_cmd="cover $@ $(_coverage-opts) || true"
        mv Build Build.run
        cat > Build <<END
#!/bin/sh
set -e

if [ "\$#" == "1" ] && [ "\$1" == "test" ]; then
  ./Build.run
  . "$HELPERS_ROOT/lib/prove.bash"
  prove $blib -r -s -j$(test-jobs) $(test-files)
  $coverage_cmd
else
  exec ./Build.run "\$@"
fi
END
        chmod +x Build
      fi
    }
  else
    [ -n "$HELPERS_DEBUG" ] && echo "## overriding make" 1>&2
    function make {
      if [ "$#" == 1 ] && [ "$1" == "test" ]; then
        coverage-setup
        command make
        local blib
        if [ "$(find blib/arch/ -type f ! -empty)" == "" ]; then
          blib="-l"
        else
          blib="-b"
        fi
        prove $blib -r -s -j$(test-jobs) $(test-files) || return "$?"
        coverage-report
      else
        command make "$@"
      fi
    }
  fi
}
