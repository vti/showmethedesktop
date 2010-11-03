#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 86;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::WebSocket::Request';

my $req = ReAnimator::WebSocket::Request->new;

is $req->state => 'request_line';
ok !$req->is_done;
ok $req->parse;
ok $req->parse('');
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
is $req->state => 'fields';

ok $req->parse("Upgrade: WebSocket\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Connection: Upgrade\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Host: example.com\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Origin: http://example.com\x0d\x0a");
is $req->state => 'fields';
ok $req->parse(
    "Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8\x0d\x0a");
ok $req->parse(
    "Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("\x0d\x0aTm[K T2u");
is $req->state     => 'done';
is $req->key1      => '155712099';
is $req->key2      => '173347027';
is $req->challenge => 'Tm[K T2u';

is $req->version       => 76;
is $req->resource_name => '/demo';
is $req->host          => 'example.com';
is $req->origin        => 'http://example.com';
is $req->checksum      => 'fQJ,fN/4F4!~K~MH';

$req = ReAnimator::WebSocket::Request->new;

is $req->state => 'request_line';
ok !$req->is_done;
ok $req->parse;
ok $req->parse('');
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
is $req->state => 'fields';

ok $req->parse("Upgrade: WebSocket\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Connection: Upgrade\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Host: example.com\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Origin: http://example.com\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("\x0d\x0a");
is $req->state => 'done';

is $req->version       => 75;
is $req->resource_name => '/demo';
is $req->host          => 'example.com';
is $req->origin        => 'http://example.com';

ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Host: example.com\x0d\x0a");
ok $req->parse("Origin: null\x0d\x0a");
ok $req->parse("\x0d\x0a");
is $req->state => 'done';

$req = ReAnimator::WebSocket::Request->new;
is $req->state => 'request_line';
ok !$req->is_done;
ok not defined $req->parse("foo\x0d\x0a");
ok $req->is_state('error');

$req = ReAnimator::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Origin: http://example.com\x0d\x0a");
ok not defined $req->parse("\x0d\x0a");
is $req->state => 'error';

$req = ReAnimator::WebSocket::Request->new;
ok not defined $req->parse('x' x (1024 * 10));
is $req->state => 'error';

$req = ReAnimator::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: Foo\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Host: example.com\x0d\x0a");
ok $req->parse("Origin: http://example.com\x0d\x0a");
ok not defined $req->parse("\x0d\x0a");
is $req->state => 'error';

$req = ReAnimator::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Bar\x0d\x0a");
ok $req->parse("Host: example.com\x0d\x0a");
ok $req->parse("Origin: http://example.com\x0d\x0a");
ok not defined $req->parse("\x0d\x0a");
is $req->state => 'error';

$req = ReAnimator::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Host: example.com\x0d\x0a");
ok not defined $req->parse("\x0d\x0a");
is $req->state => 'error';
