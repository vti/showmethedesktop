package Protocol::RFB::Message::FramebufferUpdateRequest;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use overload '""' => \&to_string;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{incremental} ||= 0;

    return $self;
}

sub name { 'framebuffer_update_request' }

sub prefix { 3 }

sub incremental {
    @_ > 1 ? $_[0]->{incremental} = $_[1] : $_[0]->{incremental};
}
sub x      { @_ > 1 ? $_[0]->{x}      = $_[1] : $_[0]->{x} }
sub y      { @_ > 1 ? $_[0]->{y}      = $_[1] : $_[0]->{y} }
sub width  { @_ > 1 ? $_[0]->{width}  = $_[1] : $_[0]->{width} }
sub height { @_ > 1 ? $_[0]->{height} = $_[1] : $_[0]->{height} }

sub to_string {
    my $self = shift;

    return pack('CCnnnn',
        $self->prefix, $self->incremental, $self->x, $self->y, $self->width,
        $self->height);
}

1;
