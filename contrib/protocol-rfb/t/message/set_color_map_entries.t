#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;

use_ok('Protocol::RFB::Message::SetColorMapEntries');

ok(not defined Protocol::RFB::Message::SetColorMapEntries->new->parse());
ok(not defined Protocol::RFB::Message::SetColorMapEntries->new->parse(''));

my $m = Protocol::RFB::Message::SetColorMapEntries->new;
ok($m->parse(pack('C', 1)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 123)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnn', 1, 2, 3)));
ok($m->is_done);
is_deeply($m->colors, [{red => 1, green => 2, blue => 3}]);

$m = Protocol::RFB::Message::SetColorMapEntries->new;
ok($m->parse(pack('C', 1)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 123)));
ok(!$m->is_done);
ok($m->parse(pack('n', 2)));
ok(!$m->is_done);
ok($m->parse(pack('nnn', 1, 2, 3)));
ok(!$m->is_done);
ok($m->parse(pack('nnn', 3, 2, 1)));
ok($m->is_done);
is_deeply($m->colors,
    [{red => 1, green => 2, blue => 3}, {red => 3, green => 2, blue => 1}]);
