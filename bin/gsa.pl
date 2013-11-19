#!/usr/bin/perl -I ../lib/

use strict;
use warnings;

use XML::GSA ();
use Data::Dumper;
use DateTime;
use Date::Parse;

my $gsa = XML::GSA->new( 'base_url' => 'http://icdif.com' );

my $xml = $gsa->create(
    [   {   'action'  => 'add',
            'records' => [
                {   'last-modified' => '2013-01-10 13:25:31',
                    'url'           => '/particulares/movel/tarifarios',
                    'metadata'      => [
                        {   'content' => ['particulares', 'empresas'],
                            'name'    => 'gsa:group'
                        },
                        {   'content' => "Tarif\x{e1}rios",
                            'name'    => 'og:title'
                        }
                    ],
                    'mimetype' => 'text/plain'
                }
            ]
        }
    ]
);

print $xml;

1;
