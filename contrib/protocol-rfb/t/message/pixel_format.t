#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;

use_ok('Protocol::RFB::Message::PixelFormat');

ok(not defined Protocol::RFB::Message::PixelFormat->new->parse());
ok(not defined Protocol::RFB::Message::PixelFormat->new->parse(''));

my $m = Protocol::RFB::Message::PixelFormat->new;
ok($m->parse(pack('C', 25)));
ok(!$m->is_done);
ok($m->parse(pack('C', 31)));
ok(!$m->is_done);
ok($m->parse(pack('C', 1)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 10)));
ok(!$m->is_done);
ok($m->parse(pack('n', 15)));
ok(!$m->is_done);
ok($m->parse(pack('n', 19)));
ok(!$m->is_done);
ok($m->parse(pack('C', 50)));
ok(!$m->is_done);
ok($m->parse(pack('C', 51)));
ok(!$m->is_done);
ok($m->parse(pack('C', 52)));
ok(!$m->is_done);
ok($m->parse(pack('C3', 0, 0, 255)));
ok($m->is_done);
is($m->bits_per_pixel, 25);
is($m->depth, 31);
is($m->big_endian_flag, 1);
is($m->true_color_flag, 0);
is($m->red_max, 10);
is($m->green_max, 15);
is($m->blue_max, 19);
is($m->red_shift, 50);
is($m->green_shift, 51);
is($m->blue_shift, 52);

is(length $m->to_string, 20);
is("$m", pack('CC3CCCCnnnCCCC3', 0, 0, 0, 0, 25, 31, 1, 0, 10, 15, 19, 50, 51, 52, 0, 0, 255));
