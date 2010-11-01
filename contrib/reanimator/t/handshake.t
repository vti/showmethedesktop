#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::Handshake';

my $h = ReAnimator::Handshake->new;

ok !$h->is_done;
ok $h->parse;
ok !$h->is_done;
ok $h->parse('');
ok !$h->is_done;
ok $h->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $h->parse("Upgrade: WebSocket\x0d\x0a");
ok $h->parse("Connection: Upgrade\x0d\x0a");
ok $h->parse("Host: example.com\x0d\x0a");
ok $h->parse("Origin: file://\x0d\x0a");
ok $h->parse(
    "Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8\x0d\x0a");
ok $h->parse(
    "Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0\x0d\x0a");
ok $h->parse("\x0d\x0aTm[K T2u");
ok $h->is_done;

my $string = '';
$string .= "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a";
$string .= "Upgrade: WebSocket\x0d\x0a";
$string .= "Connection: Upgrade\x0d\x0a";
$string .= "Sec-WebSocket-Origin: file://\x0d\x0a";
$string .= "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a";
$string .= "\x0d\x0a";
$string .= "fQJ,fN/4F4!~K~MH";
is $h->res->to_string => $string;
