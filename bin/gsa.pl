#!/usr/bin/perl -I ../lib/

use strict;
use warnings;

use XML::GSA;
use Data::Dumper;

my $gsa = XML::GSA->new('base_url' => 'http://www.optimus.pt');

my $xml = $gsa->create(
    [   {   'action'  => 'add',
            'records' => [
                {   'url'      => '/particulares',
                    'mimetype' => 'text/plain',
                    'action'   => 'delete',
                },
                {   'url'      => '/empresas',
                    'mimetype' => 'text/plain'
                }
            ],
        },
        {   'action'  => 'delete',
            'records' => [
                {   'url'      => '/cliente',
                    'mimetype' => 'text/plain',
                    'action'   => 'delete',
                    'metadata' => [
                        { 'name' => 'John', 'content' => 'Jenny Wong' },
                        {   'name' => 'url',
                            'content' =>
                                'http://www.corp.enterprise.com/search/employeesearch.php?q=jwong'
                        }
                    ],
                },
                {   'url'      => '/empresas',
                    'mimetype' => 'text/plain'
                }
            ],
        }
    ]
);

print $gsa->xml();

1;
