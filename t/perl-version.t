BEGIN { do { print "1..0 # SKIP\n"; exit } if $] lt '5.006' }
use strict;
use warnings;
use Config;
use Test::More tests => 5;
my $want = $ENV{TRAVIS_PERL_VERSION};
my ($full_version, $local_lib) = split /@/, $want;
my ($version, @flags) = split /-/, $full_version;
my %flags = map { $_ => 1 } @flags;

my $got_version = $Config{version};

if ($version =~ /^\d\.\d+$/) {
  like $got_version, qr/^\Q$version\E\b/, 'correct perl version selected';
}
elsif ($version =~ /^(?:blead|dev)$/) {
  like $got_version, qr/^5\.\d*[13579]\b/, "devel perl installed for $version";
}
else {
  is $got_version, $version, 'correct perl version installed';
}

for (
  [ thr     => 'useithreads' ],
  [ mb      => 'usemorebits' ],
  [ dbg     => 'DEBUGGING' ],
  [ shrplib => 'useshrplib' ],
) {
  my ($vflag, $dflag) = @$_;
  my $want_flag = !!$flags{$vflag};
  my $got_flag = $Config{config_args} =~ /-D$dflag\b/;
  ok $want_flag eq $got_flag,
    "built with" . ($want_flag ? '' : 'out') . " $dflag";
}
