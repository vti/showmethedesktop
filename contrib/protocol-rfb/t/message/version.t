#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;

use_ok('Protocol::RFB::Message::Version');

ok(not defined Protocol::RFB::Message::Version->new->parse());
ok(not defined Protocol::RFB::Message::Version->new->parse(''));
ok(not defined Protocol::RFB::Message::Version->new->parse('RFB xxx.xxxa'));
ok(not defined Protocol::RFB::Message::Version->new->parse("RFB abc.cbd\x0a"));

my $m = Protocol::RFB::Message::Version->new;
ok($m->parse("RFB 003.007\x0a"));
is($m->major, '003');
is($m->minor, '007');
is($m->to_string, "RFB 003.007\x0a");
ok($m->is_done);

$m = Protocol::RFB::Message::Version->new;
ok($m->parse("RFB 003"));
ok(!$m->is_done);
ok($m->parse("\.007"));
ok(!$m->is_done);
ok($m->parse("\x0a"));
ok($m->is_done);
is($m->major, '003');
is($m->minor, '007');
is($m->to_string, "RFB 003.007\x0a");

$m = Protocol::RFB::Message::Version->new;
$m->major(3);
$m->minor(7);
is($m->to_string, "RFB 003.007\x0a");
