package ReAnimator::Client;

use strict;
use warnings;

use base 'ReAnimator::Connection';

use ReAnimator::WebSocket::Handshake;
use ReAnimator::WebSocket::Frame;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{frame}     = ReAnimator::WebSocket::Frame->new;
    $self->{handshake} = ReAnimator::WebSocket::Handshake->new;

    $self->{on_message}   ||= sub { };
    $self->{on_handshake} ||= sub { };

    $self->{buffer} = '';

    $self->connected;

    return $self;
}

sub handshake { @_ > 1 ? $_[0]->{handshake} = $_[1] : $_[0]->{handshake} }

sub on_message { @_ > 1 ? $_[0]->{on_message} = $_[1] : $_[0]->{on_message} }

sub on_handshake {
    @_ > 1 ? $_[0]->{on_handshake} = $_[1] : $_[0]->{on_handshake};
}

sub read {
    my $self  = shift;
    my $chunk = shift;

    unless ($self->handshake->is_done) {
        my $handshake = $self->handshake;

        my $rs = $handshake->parse($chunk);
        return unless defined $rs;

        if ($handshake->is_done) {
            my $res = $handshake->res->to_string;

            $self->write(
                $res => sub {
                    my $self = shift;

                    $self->on_handshake->($self);
                }
            );

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

    return unless $self->handshake->is_done;

    my $frame = ReAnimator::WebSocket::Frame->new($message);
    $self->write($frame->to_string);
}

1;
