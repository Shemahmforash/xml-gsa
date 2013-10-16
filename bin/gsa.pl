#!/usr/bin/perl -I ../lib/

use strict;
use warnings;

use GSA;
use Data::Dumper;

my $gsa = GSA->new();

my $xml = $gsa->create(
    [   {   'action'  => 'add',
            'records' => [
                {   'url'      => 'www.optimus.pt/particulares',
                    'mimetype' => 'text/plain',
                    'action'   => 'delete',
                },
                {   'url'      => 'www.optimus.pt/empresas',
                    'mimetype' => 'text/plain'
                }
            ],
        },
        {   'action'  => 'delete',
            'records' => [
                {   'url'      => 'www.optimus.pt/particulares',
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
                {   'url'      => 'www.optimus.pt/empresas',
                    'mimetype' => 'text/plain'
                }
            ],
        }
    ]
);

print $gsa->xml();

1;
