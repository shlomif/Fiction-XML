#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 49;

use lib './t/lib';
use XmlGrammarTestXML qw(my_is_xml);

use XML::LibXML                                   ();
use XML::Grammar::Fiction::FromProto              ();
use XML::Grammar::Fiction::FromProto::Parser::QnD ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

my @tests = (
    qw(
        sections-and-paras
        sections-p-b-i
        sections-p-b-i-comments
        sections-a-href
        with-ul-ol-li
        with-blockquote
        with-programlisting
        paras-with-entities-at-start-of-line
        with-xml-lang-attribute
        with-xml-lang-attr-in-section
        with-span
        a-href-with-id-and-lang
        with-blockquote-with-lang-and-id
        with-style-tag-at-start-of-paragraph
        with-comment-with-newlines
        with-entities-in-tag-attrs
        )
);

# TEST:$num_texts=16

my $grammar = XML::Grammar::Fiction::FromProto->new(
    {
        parser_class => "XML::Grammar::Fiction::FromProto::Parser::QnD",
    }
);

my $rngschema =
    XML::LibXML::RelaxNG->new( location => "./extradata/fiction-xml.rng" );

my $xml_parser = XML::LibXML->new();
$xml_parser->validation(0);

foreach my $fn (@tests)
{
    my $got_xml = $grammar->convert(
        {
            source => {
                file => "t/fiction/data/proto-text/$fn.txt",
            },
        }
    );

    if ( $fn eq "sections-p-b-i" )
    {
        # TEST
        like( $got_xml, qr{</b> }, "Space after the </b>", );
    }

    # TEST*$num_texts
    unlike( $got_xml, qr{[ \t+]$}ms, "No trailing space in \"$fn\"" );

    # TEST*$num_texts
    my_is_xml(
        [ string => $got_xml, ],
        [ string => path("t/fiction/data/xml/$fn.xml")->slurp_utf8, ],
        "Output of the Proto Text \"$fn\"",
    );

    my $dom = $xml_parser->parse_string($got_xml);

    my $code;
    $code = $rngschema->validate($dom);

    # TEST*$num_texts
    ok(
        ( defined($code) && ( $code == 0 ) ),
        "The validation of '$fn' succeeded."
    ) || diag("\$\@ == $@");
}

1;
