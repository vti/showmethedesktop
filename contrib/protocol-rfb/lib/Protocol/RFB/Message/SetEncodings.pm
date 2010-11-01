package Protocol::RFB::Message::SetEncodings;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use Protocol::RFB::Encodings;

use overload '""' => \&to_string;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{encodings} ||= ['Raw'];

    return $self;
}

sub name { 'set_encodings' }

sub prefix { 2 }

sub encodings { @_ > 1 ? $_[0]->{encodings} = $_[1] : $_[0]->{encodings} }

sub to_string {
    my $self = shift;

    my $string = pack('CCn', $self->prefix, 0, scalar @{$self->encodings});
    $string .= pack('N', $_) for map {Protocol::RFB::Encodings->encoding($_)} @{$self->encodings};
    return $string;
}

1;
