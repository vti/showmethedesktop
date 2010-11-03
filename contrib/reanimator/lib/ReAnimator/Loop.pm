package ReAnimator::Loop;

use strict;
use warnings;

use ReAnimator::Loop::Poll;

sub build {
    return ReAnimator::Loop::Poll->new
}

1;
