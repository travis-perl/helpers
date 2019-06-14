BEGIN { do { print "1..0 # SKIP\n"; exit } if $] lt '5.006' }
use strict;
use warnings;
use Test::More tests => 3;
use Config;
my $want = $ENV{TRAVIS_PERL_VERSION};
my ($full_version, $local_lib) = split /@/, $want;
my ($version, @flags) = split /-/, $full_version;

$local_lib ||= 'base-5.6'
  if $version =~ /^5\.6\b/;

SKIP: {
  package TestClass;
  ::skip "only testing for modules in moo local::lib", 2
    unless $local_lib && $local_lib eq 'moo';
  ::use_ok('Moo');
  ::use_ok('Type::Tiny');
}

my @active_lls = sort grep { m{\Q$ENV{PERLBREW_HOME}/libs/} } @INC;
if ($local_lib) {
  is_deeply \@active_lls, [
    "$ENV{PERLBREW_HOME}/libs/$version\@$local_lib/lib/perl5",
    "$ENV{PERLBREW_HOME}/libs/$version\@$local_lib/lib/perl5/$Config{archname}",
  ], 'Found correct local::lib in @INC';
}
else {
  is_deeply \@active_lls, [],
    'No active local::lib found in @INC';
}
