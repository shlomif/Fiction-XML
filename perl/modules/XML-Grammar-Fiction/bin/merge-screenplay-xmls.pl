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

my $new_xml = XML::LibXML::Element->new('XML');
foreach my $src (@sources)
{
    $new_xml->appendWellBalancedChunk( $src->documentElement()->toString() );
}
print $new_xml->toString(1);
