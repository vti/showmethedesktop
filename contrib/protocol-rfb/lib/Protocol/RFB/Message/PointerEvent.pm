package Protocol::RFB::Message::PointerEvent;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use overload '""' => \&to_string;

sub name { 'pointer_event' }

sub prefix { 5 }

sub button_mask {
    @_ > 1 ? $_[0]->{button_mask} = $_[1] : $_[0]->{button_mask};
}

sub x { @_ > 1 ? $_[0]->{x} = $_[1] : $_[0]->{x} }
sub y { @_ > 1 ? $_[0]->{y} = $_[1] : $_[0]->{y} }

sub to_string {
    my $self = shift;

    return pack('CCnn', $self->prefix, $self->button_mask, $self->x, $self->y);
}

1;
