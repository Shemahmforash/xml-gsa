package XML::GSA::Group::Record;

use strict;
use warnings;

use XML::Writer;
use Data::Dumper;
use Carp;
use DateTime    ();
use Date::Parse ();

sub new {
    my $class = shift;

    return bless { @_, 'writer' => XML::Writer->new( OUTPUT => 'self', ) },
        ref $class || $class;
}

sub to_string {
    my $self = shift;

    my $string;

    return $self->writer->to_string();
}

1;
