use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Travis::Test::Dist',
  VERSION => 0.01,
  ABSTRACT => 'test dist for travis',
  PREREQ_PM => {
    'Acme::CPAN::Testers::PASS' => 0,
  },
);
