package Protocol::RFB::Message::Authentication;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use Crypt::DES;

use overload '""' => \&to_string;

sub challenge { @_ > 1 ? $_[0]->{challenge} = $_[1] : $_[0]->{challenge} }
sub password  { @_ > 1 ? $_[0]->{password}  = $_[1] : $_[0]->{password} }

sub name {'authentication'}

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless $chunk;

    $self->{buffer} .= $chunk;

    return 1 unless length($self->{buffer}) == 16;

    $self->challenge($self->{buffer});

    $self->done;

    return 1;
}

sub to_string {
    my $self = shift;

    # Use only first 8 bytes
    my $key = substr($self->password, 0, 8);

    # Swap bits in bytes
    $key = pack('b*', unpack('B*', $key));

    # Append with zeros
    while (length $key < 8) {
        $key .= pack('C', 0);
    }

    my $cipher = Crypt::DES->new($key);

    my $result = '';

    $result .= $cipher->encrypt(substr($self->challenge, 0, 8));
    $result .= $cipher->encrypt(substr($self->challenge, 8, 8));

    return $result;
}

1;
