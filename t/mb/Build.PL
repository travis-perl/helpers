use strict;
use warnings;
use Module::Build;

Module::Build->new(
  module_name => 'Travis::Test::Dist::MB',
  dist_version => '0.01',
  dist_author => 'SOMEONE',
  dist_abstract => 'test module',
  license  => 'perl',
  requires => {
    'Devel::GlobalPhase' => 0,
  },
)->create_build_script;
