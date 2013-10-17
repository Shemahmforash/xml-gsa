package XML::GSA;

use Moose;
use Scalar::Util ();
use XML::Writer;
use Data::Dumper;
use Carp;

use namespace::autoclean;

has 'type' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'incremental'    #full || metadata-and-url
);

has 'datasource' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Source'
);

#base url to be preppended to all urls
has 'base_url' => (
    is  => 'ro',
    isa => 'Str',
);

has 'xml' => (
    is  => 'rw',
    isa => 'Str',
);

sub create {
    my ( $self, $data ) = @_;

    unless ( $data && ref $data eq 'ARRAY' ) {
        carp("An array data structure must be passed as parameter");
        return;
    }

    my $writer = XML::Writer->new( OUTPUT => 'self', );
    $writer->doctype( "gsafeed", '-//Google//DTD GSA Feeds//EN', "" );

    $writer->startTag('gsafeed');
    $writer->startTag('header');
    $writer->dataElement( 'datasource', $self->datasource() );
    $writer->dataElement( 'feedtype',   $self->type() );
    $writer->endTag('header');

    for my $group ( @{ $data || [] } ) {
        $self->_add_group( $writer, $group );
    }

    $writer->endTag('gsafeed');

    $self->xml( $writer->to_string );

    return $writer->to_string;
}

sub _add_group {
    my ( $self, $writer, $group ) = @_;

    return unless $writer && $group && ref $group eq 'HASH';

    my %attributes;
    $attributes{'action'} = $group->{'action'}
        if defined $group->{'action'};

    $writer->startTag( 'group', %attributes );

    for my $record ( @{ $group->{'records'} || [] } ) {
        $self->_add_record( $writer, $record );
    }

    $writer->endTag('group');
}

sub _add_record {
    my ( $self, $writer, $record ) = @_;

    return unless $writer && $record && ref $record eq 'HASH';

    #url and mimetype are mandatory parameters for the record
    return unless $record->{'url'} && $record->{'mimetype'};

    my $attributes = $self->_record_attributes($record);

    #TODO: according to feed type, change the way it interprets this
    if ( $record->{'metadata'} && ref $record->{'metadata'} eq 'ARRAY' ) {
        $writer->startTag( 'record', %{ $attributes || {} } );
        $self->_add_metadata( $writer, $record->{'metadata'} );

        #TODO: support content in record (as text and CDATA)

        $writer->endTag('record');
    }
    else {
        $writer->dataElement( 'record', '', %{ $attributes || {} } );
    }
}

#creates record attributes
sub _record_attributes {
    my ( $self, $record ) = @_;

    #must be a full record url
    #that is: no base url, the url in record must include the domain
    #base url and url in record can't include the domain at the same time
    if ( ( !$self->base_url && $record->{'url'} !~ /^http/ )
        || $self->base_url && $record->{'url'} =~ /^http/ )
    {
        return {};
    }

    #mandatory attributes
    my %attributes = (
        'url' => $self->base_url
        ? sprintf( '%s%s', $self->base_url, $record->{'url'} )
        : $record->{'url'},
        'mimetype' => $record->{'mimetype'},
    );

    #optional attributes
    $attributes{'action'} = $record->{'action'}
        if ( $record->{'action'}
        && ( $record->{'action'} eq 'delete' || $record->{'action'} eq 'add' )
        );
    $attributes{'lock'} = $record->{'lock'}
        if ( $record->{'lock'}
        && ( $record->{'lock'} eq 'true' || $record->{'lock'} eq 'false' ) );
    $attributes{'displayurl'} = $record->{'displayurl'}
        if $record->{'displayurl'};
    $attributes{'last-modified'} = $record->{ 'last-modified'
        } #TODO: validate if it is in the format  RFC822 (Mon, 15 Nov 2004 04:58:08 GMT)
        if $record->{'last-modified'};
    $attributes{'authmethod'} = $record->{'authmethod'}
        if $record->{ 'authmethod'
            };    #validate if it is none, httpbasic, ntlm, or httpsso
    $attributes{'pagerank'} = $record->{'pagerank'}
        if $self->type ne 'metadata-and-url' && defined $record->{'pagerank'};
    $attributes{'crawl-immediately'} = $record->{'crawl-immediately'}
        if (
           $self->datasource eq 'web'
        && $record->{'crawl-immediately'}
        && (   $record->{'crawl-immediately'} eq 'true'
            || $record->{'crawl-immediately'} eq 'false' )
        );
    $attributes{'crawlonce'} = $record->{'crawlonce'}
        if $self->datasource eq 'web'
            && defined $record->{'crawlonce'}
            && $self->type() eq 'metadata-and-url';

    return \%attributes;
}

sub _add_metadata {
    my ( $self, $writer, $metadata ) = @_;

    return unless scalar @{ $metadata || [] };

    $writer->startTag('metadata');
    for my $meta ( @{ $metadata || [] } ) {
        next unless $meta->{'name'} && $meta->{'content'};

        my %attributes = (
            'name'    => $meta->{'name'},
            'content' => $meta->{'content'},
        );

        $writer->dataElement( 'meta', '', %attributes );
    }

    $writer->endTag('metadata');
}

no Moose;
__PACKAGE__->meta->make_immutable;
