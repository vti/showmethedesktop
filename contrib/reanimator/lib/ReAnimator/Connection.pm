package ReAnimator::Connection;

use strict;
use warnings;

use base 'ReAnimator::Stateful';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{on_connect}    ||= sub { };
    $self->{on_disconnect} ||= sub { };

    $self->{on_read}  ||= sub { };
    $self->{on_write} ||= sub { };
    $self->{on_error} ||= sub { };

    $self->{chunks} = [];

    $self->state('init');

    return $self;
}

sub id {"$_[0]->{socket}"}
sub socket { @_ > 1 ? $_[0]->{socket} = $_[1] : $_[0]->{socket} }

sub on_connect { @_ > 1 ? $_[0]->{on_connect} = $_[1] : $_[0]->{on_connect} }

sub on_disconnect {
    @_ > 1 ? $_[0]->{on_disconnect} = $_[1] : $_[0]->{on_disconnect};
}
sub on_read  { @_ > 1 ? $_[0]->{on_read}  = $_[1] : $_[0]->{on_read} }
sub on_error { @_ > 1 ? $_[0]->{on_error} = $_[1] : $_[0]->{on_error} }

sub on_write { @_ > 1 ? $_[0]->{on_write} = $_[1] : $_[0]->{on_write} }

sub error {
    my $self  = shift;
    my $error = shift;

    return $self->{error} unless defined $error;

    $self->{error} = $error;
    $self->on_error->($self, $error);

    return $self;
}

sub connecting    { shift->state('connecting') }
sub is_connecting { shift->is_state('connecting') }

sub connected {
    my $self = shift;

    $self->state('connected');

    $self->on_connect->($self);

    return $self;
}

sub is_connected { shift->is_state('connected') }

sub disconnected {
    my $self = shift;

    $self->state('disconnected');

    $self->on_disconnect->($self);

    return $self;
}

sub read {
    my $self  = shift;
    my $chunk = shift;

    $self->on_read->($self, $chunk);

    return 1;
}

sub write {
    my $self  = shift;
    my $chunk = shift;
    my $cb    = shift;

    push @{$self->{chunks}}, [$chunk => $cb];

    $self->{buffer} .= $chunk;
    $self->on_write->($self);
}

sub bytes_written {
    my $self  = shift;
    my $count = shift;

    substr $self->{buffer}, 0, $count, '';

    while (my $chunk = $self->{chunks}->[0]) {
        my $length = length $chunk->[0];

        if ($count >= $length) {
            shift @{$self->{chunks}};

            $count -= $length;

            $chunk->[1]->($self) if $chunk->[1];

            next if $count > 0;

            last;
        }

        substr $chunk->[0], 0, $count, '';
        last;
    }

    return $self;
}

sub is_writing {
    my $self = shift;

    return length $self->{buffer} ? 1 : 0;
}

sub buffer { shift->{buffer} }

1;
