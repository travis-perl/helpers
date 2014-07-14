Perl Module Travis-CI Helper
============================
This is a set of utilities meant to aid in testing modules on travis-ci.  It
will automatically build perl if the version requested doesn't exist.

Example .travis.yml
-------------------

    language: perl
    perl:
      - "5.8"                     # normal preinstalled perl
      - "5.8.4"                   # installs perl 5.8.4
      - "5.8.4-thr"               # installs perl 5.8.4 with threading
      - "5.20"                    # installs latest perl 5.20 (if not already available)
      - "blead"                   # installs perl from git
    matrix:
      include:
        - perl: 5.18
          env: COVERAGE=1         # enables coverage+coveralls reporting
    before_install:
      - git clone git://github.com/haarg/perl-travis-helper
      - source perl-travis-helper/init
      - build-perl
      - perl -V
      - build-dist
      - cd $BUILD_DIR             # $BUILD_DIR is set by the build-dist command
    install:
      - cpan-install --deps       # installs prereqs, including recommends
      - cpan-install --coverage   # installs converage prereqs, if enabled
    before_script:
      - coverage-setup
    script:
      - prove -l -j$((SYSTEM_CORES + 1)) $(test-dirs)   # parallel testing
    after_success:
      - coverage-report


Description
-----------
While Travis-CI provides simple testing with perl or other languages, it has
several limitations to address.  It only has a limited number of perl versions
available, and only uses the default build options.

These helpers will build perl versions for you if they aren't available.
Additional helpers will build a dist package using a newer perl than the tests
are run with, or aid with installing dependencies or reporting code coverage.

The helpers are meant to be usable indivitually, so you can pick only the ones
needed for your use case.

Perl Building
-------------
If the specified perl version is already installed on the Travis testing
machine, it will be used as is.  Any requested perl version that isn't available
will be built for you.  If the patch level isn't included in the version, the
latest in that series will be used.  Additionally, some build flags can be
specified by adding them as dash separated suffixes (e.g. 5.10.1-thr-mb).

  * thr
    Builds a perl with thread support.  Controls the ```useithreads``` flag.

  * dbg
    Builds a debugging perl.  Controls the ```DEBUGGING``` flag.

  * mb
    Builds a perl with 64-bit and long double support.  Controls the
    ```usemorebits``` flag.

  * shrplib
    Builds a shared libperl used by perl.  Needed for some dynamic loading
    cases.  Controls the ```useshrplib``` flag.

Environment Variables
---------------------
There are various environment variables that will either control how a build is
done, or are just set by the commands.

  * `COVERAGE`

    If true, coverage will be reported after running tests.  Coverage results
    will also be submitted to [Coveralls](https://coveralls.io/).  If false,
    the `coverage-setup`, `coverage-report`, and `cpan-install --coverage`
    commands will be no-ops.

    Defaults to false.

  * `AUTHOR_TESTING`

    If true, developer prerequisites will be installed by the
    `cpan-install --deps` command, and the `test-dirs` and `test-files`
    commands will include the `xt` directory.  This will also be used by many
    test scripts.

    Defaults to true.

  * `SPLIT_BUILD`

    Controls if the dist should be generated using a separate (more modern)
    perl version.  This is needed if the dist generation process requires a
    newer perl version than is being tested.  It can also help speed up the
    generation process if it has heavy dependencies, such as Dist::Zilla, and
    testing is being done on a freshly built perl.

    Defaults to true.

  * `CPAN_MIRROR`

    The CPAN mirror that dependencies will be installed from.

    Defaults to http://www.cpan.org/.

  * `HELPER_ROOT`

    The root directory of the helper scripts.  Set by init.

  * `MODERN_PERL`

    The command that will be used to generate the dist.  Set by `init` and
    `build-perl`.

  * `SYSTEM_CORES`

    The number of CPU cores the system has.  Useful for parallel testing.  Set
    by `init`.

  * `BUILD_DIR`

    The path to the generated dist.  Set by the `build-dist` command.

Commands
--------
  * init

    Sets up the helper functions, and initializes environment variables.

  * build-perl

    Builds the requested perl version if needed, and switches to it.

  * build-dist

    Builds a dist directory for the module.  Sets the `BUILD_DIR` environment
    variable to the path of the built dist.  If `SPLIT_BUILD` is true, the
    latest preinstalled perl version will used.  If `SPLIT_BUILD` is false, the
    requested perl version will be.

    If a `dist.ini` file exists in the repository, Dist::Zilla will be used to
    generate the dist.  Additional prerequisites will be installed as needed.

    If a `Makefile.PL` file exists, ExtUtils::MakeMaker's distdir command will
    be used.

    If a `Build.PL` file exists, Module::Build's distdir command will be used.

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

  * tests-files

    Outputs all of the test files found in the directories returned from `test-dirs`

  * coverage-setup

    Sets up the environment to record coverage data when running tests.  Does
    nothing if `COVERAGE` is false.

  * coverage-report

    Outputs a coverage report.  If Devel::Cover::Report::Coveralls is
    available, it will send the report to Coveralls.  Does nothing if
    `COVERAGE` is false.

Notes
-----
Travis-CI will attempt to switch to the specified perl version, and report the
output of `perl --version`.  If the perl version specified isn't one of the
prebuilt options, this will result in an error and mismatched version
information.  These can be ignored.  The build will continue, allowing the
`build-perl` command to build and switch to the requested version.  It is
recommended to include `perl -V` after `build-perl`, so the build details of
the perl being used will be included in the build log.

Example Projects
----------------
  * [Moo](https://github.com/moose/Moo)
  * [Moose](https://github.com/moose/Moose)
  * [Match::Simple](https://github.com/tobyink/p5-match-simple)
  * [DateTime::Format::MSSQL](https://github.com/frioux/DateTime-Format-MSSQL)
  * [local::lib](https://github.com/Perl-Toolchain-Gang/local-lib)
