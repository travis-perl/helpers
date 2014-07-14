use strict;
use warnings;
use Config;
use Test::More tests => 5;
my $want = $ENV{TRAVIS_PERL_VERSION};

(my $version = $want) =~ s/-.*//;
my $got_version = $Config{version};
if ($version =~ /^\d\.\d+$/) {
  like $got_version, qr/^\Q$version\E\b/, 'correct perl version selected';
}
elsif ($version eq 'blead') {
  like $got_version, qr/^5\.\d*[13579]\b/, 'devel perl installed for blead';
}
else {
  is $got_version, $version, 'correct perl version installed';
}

for (
  [ thr => 'useithreads' ],
  [ mb  => 'usemorebits' ],
  [ dbg => 'DEBUGGING' ],
  [ shrplib => 'useshrplib' ],
) {
  my ($vflag, $dflag) = @$_;
  my $want_flag = "${want}-" =~ /-${vflag}-/;
  ok(($Config{config_args} =~ /-D$dflag\b/) eq $want_flag,
    "built with" . ($want_flag ? '' : 'out') . " $dflag");
}
