XML::GSA
=============

Lib that creates xml in google gsa format.

#How to use it

```perl
my $gsa = XML::GSA->new();
my $xml = $gsa->create(
    [   {   'action'  => 'add',
            'records' => [
                {   'url'      => '/particulares',
                    'mimetype' => 'text/plain',
                    'action'   => 'delete',
                },
                {   'url'      => '/empresas',
                    'mimetype' => 'text/plain'
                    'metadata' => [
                        { 'name' => 'og:title', 'content' => 'Empresas' },
                    ],
                }
            ],
        },
    ]
);

print $gsa->xml();
```
