package Protocol::RFB::MessageFactory;

use strict;
use warnings;

sub build {
    shift;
    my $name = shift;

    $name = join '' => map {ucfirst} split '_' => $name;
    my $class_name = 'Protocol::RFB::Message::' . $name;

    unless ($class_name->can('new')) {
        eval "require $class_name";
        die $@ if $@;
    }

    return $class_name->new(@_);
}

1;
