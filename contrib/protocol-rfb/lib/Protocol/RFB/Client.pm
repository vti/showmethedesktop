package Protocol::RFB::Client;

use strict;
use warnings;

use constant DEBUG => $ENV{PROTOCOL_RFB_DEBUG} ? 1 : 0;

use Protocol::RFB::Handshake;
use Protocol::RFB::MessageFactory;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{state} = 'init';

    $self->{version}   ||= '3.7';
    $self->{encodings} ||= [qw/CopyRect Raw/];

    $self->{handshake} = Protocol::RFB::Handshake->new;

    return $self;
}

sub handshake { shift->{handshake} }

sub _build_message { shift; Protocol::RFB::MessageFactory->build(@_) }

sub done { shift->state('done') }
sub is_done { shift->state =~ /done/ }

sub password { @_ > 1 ? $_[0]->{password} = $_[1] : $_[0]->{password} }

sub state     { @_ > 1 ? $_[0]->{state}     = $_[1] : $_[0]->{state} }
sub encodings { @_ > 1 ? $_[0]->{encodings} = $_[1] : $_[0]->{encodings} }

sub width  { @_ > 1 ? $_[0]->{width}  = $_[1] : $_[0]->{width} }
sub height { @_ > 1 ? $_[0]->{height} = $_[1] : $_[0]->{height} }

sub pixel_format {
    @_ > 1 ? $_[0]->{pixel_format} = $_[1] : $_[0]->{pixel_format};
}

sub server_name {
    @_ > 1 ? $_[0]->{server_name} = $_[1] : $_[0]->{server_name};
}

sub on_handshake {
    @_ > 1 ? $_[0]->{on_handshake} = $_[1] : $_[0]->{on_handshake};
}

sub on_write { @_ > 1 ? $_[0]->{on_write} = $_[1] : $_[0]->{on_write} }
sub on_error { @_ > 1 ? $_[0]->{on_error} = $_[1] : $_[0]->{on_error} }

sub on_framebuffer_update {
    @_ > 1
      ? $_[0]->{on_framebuffer_update} = $_[1]
      : $_[0]->{on_framebuffer_update};
}

sub set_color_map_entries {
    @_ > 1
      ? $_[0]->{set_color_map_entries} = $_[1]
      : $_[0]->{set_color_map_entries};
}
sub on_bell { @_ > 1 ? $_[0]->{on_bell} = $_[1] : $_[0]->{on_bell} }

sub on_server_cut_text {
    @_ > 1
      ? $_[0]->{on_server_cut_text} = $_[1]
      : $_[0]->{on_server_cut_text};
}

sub write {
    my $self = shift;

    $self->on_write->($self, $_[0]);
}

sub error {
    my $self  = shift;
    my $error = shift;

    return $self->{error} unless $error;

    $self->{error} = $error;
    $self->on_error->($self, $error);

    return $self;
}

sub parse {
    my $self  = shift;
    my $chunk = shift;

    warn '< ' . unpack 'h*' => $chunk if DEBUG;

    if ($self->state eq 'init') {
        warn 'Initialization state' if DEBUG;

        $self->state('handshake');

        $self->handshake->init(password => $self->password);

        warn 'Handshake state' if DEBUG;
    }

    return $self->_parse_handshake($chunk) if $self->state eq 'handshake';

    return $self->_parse_server_message($chunk) if $self->state eq 'ready';

    warn "Unknown state";

    return;
}

sub _parse_handshake {
    my $self  = shift;
    my $chunk = shift;

    my $handshake = $self->handshake;

    # Error
    return unless $handshake->parse($chunk);

    # Wait
    return 1 if $handshake->need_more_data;

    # Send request
    unless ($handshake->is_done) {
        warn '> '
          . $handshake->req->to_hex . ' ('
          . $handshake->req->name . ')'
          if DEBUG;

        $self->write($handshake->req->to_string);
        return 1;
    }

    $self->_setup_after_handshake;

    $self->state('ready');

    $self->_send_init_messages;

    warn 'Call on_handshake callback' if DEBUG;
    $self->on_handshake->($self);

    return 1;
}

sub _setup_after_handshake {
    my $self = shift;

    warn 'Setup after handshake' if DEBUG;

    my $handshake = $self->handshake;

    $self->width($handshake->width);
    $self->height($handshake->height);

    $self->server_name($handshake->server_name);

    $self->pixel_format($handshake->format);
}

sub _send_init_messages {
    my $self = shift;

    warn 'Sending initializing message' if DEBUG;

    $self->set_pixel_format;

    $self->set_encodings;
}

sub _parse_server_message {
    my $self  = shift;
    my $chunk = shift;

    while (length($chunk) > 0) {
        my $message = $self->{server_message};
        if (!$message || $message->is_done) {
            $message = $self->{server_message} = $self->_build_message(
                server => (pixel_format => $self->pixel_format));
        }

        my $parsed = $message->parse($chunk);
        return unless defined $parsed;

        return 1 unless $message->is_done;

        $chunk = length($chunk) > $parsed ? substr($chunk, $parsed) : "";

        my $cb = 'on_' . $message->name;

        $self->$cb->($self, $message->submessage) if $self->$cb;
    }

    return 1;
}

sub framebuffer_update_request {
    my $self = shift;
    my ($x, $y, $width, $height, $incremental) = @_;

    my $m = $self->_build_message(
        framebuffer_update_request => (
            x           => $x,
            y           => $y,
            width       => $width,
            height      => $height,
            incremental => $incremental || 0
        )
    );

    $self->write($m->to_string);
}

sub set_pixel_format {
    my $self = shift;

    my $format = $self->pixel_format->{format};

    my $m = $self->_build_message(pixel_format => (format => $format));

    warn 'Set pixel format' if DEBUG;

    $self->write($m->to_string);
}

sub set_encodings {
    my $self = shift;

    my $encodings = $self->encodings;

    my $m = $self->_build_message(set_encodings => (encodings => $encodings));

    warn 'Set encodings' if DEBUG;

    $self->write($m->to_string);
}

sub pointer_event {
    my $self = shift;
    my ($x, $y, $mask) = @_;

    my $m = $self->_build_message(
        pointer_event => (
            x           => $x,
            y           => $y,
            button_mask => $mask
        )
    );

    $self->write($m->to_string);
}

sub key_event {
    my $self = shift;
    my ($is_down, $key) = @_;

    my $m = $self->_build_message(
        key_event => (
            down => $is_down,
            key  => $key
        )
    );

    $self->write($m->to_string);
}

1;
