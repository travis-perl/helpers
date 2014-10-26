function setup-auto {
  build-perl
  perl -V
  build-dist
  cd $BUILD_DIR
  function cpanm {
    if [ "$*" == "--quiet --installdeps --notest ." ]; then
      cpan-install --deps --coverage
    else
      command cpanm "$@"
    fi
  }
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
      prove $blib -r -s -j$(test-jobs) $(test-files) \
        && coverage-report
    else
      command make "$@"
    fi
  }
  function perl {
    command perl "$@"
    if [ "$#" == 1 ] && [ "$1" == "Build.PL" ]; then
      coverage-setup
      ./Build || return $?
      local blib
      if [ "$(find blib/arch/ -type f ! -empty)" == "" ]; then
        blib="-l"
      else
        blib="-b"
      fi
      prove $blib -r -s -j$(test-jobs) $(test-files) \
        && coverage-report
      echo '#!/bin/sh' > Build
      chmod +x Build
    fi
  }
}
