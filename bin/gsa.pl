#!/usr/bin/perl -I ../lib/

use strict;
use warnings;

use XML::GSA ();
use Data::Dumper;
use DateTime;
use Date::Parse;

=for
my $epoch    = Date::Parse::str2time("2013-08-12 11:09:43");
my $datetime = DateTime->from_epoch(
    'epoch'     => $epoch,
    'time_zone' => 'local',
);

#die Dumper $datetime->strftime('%a, %d %b %y %T %Z');

die Dumper $datetime->strftime('%a, %d %b %Y %H:%M:%S %z');

#RFC822 (Mon, 15 Nov 2004 04:58:08 GMT)
=cut

my $gsa = XML::GSA->new('base_url' => 'http://www.optimus.pt', 'type' => 'full');

my $xml = $gsa->create(
    [   {   'records' => [
                {   'url'           => '/particulares',
                    'mimetype'      => 'text/plain',
                    'abc' => 'abc'
                },
            ]
        }
    ]
);

=for
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
=cut

print $gsa->xml();

1;
