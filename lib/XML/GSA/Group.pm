package XML::GSA::Group;

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

#getters and setters
sub action {
    my ( $self, $value ) = @_;

    $self->{'action'} = $value
        if $value && $value =~ /(add|delete)/;

    return $self->{'action'};
}

sub writer {
    my $self = shift;

    return $self->{'writer'};
}

sub records {
    my $self = shift;

    return $self->{'records'} || [];
}

sub create {
    my ( $self, $values ) = @_;

    $self->writer->startTag( 'group', %attributes );

    for my $value ( @{ $values || [] } ) {
        my $record = XML::GSA::Record->new();
        $self->add_record( $record );
    } 

    $self->writer->endTag('group');

    #TODO: what should one return string representation of the xml?
}

#other public methods
sub add_record {
    my ( $self, $record ) = @_;

    return unless ref $record eq XML::GSA::Group::Record;

    my @records = @{ $self->records() };

    push @records, $record;

    $self->{'records'} = @records;

    return $record;
}

sub to_string {
    my $self = shift;

    my $string;

    return $self->writer->to_string();
}

1;
