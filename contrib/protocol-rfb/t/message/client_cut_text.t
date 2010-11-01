#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok('Protocol::RFB::Message::ClientCutText');

my $m = Protocol::RFB::Message::ClientCutText->new;
is($m->prefix, 6);
$m->text('Hello, world!');
is("$m", pack('CC3N2', 6, 0, 13) . 'Hello, world!');
