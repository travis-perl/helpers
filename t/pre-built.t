BEGIN { do { print "1..0 # SKIP\n"; exit } if $] lt '5.006' }
use strict;
use warnings;
use Test::More tests => 1;
use Config;
my $want = $ENV{TRAVIS_PERL_VERSION};
my ($full_version, $local_lib) = split /@/, $want;
my ($version, @flags) = split /-/, $full_version;

my $readme = "$ENV{PERLBREW_ROOT}/perls/$full_version/README";
if ($full_version =~ /^5\.\d*[13579]\./ || $full_version eq 'blead') {
  ok !-e $readme,
    "perl $full_version not prebuilt";
}
elsif ($full_version =~ /^5\.8\.8(-thr)?$/) {
  my $line = do {
    if (open my $fh, '<', $readme) {
      my $line = readline $fh;
      chomp $line;
      close $fh;
      $line;
    }
    else {
      undef;
    }
  };

  like $line, qr/^Perl \Q$full_version\E built by Travis Helpers:/,
    "have a prebuilt perl for $full_version";
}
else {
  SKIP: {
    skip "not testing prebuilt status for $full_version", 1;
  }
}
