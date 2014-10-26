#!/bin/bash
. lib/tap.bash

(
  cd t/eumm
  set -e
  set -x
  . $PERLBREW_ROOT/etc/bashrc
  . $HELPERS_ROOT/init
  build-dist
  cd $BUILD_DIR
  cpan-install --deps
  prove -lv $(test-dirs)
) 2>&1 | note

ok ${PIPESTATUS[0]} 'EUMM dist with explicit commands'

(
  cd t/eumm
  set -e
  set -x
  . $PERLBREW_ROOT/etc/bashrc
  . $HELPERS_ROOT/init --auto
  cpanm --quiet --installdeps --notest .
  perl Makefile.PL && make test
) 2>&1 | note

ok ${PIPESTATUS[0]} 'EUMM dist with --auto'

done_testing

# vim: ft=sh
