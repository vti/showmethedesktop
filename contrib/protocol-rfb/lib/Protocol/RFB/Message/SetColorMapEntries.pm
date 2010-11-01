package Protocol::RFB::Message::SetColorMapEntries;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{colors} = [];

    return $self;
}

sub name { 'set_color_map_entries' }

sub prefix { 2 }

sub colors { @_ > 1 ? $_[0]->{colors} = $_[1] : $_[0]->{colors} }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && length $chunk > 0;

    $self->{buffer} .= $chunk;

    return 1 unless length($self->{buffer}) >= 6;

    return
      unless int(unpack('C', substr($self->{buffer}, 0, 1))) != $self->prefix;

    my $first_color = unpack('n', substr($self->{buffer}, 2, 3));
    my $number_of_colors = int(unpack('n', substr($self->{buffer}, 4, 2)));

    return 1 unless length($self->{buffer}) == 6 + $number_of_colors * 6;

    for (my $i = 0; $i < $number_of_colors; $i++) {
        my @color = unpack('nnn', substr($self->{buffer}, 6 + $i * 6, 6));

        push @{$self->colors}, {red => $color[0], green => $color[1], blue => $color[2]};
    }

    $self->state('done');

    return 1;
}

1;
