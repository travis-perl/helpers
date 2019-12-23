BEGIN { do { print "1..0 # SKIP\n"; exit } if $] lt '5.006' }
use strict;
use warnings;
use Test::More tests => 1 + ($] >= 5.010 ? 9 : 0);

my $author_mode = !!$ENV{AUTHOR_TESTING};

for my $prereq (
  ['Acme::CPAN::Testers::PASS'],
  $] >= 5.010 ? (
    ['Dist::Zilla::Plugin::Test::Compile', 1],
    ['curry'],
    ['Devel::Confess', $author_mode],
    ['Devel::DefaultWarnings', $author_mode],
    ['Devel::GlobalPhase', $author_mode],
    ['Dist::Zilla::Plugin::Breaks', $author_mode],
    ['Module::Reader', $author_mode],
    ['Safe::Isa', 0],
    ['Dist::Zilla::Plugin::OnlyCorePrereqs', 0],
  ) : (),
) {
  my ($mod, $installed) = @$prereq;
  $installed = 1 if ! defined $installed;
  (my $file = "$mod.pm") =~ s{::}{/}g;
  my $worked = eval { require $file };
  $worked = !$worked if !$installed;
  ok $worked, "$mod was " . ($installed ? '' : 'not ') . "installed";
}
