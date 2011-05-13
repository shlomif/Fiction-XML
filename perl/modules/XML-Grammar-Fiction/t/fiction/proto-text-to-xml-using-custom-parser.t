#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Test::XML;

use XML::LibXML;

use XML::Grammar::Fiction::FromProto;

use XML::Grammar::Fiction::FromProto::Parser::QnD;

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
    sections-and-paras
    sections-p-b-i
    sections-p-b-i-comments
    sections-a-href
    with-ul-ol-li
    ));

# TEST:$num_texts=5

my $grammar = XML::Grammar::Fiction::FromProto->new({
        parser_class => "XML::Grammar::Fiction::FromProto::Parser::QnD",
    });

my $rngschema = XML::LibXML::RelaxNG->new(
        location => "./extradata/fiction-xml.rng" 
    );

my $xml_parser = XML::LibXML->new();
$xml_parser->validation(0);

foreach my $fn (@tests)
{
    my $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/fiction/data/proto-text/$fn.txt",
            },
        }
    );

    # TEST*$num_texts
    is_xml ($got_xml, load_xml("t/fiction/data/xml/$fn.xml"),
        "Output of the Proto Text \"$fn\""
    );

    my $dom = $xml_parser->parse_string($got_xml);

    my $code;
    $code = $rngschema->validate($dom);

    # TEST*$num_texts
    ok ((defined($code) && ($code == 0)),
        "The validation of '$fn' succeeded.") ||
        diag("\$@ == $@");
}

1;
