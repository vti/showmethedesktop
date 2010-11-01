#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use_ok('Protocol::RFB::Message::Bell');

ok(not defined Protocol::RFB::Message::Bell->new->parse());
ok(not defined Protocol::RFB::Message::Bell->new->parse(''));
ok(not defined Protocol::RFB::Message::Bell->new->parse(pack('C', 1)));

my $m = Protocol::RFB::Message::Bell->new;
ok($m->parse(pack('C', 2)));
ok($m->is_done);
