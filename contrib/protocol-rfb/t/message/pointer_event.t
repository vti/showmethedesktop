#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok('Protocol::RFB::Message::PointerEvent');

my $m = Protocol::RFB::Message::PointerEvent->new;
is($m->prefix, 5);
$m->button_mask(0);
$m->x(0);
$m->y(1);
is("$m", pack('CCnn', 5, 0, 0, 1));
