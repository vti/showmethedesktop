package ReAnimator::Socket;

use strict;
use warnings;

use IO::Socket;

sub new {
    my $class = shift;

    return $class->_build_server(@_) if @_;

    return $class->_build_client;
}

sub _build_server {
    shift;
    my ($host, $port) = @_;

    my $socket = IO::Socket::INET->new(
        Proto       => 'tcp',
        LocalAddres => $host,
        LocalPort   => $port,
        Type        => SOCK_STREAM,
        Listen      => SOMAXCONN,
        ReuseAddr   => 1,
        Blocking    => 0
    );

    $socket->blocking(0);

    return $socket;
}

sub _build_client {
    shift;

    my $socket = IO::Socket::INET->new(
        Proto    => 'tcp',
        Type     => SOCK_STREAM,
        Blocking => 0
    );

    $socket->blocking(0);

    return $socket;
}

1;
