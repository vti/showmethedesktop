package Protocol::RFB::Message::PixelFormat;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use overload '""' => \&to_string;

sub bits_per_pixel  { @_ > 1 ? $_[0]->{format}->[0]  = $_[1] : $_[0]->{format}->[0]  }
sub depth           { @_ > 1 ? $_[0]->{format}->[1]  = $_[1] : $_[0]->{format}->[1]  }
sub big_endian_flag { @_ > 1 ? $_[0]->{format}->[2]  = $_[1] : $_[0]->{format}->[2]  }
sub true_color_flag { @_ > 1 ? $_[0]->{format}->[3]  = $_[1] : $_[0]->{format}->[3]  }
sub red_max         { @_ > 1 ? $_[0]->{format}->[4]  = $_[1] : $_[0]->{format}->[4]  }
sub green_max       { @_ > 1 ? $_[0]->{format}->[5]  = $_[1] : $_[0]->{format}->[5]  }
sub blue_max        { @_ > 1 ? $_[0]->{format}->[6]  = $_[1] : $_[0]->{format}->[6]  }
sub red_shift       { @_ > 1 ? $_[0]->{format}->[7]  = $_[1] : $_[0]->{format}->[7]  }
sub green_shift     { @_ > 1 ? $_[0]->{format}->[8]  = $_[1] : $_[0]->{format}->[8]  }
sub blue_shift      { @_ > 1 ? $_[0]->{format}->[9]  = $_[1] : $_[0]->{format}->[9]  }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && length $chunk > 0;

    $self->{buffer} .= $chunk;

    return 1 unless length($self->{buffer}) == 16;

    $self->{format} = [unpack('CCCCnnnCCCC3', $self->{buffer})];
    $_ = int for @{$self->{format}};

    $self->state('done');

    return 1;
}

sub to_string {
    my $self = shift;

    return pack('CC3CCCCnnnCCCC3', 0, 0, 0, 0, @{$self->{format}});
}

1;
