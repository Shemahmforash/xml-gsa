#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use XML::Writer;

#the output will be available in the method to_string of $writer
my $writer = XML::Writer->new( OUTPUT => 'self', 'ENCODING' => 'utf-8' );

$writer->xmlDecl();

$writer->doctype( "gsafeed", '-//Google//DTD GSA Feeds//EN', "" )
    ;    #1 must be ''

$writer->startTag('gsafeed');
$writer->startTag('header');
$writer->dataElement('datasource', 'web');
$writer->dataElement('feedtype', 'incremental');
$writer->endTag('header');
$writer->startTag('group');
$writer->dataElement('record', '', 'url' => 'http://www.corp.enterprise.com/hello02', 'mimetype' => 'text/plain');
$writer->endTag('group');
$writer->endTag('gsafeed');

print $writer->to_string;

1;
