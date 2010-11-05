package ReAnimator::Loop::Poll;

use strict;
use warnings;

use IO::Poll qw/POLLIN POLLOUT POLLHUP POLLERR/;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    $self->{poll} = IO::Poll->new;

    return $self;
}

sub poll { shift->{poll} }

sub tick {
    my $self    = shift;
    my $timeout = shift;

    if ($self->poll->handles) {
        $self->poll->poll($timeout);
    }
    else {
        select(undef, undef, undef, $timeout);
    }
}

sub mask_rw {
    my $self   = shift;
    my $socket = shift;

    $self->poll->mask($socket => POLLIN | POLLOUT);
}

sub mask_ro {
    my $self   = shift;
    my $socket = shift;

    $self->poll->mask($socket => POLLIN);
}

sub readers { shift->poll->handles(POLLIN) }
sub writers { shift->poll->handles(POLLOUT) }
sub errors  { shift->poll->handles(POLLERR) }
sub hups    { shift->poll->handles(POLLHUP) }

sub remove { shift->poll->remove(@_) }

1;
