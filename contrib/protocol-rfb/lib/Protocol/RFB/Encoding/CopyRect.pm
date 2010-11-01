package Protocol::RFB::Encoding::CopyRect;

use strict;
use warnings;

use base 'Protocol::RFB::Encoding';

sub parse {
    my $self = shift;
    my $chunk = $_[0];

    return unless length($chunk) >= 4;

    $self->data([unpack("nn", $chunk)]);

    return 4;
}

1;
