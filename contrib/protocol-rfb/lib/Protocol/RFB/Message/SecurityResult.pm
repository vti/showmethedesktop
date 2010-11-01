package Protocol::RFB::Message::SecurityResult;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use Protocol::RFB::Message::Error;

sub name { 'security_result' }

sub error { @_ > 1 ? $_[0]->{error} = $_[1] : $_[0]->{error} }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless $chunk;

    $self->{buffer} .= $chunk;

    return 1 unless length($self->{buffer}) >= 4;

    my $result = join('', unpack('C4', substr($self->{buffer}, 0, 4)));
    if (int($result)) {
        my $error = Protocol::RFB::Message::Error->new;
        my $buffer = substr($self->{buffer}, 4);

        if (length $buffer) {
            return unless $error->parse($buffer);
            return 1 unless $error->is_done;

            $self->error($error->reason);
        }
        else {
            $self->error('Authentication failed');
        }
    }

    $self->state('done');

    return 1;
}

1;
