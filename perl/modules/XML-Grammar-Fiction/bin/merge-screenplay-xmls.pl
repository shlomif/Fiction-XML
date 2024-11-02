#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use 5.014;

use Path::Tiny  qw/ cwd path tempdir tempfile /;
use XML::LibXML ();

my $SCREENPLAY_XML_NS =
"http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/";

sub _merge
{
    my $args   = shift;
    my $inputs = $args->{inputs};

    my $parser  = XML::LibXML->new();
    my $new_xml = $parser->parse_string(
qq#<document xmlns="$SCREENPLAY_XML_NS"><head></head><body id="index"></body></document>#
    );
    my $root = $new_xml->documentElement();
    foreach my $src (@$inputs)
    {
        my $src_fn = $src->{filename};
        my $input  = $parser->parse_file($src_fn);
        my $doc    = $input->documentElement();
        my $xpc    = XML::LibXML::XPathContext->new($doc);
        $xpc->registerNs( "sp", $SCREENPLAY_XML_NS );
        my @el = $xpc->findnodes("//sp:document/sp:body/sp:scene");
        if ( not @el )
        {
            Carp::confess(q#no scenes found in "$src_fn"#);
        }
        elsif ( 1 == @el )
        {
            @el = $xpc->findnodes("//sp:document/sp:body/sp:scene/sp:scene");
        }
        my $dest_xml = $parser->parse_string(
            qq#<scene xmlns="$SCREENPLAY_XML_NS"></scene>#);
        foreach my $el (@el)
        {
            $dest_xml->documentElement()
                ->appendWellBalancedChunk( $el->toString() );
        }
        $root->appendWellBalancedChunk(
            $dest_xml->documentElement()->toString() );
    }
    return $new_xml->toString(1);
}

my $yaml_fn =
    qq#/home/shlomif/Docs/homepage/homepage/trunk/lib/screenplay-xml/list.yaml#;
use YAML::XS ();
my ($yaml) = YAML::XS::LoadFile($yaml_fn);
my @rec = ( grep { "QUEEN_PADME_TALES" eq $_->{'base'} } @$yaml );
if ( @rec != 1 )
{
    die;
}
my $docs_dir_obj =
    path("/home/shlomif/Docs/homepage/homepage/trunk/lib/screenplay-xml/xml/");

my @sources;
foreach my $chapter ( @{ $rec[0]{'docs'} } )
{
    my $bn     = $chapter->{'base'};
    my $xml_bn = "$bn.xml";
    push @sources, { filename => scalar( $docs_dir_obj->child($xml_bn) ), };

}

if (0)
{
    push @sources,
        {
        filename => scalar(
            $docs_dir_obj->child(
                "Queen-Padme-Tales--Queen-Amidala-vs-the-Klingon-Warriors.xml")
        ),
        };

    push @sources,
        {
        filename => scalar(
            $docs_dir_obj->child("Queen-Padme-Tales--Planting-Trees.xml")
        )
        };

}

my $OUTPUT_FN   = "queen-padme.screenplay-xml.xml";
my $output_text = _merge( { inputs => [@sources] } );
path($OUTPUT_FN)->spew_utf8($output_text);
print "Wrote : $OUTPUT_FN\n";
my $XHTML_FN = "queen-padme.screenplay-output.xhtml";
system( $^X, "-MXML::Grammar::Screenplay::App::ToHTML=run",
    "-E", "run()", "--", "--output", $XHTML_FN, $OUTPUT_FN );
print "Wrote : $XHTML_FN\n";
