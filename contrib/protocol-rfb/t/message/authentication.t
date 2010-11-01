#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use_ok('Protocol::RFB::Message::Authentication');

ok(not defined Protocol::RFB::Message::Authentication->new->parse());
ok(not defined Protocol::RFB::Message::Authentication->new->parse(''));

my $m = Protocol::RFB::Message::Authentication->new;
ok($m->parse(pack('C', 123)));
ok(!$m->is_done);
ok($m->parse(pack('C', 123) x 15));
ok($m->is_done);
is(length $m->challenge, 16);

$m->password('COW');
is(length $m->to_string, 16);
