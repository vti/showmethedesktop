package Protocol::RFB::Message::Error;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use overload '""' => \&to_string;

sub reason { @_ > 1 ? $_[0]->{reason} = $_[1] : $_[0]->{reason} }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && $chunk ne '';

    $self->{buffer} .= $chunk;

    return 1 unless length($self->{buffer}) >= 4;

    my $length = unpack('I', substr($self->{buffer}, 0, 4));
    return 1 unless length($self->{buffer}) == 4 + $length;

    $self->reason(substr($self->{buffer}, 4, $length));

    $self->done;

    return 1;
}

1;
