package ReAnimator;

use strict;
use warnings;

use ReAnimator::Client;
use ReAnimator::Socket;
use ReAnimator::Slave;
use ReAnimator::Timer;
use ReAnimator::Loop;

use IO::Socket;
use Errno qw/EAGAIN EWOULDBLOCK EINPROGRESS/;

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

    $self->{loop} = $self->build_loop;

    $self->{on_connect} ||= sub { };
    $self->{on_error}   ||= sub { };

    $self->{connections} = {};
    $self->{timers}      = {};

    return $self;
}

sub build_loop { ReAnimator::Loop->build }

sub on_connect { @_ > 1 ? $_[0]->{on_connect} = $_[1] : $_[0]->{on_connect} }
sub on_error   { @_ > 1 ? $_[0]->{on_error}   = $_[1] : $_[0]->{on_error} }

sub start {
    my $self = shift;

    my $host = $self->host;
    my $port = $self->port;

    my $socket = ReAnimator::Socket->new($host, $port);
    die "Can't create server" unless $socket;

    $self->{server} = $socket;

    $self->loop->mask_rw($self->server);

    print "Listening on $host:$port\n";

    $self->loop_until_i_die;
}

sub loop   { shift->{loop} }
sub server { shift->{server} }
sub host   { shift->{host} }
sub port   { shift->{port} }

sub connections { shift->{connections} }
sub timers      { shift->{timers} }

sub loop_until_i_die {
    my $self = shift;

    while (1) {
        $self->loop->tick(0.1);

        $self->_timers;

        $self->_read($_) for $self->loop->readers;

        $self->_write($_) for $self->loop->writers;
    }
}

sub _timers {
    my $self = shift;

    foreach my $id (keys %{$self->timers}) {
        my $timer = $self->timers->{$id};

        if ($timer->wake_up) {
            delete $self->timers->{$id} if $timer->one_shot;
        }
    }
}

sub _read {
    my $self   = shift;
    my $socket = shift;

    if ($socket == $self->server) {
        $self->add_client($socket->accept);
        return;
    }

    my $conn = $self->connection($socket);

    my $rb = sysread($socket, my $chunk, 1024);

    unless ($rb) {
        return if $! && $! == EAGAIN || $! == EWOULDBLOCK;

        $self->drop($conn);
        return;
    }

    warn '< ', $chunk if DEBUG;

    my $read = $conn->read($chunk);

    unless (defined $read) {
        $self->drop($conn);
    }
}

sub _write {
    my $self   = shift;
    my $socket = shift;

    return if $socket == $self->server;

    my $conn = $self->connection($socket);

    if ($conn->is_connecting) {
        unless ($socket->connected) {
            $self->drop($conn);
            return;
        }

        $conn->connected;

        return unless $conn->is_writing;
    }

    warn '> ' . $conn->buffer if DEBUG;

    my $br = syswrite($conn->socket, $conn->buffer);

    unless ($br) {
        return if $! == EAGAIN || $! == EWOULDBLOCK;

        $self->drop($conn);
        return;
    }

    $conn->bytes_written($br);

    $self->loop->mask_ro($socket) unless $conn->is_writing;
}

sub add_client {
    my $self   = shift;
    my $socket = shift;

    printf "[New client from %s]\n", $socket->peerhost if DEBUG;

    my $client = ReAnimator::Client->new(
        socket     => $socket,
        on_connect => sub {
            $self->on_connect->($self, @_);
        }
    );

    $self->add_conn($client);

    return $self;
}

sub add_slave {
    my $self = shift;
    my $conn = shift;

    my $socket = ReAnimator::Socket->new;
    $conn->socket($socket);

    $self->add_conn($conn);

    my $ip = gethostbyname($conn->address);
    my $addr = sockaddr_in($conn->port, $ip);

        $socket->connect($addr) == 0 ? $conn->connected
      : $! == EINPROGRESS            ? $conn->connecting
      :                                $self->drop($conn);

    return $self;
}

sub add_conn {
    my $self = shift;
    my $conn = shift;

    $self->loop->mask_rw($conn->socket);
    $conn->on_write(sub { $self->loop->mask_rw($conn->socket) });

    $self->connections->{$conn->id} = $conn;

    return $self;
}

sub set_timeout { shift->set_interval(@_, one_shot => 1) }

sub set_interval {
    my $self     = shift;
    my $interval = shift;
    my $cb       = shift;

    my $timer = ReAnimator::Timer->new(interval => $interval, cb => $cb, @_);

    $self->_add_timer($timer);

    return $self;
}

sub _add_timer {
    my $self  = shift;
    my $timer = shift;

    $self->timers->{"$timer"} = $timer;
}

sub connection {
    my $self = shift;
    my $id   = shift;

    $id = "$id" if ref $id;

    return $self->connections->{$id};
}

sub drop {
    my $self = shift;
    my $conn = shift;

    my $id = $conn->id;

    $self->loop->remove($conn->socket);

    close $conn->socket;

    if ($!) {
        print "Connection error: $!\n" if DEBUG;

        my $error = $!;
        undef $!;
        $conn->error($error);
    }
    else {
        print "Connection closed\n" if DEBUG;

        $conn->disconnected;
    }

    delete $self->connections->{$id};

    return $self;
}

sub clients {
    my $self = shift;

    return map { $self->connection($_) }
      grep     { $self->connections->{$_}->isa('ReAnimator::Client') }
      keys %{$self->connections};
}

sub slaves {
    my $self = shift;

    return map { $self->connection($_) }
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
