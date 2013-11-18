#!/usr/bin/perl -I ../lib/ 

use strict;
use warnings;

use charnames qw(:full);

use Test::More tests => 45;

BEGIN {
    use_ok('XML::GSA');
}

my $gsa = new_ok('XML::GSA');

$gsa = XML::GSA->new();

can_ok( $gsa, qw(create type datasource xml base_url) );

is( $gsa->type(), 'incremental', 'type is incremental by default' );

is( $gsa->create( {} ), undef, 'invalid argument passed to create' );
is( $gsa->create(""), undef, 'another invalid argument passed to create' );

is( $gsa->create(),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'no arguments passed to create'
);
is( $gsa->create( [] ),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'empty structure passed to create'
);

is( my $xml = $gsa->create( [ {} ] ),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group'
);
is( $xml, $gsa->xml(),
    'getting the xml matches the xml generate previously' );

is( $xml = $gsa->create( [ { 'action' => 'delete' } ] ),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group and properties'
);

$gsa->add_group( { 'action' => 'delete' } );
is( $xml = $gsa->create(),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group added manually and properties'
);
$gsa->clear_groups();

$gsa->add_group( XML::GSA::Group->new( 'action' => 'delete' ) );
is( $xml = $gsa->create(),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group added manually and properties'
);

is( $xml = $gsa->create( [ { 'action' => 'delete', 'records' => [ {} ] } ] ),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group, properties, and an invalid record'
);

is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [ { 'url' => '/particulares' } ]
            }
        ]
    ),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group, properties, and an invalid record (invalid url)'
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
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        'http://icdif.com/particulares/',
    ),
    'create xml using structure with one group, properties, and one valid record without base url'
);

$gsa = XML::GSA->new( 'base_url' => 'http://icdif.com' );
is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [ { 'url' => '/particulares' } ]
            }
        ]
    ),
    sprintf(
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"></group></gsafeed>',
        $gsa->datasource(), $gsa->type()
    ),
    'create xml using structure with one group, properties, and an invalid record (both url and base_url have full paths)'
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
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        sprintf( '%s%s',
            $gsa->base_url,
            '/particulares/',
        ),
    ),
    'create xml using structure with one group, properties, and one valid record with base url'
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
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"><metadata></metadata></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        sprintf( '%s%s',
            $gsa->base_url,
            '/particulares/',
        ),
    ),
    'create xml using structure with one group, properties, and one valid record with invalid metadata'
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
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record url="%s" mimetype="text/plain"><metadata><meta content="Particulares" name="og:title"></meta></metadata></record></group></gsafeed>',
        $gsa->datasource(),
        $gsa->type(),
        sprintf( '%s%s',
            $gsa->base_url,
            '/particulares/',
        ),
    ),
    'create xml using structure with one group, properties, and one valid record with valid metadata'
);

