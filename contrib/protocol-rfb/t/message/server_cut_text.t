#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok('Protocol::RFB::Message::ServerCutText');

my $m = Protocol::RFB::Message::ServerCutText->new;
is($m->prefix, 3);
$m->text('Hello, world!');
is("$m", pack('CC3N2', 3, 0, 13) . 'Hello, world!');
