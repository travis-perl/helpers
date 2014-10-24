#!/bin/bash
errors=0

echo "1..2"

cd t/eumm
(
  set -x
  . $PERLBREW_ROOT/etc/bashrc
  . $HELPERS_ROOT/init
  build-dist
  cd $BUILD_DIR
  cpan-install --deps
  prove -lv $(test-dirs)
) 1>&2

[ "$?" == "0" ] && echo "ok 1" || { echo "not ok 1"; (( errors++ )); }

(
  set -x
  . $PERLBREW_ROOT/etc/bashrc
  . $HELPERS_ROOT/init --auto
  cpanm --quiet --installdeps --notest .
  perl Makefile.PL && make test
  true
) 1>&2

[ "$?" == "0" ] && echo "ok 1" || { echo "not ok 1"; (( errors++ )); }

exit $errors

# vim: ft=sh
