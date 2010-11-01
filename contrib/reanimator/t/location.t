#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::Location';

my $l = ReAnimator::Location->new(
    host   => 'foo.com',
    secure => 1
);
is $l->to_string => 'wss://foo.com/';

$l = ReAnimator::Location->new(
    host          => 'foo.com',
    resource_name => '/demo'
);
is $l->to_string => 'ws://foo.com/demo';
