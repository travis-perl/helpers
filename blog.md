Travis CI Helpers for Perl
--------------------------
I deal with a lot of modules that promise backwards compatibility with older
versions of perl, usually back to perl 5.8.1.  Since I don't regularly use perl
versions that old when developing, accidentally introducing incompatibilities is
always a risk.  Having a continuous integration system check this for me makes
it much easier to catch mistakes like this before they get released into the
wild.

[Travis CI](https://travis-ci.org/) is a very useful continuous integration
service that is free for any public repositories on
[GitHub](https://github.com).  There are issues with using Travis CI for the
kind of testing I need though.  First, it only provides the last revision of
each perl series.  Especially in the perl 5.8 and 5.10 series, there are
substantial enough differences between them that testing only the latest isn't
adequate.  Additionally, some of the testing needs to be done on perls build
with threading, which isn't included on most of the versions available on
Travis.  It also is sometimes useful to test without any additional modules
pre-installed like Travis does.

There is a solution for this though.  Perl can be built directly on the Travis
test boxes before running the tests.  Any arbitrary perl version can be built,
including blead (perl from git) or new stable releases that haven't been
included on Travis yet (like was the case with 5.20 for a few months).

Building new perl versions was what originally inspired me to begin work on my
Travis helper scripts.  Since then, they have expanded to include a number of
other functions to simplify testing perl modules on Travis.

The Simple Version
------------------
The helpers can be used individually to customize the building and testing
process, but for most distributions the automatic mode will work.  A
simple ```.travis.yml``` using my helper scripts would look like this:

    language: perl
    perl:
      - "5.8"                     # normal pre-installed perl
      - "5.8.4"                   # installs perl 5.8.4
      - "5.8.4-thr"               # installs perl 5.8.4 with threading
      - "5.20"                    # installs latest perl 5.20 (if not already available)
      - "blead"                   # install perl from git
    before_install:
      - git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
      - source ~/travis-perl-helpers/init --auto

This includes most of the features and will work for most distributions.  It
includes building perl where needed, installing prerequisites, and will work
with dists built using Dist::Zilla, ExtUtils::MakeMaker, Module::Build, or
Module::Install.

The ```--auto``` flag means that the testing process is roughly equivalent to
the following Travis config.

    language: perl
    perl:
      - "5.8"                     # normal pre-installed perl
      - "5.8.4"                   # installs perl 5.8.4
      - "5.8.4-thr"               # installs perl 5.8.4 with threading
      - "5.20"                    # installs latest perl 5.20 (if not already available)
      - "blead"                   # install perl from git
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
      - perl Makefile.PL          # or Build.PL if it exists
      - make                      # or ./Build
      - prove -l -s -j$(test-jobs) $(test-files)
    after_success:
      - coverage-report

While the automatic mode supports most of the features the helpers provide, it
isn't meant to be used with custom build steps.  If any customization of the
build steps is needed, the automatic mode shouldn't be used.

Perl Building - build-perl
--------------------------
The first important helper function is ```build-perl```.  It takes the requested
perl version from the build matrix and either downloads or builds it for you if
it doesn't exist.  So for example, if ```5.16``` is requested, Travis will
already have it available and nothing will be done.  But if ``5.16.0``` is
requested, a fresh version of perl will be built.  If ```5.8.8``` is requested,
a pre-built copy of perl 5.8.8 will be downloaded, as it's a commonly tested
version so I've pre-built it.  Building perl generally takes around 4 minutes on
Travis, so these pre-built copies can significantly speed up small test suites.

Build flags can also be added to the versions.  ```5.8.5-thr``` will build a
version of perl including support for threads.  ```5.8.5-dbg``` will include
debugging support.  And ```5.16-thr``` will build the latest 5.16 release and
include support for threads.

If ```blead``` is requested, perl will be built from git.  This is helpful to
see if your module will be impacted by future changes to perl, but as blead is
not guaranteed stable it should usually be included in Travis's
[allow_failures](http://docs.travis-ci.com/user/build-configuration/#Rows-That-are-Allowed-To-Fail)
section.

Pre-installed Modules - local-lib
--------------------------------
When the helper scripts build or download a perl version, they don't have any
extra modules pre-installed.  The default Travis builds all include a set of
prerequisites pre-installed.  Both cases can be useful for different situations.
In some cases, you want to that your prerequisite installation works properly,
or that your module works with an older version of a core module.  But
installing all of the prerequisites every time can delay testing by a
significant amount.

To help with this, each pre-built copy of perl also has a set of pre-built
local::lib directories that can be switched to.  These can be used by adding
them directly to the build matrix, attaching them to the perl version like
```5.10.1@moose```.  The ```moose``` pre-built includes Moose and Moo.  If not
using a pre-built perl, the modules in the named local::lib will be installed.

The full list of pre-built local::libs and the libraries in them can be seen in
the
[local-libs.txt](https://github.com/travis-perl/helpers/blob/master/share/local-libs.txt)
file.

Distribution Building - build-dist
----------------------------------
There are a variety of tools used for distribution building.  Manually writing a
Makefile.PL is one, but other options include Module::Build, Module::Install, or
Dist::Zilla.  While tests can often be performed directly against the files in
the repository without building, this won't include any of the extra checks done
by or generated by the dist building tool.  It also can complicate the process
of finding prerequisites.

The approach the helpers recommend is first generating a full dist like would be
uploaded to CPAN, then testing against that.  Because the distribution building
tool often won't work on all of the perl versions you wish to test against, it's
helpful to use a different (newer) version of perl than the tests are run with.

This is what the ```build-dist``` helper does.  It uses the latest pre-built
version of perl to generate a distribution directory, automatically installing
any modules needed.  It then sets the ```BUILD_DIR``` environment variable to
the location of the built distribution.

Prerequisite Installation - cpan-install
----------------------------------------
For most cases, prerequisite installation could be handled by ```cpanm```, but
the ```cpan-install``` helper provides a few niceties.  It provides more helpful
output than cpanm in the event of a failure, but is still concise in the common
case.  It also tweaks the set of modules to be installed.  The developer
prerequisites and recommended modules of the distribution being tested will be
installed, but not those of its prerequisites.

It also includes better compatibility with ancient versions of perl.

Coverage Reporting
------------------
Setting up coverage reporting in Travis is relatively simple.  You just need to
install the Devel::Cover module and run the cover command appropriately.  But
coverage reporting slows down testing substantially and can also prevent some
tests from running (such as those using threads).  So it's useful to limit
coverage testing to only some of the perls you are testing with.  With that in
mind, the helper scripts include several coverage related commands that are
no-ops unless the COVERAGE environment variable is set.

Running the Tests
-----------------
For running the actual tests, the helpers do very little.  It's recommended to
use the standard ```prove``` command, with whatever options are wanted.

There are a few helpers that can be used with prove though.  If you want to run
tests in parallel, the ```test-jobs``` returns a recommended number of
processes to use.  The number is one more than the number CPUs available.  It
also will always return 1 if COVERAGE is enabled, since Devel::Cover is
currently buggy when used with parallel testing.

The ```test-files``` returns all of the test scripts to run.  This is generated
by searching for ```.t``` files recursively in the ```t``` and ```xt```
directories.  However, if the AUTHOR_TESTING environment variable is set to 0,
it will only return files in ```t```.  It can also help with very slow test
runs.  If the TEST_PARTITION and TEST_PARTITIONS environment variables are set,
it will return only a subset of the tests.  This allows you to split the tests
across multiple Travis builds in parallel, making the full test run take less
time.

Bits and Pieces
---------------
An important feature of the helpers is that they can all be used independently
of each other.  So if perl building is the only feature needed, the rest of the
helpers can be ignored.

Overall, having these helpers has allowed me to set up testing easier for a
variety of different projects, and allowed me to expand the versions of perl
tests.  They have been used to add perl 5.8 and blead testing to Moose, and 5.6
testing to Moo and ExtUtils::MakeMaker.
