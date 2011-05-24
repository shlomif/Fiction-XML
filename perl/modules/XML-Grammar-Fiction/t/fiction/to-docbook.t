#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::XML tests => 27;

use File::Spec;

use XML::LibXML;

use XML::Grammar::Fiction::ToDocBook;

my @tests = (qw(
        sections-and-paras
        sections-p-b-i-comments
        sections-a-href
        with-ul-ol-li
        with-blockquote
        with-programlisting
        with-xml-lang-attribute
        with-xml-lang-attr-in-section
        with-span
    ));

sub load_xml
{
    my $path = shift;

    open my $in, "<", $path
        or die "Cannot open '$path' for reading";
    my $contents;
    {
        local $/;
        $contents = <$in>;
    }
    close($in);
    return $contents;
}

# TEST:$num_texts=9

my $converter = XML::Grammar::Fiction::ToDocBook->new({
        data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
    });

foreach my $fn (@tests)
{
    my $docbook_text = $converter->translate_to_docbook({
            source => { file => "t/fiction/data/xml/$fn.xml", },
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

    # TEST*$num_texts
    is_xml ($docbook_text, load_xml("t/fiction/data/docbook/$fn.docbook.xml"),
        "Output of the DocBook \"$fn\"",
    );
}

1;

