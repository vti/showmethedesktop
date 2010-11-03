package ReAnimator::WebSocket::Request;

use strict;
use warnings;

use base 'ReAnimator::Stateful';

use Digest::MD5 'md5';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{fields} = {};

    $self->version(76);
    $self->state('request_line');

    $self->{max_request_size} = 2048;

    return $self;
}

sub version { @_ > 1 ? $_[0]->{version} = $_[1] : $_[0]->{version} }

sub challenge { @_ > 1 ? $_[0]->{challenge} = $_[1] : $_[0]->{challenge} }

sub resource_name {
    @_ > 1 ? $_[0]->{resource_name} = $_[1] : $_[0]->{resource_name};
}

sub error {
    my $self = shift;

    return $self->{error} unless @_;

    my $error = shift;
    $self->{error} = $error;
    $self->state('error');

    return $self;
}

sub parse {
    my $self  = shift;
    my $chunk = shift;

    return 1 unless length $chunk;

    return if $self->error;

    $self->{buffer} .= $chunk;
    $chunk = $self->{buffer};

    if (length $chunk > $self->{max_request_size}) {
        $self->error('Request is too big');
        return;
    }

    while ($chunk =~ s/^(.*?)\x0d\x0a//) {
        my $line = $1;

        if ($self->state eq 'request_line') {
            my ($req, $resource_name, $http) = split ' ' => $line;

            unless ($req && $resource_name && $http) {
                $self->error('Wrong request line');
                return;
            }

            unless ($req eq 'GET' && $http eq 'HTTP/1.1') {
                $self->error('Wrong method or http version');
                return;
            }

            $self->resource_name($resource_name);

            $self->state('fields');
        }
        elsif ($line ne '') {
            my ($name, $value) = split ': ' => $line => 2;

            $self->{fields}->{$name} = $value;
        }
        else {
            $self->state('body');
        }
    }

    if ($self->state eq 'body') {
        if ($self->key1 && $self->key2) {
            return 1 if length $chunk < 8;

            if (length $chunk > 8) {
                $self->error('Body is too long');
                return;
            }

            $self->challenge($chunk);
        }
        else {
            $self->version(75);
        }

        return $self->done if $self->is_valid;

        $self->error('Not valid request');
        return;
    }

    return 1;
}

sub origin     { shift->{fields}->{'Origin'} }
sub host       { shift->{fields}->{'Host'} }
sub upgrade    { shift->{fields}->{'Upgrade'} }
sub connection { shift->{fields}->{'Connection'} }

sub checksum {
    my $self = shift;

    my $key1 = pack 'N' => $self->key1;
    my $key2 = pack 'N' => $self->key2;
    my $challenge = $self->challenge;

    return md5 $key1 . $key2 . $challenge;
}

sub key1 {
    my $self = shift;

    my $key = $self->{fields}->{'Sec-WebSocket-Key1'};
    return unless $key;

    return $self->key($key);
}

sub key2 {
    my $self = shift;

    my $key = $self->{fields}->{'Sec-WebSocket-Key2'};
    return unless $key;

    return $self->key($key);
}

sub key {
    my $self = shift;
    my $key  = shift;

    my $number = '';
    while ($key =~ m/(\d)/g) {
        $number .= $1;
    }
    $number = int($number);

    my $spaces = 0;
    while ($key =~ m/ /g) {
        $spaces++;
    }

    if ($spaces == 0) {
        return;
    }

    return $number / $spaces;
}

sub is_valid {
    my $self = shift;

    return unless $self->upgrade    && $self->upgrade    eq 'WebSocket';
    return unless $self->connection && $self->connection eq 'Upgrade';
    return unless $self->origin;
    return unless $self->host;

    return 1;
}

1;
