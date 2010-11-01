package ReAnimator::Client;

use strict;
use warnings;

use base 'ReAnimator::Connection';

use ReAnimator::Handshake;
use ReAnimator::Frame;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{frame}     = ReAnimator::Frame->new;
    $self->{handshake} = ReAnimator::Handshake->new;

    $self->{buffer} = '';

    $self->state('handshake');

    return $self;
}

sub is_connected { shift->is_state('connected') }

sub connected {
    my $self = shift;

    $self->state('connected');

    $self->on_connect->($self);
}

sub read {
    my $self  = shift;
    my $chunk = shift;

    if ($self->is_state('handshake')) {
        my $handshake = $self->{handshake};

        my $rs = $handshake->parse($chunk);
        return unless defined $rs;

        if ($handshake->is_done) {
            my $res = $handshake->res->to_string;

            $self->write($res);
            $self->connected;

            return 1;
        }
    }

    my $frame = $self->{frame};
    $frame->append($chunk);

    while (my $message = $frame->next) {
        $self->on_message->($self, $message);
    }

    return 1;
}

sub send_message {
    my $self    = shift;
    my $message = shift;

    return unless $self->is_connected;

    my $frame = ReAnimator::Frame->new($message);
    $self->write($frame->to_string);
}

1;
