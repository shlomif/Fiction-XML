#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';
use Test::More tests => 30;

use XML::LibXML qw(XML_TEXT_NODE);
use XML::Grammar::Screenplay::FromProto              ();
use XML::Grammar::Screenplay::FromProto::Parser::QnD ();
use XML::Grammar::Screenplay::ToHTML                 ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

my @tests = (
    qw(
        with-internal-description
        with-img-element-inside-paragraphs
        with-tags-inside-paragraphs-with-code-block
        with-code-block--with-tag_role-as-code_block
        with-bold-tag-at-paragraph-start
        with-italics-tag-at-paragraph-start
    )
);

# TEST:$num_texts=6

my $converter = XML::Grammar::Screenplay::ToHTML->new(
    {
        data_dir => cwd()->child("extradata")->absolute->stringify,
    }
);

sub _calc_xpc_and_doc__from_text
{
    my ($fn) = @_;

    my $text_converter = XML::Grammar::Screenplay::FromProto->new(
        {
            parser_class => "XML::Grammar::Screenplay::FromProto::Parser::QnD",
        }
    );

    my $xml = $text_converter->convert(
        {
            source => { file => $fn, },
        },
    );

    #body ...
    my $xhtml_text = $converter->translate_to_html(
        {
            source => { string_ref => \$xml, },
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

    {
        my $child =
            $xpc->find( q{./x:pre[@class='asciiart' and @title='Star square']},
            $r->[0], );

        # TEST
        is( $child->size(), 1, "Found one pre", );
    }

    {
        my $child = $xpc->find( q{./x:figcaption}, $r->[0], );

        # TEST
        is( $child->size(), 1, "Found one pre", );

        # TEST
        is(
            $child->[0]->textContent(),
            "The logo of the Square company",
            "Correct figcaption textContent()",
        );

    }
}

{
    my ( $xpc, $doc ) = _calc_xpc_and_doc('with-i-element-inside-paragraphs');
    my $r = $xpc->find( q{.//x:a/x:i[text()='merciful']}, $doc, );

    # TEST
    is( $r->size(), 1, "Found one italics", );
}

{
    my ( $xpc, $doc ) = _calc_xpc_and_doc__from_text(
'./t/screenplay/data/proto-text/a-tag-followed-by-inlinedesc.screenplay-text.txt'
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
        my $r = $xpc->find(
            q{//x:a[@href='https://stexpanded.fandom.com/wiki/Katie_Jacobson']},
            $doc
        );

        # TEST
        is( $r->size(), 1, "Found one link tag", );

        my $tag    = $r->[0];
        my $ws_tag = $tag->nextSibling();

        # TEST
        is( $ws_tag->nodeType(), XML_TEXT_NODE, 'text node', );

        # TEST
        like( $ws_tag->textContent(), qr/\A\s+\z/ms, "whitespace text", );
    }
}

1;
