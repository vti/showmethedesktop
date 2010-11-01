package Protocol::RFB::Message::FramebufferUpdate;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use Protocol::RFB::Encodings;
use Protocol::RFB::Encoding::Raw;
use Protocol::RFB::Encoding::CopyRect;

sub new {
    my $self = shift->SUPER::new(@_);

    die 'pixel_format is required' unless $self->{pixel_format};

    $self->{rectangles} ||= [];

    return $self;
}

sub name { 'framebuffer_update' }

sub prefix { 0 }

sub rectangles { @_ > 1 ? $_[0]->{rectangles} = $_[1] : $_[0]->{rectangles} }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk;

    my $chunk_length = length $chunk;
    return unless $chunk_length > 0;

    $self->{buffer} .= $chunk;

    # Initialization state
    if ($self->state eq 'init') {
        return $chunk_length unless length $self->{buffer} >= 4;

        # Number of rectangles
        $self->{number} = int(join('', unpack('n', substr($self->{buffer}, 2, 2))));

        $self->{offset} = 4;

        $self->state('rectangle_header');
    }

    my $number = $self->{number};
    my $ri = scalar @{$self->rectangles};

    my $bytes_per_pixel = $self->{pixel_format}->bits_per_pixel / 8;

    for (my $i = $ri; $i < $number; $i++) {
        if ($self->state eq 'rectangle_header') {
            return $chunk_length unless length($self->{buffer}) - $self->{offset} >= 12;
            my $r = substr($self->{buffer}, $self->{offset}, 12);
            my @data = unpack('nnnnN', $r);
            my $rectangle =
              { x        => $data[0],
                y        => $data[1],
                width    => $data[2],
                height   => $data[3],
                encoding => Protocol::RFB::Encodings->encoding(int($data[4]))
              };

            $self->{rectangle} = $rectangle;

            $self->{offset} += 12;

            $self->state('rectangle');
        }

        my $rectangle = $self->{rectangle};

        my $encoding_class = "Protocol::RFB::Encoding::$rectangle->{encoding}";

        my $encoding = $encoding_class->new(
            pixel_format => $self->{pixel_format},
            rectangle    => $rectangle
        );

        my $bytes_parsed = $encoding->parse(substr($self->{buffer}, $self->{offset}));
        return $chunk_length unless $bytes_parsed;

        $self->{offset} += $bytes_parsed;

        $rectangle->{data} = $encoding->data;

        push @{$self->rectangles}, $rectangle;

        $self->state('rectangle_header');
    }

    $self->state('done');

    my $leftovers = length($self->{buffer}) - $self->{offset};
    return $chunk_length - $leftovers;
}

1;
