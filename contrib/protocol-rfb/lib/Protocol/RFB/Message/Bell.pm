package Protocol::RFB::Message::Bell;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

sub name { 'bell' }

sub prefix { 2 }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && length $chunk > 0;

    $self->{buffer} .= $chunk;

    return unless length($self->{buffer}) == 1;

    my $prefix = int(unpack('C', substr($self->{buffer}, 0, 1)));
    return unless $prefix == $self->prefix;

    $self->state('done');

    return 1;
}

1;
