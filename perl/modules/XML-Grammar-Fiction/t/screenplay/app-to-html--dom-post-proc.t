#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';
use Test::More tests => 3;

use XML::LibXML qw(XML_TEXT_NODE);
use XML::Grammar::Screenplay::App::ToHTML            ();
use XML::Grammar::Screenplay::App::FromProto         ();
use XML::Grammar::Screenplay::FromProto              ();
use XML::Grammar::Screenplay::FromProto::Parser::QnD ();
use XML::Grammar::Screenplay::ToHTML                 ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

# TEST:$num_texts=6

my $converter = XML::Grammar::Screenplay::ToHTML->new(
    {
        data_dir => cwd()->child("extradata")->absolute->stringify,
    }
);

my $xpc = XML::LibXML::XPathContext->new();
$xpc->registerNs( 'x', q{http://www.w3.org/1999/xhtml} );

sub _calc_doc__from_text
{
    my ($fn) = @_;

    my $outdir = tempdir();
    my $outfn  = "$outdir/foo.xhtml";
    my $xmlfn  = "$outdir/my-screenplay.screenplay-xml.xml";
    {
        local @ARGV = ( "--output", $xmlfn, $fn );
        XML::Grammar::Screenplay::App::FromProto::run();
    }
    {
        local @ARGV = ( "--output", $outfn, $xmlfn );
        XML::Grammar::Screenplay::App::ToHTML::run();
    }
    my $doc = XML::LibXML->load_xml( location => $outfn );

    return ($doc);
}

{
    my ($doc) = _calc_doc__from_text(
        './t/screenplay/data/proto-text/html-figure.screenplay-text.txt',
    );
    {
        my $r = $xpc->find( q{./x:html/x:head/x:title}, $doc );

        # TEST
        is( $r->size(), 1, "Found one title", );

        # TEST
        like( $r->[0]->textContent(), qr/\AQueen /ms, "Correct textContent()",
        );
    }
    {
        my $r = $xpc->find( q{//x:figure}, $doc, );

        # TEST
        is( $r->size(), 1, "Found one link tag", );
    }
}

1;
