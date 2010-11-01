#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use_ok('Protocol::RFB::Message::FramebufferUpdateRequest');

my $m = Protocol::RFB::Message::FramebufferUpdateRequest->new;
is($m->prefix, 3);
$m->incremental(0);
$m->x(0);
$m->y(40);
$m->width(100);
$m->height(245);
is($m, pack('CCnnnn', 3, 0, 0, 40, 100, 245));

$m = Protocol::RFB::Message::FramebufferUpdateRequest->new;
$m->incremental(1);
$m->x(1);
$m->y(0);
$m->width(10);
$m->height(24);
is($m, pack('CCnnnn', 3, 1, 1, 0, 10, 24));
