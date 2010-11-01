package Protocol::RFB::Message::Version;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use overload '""' => \&to_string;

sub name { 'version' }

sub major { @_ > 1 ? $_[0]->{major} = $_[1] : $_[0]->{major} }
sub minor { @_ > 1 ? $_[0]->{minor} = $_[1] : $_[0]->{minor} }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless $chunk;

    $self->{buffer} .= $chunk;

    return 1 unless length($self->{buffer}) == 12;

    return unless $self->{buffer} =~ m/^RFB (\d\d\d)\.(\d\d\d)\x0a$/;

    $self->major($1);
    $self->minor($2);

    $self->state('done');

    return 1;
}

sub to_string {
    my $self = shift;

    return "RFB " . sprintf('%03d', $self->major) . '.' . sprintf('%03d', $self->minor) . "\x0a";
}

1;
