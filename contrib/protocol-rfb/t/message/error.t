#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use_ok('Protocol::RFB::Message::Error');

ok(not defined Protocol::RFB::Message::Error->new->parse());
ok(not defined Protocol::RFB::Message::Error->new->parse(''));

my $m = Protocol::RFB::Message::Error->new;
ok($m->parse(pack('C', 0) x 3));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok($m->is_done);
is($m->reason, '');
