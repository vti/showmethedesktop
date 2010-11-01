#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

use_ok('Protocol::RFB::Message::Init');

ok(not defined Protocol::RFB::Message::Init->new->parse());
ok(not defined Protocol::RFB::Message::Init->new->parse(''));

my $m = Protocol::RFB::Message::Init->new;
ok($m->parse(pack('n', 800)));
ok(!$m->is_done);
ok($m->parse(pack('n', 600)));
ok(!$m->is_done);
ok($m->parse(pack('ccccnnncccc3', 16, 24, 0, 1, 255, 255, 255, 8, 16, 0, 0)));
ok(!$m->is_done);
ok($m->parse(pack('N', 3)));
ok(!$m->is_done);
ok($m->parse('wow'));
ok($m->is_done);
is($m->width, 800);
is($m->height, 600);
is($m->server_name, 'wow');

$m = Protocol::RFB::Message::Init->new;
is($m->to_string, pack('C', 1));
