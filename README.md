Perl Module Travis-CI Helper
============================

This is a set of utilities meant to aid in testing modules on travis-ci.  It
will automatically build perl if the version requested doesn't exist.

Example .travis.yml
-------------------

    language: perl
    perl:
      - "5.8"
      - "5.8.4"
      - "5.8.4_thr"
    matrix:
      include:
        - perl: 5.18
          env: COVERAGE=1
    before_install:
      - git clone git://github.com/haarg/perl-travis-helper
      - source perl-travis-helper/init
      - build-perl
      - perl -V
      - build-dist
      - cd $BUILD_DIR
    install:
      - cpan-install --deps
      - cpan-install --coverage
    before_script:
      - coverage-setup
    script:
      - prove -l $(test-dirs)
    after_success:
      - coverage-report

Environment Variables
---------------------

  * COVERAGE

    This should be set to report coverage when running tests.  If not set, the
    cpan-install --coverage option and the coverage-setup/coverage-report
    commands will be no-ops.

  * AUTHOR_TESTING

    Controls if the developer prerequisites will be installed, and if the xt
    tests are run.  If not set, treated as true.

  * SPLIT_BUILD

    Controls if the dist should be built with modern version of perl rather
    than the version of perl listed for the build

Commands
--------
  * build-perl

    Builds the requested perl version if needed, and switches to it.

  * build-dist

    Builds a dist directory for the module.  Sets the BUILD_DIR environment
    variable to the path of the built dist.  If SPLIT_BUILD is set to 0, it
    the selected perl version will be used to build the dist.  If it is set to 1
    or unset, a modern version of perl will be used to build.

  * cpan-install

    Installs dependencies.  Dependencies can either be listed manually, or
    the --deps flag can be given to install all dependencies of the current
    dist.

    Also accepts the --coverage option.  If the COVERAGE environment variable
    is set, this will attempt to install Devel::Cover and
    Devel::Cover::Report::Coveralls.  If the environment variable is not set,
    does nothing.

  * tests-dirs

    Outputs either "t xt" normally, or just "t" if the AUTHOR_TESTING
    environment variable is set to 0.

  * coverage-setup

    Sets up the environment to record coverage data when running tests.

  * coverage-report

    Outputs a coverage report.  If Devel::Cover::Report::Coveralls is
    available, it will send the report to Coveralls.

