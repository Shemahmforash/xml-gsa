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

    return bless { 'records' => [], 'action' => 'add', @_, },
        ref $class || $class;
}

#getters
sub writer {
    my $self = shift;

    return $self->{'writer'};
}

sub xml {
    my $self = shift;

    return $self->{'xml'};
}

sub to_string {
    my $self = shift;

    return $self->{'xml'};
}

sub records {
    my $self = shift;

    return $self->{'records'} || [];
}

#getters and setters
sub action {
    my ( $self, $value ) = @_;

    $self->{'action'} = $value
        if $value && $value =~ /(add|delete)/;

    return $self->{'action'};
}

#other public methods
sub create {
    my ( $self, $feed ) = @_;

    return unless $feed && ref $feed eq 'XML::GSA';

    #always
    my $writer = XML::Writer->new( OUTPUT => 'self', );
    $self->{'writer'} = $writer;

    my %attributes;
    $attributes{'action'} = $self->action
        if defined $self->action;

    $self->writer->startTag( 'group', %attributes );

    for my $record ( @{ $self->records || [] } ) {
        $self->_add_record( $record, $feed );
    }

    $self->writer->endTag('group');

    my $xml = $self->writer->to_string;
    $self->{'xml'} = $xml;

    return $xml;
}

#private methods

#adds a record to a feed
sub _add_record {
    my ( $self, $record, $feed ) = @_;

    return unless $self->writer && $record && ref $record eq 'HASH';

    #url and mimetype are mandatory parameters for the record
    return unless $record->{'url'} && $record->{'mimetype'};

    my $attributes = $self->_record_attributes( $record, $feed );

    $self->writer->startTag( 'record', %{ $attributes || {} } );

    if ( $record->{'metadata'} && ref $record->{'metadata'} eq 'ARRAY' ) {
        $self->_add_metadata( $record->{'metadata'} );
    }

    $self->_record_content($record)
        if $feed->type eq 'full';

    $self->writer->endTag('record');
}

#adds record content part
sub _record_content {
    my ( $self, $record ) = @_;

    return unless $self->writer && $record->{'content'};

    if ( $record->{'mimetype'} eq 'text/plain' ) {
        $self->writer->dataElement( 'content', $record->{'content'} );
    }
    elsif ( $record->{'mimetype'} eq 'text/html' ) {
        $self->writer->cdataElement( 'content', $record->{'content'} );
    }

    #else {
    #TODO support other mimetype with base64 encoding content
    #}
}

#creates record attributes
sub _record_attributes {
    my ( $self, $record, $feed ) = @_;

    #must be a full record url
    #that is: if no base url, the url in record must start with http
    #base url and url in record can't include the domain at the same time
    if (( !$feed->base_url && $record->{'url'} !~ /^http/ )
        || (   $feed->base_url
            && $feed->base_url  =~ /^http/
            && $record->{'url'} =~ /^http/ )
        )
    {
        return {};
    }

    #mandatory attributes
    my %attributes = (
        'url' => $feed->base_url
        ? sprintf( '%s%s', $feed->base_url, $record->{'url'} )
        : $record->{'url'},
        'mimetype' => $record->{'mimetype'},
    );

    ####optional attributes####

    #action is delete or add
    $attributes{'action'} = $record->{'action'}
        if $record->{'action'}
            && $record->{'action'} =~ /^(delete|add)$/;

    #lock is true or false
    $attributes{'lock'} = $record->{'lock'}
        if $record->{'lock'}
            && $record->{'lock'} =~ /^(true|false)$/;

    $attributes{'displayurl'} = $record->{'displayurl'}
        if $record->{'displayurl'};

    #validate datetime format
    if ( $record->{'last-modified'} ) {
        my $date = $self->_to_RFC822_date( $record->{'last-modified'} );

        $attributes{'last-modified'} = $date
            if $date;
    }

    #allowed values for authmethod
    $attributes{'authmethod'} = $record->{'authmethod'}
        if $record->{'authmethod'}
            && $record->{'authmethod'} =~ /^(none|httpbasic|ntlm|httpsso)$/;

    $attributes{'pagerank'} = $record->{'pagerank'}
        if $feed->type ne 'metadata-and-url' && defined $record->{'pagerank'};

    #true or false and only for web feeds
    $attributes{'crawl-immediately'} = $record->{'crawl-immediately'}
        if $feed->datasource eq 'web'
            && $record->{'crawl-immediately'}
            && $record->{'crawl-immediately'} =~ /^(true|false)$/;

    #for web feeds
    $attributes{'crawl-once'} = $record->{'crawl-once'}
        if ( $feed->datasource eq 'web'
        && $feed->type() eq 'metadata-and-url'
        && $record->{'crawl-once'}
        && $record->{'crawl-once'} =~ /^(true|false)$/ );

    return \%attributes;
}

sub _add_metadata {
    my ( $self, $metadata ) = @_;

    return unless $self->writer && scalar @{ $metadata || [] };

    $self->writer->startTag('metadata');
    for my $meta ( @{ $metadata || [] } ) {
        next unless $meta->{'name'} && $meta->{'content'};

        my %attributes = (
            'name'    => $meta->{'name'},
            'content' => $meta->{'content'},
        );

        $self->writer->dataElement( 'meta', '', %attributes );
    }

    $self->writer->endTag('metadata');
}

#receives a string representing a datetime and returns its RFC822 representation
sub _to_RFC822_date {
    my ( $self, $value ) = @_;

    my $epoch = Date::Parse::str2time($value);

    unless ($epoch) {
        carp("Unknown date format received");
        return;
    }

    my $datetime = DateTime->from_epoch(
        'epoch'     => $epoch,
        'time_zone' => 'local',
    );

    return $datetime->strftime('%a, %d %b %Y %H:%M:%S %z');
}

1;
