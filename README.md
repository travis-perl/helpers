Perl Module Travis-CI Helper
============================
This is a set of utilities meant to aid in testing modules on travis-ci.  It
will automatically build perl if the version requested doesn't exist.

While Travis-CI provides simple testing with perl or other languages, it has
several limitations to address.  It only has a limited number of perl versions
available, and only uses the default build options.

These helpers will build perl versions for you if they aren't available.
Additional helpers will build a dist package using a newer perl than the tests
are run with, or aid with installing dependencies or reporting code coverage.

The helpers can be used individually, or _automatic mode_ can be used if using
a standard testing setup.

Example Simple .travis.yml
--------------------------

    language: perl
    perl:
      - "5.8"               # normal preinstalled perl
      - "5.8.4"             # downloads a pre-built 5.8.4
      - "5.8.4-thr"         # pre-built 5.8.4 with threading
      - "5.12.2"            # builds perl 5.12.2 from source (pre-built not available)
      - "5.20"              # installs latest perl 5.20 (if not already available)
      - "dev"               # installs latest developer release of perl (e.g. 5.21.8)
      - "blead"             # builds perl from git
    cache:
      directories:
        - $HOME/perl5
    matrix:
      include:
        - perl: 5.18
          env: COVERAGE=1   # enables coverage reporting (coveralls by default),
                            # or COVERAGE=report_name to use a specific report
                            # module
      allow_failures:
        - perl: blead       # ignore failures for blead perl
    before_install:
      - eval $(curl https://travis-perl.github.io/init) --auto

This will work for most distributions.  It will work with dists using a
Makefile.PL, Build.PL, Dist::Zilla or Dist::Inkt.

Perl Building
-------------
If the specified perl version is already installed on the Travis testing
machine, it will be used as is.  Any requested perl version that isn't available
will be built for you.  Additionally, a number of commonly tested versions are
pre-built and will be automatically downloaded and used to speed up testing.
The pre-built perl versions are listed in the [.travis.yml for the builder
repo](https://github.com/travis-perl/builder/blob/master/.travis.yml).
If the patch level isn't included in the version, the latest in that series will
be used.  Additionally, some build flags can be specified by adding them as dash
separated suffixes (e.g. 5.10.1-thr-mb).

  * thr
    Builds a perl with thread support.  Controls the `useithreads` flag.

  * dbg
    Builds a debugging perl.  Controls the `DEBUGGING` flag.

  * mb
    Builds a perl with 64-bit and long double support.  Controls
    the `usemorebits` flag.

  * shrplib
    Builds a shared libperl used by perl.  Needed for some dynamic loading
    cases.  Controls the `useshrplib` flag.

There are three other special versions that can be requested:

  * system
    Uses the default system perl.  This can be useful if there are perl modules
    you want to install using apt-get.

  * dev
    Installs the latest development perl build available.  This will be
    something like 5.21.8.

  * blead
    Installs perl from git.  This is bleading-edge version of perl, and will
    occasionally fail to build at all.  If used, it's usually recommended to
    list in `allow_failures`.


Control Environment Variables
-----------------------------
There are various environment variables that will control how a build is done.

  * `COVERAGE`

    If true, coverage will be reported after running tests. When value is
    1 coverage results will be submitted to [Coveralls](https://coveralls.io/).
    Otherwise the value is going to be used a Devel::Cover report module name.
    If false, the `coverage-setup`, `coverage-report`, and `cpan-install
    --coverage` commands will be no-ops.

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

    Makes a local::lib that is blank.

    Defaults to true.

  * `LOCAL_LIB_CACHE`

    The directory used to cache the local::lib used if you specify
    `local-lib cache`.

    Defaults to `$HOME/.perlbrew-cache`.

  * `CPAN_MIRROR`

    The CPAN mirror that dependencies will be installed from.

    Defaults to http://www.cpan.org/.

  * `REBUILD_PERL`

    If set, prebuilt versions of perl will not automatically be downloaded and
    used.

  * `TEST_PARTITION`, `TEST_PARTITIONS`

    If set, `test-files` will divide all of the tests into partitions and
    return the files from one of them.  This can be used to split up long
    testing runs to keep them under the time limits imposed by Travis-CI.

  * `TRAVIS_PERL_DEBUG`
  
    If set, then all the helper scripts will include `set +x`, causing them
    echo all the commands that they run. This can be helpful when trying to
    understand problems with using these helpers.

Example Long .travis.yml
------------------------
The simple `.travis.yml` listed above is roughly equivalent to:

    language: perl
    perl:
      - "5.8"
      - "5.8.4"
      - "5.8.4-thr"
      - "5.12.2"
      - "5.20"
      - "dev"
      - "blead"
    matrix:
      include:
        - perl: 5.18
          env: COVERAGE=1
      allow_failures:
        - perl: "blead"
    before_install:
      - git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
      - source ~/travis-perl-helpers/init
      - build-perl
      - perl -V
      - build-dist
      - cd $BUILD_DIR             # $BUILD_DIR is set by the build-dist command
    install:
      - cpan-install --deps       # installs prereqs, including recommends
      - cpan-install --coverage   # installs coverage prereqs, if enabled
    before_script:
      - coverage-setup
    script:
      - prove -l -j$(test-jobs) $(test-files)   # parallel testing
    after_success:
      - coverage-report

Using this form rather than `--auto` allows many more parts of the process to be
controlled.

Commands
--------
  * init

    Sets up the helper functions, and initializes environment variables.
    Accepts three options:
      * --perl
        automatically runs the build-perl command for you

      * --auto
        Does as much as possible for you.  Runs build-perl, and uses other
        commands as appropriate to do a full build and test.  If this option is
        used, none of the other build phases should be customized, and none of
        the commands should be used aside from cpan-install.

      * --always-upgrade-modules
        The `cpanm` command will be run without the `--skip-satisfied`
        option. If you are using Travis caching to cache your installed Perl
        prereqs, you will want to add this flag so that your local lib does
        not get progressively more out of date over time.

  * build-perl

    Installs the requested perl version as needed, and switches to it.

  * build-dist

    Builds a dist directory for the module.  Sets the `BUILD_DIR` environment
    variable to the path of the built dist.  If `SPLIT_BUILD` is true, the
    latest preinstalled perl version will used.  If `SPLIT_BUILD` is false, the
    requested perl version will be used instead.

    If a `dist.ini` file exists in the repository, Dist::Zilla or
    Dist::Inkt will be used to generate the dist.  Additional
    prerequisites will be installed as needed.

    If a `Makefile.PL` file exists, ExtUtils::MakeMaker's distdir command will
    be used.

    If a `Build.PL` file exists, Module::Build's distdir command will be used.

  * cpan-install

    Installs dependencies.  Dependencies can either be listed manually, or
    the --deps flag can be given to install all dependencies of the current
    dist.

    This command accepts the --coverage option.  If the COVERAGE environment
    variable is set, this will attempt to install Devel::Cover and
    Devel::Cover::Report::$COVERAGE (Coveralls when value is 1).  If the
    environment variable is not set, does nothing.

    Finally, you can pass --update-prereqs to make this script run without
    passing `--skip-satisfied` to `cpanm`.

  * tests-dirs

    Outputs either "t xt" normally, or just "t" if the AUTHOR_TESTING
    environment variable is set to 0.

  * tests-files

    Outputs all of the test files found in the directories returned from
    `test-dirs`.  If `TEST_PARTITIONS` and `TEST_PARTITION` are set, the tests
    are divided into `TEST_PARTITIONS` equal sized groups, and group
    `TEST_PARTITION` will be returned.

  * test-jobs

    Outputs the recommended number of parallel test runs to use.  This will be
    calculated based on the number of CPUs available.  If `COVERAGE` is true, it
    will be 1, as Devel::Cover does not yet cope well with parallel testing.

  * coverage-setup

    Sets up the environment to record coverage data when running tests.  Does
    nothing if `COVERAGE` is false.

  * coverage-report

    Outputs a coverage report.  If Devel::Cover::Report::$COVERAGE is available,
    it will use the corresponding report module. When set to 1 default module
    name is Coveralls. Does nothing if `COVERAGE` is false.

  * local-lib

    Activates a local::lib directory.  Without a parameter, creates a new
    local::lib directory and activates it. This is used by `build-dist`
    for a `Dist::Zilla` distribution, and can be valuable if you need to
    isolate the prereqs you are installing from the core modules.  Any parameters
    given are taken as names of [predefined local::libs](share/local-libs.txt) to
    load. For example, `local-lib dzil` can save a lot of time for Dist::Zilla
    based modules. If you specified a prebuilt local::lib there is no
    need to give it again. If you do want further local::libs, you can
    give them to this command and they will be downloaded if pre-built,
    or built if not, and added to the library path. This is taken care
    of by the `build-perl` step.

    There is a special local::lib name you can give:
    `cache`, which works together with [Travis's caching
    feature](https://docs.travis-ci.com/user/caching). Its location
    defaults to `$HOME/.perlbrew-cache` but can be overridden
    by supplying the environment variable `LOCAL_LIB_CACHE`. Use it
    like this:

        cache:
          directories:
          - $HOME/.perlbrew-cache # keeps between builds here
        perl:
          - "5.8.4@moo"
        before_install:
          - git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
          - source ~/travis-perl-helpers/init
          - build-perl
          - local-lib cache # makes a local::lib from cached
          - perl -V
          - build-dist
          - cd $BUILD_DIR
        install:
          - cpan-install --deps # installs prereqs, including recommends
        before_cache:
          - local-lib-cachestore # saves for local::lib next time

    Alternatively, this will also work and the `build-perl` will do the
    `local-lib` step for you:

        cache:
          directories:
          - $HOME/.perlbrew-cache # keeps between builds here
        perl:
          - "5.8.4@cache"
        before_install:
          - git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
          - source ~/travis-perl-helpers/init
          - build-perl
        # no need for local-lib cache
          - perl -V
          - build-dist
          - cd $BUILD_DIR
        install:
          - cpan-install --deps # installs prereqs, including recommends
        before_cache:
          - local-lib-cachestore # saves for local::lib next time

local::lib
----------
A number of [predefined local::lib](share/local-libs.txt) directories are
available for use.  Pre-built perl versions will also include pre-built
local::lib directories.  If there is no pre-built copy of the local::lib
available, it will be built when requested. The list of available pre-built
versions of Perl is available
[here](https://github.com/travis-perl/builder/blob/master/.travis.yml). To
use one of these, specify like this:

    perl:
      - "5.6.2@moo"
      - "5.8.4@moo"

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
