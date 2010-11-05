package ReAnimator::Slave;

use strict;
use warnings;

use base 'ReAnimator::Connection';

sub address { @_ > 1 ? $_[0]->{address} = $_[1] : $_[0]->{address} }
sub port    { @_ > 1 ? $_[0]->{port}    = $_[1] : $_[0]->{port} }

1;
