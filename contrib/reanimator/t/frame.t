#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 18;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::Frame';

my $f = ReAnimator::Frame->new;

$f->append;
ok not defined $f->next;
$f->append('');
ok not defined $f->next;

$f->append('qwe');
ok not defined $f->next;
$f->append("\x00foo\xff");
is $f->next => 'foo';
ok not defined $f->next;

$f->append("\x00");
ok not defined $f->next;
$f->append("\xff");
is $f->next => '';

$f->append("\x00");
ok not defined $f->next;
$f->append("foo");
$f->append("\xff");
is $f->next => 'foo';

$f->append("\x00foo\xff\x00bar\n\xff");
is $f->next => 'foo';
is $f->next => "bar\n";
ok not defined $f->next;

$f->append("123\x00foo\xff56\x00bar\xff789");
is $f->next => 'foo';
is $f->next => 'bar';
ok not defined $f->next;

$f = ReAnimator::Frame->new;
is $f->to_string => "\x00\xff";

$f = ReAnimator::Frame->new('123');
is $f->to_string => "\x00123\xff";
