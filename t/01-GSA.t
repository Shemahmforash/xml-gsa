#!/usr/bin/perl -I ../lib/ 

use strict;
use warnings;

use Data::Dumper;    #TODO: remove this when tests are closed
use Test::More tests => 19;

BEGIN {
    use_ok('XML::GSA');
}

my $gsa = new_ok('XML::GSA');

can_ok( $gsa, qw(create type datasource xml base_url) );

is( $gsa->type(), 'incremental', 'type is incremental by default' );

is( $gsa->create(), undef, 'no arguments passed to create' );
is( $gsa->create( {} ), undef, 'invalid argument passed to create' );
is( $gsa->create(""), undef, 'another invalid argument passed to create' );

is( $gsa->create( [] ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'empty structure passed to create'
);

is( my $xml = $gsa->create( [ {} ] ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group'
);
is( $xml, $gsa->xml(),
    'getting the xml matches the xml generate previously' );

is( $xml = $gsa->create( [ { 'action' => 'delete' } ] ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group and properties'
);

is( $xml = $gsa->create( [ { 'action' => 'delete', 'records' => [ {} ] } ] ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group, properties,and an invalid record'
);

is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [ { 'url' => '/particulares' } ]
            }
        ]
    ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group, properties,and an invalid record (invalid url)'
);

is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [
                    {   'url'      => 'http://icdif.com/particulares/',
                        'mimetype' => 'text/plain'
                    }
                ]
            }
        ]
    ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        'http://icdif.com/particulares/',
    ),
    'create xml using structure with one group, properties and one valid record without base url'
);

$gsa = XML::GSA->new( 'base_url' => 'http://icdif.com' );
is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [ { 'url' => '/particulares' } ]
            }
        ]
    ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group, properties,and an invalid record (both url and base_url have full paths)'
);

is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [
                    { 'url' => '/particulares/', 'mimetype' => 'text/plain' }
                ]
            }
        ]
    ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        sprintf( '%s%s',
            $gsa->base_url,
            '/particulares/',
        ),
    ),
    'create xml using structure with one group, properties and one valid record with base url'
);

is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [
                    {   'url'      => '/particulares/',
                        'mimetype' => 'text/plain',
                        'metadata' => [ {} ]
                    }
                ]
            }
        ]
    ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"><metadata></metadata></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        sprintf( '%s%s',
            $gsa->base_url,
            '/particulares/',
        ),
    ),
    'create xml using structure with one group, properties and one valid record with invalid metadata'
);

is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [
                    {   'url'      => '/particulares/',
                        'mimetype' => 'text/plain',
                        'metadata' => [
                            {   'name'    => 'og:title',
                                'content' => 'Particulares'
                            }
                        ]
                    }
                ]
            }
        ]
    ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"><metadata><meta content="Particulares" name="og:title"></meta></metadata></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        sprintf( '%s%s',
            $gsa->base_url,
            '/particulares/',
        ),
    ),
    'create xml using structure with one group, properties and one valid record with valid metadata'
);

$gsa->type('full');
is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'action'   => 'delete',
                        'content'  => 'Conteúdo'
                    },
                    {   'url'      => '/empresas',
                        'mimetype' => 'text/html',
                        'content'  => '<html></html>'
                    }
                ]
            }
        ]
    ),
    sprintf(
        '<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record action="delete" url="%s" mimetype="text/plain"><content>Conteúdo</content></record><record url="%s" mimetype="text/html"><content><![CDATA[<html></html>]]></content></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        sprintf( '%s%s',
            $gsa->base_url,
            '/particulares',
        ),
        sprintf( '%s%s',
            $gsa->base_url,
            '/empresas',
        ),
    ),
    'create xml using structure with one group, properties and two valid records with content (full feed)'
);


1;
