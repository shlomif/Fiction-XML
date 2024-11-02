#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use Path::Tiny  qw/ cwd path tempdir tempfile /;
use XML::LibXML ();

my $docs_dir_obj =
    path("/home/shlomif/Docs/homepage/homepage/trunk/lib/screenplay-xml/xml/");

my $parser = XML::LibXML->new();
my @sources;
push @sources,
    scalar(
    $parser->parse_file(
        $docs_dir_obj->child(
            "Queen-Padme-Tales--Queen-Amidala-vs-the-Klingon-Warriors.xml")
    )
    );

push @sources,
    scalar(
    $parser->parse_file(
        $docs_dir_obj->child("Queen-Padme-Tales--Planting-Trees.xml")
    )
    );

my $SCREENPLAY_XML_NS =
"http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/";

my $new_xml = $parser->parse_string(
qq#<document xmlns="$SCREENPLAY_XML_NS"><head></head><body id="index"></body></document>#
);
my $root = $new_xml->documentElement();
foreach my $src (@sources)
{
    my $doc = $src->documentElement();
    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs( "sp", $SCREENPLAY_XML_NS );
    my @el = $xpc->findnodes("//sp:document/sp:body/sp:scene");
    foreach my $el (@el)
    {
        $root->appendWellBalancedChunk( $el->toString() );
    }
}
print $new_xml->toString(1);
