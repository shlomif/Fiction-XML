#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::XML tests => 2;

use File::Spec;

use XML::LibXML;

use XML::Grammar::Fiction::ToDocBook;

my @tests = (qw(
        with-internal-description
    ));

sub load_xml
{
    my $path = shift;

    open my $in, "<", $path;
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

# TEST:$num_texts=1

my $converter = XML::Grammar::Fiction::ToDocBook->new({
        data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
    });

foreach my $fn (@tests)
{
    my $docbook_text = $converter->translate_to_docbook({
            source => { file => "t/data/xml/$fn.xml", },
            output => "string",
        }
        );

    # TEST*$num_texts*2
    
    my $parser = XML::LibXML->new();

    my $doc = $parser->parse_string($docbook_text);

    my $xc = XML::LibXML::XPathContext->new($doc);

    $xc->registerNs('db', 'http://docbook.org/ns/docbook');

    is (
        scalar(() = $xc->findnodes(q{//db:article[@xml:id='index']})),
        1,
        "Found one article with id index",
    );

    ok (
        (scalar(() = $xc->findnodes(q{//db:section}))
            >=
            1
        ),
        "Found role=description sections",
    );
}

1;

