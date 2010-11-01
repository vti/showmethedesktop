package Protocol::RFB::Message::Security;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use Protocol::RFB::Message::Error;

use overload '""' => \&to_string;

sub types { @_ > 1 ? $_[0]->{types} = $_[1] : $_[0]->{types} }
sub type  { @_ > 1 ? $_[0]->{type}  = $_[1] : $_[0]->{type} }

sub name { 'security' }

sub error { @_ > 1 ? $_[0]->{error} = $_[1] : $_[0]->{error} }

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{types} = [];

    return $self;
}

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless $chunk;

    $self->{buffer} .= $chunk;

    if (my $length = unpack('C', substr($self->{buffer}, 0, 1))) {
        return 1 unless $length == length($self->{buffer}) - 1;

        my $types = [];
        my $i = 0;
        while ($i < $length) {
            push @$types, unpack('C', substr($self->{buffer}, $i + 1, 1));
            $i++;
        }

        $self->types($types);
        $self->state('done');
    }
    else {
        my $error = Protocol::RFB::Message::Error->new;
        return unless $error->parse(substr($self->{buffer}, 1));

        return 1 unless $error->is_done;

        $self->error($error->reason);
        $self->state('done');
    }

    return 1;
}

sub to_string {
    my $self = shift;

    return pack('C', $self->type);
}

1;
