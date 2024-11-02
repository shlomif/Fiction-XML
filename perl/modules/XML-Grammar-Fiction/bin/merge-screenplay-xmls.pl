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
    $docs_dir_obj->child(
    "Queen-Padme-Tales--Queen-Amidala-vs-the-Klingon-Warriors.xml");

push @sources, $docs_dir_obj->child("Queen-Padme-Tales--Planting-Trees.xml");

my $SCREENPLAY_XML_NS =
"http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/";

my $output_text = _merge( { inputs => [@sources] } );
print $output_text;

sub _merge
{
    my $args    = shift;
    my $inputs  = $args->{inputs};
    my $new_xml = $parser->parse_string(
qq#<document xmlns="$SCREENPLAY_XML_NS"><head></head><body id="index"></body></document>#
    );
    my $root = $new_xml->documentElement();
    foreach my $src (@$inputs)
    {
        my $input = $parser->parse_file($src);
        my $doc   = $input->documentElement();
        my $xpc   = XML::LibXML::XPathContext->new($doc);
        $xpc->registerNs( "sp", $SCREENPLAY_XML_NS );
        my @el = $xpc->findnodes("//sp:document/sp:body/sp:scene");
        foreach my $el (@el)
        {
            $root->appendWellBalancedChunk( $el->toString() );
        }
    }
    return $new_xml->toString(1);
}
