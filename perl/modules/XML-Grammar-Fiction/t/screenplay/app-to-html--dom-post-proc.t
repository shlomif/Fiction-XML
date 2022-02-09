#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';
use Test::More tests => 5;

use XML::LibXML qw(XML_TEXT_NODE);
use XML::Grammar::Screenplay::App::ToHTML    ();
use XML::Grammar::Screenplay::App::FromProto ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

# TEST:$num_texts=1

my $xpc     = XML::LibXML::XPathContext->new();
my $XHTMLNS = "http://www.w3.org/1999/xhtml";
$xpc->registerNs( 'x', $XHTMLNS, );

my %dom_post_proc__was_called__counts;

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
        XML::Grammar::Screenplay::App::ToHTML->run(
            +{
                dom_post_proc => sub {
                    my $output_dom = shift()->{dom};

                    ++$dom_post_proc__was_called__counts{$fn};

                    my @list = $xpc->findnodes(
                        q#descendant::x:figure[contains(@class, 'asciiart')]#,
                        ($$output_dom) );

                    foreach my $el (@list)
                    {
                        my $parent = $el->parentNode;
                        my $wrapper =
                            $$output_dom->createElementNS( $XHTMLNS, 'div' );
                        $wrapper->setAttribute( 'class', 'asciiart_wrapper' );
                        $wrapper->appendChild( $el->cloneNode(1) );
                        $parent->replaceChild( $wrapper, $el );
                    }
                    return;
                },
            }
        );
    }
    my $doc = XML::LibXML->load_xml( location => $outfn );

    return ($doc);
}

{
    my ($doc) = _calc_doc__from_text(
        './t/screenplay/data/proto-text/html-figure.screenplay-text.txt', );
    {
        my $r = $xpc->find( q{./x:html/x:head/x:title}, $doc );

        # TEST
        is( $r->size(), 1, "Found one title", );

        # TEST
        is(
            $r->[0]->textContent(),
            "Stub title", "Correct title textContent()",
        );
    }
    {
        my $r = $xpc->find( q{//x:figure}, $doc, );

        # TEST
        is( $r->size(), 1, "Found one link tag", );
    }
    {
        my $r = $xpc->find( q{//x:div[@class='asciiart_wrapper' and x:figure]},
            $doc, );

        # TEST
        is( $r->size(), 1, "Preprocessing was done", );
    }
}

# TEST
is_deeply(
    ( \%dom_post_proc__was_called__counts ),
    +{
        './t/screenplay/data/proto-text/html-figure.screenplay-text.txt' => 1,
    },
    "dom_post_proc__was_called__counts",
);
