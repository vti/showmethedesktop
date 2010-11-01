package Protocol::RFB::Framebuffer;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    die 'width is required'  unless $self->{width};
    die 'height is required' unless $self->{height};

    $self->{x} ||= 0;
    $self->{y} ||= 0;

    $self->reset;

    return $self;
}

sub reset {
    my $self = shift;

    $self->{buffer} = [];
}

sub buffer { @_ > 1 ? $_[0]->{buffer} = $_[1] : $_[0]->{buffer} }

sub x  { @_ > 1 ? $_[0]->{x}  = $_[1] : $_[0]->{x} }
sub y  { @_ > 1 ? $_[0]->{y}  = $_[1] : $_[0]->{y} }

sub width  { @_ > 1 ? $_[0]->{width}  = $_[1] : $_[0]->{width} }
sub height { @_ > 1 ? $_[0]->{height} = $_[1] : $_[0]->{height} }

sub size { scalar @{shift->{buffer}} }

sub set_rectangle {
    my $self = shift;
    my ($start_x, $start_y, $width, $height, $data) = @_;

    my $max_x = $self->{width} + $self->{x};
    my $max_y = $self->{height} + $self->{y};
    for (my $i = 0; $i < @$data; $i++) {
       my $x = $start_x + $i % $width;
       my $y = $start_y + int($i / $width);

       if (   $x >= $self->{x}
           && $x < $max_x
           && $y >= $self->{y}
           && $y < $max_y
       )
       {
           $self->{buffer}->[($y - $self->{y}) * $self->{width} + $x - $self->{x}] = $data->[$i];
       }
    }
}

1;
