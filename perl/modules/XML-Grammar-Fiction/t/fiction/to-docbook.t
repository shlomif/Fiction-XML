#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 33;

use XmlGrammarTestXML qw(my_is_xml);
use Path::Tiny qw/ path tempdir tempfile cwd /;

use XML::LibXML                      ();
use XML::Grammar::Fiction::ToDocBook ();

my @tests = (
    qw(
        sections-and-paras
        sections-p-b-i-comments
        sections-a-href
        with-ul-ol-li
        with-blockquote
        with-programlisting
        with-xml-lang-attribute
        with-xml-lang-attr-in-section
        with-span
        a-href-with-id-and-lang
        with-blockquote-with-lang-and-id
    )
);

# TEST:$num_texts=11

my $converter = XML::Grammar::Fiction::ToDocBook->new(
    {
        data_dir => cwd()->child("extradata")->absolute->stringify,
    }
);

foreach my $fn (@tests)
{
    my $docbook_text = $converter->translate_to_docbook(
        {
            source => { file => "t/fiction/data/xml/$fn.xml", },
            output => "string",
        }
    );

    # TEST*$num_texts*2

    my $parser = XML::LibXML->new();

    my $doc = $parser->parse_string($docbook_text);

    my $xc = XML::LibXML::XPathContext->new($doc);

    $xc->registerNs( 'db', 'http://docbook.org/ns/docbook' );

    is(
        scalar( () = $xc->findnodes(q{//db:article[@xml:id='index']}) ),
        1, "Found one article with id index",
    );

    ok(
        ( scalar( () = $xc->findnodes(q{//db:section}) ) >= 1 ),
        "Found role=description sections",
    );

    # TEST*$num_texts
    my_is_xml(
        [ string => $docbook_text, ],
        [
            string =>
                path("t/fiction/data/docbook/$fn.docbook.xml")->slurp_utf8,
        ],
        "Output of the DocBook \"$fn\"",
    );
}
