#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use 5.014;

use Carp        ();
use Path::Tiny  qw/ cwd path tempdir tempfile /;
use XML::LibXML ();

my $SCREENPLAY_XML_NS =
"http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/";

sub _get_xpc
{
    my ( $elem, ) = @_;

    my $xpc = XML::LibXML::XPathContext->new($elem);
    $xpc->registerNs( "sp", $SCREENPLAY_XML_NS );
    return $xpc;
}

sub _merge
{
    my $args   = shift;
    my $inputs = $args->{inputs};

    my $parser  = XML::LibXML->new();
    my $new_xml = $parser->parse_string(
qq#<document xmlns="$SCREENPLAY_XML_NS"><head></head><body id="index"></body></document>#
    );
    my $root        = $new_xml->documentElement();
    my $root_xpc    = _get_xpc($root);
    my ($root_body) = $root_xpc->findnodes('./sp:body');

    my $id_differentiator_counters = +{};
    my $chspter_idx                = 0;
    foreach my $src (@$inputs)
    {
        my $this_chapter_idx = ( ++$chspter_idx );
        my $src_type         = $src->{type};
        if ( $src_type ne 'file' )
        {
            Carp::confess(qq#Unknown input type "$src_type"#);
        }
        my $src_fn = $src->{filename};
        my $input  = $parser->parse_file($src_fn);
        my $doc    = $input->documentElement();
        my $xpc    = _get_xpc($doc);
        $xpc->registerNs( "sp", $SCREENPLAY_XML_NS );
        my @el = $xpc->findnodes("//sp:document/sp:body/sp:scene");
        my $dest_xml;

        if ( not @el )
        {
            Carp::confess(q#no scenes found in "$src_fn"#);
        }
        elsif ( 1 == @el )
        {
            $dest_xml = $el[0];

            # @el = $xpc->findnodes("//sp:document/sp:body/sp:scene/sp:scene");
        }
        else
        {
            $dest_xml = $parser->parse_string(
qq#<scene xmlns="$SCREENPLAY_XML_NS" id="chapter_$this_chapter_idx" title="Chapter $this_chapter_idx"></scene>#
            );
            foreach my $el (@el)
            {
                $dest_xml->documentElement()
                    ->appendWellBalancedChunk( $el->toString() );
            }
        }
        foreach my $el ($dest_xml)
        {
            my $xpc   = _get_xpc($el);
            my @idels = $xpc->findnodes("//sp:scene[\@id]");
            foreach my $id_el (@idels)
            {
                my $old_id = $id_el->getAttribute('id');
                if ( exists $id_differentiator_counters->{$old_id} )
                {
                    my $new_idx = $id_differentiator_counters->{$old_id}++;
                    my $new_id  = sprintf( "%s_%d", $old_id, $new_idx );
                    $id_el->setAttribute( 'id', $new_id );
                }
                else
                {
                    $id_differentiator_counters->{$old_id} = 1;
                }
            }
        }
        $root_body->appendWellBalancedChunk(

            # $dest_xml->documentElement()->toString() );
            $dest_xml->toString()
        );
    }
    return +{ xml => $new_xml, };
}

my $yaml_fn =
    qq#/home/shlomif/Docs/homepage/homepage/trunk/lib/screenplay-xml/list.yaml#;
use YAML::XS ();
my ($yaml) = YAML::XS::LoadFile($yaml_fn);
my @rec = ( grep { "QUEEN_PADME_TALES" eq $_->{'base'} } @$yaml );
if ( @rec != 1 )
{
    Carp::confess(qq#There are more than 1, or fewer, matching records!#);
}
my $docs_dir_obj =
    path("/home/shlomif/Docs/homepage/homepage/trunk/lib/screenplay-xml/xml/");

my @inputs;
foreach my $chapter ( @{ $rec[0]{'docs'} } )
{
    my $bn     = $chapter->{'base'};
    my $xml_bn = "$bn.xml";
    push @inputs,
        {
        type     => "file",
        filename => scalar( $docs_dir_obj->child($xml_bn) ),
        };

}

my $OUTPUT_FN   = "queen-padme.screenplay-xml.xml";
my $output_xml  = _merge( { inputs => [@inputs] } );
my $output_text = $output_xml->{'xml'}->toString();
path($OUTPUT_FN)->spew_utf8($output_text);
print "Wrote : $OUTPUT_FN\n";
my $XHTML_FN = "queen-padme.screenplay-output.xhtml";
system( $^X, "-MXML::Grammar::Screenplay::App::ToHTML=run",
    "-E", "run()", "--", "--output", $XHTML_FN, $OUTPUT_FN );
print "Wrote : $XHTML_FN\n";
