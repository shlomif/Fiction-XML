#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';
use Test::More tests => 12;

use XML::LibXML                      ();
use XML::Grammar::Screenplay::ToHTML ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

my @tests = (
    qw(
        with-internal-description
        with-img-element-inside-paragraphs
        with-tags-inside-paragraphs-with-code-block
        )
);

# TEST:$num_texts=3

my $converter = XML::Grammar::Screenplay::ToHTML->new(
    {
        data_dir => cwd()->child("extradata")->absolute->stringify,
    }
);

sub _calc_xpc_and_doc
{
    my ($fn) = @_;

    #body ...
    my $xhtml_text = $converter->translate_to_html(
        {
            source => { file => "t/screenplay/data/xml/$fn.xml", },
            output => "string",
        }
    );

    my $parser = XML::LibXML->new();

    $parser->load_ext_dtd(0);

    my $doc = $parser->parse_string($xhtml_text);

    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs( 'x', q{http://www.w3.org/1999/xhtml} );

    return ( $xpc, $doc );
}

foreach my $fn (@tests)
{
    my ( $xpc, $doc ) = _calc_xpc_and_doc($fn);

    # TEST*$num_texts
    my $r = $xpc->find( q{//x:html}, $doc );
    is( $r->size(), 1, "Found one article with id index", );

    $r = $xpc->find( q{//x:div[@class='saying']}, $doc );

    # TEST*$num_texts
    ok( ( $r->size() >= 1 ), "Found role=description sections", );

    $r = $xpc->find( q{//x:div[@class='saying']/x:p/x:strong[@class='sayer']},
        $doc );

    # TEST*$num_texts
    ok( ( $r->size() >= 1 ), "Found role=description sections", );
}

{
    my ( $xpc, $doc ) = _calc_xpc_and_doc('main-title');
    my $r = $xpc->find( q{./x:html/x:head/x:title}, $doc );

    # TEST
    is( $r->size(), 1, "Found one title", );

    # TEST
    is(
        $r->[0]->textContent(),
        "My Lame Screenplay: Joshua Gets a Life",
        "Correct textContent()",
    );
}

{
    my ( $xpc, $doc ) =
        _calc_xpc_and_doc('with-tags-inside-paragraphs-with-code-block');
    my $r = $xpc->find(
q{./x:html/x:body/x:main/x:section[@id='scene-top']/x:section[@id='scene-david_and_goliath']/x:div/x:figure[@class='asciiart']},
        $doc
    );

    # TEST
    is( $r->size(), 1, "Found one title", );
}

1;
