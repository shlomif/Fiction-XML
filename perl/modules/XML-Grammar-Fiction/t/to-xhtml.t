#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;

use File::Spec;

use XML::LibXML;

use XML::Grammar::Fiction::ToHTML;
use XML::Grammar::Fiction::ToDocBook;

my @tests = (qw(
        sections-and-paras
        sections-p-b-i
    ));

sub load_xml
{
    my $path = shift;

    open my $in, "<", $path;
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

# TEST:$num_texts=2

my $converter = XML::Grammar::Fiction::ToHTML->new({
        data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
    });

my $db_converter = XML::Grammar::Fiction::ToDocBook->new({
        data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
    });

foreach my $fn (@tests)
{
    my $xhtml_text = $converter->translate_to_html({
            source => { file => "t/data/xml/$fn.xml", },
            output => "string",
        }
        );

    my $docbook_text = $db_converter->translate_to_docbook({
            source => { file => "t/data/xml/$fn.xml", },
            output => "string",
        }
        );

    my $parser = XML::LibXML->new();

    $parser->load_ext_dtd(0);

    my $doc = $parser->parse_string($xhtml_text);

    my $db_parser = XML::LibXML->new();

    $db_parser->load_ext_dtd(0);

    my $db_doc = $db_parser->parse_string($docbook_text);
    
    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs('x', q{http://www.w3.org/1999/xhtml});
    $xpc->registerNs('db', q{http://docbook.org/ns/docbook});

    my $xhtml_find = sub {
        my $xpath = shift;
        return $xpc->findnodes($xpath, $doc);
    };

    my $db_find = sub {
        my $xpath = shift;
        return $xpc->findnodes($xpath, $db_doc);
    };

    # TEST*$num_texts
    is (
        scalar(() = $xhtml_find->(q{//x:html})),
        1,
        "Found one article with id index",
    );

    {
        my @title = $db_find->(q{//db:article/db:info/db:title});

        # TEST*$num_texts
        is (
            scalar(@title),
            1,
            "Found one global <db:title>",
        );

        # TEST*$num_texts
        is ($title[0]->textContent(), "David vs. Goliath - Part I");
    }

    # TEST:$num_xhtml_top_titles=2;
    # TEST:$n=$num_texts*$num_xhtml_top_titles;
    foreach my $xpath (
        q{//x:html/x:head/x:title}, 
        q{//x:html/x:body/x:div/x:h1},
    )
    {
        my @title = $xhtml_find->($xpath);

        # TEST*$n
        is (
            scalar(@title),
            1,
            "Found one global <x:title>",
        );

        # TEST*$n
        is ($title[0]->textContent(), "David vs. Goliath - Part I",
            "XHTML <title> has good content"
        );
    }
    
    # TEST*$num_texts
    ok (
        (scalar(() = $xhtml_find->(q{//x:div}))
            >=
            1
        ),
        "Found role=description sections",
    );

    {
        my @elems = $xhtml_find->(q{//x:div[@xml:id="top"]/x:h2});
        # TEST*$num_texts
        is (scalar(@elems), 1, "One element");

        # TEST*$num_texts
        is ($elems[0]->textContent(), "The Top Section", 
            "<h2> element contains the right thing.");
    }

    # TEST:$num_with_styles=1;
    if ($fn eq "sections-p-b-i")
    {
        my @elems;

        @elems = $xhtml_find->(q{//x:div/x:p/x:b});
        # TEST*$num_with_styles
        is (
            scalar(@elems),
            1,
            "Found bold tag",
        );

        # TEST*$num_with_styles
        like ($elems[0]->toString(), qr{swear}, 
            "Elem[0] is the right <b> tag."
        );
        
        @elems = $xhtml_find->(q{//x:div/x:p/x:i});
        # TEST*$num_with_styles
        is (
            scalar(@elems),
            1,
            "Found italic tag",
        );

        # TEST*$num_with_styles
        like ($elems[0]->toString(), qr{David}, 
            "<i>[0] contains the right contents."
        );
    }
}

1;

