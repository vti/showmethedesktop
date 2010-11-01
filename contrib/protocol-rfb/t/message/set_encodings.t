#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Protocol::RFB::Message::SetEncodings');

my $m = Protocol::RFB::Message::SetEncodings->new;
is($m->prefix, 2);
is("$m", pack('CCnN', 2, 0, 1, 0));

$m = Protocol::RFB::Message::SetEncodings->new;
is($m->prefix, 2);
$m->encodings(['CopyRect', 'Raw']);
is("$m", pack('CCnNN', 2, 0, 2, 1, 0));
