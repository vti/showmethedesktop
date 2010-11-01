#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use_ok('Protocol::RFB::Message::KeyEvent');

my $m = Protocol::RFB::Message::KeyEvent->new;
is($m->prefix, 4);
$m->down(0);
$m->key(0xff08);
is("$m", pack('CCnN', 4, 0, 0, 0xff08));

$m = Protocol::RFB::Message::KeyEvent->new;
$m->down(1);
$m->key(0xff09);
is("$m", pack('CCnN', 4, 1, 0, 0xff09));
