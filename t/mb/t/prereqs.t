BEGIN { do { print "1..0 # SKIP\n"; exit } if $] lt '5.006' }
use strict;
use warnings;
use Test::More tests => 1;

for my $prereq (
  ['Devel::GlobalPhase'],
) {
  my ($mod, $installed) = @$prereq;
  $installed = 1 if ! defined $installed;
  (my $file = "$mod.pm") =~ s{::}{/}g;
  my $worked = eval { require $file };
  $worked = !$worked if !$installed;
  ok $worked, "$mod was " . ($installed ? '' : 'not ') . "installed";
}
