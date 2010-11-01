package Protocol::RFB::Message;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{state}  = 'init';
    $self->{buffer} = '';

    return $self;
}

sub done { shift->state('done') }
sub state { @_ > 1 ? $_[0]->{state} = $_[1] : $_[0]->{state} }

sub is_done { shift->state eq 'done' }

sub to_hex {
    my $self = shift;

    return unpack "h*" => $self->to_string;
}

1;
