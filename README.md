XML::GSA
=============

Lib that creates xml in google gsa format.

#Dependencies

1. [XML::Writer](https://github.com/josephw/xml-writer-perl)

#How to use it

To create a xml in google search appliance format, you can use this lib in the following way:

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
                    'mimetype' => 'text/plain',
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

This will output:

```xml
<!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
<gsafeed><header><datasource>Source</datasource><feedtype>incremental</feedtype></header><group action="add"><record action="delete" url="http://www.icdif.com/particulares" mimetype="text/plain"></record><record url="http://www.icdif.com/empresas" mimetype="text/plain"><metadata><meta content="Empresas" name="og:title"></meta></metadata></record></group></gsafeed>
```
