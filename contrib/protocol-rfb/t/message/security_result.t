#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

use_ok('Protocol::RFB::Message::SecurityResult');

ok(not defined Protocol::RFB::Message::SecurityResult->new->parse());
ok(not defined Protocol::RFB::Message::SecurityResult->new->parse(''));

my $m = Protocol::RFB::Message::SecurityResult->new;
ok($m->parse(pack('C', 0) x 3));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok($m->is_done);
ok(not defined $m->error);

$m = Protocol::RFB::Message::SecurityResult->new;
ok($m->parse(pack('C', 0) x 3));
ok(!$m->is_done);
ok($m->parse(pack('C', 1) . pack('C4', 5)));
ok(!$m->is_done);
ok($m->parse('error'));
ok($m->is_done);
is($m->error, 'error');
