package ReAnimator::WebSocket::Location;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{secure}        = 0   unless $self->{secure};
    $self->{resource_name} = '/' unless $self->{resource_name};

    return $self;
}

sub to_string {
    my $self = shift;

    my $string = '';

    $string .= 'ws';
    $string .= 's' if $self->{secure};
    $string .= '://';
    $string .= $self->{host};
    $string .= $self->{resource_name};

    return $string;
}

1;
