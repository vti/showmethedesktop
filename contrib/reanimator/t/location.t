#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::WebSocket::Location';

my $l = ReAnimator::WebSocket::Location->new(
    host   => 'foo.com',
    secure => 1
);
is $l->to_string => 'wss://foo.com/';

$l = ReAnimator::WebSocket::Location->new(
    host          => 'foo.com',
    resource_name => '/demo'
);
is $l->to_string => 'ws://foo.com/demo';
