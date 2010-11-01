package Protocol::RFB::Message::KeyEvent;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use overload '""' => \&to_string;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{down} ||= 0;

    return $self;
}

sub name { 'key_event' }

sub prefix { 4 }

sub down { @_ > 1 ? $_[0]->{down} = $_[1] : $_[0]->{down} }
sub key  { @_ > 1 ? $_[0]->{key}  = $_[1] : $_[0]->{key} }

sub to_string {
    my $self = shift;

    return pack('CCnN', $self->prefix, $self->down, 0, $self->key);
}

1;
