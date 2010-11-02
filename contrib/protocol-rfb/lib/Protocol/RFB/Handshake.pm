package Protocol::RFB::Handshake;

use strict;
use warnings;

use constant DEBUG => $ENV{PROTOCOL_RFB_DEBUG} ? 1 : 0;

use Protocol::RFB::MessageFactory;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub _build_message { shift; Protocol::RFB::MessageFactory->build(@_) }

sub req { @_ > 1 ? $_[0]->{req} = $_[1] : $_[0]->{req} }
sub res { @_ > 1 ? $_[0]->{res} = $_[1] : $_[0]->{res} }

sub state { @_ > 1 ? $_[0]->{state} = $_[1] : $_[0]->{state} }
sub done { shift->state('done') }
sub is_done { shift->state eq 'done' }

sub error { @_ > 1 ? $_[0]->{error} = $_[1] : $_[0]->{error} }

sub need_more_data {
    @_ > 1 ? $_[0]->{need_more_data} = $_[1] : $_[0]->{need_more_data};
}

sub width  { @_ > 1 ? $_[0]->{width}  = $_[1] : $_[0]->{width} }
sub height { @_ > 1 ? $_[0]->{height} = $_[1] : $_[0]->{height} }

sub server_name {
    @_ > 1 ? $_[0]->{server_name} = $_[1] : $_[0]->{server_name};
}
sub format { @_ > 1 ? $_[0]->{format} = $_[1] : $_[0]->{format} }

sub init {
    my $self   = shift;
    my %params = @_;

    $self->state('init');

    $self->req(undef);
    $self->res($self->_build_message('version'));

    $self->{password} = $params{password};

    return $self;
}

sub parse {
    my $self  = shift;
    my $chunk = shift;

    # Error
    return unless $self->res->parse($chunk);

    # Wait
    unless ($self->res->is_done) {
        $self->need_more_data(1);
        return 1;
    }

    $self->need_more_data(0);

    my $res_name = $self->res->name;

    if ($res_name eq 'version') {
        warn 'Received version' if DEBUG;

        $self->req(
            $self->_build_message(version => (major => 3, minor => 7)));
        $self->res($self->_build_message('security'));
    }
    elsif ($res_name eq 'security') {
        warn 'Received security type' if DEBUG;

        # Check what kind of security is available
        $self->req($self->_build_message(security => (type => 2)));
        $self->res($self->_build_message('authentication'));
    }
    elsif ($res_name eq 'authentication') {
        warn 'Received authentication' if DEBUG;

        $self->req(
            $self->_build_message(
                authentication => (
                    challenge => $self->res->challenge,
                    password  => $self->{password}
                )
            )
        );
        $self->res($self->_build_message('security_result'));
    }
    elsif ($res_name eq 'security_result') {
        warn 'Received security result' if DEBUG;

        return $self->error($self->res->error) if $self->res->error;

        # Initialization
        $self->req($self->_build_message('init'));
        $self->res($self->_build_message('init'));
    }
    elsif ($res_name eq 'init') {
        $self->width($self->res->width);
        $self->height($self->res->height);
        $self->server_name($self->res->server_name);
        $self->format($self->res->format);

        if (DEBUG) {
            warn 'Received settings';

            warn "name=" . $self->server_name;
            warn "width=" . $self->width;
            warn "height=" . $self->height;
        }

        $self->done;
    }

    return 1;
}

1;
