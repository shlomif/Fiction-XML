#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::XML tests => 39;

use XML::LibXML;

use XML::Grammar::Screenplay::FromProto;
use XML::Grammar::Screenplay::FromProto::Parser::PRD;

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

my $rngschema = XML::LibXML::RelaxNG->new(
        location => "./extradata/fiction-xml.rng"
    );

my @tests = (qw(
        nested-s
        two-nested-s
        with-dialogue
        dialogue-with-several-paragraphs
        with-description
        with-tags-inside-paragraphs
        with-internal-description
        with-comments
        with-multi-para-desc
        with-multi-line-comments
        scenes-with-titles
        with-entities
        with-brs
    ));

# TEST:$num_texts=13

my $grammar = XML::Grammar::Screenplay::FromProto->new({
        parser_class => "XML::Grammar::Screenplay::FromProto::Parser::PRD",
    });

my $dtd =
    XML::LibXML::Dtd->new(
        "Screenplay XML 0.1.0",
        File::Spec->catfile(
            "extradata", "screenplay-xml.dtd",
        ),
    );

my $xml_parser = XML::LibXML->new();
$xml_parser->validation(0);

foreach my $fn (@tests)
{
    my $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/data/proto-text/$fn.txt",
            },
        }
    );

    # TEST*$num_texts
    is_xml ($got_xml, load_xml("t/data/xml/$fn.xml"),
        "Output of the Proto Text \"$fn\""
    );

    my $dom = $xml_parser->parse_string($got_xml);

    # TEST*$num_texts
    ok ($dom->validate($dtd),
        "Checking for validity of '$fn'"
    );

    my $code;
    $code = $rngschema->validate($dom);

    # TEST*$num_texts
    ok ((defined($code) && ($code == 0)),
        "The validation of '$fn' succeeded.") ||
        diag("\$@ == $@");

}

1;

