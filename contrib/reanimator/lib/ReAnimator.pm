package ReAnimator;

use strict;
use warnings;

use ReAnimator::Client;
use ReAnimator::Slave;
use ReAnimator::Timer;
use Time::HiRes 'time';

use IO::Socket;
use IO::Poll qw/POLLIN POLLOUT POLLHUP POLLERR/;
use Errno qw/EAGAIN EWOULDBLOCK/;

use constant DEBUG => $ENV{DEBUG} ? 1 : 0;

our $VERSION = '0.0001';

$SIG{PIPE} = 'IGNORE';

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    $self->{host} ||= 'localhost';
    $self->{port} ||= '3000';

    $self->{poll} = IO::Poll->new;

    $self->{on_connect} ||= sub { };
    $self->{on_error}   ||= sub { };

    $self->{connections} = {};
    $self->{timers}      = {};

    return $self;
}

sub on_connect { @_ > 1 ? $_[0]->{on_connect} = $_[1] : $_[0]->{on_connect} }
sub on_error   { @_ > 1 ? $_[0]->{on_error}   = $_[1] : $_[0]->{on_error} }

sub start {
    my $self = shift;

    my $host = $self->host;
    my $port = $self->port;

    $self->{server} = IO::Socket::INET->new(
        Proto       => 'tcp',
        LocalAddres => $host,
        LocalPort   => $port,
        Type        => SOCK_STREAM,
        Listen      => SOMAXCONN,
        ReuseAddr   => 1,
        Blocking    => 0
    );

    $self->server->blocking(0);

    print "Listening on $host:$port\n";

    $self->poll->mask($self->{server} => POLLIN | POLLOUT);

    $self->loop;
}

sub poll   { shift->{poll} }
sub server { shift->{server} }
sub host   { shift->{host} }
sub port   { shift->{port} }

sub connections { shift->{connections} }
sub timers      { shift->{timers} }

sub loop {
    my $self = shift;

    while (1) {
        $self->_loop_once;

        $self->_timers;

        $self->_read;

        $self->_write;
    }
}

sub _loop_once {
    my $self = shift;

    my $timeout = 0.1;

    if ($self->poll->handles) {
        $self->poll->poll($timeout);
    }
    else {
        select(undef, undef, undef, $timeout);
    }
}

sub _timers {
    my $self = shift;

    foreach my $id (keys %{$self->timers}) {
        my $timer = $self->timers->{$id};

        if ($timer->{timer}->elapsed) {
            $timer->{cb}->();
            delete $self->timers->{$id} if $timer->{timer}->shot;
        }
    }
}

sub _read {
    my $self = shift;

    foreach my $socket ($self->poll->handles(POLLIN | POLLERR)) {
        if ($socket == $self->server) {
            $self->add_client($socket->accept);
            next;
        }

        my $rb = sysread($socket, my $chunk, 1024);

        unless ($rb) {
            next if $! && $! == EAGAIN || $! == EWOULDBLOCK;

            $self->drop_connection("$socket");
            next;
        }

        warn '< ', $chunk if DEBUG;

        my $client = $self->get_connection("$socket");

        my $read = $client->read($chunk);

        unless (defined $read) {
            $self->drop_connection("$socket")
        }
    }
}

sub _write {
    my $self = shift;

    foreach my $socket ($self->poll->handles(POLLOUT | POLLERR | POLLHUP)) {
        if ($socket == $self->server) {
            next;
        }

        my $id = "$socket";

        my $c = $self->get_connection($id);

        warn '> ' . $c->buffer if DEBUG;

        my $br = syswrite($c->socket, $c->buffer);

        unless ($br) {
            next if $! == EAGAIN || $! == EWOULDBLOCK;

            $self->drop_connection($id);
            next;
        }

        $c->bytes_written($br);

        $self->poll->mask($socket => POLLIN) unless $c->is_writing;
    }
}

sub add_client {
    my $self   = shift;
    my $socket = shift;

    $self->_register_socket($socket);

    printf "[New client from %s]\n", $socket->peerhost;

    my $id = "$socket";

    my $client = ReAnimator::Client->new(
        id         => $id,
        socket     => $socket,
        on_connect => sub {
            $self->on_connect->($self, @_);
        },
        on_write => sub {
            my $client = shift;

            $self->poll->mask($client->socket => POLLIN | POLLOUT);
        }
    );

    $self->connections->{$id} = $client;
}

sub add_slave {
    my $self = shift;
    my $c    = shift;

    my $socket = IO::Socket::INET->new(
        Proto => 'tcp',
        Type  => SOCK_STREAM
    );

    $socket->blocking(0);

    my $id = "$socket";

    $self->_register_socket($socket);

    $c->id($id);
    $c->socket($socket);

    $self->connections->{$id} = $c;

    $c->on_write(
        sub {
            my $c = shift;

            $self->poll->mask($c->socket => POLLIN | POLLOUT);
        }
    );

    my $addr = sockaddr_in($c->port, inet_aton($c->address));
    my $result = $socket->connect($addr);
}

sub set_timeout {
    my $self = shift;
    my ($interval, $cb) = @_;

    my $timer = ReAnimator::Timer->new(interval => $interval, shot => 1);

    $self->_add_timer($timer, $cb);

    return $self;
}

sub set_interval {
    my $self = shift;
    my ($interval, $cb) = @_;

    my $timer = ReAnimator::Timer->new(interval => $interval);

    $self->_add_timer($timer, $cb);

    return $self;
}

sub _add_timer {
    my $self = shift;
    my ($timer, $cb) = @_;

    $self->timers->{"$timer"} = {timer => $timer, cb => $cb};
}

sub _register_socket {
    my $self   = shift;
    my $socket = shift;

    $self->poll->mask($socket => POLLIN);
    #$self->poll->mask($socket => POLLIN | POLLOUT);
    #$self->poll->mask($socket => POLLOUT);
}

sub get_connection {
    my $self = shift;
    my $id   = shift;

    return $self->connections->{$id};
}

sub drop_connection {
    my $self = shift;
    my $id   = shift;

    my $c = $self->connections->{$id};

    print "Connection closed\n";

    $self->poll->remove($c->socket);
    close $c->socket;

    delete $self->connections->{$id};
}

sub clients {
    my $self = shift;

    return map { $self->get_connection($_) }
      grep     { $self->connections->{$_}->isa('ReAnimator::Client') }
      keys %{$self->connections};
}

sub slaves {
    my $self = shift;

    return map { $self->get_connection($_) }
      grep     { $self->connections->{$_}->isa('ReAnimator::Slave:') }
      keys %{$self->connections};
}

sub send_broadcast_message {
    my $self    = shift;
    my $message = shift;

    foreach my $client ($self->clients) {
        $client->send_message($message);
    }
}

1;
