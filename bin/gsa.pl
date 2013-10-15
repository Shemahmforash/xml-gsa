#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use XML::Simple;

my $xs = XML::Simple->new(
    'AttrIndent' => 1,
    'KeepRoot'   => 1,
    'ForceArray' => ['gsa']
);
my $xml = $xs->XMLout(
    {   'gsa' => [
            { 'name' => 'abc', 'value' => 122 },
            { 'name' => 'dce', 'value' => 142 }
        ]
    }
);

die Dumper $xml;

1;