$gsa->type('full');
is( $gsa->create(
        [   {   'action'  => 'delete',
                'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'action'   => 'delete',
                        'content'  => "Content"
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
        '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>%s</datasource><feedtype>%s</feedtype></header><group action="delete"><record action="delete" url="%s" mimetype="text/plain"><content>Content</content></record><record url="%s" mimetype="text/html"><content><![CDATA[<html></html>]]></content></record></group></gsafeed>',
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
    'create xml using structure with one group, properties, and two valid records with content (full feed)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'action'   => 'delete',
                        'content' =>
                            "Conte\N{LATIN SMALL LETTER U WITH ACUTE}do"
                    },
                ]
            }
        ]
    ),
    qr/<record.*><content>Conteúdo<\/content><\/record>/,
    'Valid utf8 encoding'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'action'   => 'delete',
                    },
                ]
            }
        ]
    ),
    qr/<record.*action="delete".*>.*<\/record>/,
    'record valid action attr value (delete)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'action'   => 'add',
                    },
                ]
            }
        ]
    ),
    qr/<record.*action="add".*>.*<\/record>/,
    'record valid action attr value (add)'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'action'   => 'aaa',
                    },
                ]
            }
        ]
    ),
    qr/<record.*action="aaa".*>.*<\/record>/,
    'record invalid action attr value'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'lock'     => 'true',
                    },
                ]
            }
        ]
    ),
    qr/<record.*lock="true".*>.*<\/record>/,
    'record valid lock attr value (true)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'lock'     => 'false',
                    },
                ]
            }
        ]
    ),
    qr/<record.*lock="false".*>.*<\/record>/,
    'record valid lock attr value (false)'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'lock'     => 'aaa',
                    },
                ]
            }
        ]
    ),
    qr/<record.*lock="aaa".*>.*<\/record>/,
    'record invalid lock attr value'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'           => '/particulares',
                        'mimetype'      => 'text/plain',
                        'last-modified' => '2013/10/10 18:09:43'
                    },
                ]
            }
        ]
    ),
    qr/<record.*last-modified="Thu, 10 Oct 2013 18:09:43 .+".*>.*<\/record>/,
    'record - valid date format in last-modified attribute'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'           => '/particulares',
                        'mimetype'      => 'text/plain',
                        'last-modified' => '2013/10/'
                    },
                ]
            }
        ]
    ),
    qr/<record.*last-modified=".+".*>.*<\/record>/,
    'record - invalid date format in last-modified attribute'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'authmethod' => 'none',
                    },
                ]
            }
        ]
    ),
    qr/<record.*authmethod="none".*>.*<\/record>/,
    'record valid authmethod attr value (none)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'authmethod' => 'ntlm',
                    },
                ]
            }
        ]
    ),
    qr/<record.*authmethod="ntlm".*>.*<\/record>/,
    'record valid authmethod attr value (ntlm)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'authmethod' => 'httpbasic',
                    },
                ]
            }
        ]
    ),
    qr/<record.*authmethod="httpbasic".*>.*<\/record>/,
    'record valid authmethod attr value (httpbasic)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'authmethod' => 'httpsso',
                    },
                ]
            }
        ]
    ),
    qr/<record.*authmethod="httpsso".*>.*<\/record>/,
    'record valid authmethod attr value (httpsso)'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'authmethod' => 'aaa',
                    },
                ]
            }
        ]
    ),
    qr/<record.*authmethod="aaa".*>.*<\/record>/,
    'record invalid authmethod attr value'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'               => '/particulares',
                        'mimetype'          => 'text/plain',
                        'crawl-immediately' => 'true',
                    },
                ]
            }
        ]
    ),
    qr/<record.*crawl-immediately="true".*>.*<\/record>/,
    'record valid crawl-immediately attr value (true)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'               => '/particulares',
                        'mimetype'          => 'text/plain',
                        'crawl-immediately' => 'false',
                    },
                ]
            }
        ]
    ),
    qr/<record.*crawl-immediately="false".*>.*<\/record>/,
    'record valid crawl-immediately attr value (false)'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'               => '/particulares',
                        'mimetype'          => 'text/plain',
                        'crawl-immediately' => 'aaa',
                    },
                ]
            }
        ]
    ),
    qr/<record.*crawl-immediately="aaa".*>.*<\/record>/,
    'record invalid crawl-immediately attr value'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'pagerank' => '1',
                    },
                ]
            }
        ]
    ),
    qr/<record.*pagerank="1".*>.*<\/record>/,
    'record valid page rank'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'crawl-once' => 'true',
                    },
                ]
            }
        ]
    ),
    qr/<record.*crawl-once="true".*>.*<\/record>/,
    'valid crawl once attribute in a feed type that does not support crawl-once.'
);

$gsa->type('metadata-and-url');

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'pagrank'  => '1',
                    },
                ]
            }
        ]
    ),
    qr/<record.*pagerank="1".*>.*<\/record>/,
    'valid pagerank attribute in a feed type that does not support pagerank.'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'crawl-once' => 'true',
                    },
                ]
            }
        ]
    ),
    qr/<record.*crawl-once="true".*>.*<\/record>/,
    'record valid crawl-once attr value (true)'
);

like(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'crawl-once' => 'false',
                    },
                ]
            }
        ]
    ),
    qr/<record.*crawl-once="false".*>.*<\/record>/,
    'record valid crawl-once attr value (false)'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'        => '/particulares',
                        'mimetype'   => 'text/plain',
                        'crawl-once' => 'aaa',
                    },
                ]
            }
        ]
    ),
    qr/<record.*crawl-once="aaa".*>.*<\/record>/,
    'record invalid crawl-once attr value'
);

unlike(
    $gsa->create(
        [   {   'records' => [
                    {   'url'      => '/particulares',
                        'mimetype' => 'text/plain',
                        'abc'      => 'abc',
                    },
                ]
            }
        ]
    ),
    qr/<record.*abc="abc".*>.*<\/record>/,
    'record unknown attribute'
);

1;
