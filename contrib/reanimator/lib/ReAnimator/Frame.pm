package ReAnimator::Frame;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $buffer = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{buffer} = length $buffer ? $buffer : '';

    return $self;
}

sub append {
    my $self = shift;
    my $chunk = shift;

    $chunk = '' unless defined $chunk;

    $self->{buffer} .= $chunk;

    return $self;
}

sub next {
    my $self = shift;

    return unless $self->{buffer} =~ s/^[^\x00]*\x00(.*?)\xff//s;

    return $1;
}

sub to_string {
    my $self = shift;

    return "\x00" . $self->{buffer} . "\xff";
}

1;
