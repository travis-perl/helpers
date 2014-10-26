#!/bin/bash
. lib/tap.bash

if ! perl -e'require 5.008' 2>/dev/null; then
  plan 0 'Perl 5.8 required'
fi

(
  cd t/mb
  set -e
  set -x
  . $PERLBREW_ROOT/etc/bashrc
  . $HELPERS_ROOT/init --auto
  cpanm --quiet --installdeps --notest .
  perl Build.PL && ./Build && ./Build test
) 2>&1 | note

ok ${PIPESTATUS[0]} 'Module::Build dist with --auto'

done_testing

# vim: ft=sh
