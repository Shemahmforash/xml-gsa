#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use XML::Dumper;
my $dump = new XML::Dumper;

my $perl = '';
my $xml  = '';

# ===== Convert Perl code to XML
$perl = [
    {   fname     => 'Fred',
        lname     => 'Flintstone',
        residence => 'Bedrock'
    },
    {   fname     => 'Barney',
        lname     => 'Rubble',
        residence => 'Bedrock'
    }
];
$xml = $dump->pl2xml($perl);

die Dumper $xml;

1;
