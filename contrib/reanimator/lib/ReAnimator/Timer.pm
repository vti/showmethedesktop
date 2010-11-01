package ReAnimator::Timer;

use strict;
use warnings;

use Time::HiRes 'time';

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    $self->{set_time} = time;

    return $self;
}

sub shot { @_ > 1 ? $_[0]->{shot} = $_[1] : $_[0]->{shot} }

sub interval { @_ > 1 ? $_[0]->{interval} = $_[1] : $_[0]->{interval} }
sub set_time { @_ > 1 ? $_[0]->{set_time} = $_[1] : $_[0]->{set_time} }

sub elapsed {
    my $self = shift;

    if (time - $self->set_time >= $self->interval) {
        $self->set_time(time);
        return 1;
    }

    return 0;
}

1;
