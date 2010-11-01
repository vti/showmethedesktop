#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use_ok('Protocol::RFB::Encoding::CopyRect');

my $m = Protocol::RFB::Encoding::CopyRect->new;
ok(not defined $m->parse(pack('n', 100)));

$m = Protocol::RFB::Encoding::CopyRect->new;
is($m->parse(pack('n', 100) . pack('n', 200) . 123), 4);
is_deeply($m->data, [100, 200]);
