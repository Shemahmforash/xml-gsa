package XML::GSA;

use strict;
use warnings;

use XML::Writer;
use Data::Dumper;
use Carp;
use DateTime    ();
use Date::Parse ();

sub new {
    my $class = shift;

    return bless {
        'type'       => 'incremental',
        'datasource' => 'web',
        @_,
        'encoding'   => 'UTF-8',#read-only
        },
        ref $class || $class;
}

#encoding is read-only
sub encoding {
    my $self = shift;

    return $self->{'encoding'};
}

#getters and setters
sub type {
    my ( $self, $value ) = @_;

    $self->{'type'} = $value
        if $value && $value =~ /(incremental|full|metadata-and-url)/;

    return $self->{'type'};
}

sub datasource {
    my ( $self, $value ) = @_;

    $self->{'datasource'} = $value
        if $value;

    return $self->{'datasource'};
}

sub base_url {
    my ( $self, $value ) = @_;

    $self->{'base_url'} = $value
        if $value;

    return $self->{'base_url'};
}

sub xml {
    my $self = shift;

    return $self->{'xml'};
}

sub create {
    my ( $self, $data ) = @_;

    unless ( ref $data eq 'ARRAY' ) {
        carp("An array data structure must be passed as parameter");
        return;
    }

    my $writer = XML::Writer->new( OUTPUT => 'self', );
    $writer->xmlDecl("UTF-8");
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

    my $xml = $writer->to_string;
    #gsa needs utf8 encoding
    utf8::encode($xml);

    $self->{'xml'} = $xml;
    return $xml;
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

    $writer->startTag( 'record', %{ $attributes || {} } );

    if ( $record->{'metadata'} && ref $record->{'metadata'} eq 'ARRAY' ) {
        $self->_add_metadata( $writer, $record->{'metadata'} );
    }

    $self->_record_content( $writer, $record )
        if $self->type eq 'full';

    $writer->endTag('record');
}

#adds record content part
sub _record_content {
    my ( $self, $writer, $record ) = @_;

    return unless $record->{'content'};

    if ( $record->{'mimetype'} eq 'text/plain' ) {
        $writer->dataElement( 'content', $record->{'content'} );
    }
    elsif ( $record->{'mimetype'} eq 'text/html' ) {
        $writer->cdataElement( 'content', $record->{'content'} );
    }

    #else {
    #TODO support other mimetype with base64 encoding content
    #}
}

#creates record attributes
sub _record_attributes {
    my ( $self, $record ) = @_;

    #must be a full record url
    #that is: if no base url, the url in record must start with http
    #base url and url in record can't include the domain at the same time
    if (( !$self->base_url && $record->{'url'} !~ /^http/ )
        || (   $self->base_url
            && $self->base_url  =~ /^http/
            && $record->{'url'} =~ /^http/ )
        )
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
        if $self->type ne 'metadata-and-url' && defined $record->{'pagerank'};

    #true or false and only for web feeds
    $attributes{'crawl-immediately'} = $record->{'crawl-immediately'}
        if $self->datasource eq 'web'
            && $record->{'crawl-immediately'}
            && $record->{'crawl-immediately'} =~ /^(true|false)$/;

    #for web feeds
    $attributes{'crawl-once'} = $record->{'crawl-once'}
        if ( $self->datasource eq 'web'
        && $self->type() eq 'metadata-and-url'
        && $record->{'crawl-once'}
        && $record->{'crawl-once'} =~ /^(true|false)$/ );

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

=head1 NAME

XML::GSA - Creates xml in google search appliance (GSA) format

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This is a lib that allows one to create xml in Google Search Appliance (GSA) format.

You can use this lib in the following way:

    use XML::GSA;

    my $gsa = XML::GSA->new('base_url' => 'http://foo.bar');
    my $xml = $gsa->create(
        [   {   'action'  => 'add',
                'records' => [
                    {   'url'      => '/aaa',
                        'mimetype' => 'text/plain',
                        'action'   => 'delete',
                    },
                    {   'url'      => '/bbb',
                        'mimetype' => 'text/plain',
                        'metadata' => [
                            { 'name' => 'og:title', 'content' => 'BBB' },
                        ],
                    }
                ],
            },
        ]
    );
    print $xml;

Which will output:

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>Source</datasource><feedtype>incremental</feedtype></header><group action="add"><record action="delete" url="http://www.foo.bar/aaa" mimetype="text/plain"></record><record url="http://www.foo.bar/bbb" mimetype="text/plain"><metadata><meta content="BBB" name="og:title"></meta></metadata></record></group></gsafeed>


=head1 METHODS

=head2 new( C<$params> )

    Create a new XML::GSA object:

        my $gsa = XML::GSA->new('base_url' => 'http://foo.bar');

    Arguments of this method are an anonymous hash of parameters:

=head3 datasource

Defines the datasource to be included in the header of the xml.

=head3 type

Defines the type of the feed. This attribute tells the feed what kind of attributes the records are able to receive.

=head3 base_url

Defines a base url to be preppended to all records' urls.

=cut

=head2 type( C<$value> )

    Getter/setter for the type attribute of GSA feed. By default it is 'incremental'.
    Possible values are 'incremental', 'full' or 'metadata-and-url'

=cut

=head2 datasource( C<$value> )

    Getter/setter for the datasource attribute of GSA feed. By default it is 'web'.

=cut

=head2 base_url( C<$value> )

    Getter/setter for the base_url attribute of GSA feed. This is an url that will be preppended to all record urls. If a base_url is not defined, one must pass full urls in the records data structure.

=cut

=head2 create( C<$data> )

    Receives an arrayref data structure where each entry represents a group in the xml, generates an xml in GSA format and returns it as a string.
    Important note: All data passed to create must be in unicode! This class will utf-8 encode it making it compatible with GSA.

    One can have has many group has one wants, and a group is an hashref with an optional key 'action' and a mandatory key 'records'. The key 'action' can have the values of 'add' or 'delete' and the 'records' key is an array of hashrefs.

    Each hashref in the array corresponding to 'records' can have the following keys:

    * Mandatory
        * url
        * mimetype => (text/plain|text/html) - in the future it will also support other mimetype
    * Optional
        * action            => (add|delete)
        * lock              => (true|false)
        * displayurl        => an url
        * last-modified     => a well formatted date as string
        * authmethod        => (none|httpbasic|ntlm|httpsso)
        * pagerank          => an int number
        * crawl-immediately => (true|false)
        * crawl-once        => (true|false)

=cut

=head2 xml

    Getter for the xml generated by the `create` method.

=cut

=head1 AUTHOR

Shemahmforash, C<< <shemahmforash at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-gsa at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-GSA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::GSA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-GSA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-GSA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-GSA>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-GSA/>

=item * Github Repository

L<https://github.com/Shemahmforash/xml-gsa/>

=back


=head1 ACKNOWLEDGEMENTS

Great thanks to Andre Rivotti Casimiro for the invaluable suggestions and the help in setting a cpan compatible module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Shemahmforash.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut
