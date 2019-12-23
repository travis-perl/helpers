BEGIN { do { print "1..0 # SKIP\n"; exit } if $] lt '5.006' }
use strict;
use warnings;
use Test::More tests => 1;

ok 1;
