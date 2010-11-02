#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 81;

use_ok('Protocol::RFB::Message::FramebufferUpdate');
use Protocol::RFB::Message::PixelFormat;

my $pixel_format = Protocol::RFB::Message::PixelFormat->new;
$pixel_format->depth(32);
$pixel_format->big_endian_flag(0);
$pixel_format->true_color_flag(1);
$pixel_format->red_max(255);
$pixel_format->green_max(255);
$pixel_format->blue_max(255);
$pixel_format->red_shift(8);
$pixel_format->green_shift(8);
$pixel_format->blue_shift(16);
$pixel_format->bits_per_pixel(32);

my $m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok(not defined $m->parse());
ok(not defined $m->parse(''));

# Packet header
is($m->parse(pack('C', 0)), 1);
is($m->parse(pack('C', 0)), 1);
is($m->parse(pack('n', 1)), 2);

# Rectangle header
is($m->parse(pack('n', 5)),  2);
is($m->parse(pack('n', 14)), 2);
is($m->parse(pack('n', 1)),  2);
is($m->parse(pack('n', 1)),  2);
is($m->parse(pack('N', 0)),  4);

# Rectangle pixels
is($m->parse(pack('C', 128)),               1);
is($m->parse(pack('C', 255)),               1);
is($m->parse(pack('C', 128)),               1);
is($m->parse(pack('C', 255) . 'leftovers'), 1);

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 5, 14, 1, 1, 0, 128)));
ok(!$m->is_done);
ok($m->parse(pack('C', 255)));
ok($m->parse(pack('C', 128)));
ok($m->parse(pack('C', 255)));
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [255, 255, 128, 255]
        }
    ]
);

my $data = pack('CCnnnnnNCCCC', 0, 0, 1, 5, 14, 1, 1, 0, 128, 255, 128, 255);

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
is($m->parse($data), 20);

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
is($m->parse(substr($data, 0, 5)),  5);
is($m->parse(substr($data, 5, 11)), 11);
is($m->parse(substr($data, 11)), 4);

# Parse leftovers
$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
is($m->parse(substr($data, 0, 5)),  5);
is($m->parse(substr($data, 5, 11)), 11);
is($m->parse(substr($data, 11) . 'leftover'), 4);

$pixel_format->bits_per_pixel(8);

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
is($m->parse(pack('C', 0)), 1);
ok(!$m->is_done);
is($m->parse(pack('C', 0)), 1);
ok(!$m->is_done);
is($m->parse(pack('n', 1)), 2);
ok(!$m->is_done);
is($m->parse(pack('nn', 5, 14)), 4);
ok(!$m->is_done);
is($m->parse(pack('n', 1)), 2);
ok(!$m->is_done);
is($m->parse(pack('n', 1)), 2);
ok(!$m->is_done);
is($m->parse(pack('N', 0)), 4);
ok(!$m->is_done);
is($m->parse(pack('CCC', 255, 0, 0)), 1);
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [0, 0, 0, 255]
        }
    ]
);

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 2)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 5, 14, 1, 1, 0, 254)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 6, 15, 1, 1, 0, 255)));
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [0, 0, 0, 255]
        },
        {   x        => 6,
            y        => 15,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [0, 0, 0, 255]
        },
    ]
);

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNCC', 5, 14, 1, 2, 0, 255, 255)));
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 2,
            encoding => 'Raw',
            data     => [0, 0, 0, 255, 0, 0, 0, 255]
        },
    ]
);

# CopyRect encoding
$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNnn', 5, 14, 1, 2, 1, 20, 10)));
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 2,
            encoding => 'CopyRect',
            data     => [20, 10]
        },
    ]
);

