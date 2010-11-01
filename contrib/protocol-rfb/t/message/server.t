#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 26;

use_ok('Protocol::RFB::Message::Server');

use Protocol::RFB::Message::PixelFormat;

my $pixel_format = Protocol::RFB::Message::PixelFormat->new;
$pixel_format->depth(32);
$pixel_format->big_endian_flag(0);
$pixel_format->true_color_flag(1);
$pixel_format->red_max(255);
$pixel_format->green_max(255);
$pixel_format->blue_max(255);
$pixel_format->red_shift(8);
$pixel_format->green_shift(0);
$pixel_format->blue_shift(0);
$pixel_format->bits_per_pixel(8);

ok(not defined Protocol::RFB::Message::Server->new->parse());
ok(not defined Protocol::RFB::Message::Server->new->parse(''));

# FramebufferUpdate
my $m = Protocol::RFB::Message::Server->new(pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 5, 14, 1, 1, 0, 255)));
ok($m->is_done);
is($m->name, 'framebuffer_update');

# SetColorMapEntries
$m = Protocol::RFB::Message::Server->new;
ok($m->parse(pack('C', 1)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 123)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnn', 1, 2, 3)));
ok($m->is_done);
is($m->name, 'set_color_map_entries');

# Bell
$m = Protocol::RFB::Message::Server->new;
ok($m->parse(pack('C', 2)));
ok($m->is_done);
is($m->name, 'bell');

# ServerCutText
#$m = Protocol::RFB::Message::Server->new;
#ok($m->parse(pack('C', 3)));
#ok($m->is_done);
#is($m->name, 'server_cut_text');
