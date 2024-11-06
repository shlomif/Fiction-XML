#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use 5.014;

use Carp                                  ();
use Path::Tiny                            qw/ cwd path tempdir tempfile /;
use XML::Grammar::Screenplay::API::Concat ();

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

my $OUTPUT_FN  = "queen-padme.screenplay-xml.xml";
my $output_xml = XML::Grammar::Screenplay::API::Concat->new()
    ->concat( { inputs => [@inputs] } );
my $output_text = $output_xml->{'xml'}->toString();
path($OUTPUT_FN)->spew_utf8($output_text);
print "Wrote : $OUTPUT_FN\n";
my $XHTML_FN = "queen-padme.screenplay-output.xhtml";
system( $^X, "-MXML::Grammar::Screenplay::App::ToHTML=run",
    "-E", "run()", "--", "--output", $XHTML_FN, $OUTPUT_FN );
print "Wrote : $XHTML_FN\n";
