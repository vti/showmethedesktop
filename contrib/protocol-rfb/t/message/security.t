#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;

use_ok('Protocol::RFB::Message::Security');

ok(not defined Protocol::RFB::Message::Security->new->parse());
ok(not defined Protocol::RFB::Message::Security->new->parse(''));

my $m = Protocol::RFB::Message::Security->new;
ok($m->parse(pack('C', 1) . pack('C', 1)));
ok($m->is_done);
ok(not defined $m->error);
is_deeply($m->types, [1]);

$m = Protocol::RFB::Message::Security->new;
ok($m->parse(pack('C', 2) . pack('C', 1) . pack('C', 0)));
ok($m->is_done);
ok(not defined $m->error);
is_deeply($m->types, [1, 0]);

$m = Protocol::RFB::Message::Security->new;
ok($m->parse(pack('C', 2) . pack('C', 1)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok($m->is_done);
ok(not defined $m->error);
is_deeply($m->types, [1, 0]);

$m = Protocol::RFB::Message::Security->new;
ok($m->parse(pack('C', 0) . pack('I', 13) . "what t"));
ok(!$m->is_done);
ok($m->parse("he hell"));
ok($m->is_done);
is_deeply($m->error, 'what the hell');
is_deeply($m->types, []);

$m = Protocol::RFB::Message::Security->new;
$m->type(1);
is($m->to_string, pack('C', 1));
