#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 19;

use_ok('Protocol::RFB::Client');

my $client = Protocol::RFB::Client->new(password => '123');

my $on_handshake;
$client->on_handshake(sub { $on_handshake = 1 });
$client->on_write(sub { });

# Server sends version
$client->parse("RFB 003.007\x0a");
is($client->state, 'handshake');

# Server sends security types
$client->parse(pack('C', 1) . pack('C', 1));
is($client->state, 'handshake');

# Server sends authentication challenge
$client->parse(pack('C', 1) x 16);
is($client->state, 'handshake');

# Server sends security result
$client->parse(pack('N', 0));
is($client->state, 'handshake');

# Server sends initialization
ok($client->parse(pack('n', 800)));
ok($client->parse(pack('n', 600)));
ok( $client->parse(
        pack('ccccnnncccc3', 32, 32, 0, 1, 255, 255, 255, 8, 16, 0, 0)
    )
);
ok($client->parse(pack('N', 3)));
ok($client->parse('wow'));
is($client->state, 'ready');

# Server sends bell
ok($client->parse(pack('C', 2)));

# Server sends framebuffer update with Raw encoding
my $update =
  pack('CCnnnnnNCCCC', 0, 0, 1, 5, 14, 1, 1, 0, 128, 255, 128, 255);
ok($client->parse($update . $update . $update));

ok($client->parse(substr($update, 0, 5)));
ok($client->parse(substr($update, 5) . substr($update, 0, 3)));
ok($client->parse(substr($update, 3)));

# Server sends framebuffer update with CopyRect encoding
$client->on_framebuffer_update(
    sub { is_deeply($_[1]->rectangles->[0]->{data}, [128, 255]) });
$update = pack('CCnnnnnNnn', 0, 0, 1, 5, 14, 1, 1, 1, 128, 255);
ok($client->parse($update));

ok($on_handshake);
