#!/usr/bin/perl -I ../lib/

use strict;
use warnings;

use XML::GSA ();
use Data::Dumper;
use DateTime;
use Date::Parse;

my $gsa = XML::GSA->new('base_url' => 'http://icdif.com');

$gsa->add_group({   'action'  => 'add',
            'records' => [
                {   'url'      => '/particulares',
                    'mimetype' => 'text/plain',
                    'action'   => 'delete',
                },
            ],
        } );

my $xml = $gsa->create();

print $xml;

1;
