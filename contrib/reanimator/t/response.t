#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::Response';

my $res = ReAnimator::Response->new;
$res->checksum('fQJ,fN/4F4!~K~MH');
$res->host('example.com');
$res->resource_name('/demo');
$res->origin('file://');

my $string = '';
$string .= "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a";
$string .= "Upgrade: WebSocket\x0d\x0a";
$string .= "Connection: Upgrade\x0d\x0a";
$string .= "Sec-WebSocket-Origin: file://\x0d\x0a";
$string .= "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a";
$string .= "\x0d\x0a";
$string .= "fQJ,fN/4F4!~K~MH";

is $res->to_string => $string;

$res = ReAnimator::Response->new;
$res->version(75);
$res->host('example.com');
$res->resource_name('/demo');
$res->origin('file://');

$string = '';
$string .= "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a";
$string .= "Upgrade: WebSocket\x0d\x0a";
$string .= "Connection: Upgrade\x0d\x0a";
$string .= "Sec-WebSocket-Origin: file://\x0d\x0a";
$string .= "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a";
$string .= "\x0d\x0a";

is $res->to_string => $string;
