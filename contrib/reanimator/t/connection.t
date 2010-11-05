#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::Connection';

my $conn;
my $written;

$conn = ReAnimator::Connection->new;
$written = 0;
$conn->write('foo' => sub { $written = 1 });
ok !$written;
$conn->bytes_written(1);
ok !$written;
$conn->bytes_written(2);
ok $written;
is $conn->is_writing => 0;

$conn = ReAnimator::Connection->new;
$written = 0;
$conn->write('foo' => sub { $written++ });
$conn->write('bar' => sub { $written++ });
ok !$written;
$conn->bytes_written(1);
ok !$written;
$conn->bytes_written(5);
is $written => 2;
is $conn->is_writing => 0;

$conn = ReAnimator::Connection->new;
$written = 0;
$conn->write('foo' => sub { $written++ });
$conn->bytes_written(10);
is $written => 1;
is $conn->is_writing => 0;

$conn = ReAnimator::Connection->new;
$written = 0;
$conn->write('foo');
$conn->bytes_written(3);
is $conn->is_writing => 0;
