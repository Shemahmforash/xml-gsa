package GSA;

use Moose;
use Scalar::Util ();
use XML::Writer;
use Data::Dumper;

use namespace::autoclean;

has 'type' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'incremental'
);

has 'datasource' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Beta-Optimus'
);

has 'url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://www.optimus.pt'
);

has 'xml' => (
    is  => 'rw',
    isa => 'Str',
);

sub create {
    my ( $self, $data ) = @_;

    return unless $data && ref $data eq 'ARRAY';

    my $writer = XML::Writer->new(
        OUTPUT      => 'self',
    );
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

#private methods
sub _add_group {
    my ( $self, $writer, $group ) = @_;

    return unless $writer && $group && ref $group eq 'HASH';

    my %element;
    $element{'action'} = $group->{'action'}
        if defined $group->{'action'};

    $writer->startTag( 'group', %element );

    for my $record ( @{ $group->{'records'} || [] } ) {
        $self->_add_record( $writer, $record );
    }

    $writer->endTag('group');
}

sub _add_record {
    my ( $self, $writer, $record ) = @_;

    return unless $writer && $record && ref $record eq 'HASH';

    my %element = (
        'url'      => $record->{'url'},
        'mimetype' => $record->{'mimetype'},
    );

    $element{'action'} = $record->{'action'}
        if $record->{'action'};

    #TODO: according to feed type, change the way it interprets this
    if ( $record->{'metadata'} && ref $record->{'metadata'} eq 'ARRAY' ) {
        $writer->startTag( 'record', %element );
        $self->_add_metadata( $writer, $record->{'metadata'} );

        #TODO: support content as CDATA
        $writer->endTag('record');
    }
    else {
        $writer->dataElement( 'record', '', %element );
    }
}

sub _add_metadata {
    my ( $self, $writer, $metadata ) = @_;

    return unless scalar @{ $metadata || [] };

    $writer->startTag('metadata');
    for my $meta ( @{ $metadata || [] } ) {
        next unless $meta->{'name'} && $meta->{'content'};

        my %element = (
            'name'    => $meta->{'name'},
            'content' => $meta->{'content'},
        );

        $writer->dataElement( 'meta', '', %element );
    }

    $writer->endTag('metadata');
}

no Moose;
__PACKAGE__->meta->make_immutable;
