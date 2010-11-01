package Protocol::RFB::Message::Init;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use Protocol::RFB::Message::PixelFormat;

use overload '""' => \&to_string;

sub width  { @_ > 1 ? $_[0]->{width}  = $_[1] : $_[0]->{width} }
sub height { @_ > 1 ? $_[0]->{height} = $_[1] : $_[0]->{height} }
sub format { @_ > 1 ? $_[0]->{format} = $_[1] : $_[0]->{format} }

sub server_name {
    @_ > 1 ? $_[0]->{server_name} = $_[1] : $_[0]->{server_name};
}

sub name {'init'}

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && length $chunk > 0;

    $self->{buffer} .= $chunk;

    return 1 unless length($self->{buffer}) > 2 + 2 + 16 + 4;

    $self->width(int(join('', unpack('n2', substr($self->{buffer}, 0, 2)))));
    $self->height(int(join('', unpack('n2', substr($self->{buffer}, 2, 2)))));

    $self->format(Protocol::RFB::Message::PixelFormat->new);

    return unless $self->format->parse(substr($self->{buffer}, 4, 16));
    return 1 unless $self->format->is_done;

    my $server_name_length =
      int(join('', unpack('C4', substr($self->{buffer}, 20, 4))));

    return 1
      unless length($self->{buffer}) == 2 + 2 + 16 + 4 + $server_name_length;

    $self->server_name(substr($self->{buffer}, 24));

    $self->state('done');

    return 1;
}

sub to_string {
    my $self = shift;

    return pack('C', 1);
}

1;
