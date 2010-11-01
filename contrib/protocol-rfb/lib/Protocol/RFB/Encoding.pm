package Protocol::RFB::Encoding;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{data} = [];

    return $self;
}

sub data { @_ > 1 ? $_[0]->{data} = $_[1] : $_[0]->{data} }

1;
