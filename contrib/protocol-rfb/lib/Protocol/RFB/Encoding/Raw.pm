package Protocol::RFB::Encoding::Raw;

use strict;
use warnings;

use base 'Protocol::RFB::Encoding';

my $IS_BIG_ENDIAN = unpack('h*', pack('s', 1)) =~ /01/ ? 1 : 0;

sub new {
    my $self = shift->SUPER::new(@_);

    die 'rectangle is required'    unless $self->{rectangle};
    die 'pixel_format is required' unless $self->{pixel_format};

    return $self;
}

sub parse {
    my $self  = shift;
    my $chunk = $_[0];

    my $pixel_format = $self->{pixel_format};

    my $bpp = $pixel_format->bits_per_pixel;

    my $rectangle_length =
      $self->{rectangle}->{width} * $self->{rectangle}->{height} * ($bpp / 8);

    return unless length($chunk) >= $rectangle_length;
    $chunk = substr($chunk, 0, $rectangle_length);

    my $unpack =
        ($pixel_format->big_endian_flag && !$IS_BIG_ENDIAN)
      ? $bpp == 32
          ? 'N'
          : $bpp == 16 ? 'n'
        : 'C'
      : $bpp == 32 ? 'L'
      : $bpp == 16 ? 'S'
      :              'C';

    my @pixels = unpack("$unpack*", $chunk);

    my $red_shift = $pixel_format->red_shift;
    my $red_max   = $pixel_format->red_max;

    my $green_shift = $pixel_format->green_shift;
    my $green_max   = $pixel_format->green_max;

    my $blue_shift = $pixel_format->blue_shift;
    my $blue_max   = $pixel_format->blue_max;

    my $cache = {};

    my $parsed = [];
    my $color;
    foreach my $pixel (@pixels) {
        if (exists $cache->{$pixel}) {
            $color = $cache->{$pixel};
        }
        else {
            $color = [
                ($pixel >> $red_shift) & $red_max,
                ($pixel >> $green_shift) & $green_max,
                ($pixel >> $blue_shift) & $blue_max,
                255
            ];
            $cache->{$pixel} = $color;
        }

        push @$parsed, @$color;
    }

    $self->data($parsed);

    return $rectangle_length;
}

1;
