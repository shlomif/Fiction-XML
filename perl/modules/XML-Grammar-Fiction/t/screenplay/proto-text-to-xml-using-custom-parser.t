#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::XML tests => 32;

use XML::LibXML;

require XML::Grammar::Screenplay::FromProto;

require XML::Grammar::Screenplay::FromProto::Parser::QnD;

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

my @tests = (qw(
        nested-s
        two-nested-s
        with-dialogue
        dialogue-with-several-paragraphs
        with-description
        with-tags-inside-paragraphs
        with-i-element-inside-paragraphs
        with-internal-description
        with-comments
        with-multi-para-desc
        with-multi-line-comments
        scenes-with-titles
        with-entities
        with-brs
        with-internal-description-at-start-of-line
        with-colon-inside-description
    ));

# TEST:$num_texts=16

my $grammar = XML::Grammar::Screenplay::FromProto->new({
        parser_class => "XML::Grammar::Screenplay::FromProto::Parser::QnD",
    });

my $rngschema = XML::LibXML::RelaxNG->new(
        location => "./extradata/screenplay-xml.rng"
    );

my $xml_parser = XML::LibXML->new();
$xml_parser->validation(0);

foreach my $fn (@tests)
{
    my $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/screenplay/data/proto-text/$fn.txt",
            },
        }
    );

    # TEST*$num_texts
    is_xml ($got_xml, load_xml("t/screenplay/data/xml/$fn.xml"),
        "Output of the Proto Text \"$fn\""
    );

    my $dom = $xml_parser->parse_string($got_xml);

    my $code;
    eval
    {
    $code = $rngschema->validate($dom);
    };

    # TEST*$num_texts
    ok ((defined($code) && ($code == 0)),
        "The validation of '$fn' succeeded.") ||
        diag("\$@ == $@");
}

1;
