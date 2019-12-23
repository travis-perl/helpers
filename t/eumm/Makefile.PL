use strict;
BEGIN { $^W = 1 }
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Travis::Test::Dist::EUMM',
  VERSION => 0.01,
  ABSTRACT => 'test dist for travis',
  PREREQ_PM => {
    'Acme::CPAN::Testers::PASS' => 0,
    $] >= 5.010 ? ('Dist::Zilla::Plugin::Test::Compile' => 0) : (),
  },
  $] >= 5.010 ? (
    META_MERGE => {
      'meta-spec' => { version => 2 },
      prereqs => {
        runtime => {
          requires => {
            'Acme::CPAN::Testers::PASS' => 0,
            'Dist::Zilla::Plugin::Test::Compile' => 0,
          },
          recommends => {
            'curry' => 0,
          },
          suggest => {
            'Safe::Isa' => 0,
          },
        },
        develop => {
          requires => {
            'Devel::Confess' => 0,
            'Dist::Zilla::Plugin::OnlyCorePrereqs' => 0,
          },
          recommends => {
            'Devel::DefaultWarnings' => 0,
          },
        },
        x_test => {
          requires => {
            'Devel::GlobalPhase' => 0,
            'Dist::Zilla::Plugin::Breaks' => 0,
          },
          recommends => {
            'Module::Reader' => 0,
          },
        },
      },
    },
  ) : (),
);
