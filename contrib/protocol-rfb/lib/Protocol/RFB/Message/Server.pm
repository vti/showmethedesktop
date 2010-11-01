package Protocol::RFB::Message::Server;

use strict;
use warnings;

use Protocol::RFB::Message::FramebufferUpdate;
use Protocol::RFB::Message::SetColorMapEntries;
use Protocol::RFB::Message::Bell;
use Protocol::RFB::Message::ServerCutText;

our $MESSAGES = {
    0 => 'Protocol::RFB::Message::FramebufferUpdate',
    1 => 'Protocol::RFB::Message::SetColorMapEntries',
    2 => 'Protocol::RFB::Message::Bell',
    3 => 'Protocol::RFB::Message::ServerCutText'
};

sub new {
    my $class = shift;

    my $self = {args => [@_]};
    bless $self, $class;

    return $self;
}

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && length $chunk > 0;

    my $message = $self->{message};
    unless ($message) {
        my $prefix = unpack('C', substr($chunk, 0, 1));

        my $class = $MESSAGES->{$prefix};
        return unless $class;

        $message = $self->{message} = $class->new(@{$self->{args}});
    }

    my $parsed = $message->parse($chunk);
    return unless defined $parsed;

    return $parsed;
}

sub submessage { shift->{message} }

sub name {
    my $self = shift;

    return $self->{message} ? $self->{message}->name : undef;
}

sub is_done {
    my $self = shift;

    return $self->{message} ? $self->{message}->is_done : undef;
}

1;
