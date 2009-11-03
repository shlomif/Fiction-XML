#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use File::Spec;

use XML::LibXML;

use XML::Grammar::Fiction::ToHTML;

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

foreach my $fn (@tests)
{
    my $xhtml_text = $converter->translate_to_html({
            source => { file => "t/data/xml/$fn.xml", },
            output => "string",
        }
        );

    my $parser = XML::LibXML->new();

    my $doc = $parser->parse_string($xhtml_text);

    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs('x', q{http://www.w3.org/1999/xhtml});
    # TEST*$num_texts
    is (
        scalar(() = $xpc->findnodes(q{//x:html}, $doc)),
        1,
        "Found one article with id index",
    );

    # TEST*$num_texts
    ok (
        (scalar(() = $xpc->findnodes(q{//x:div}, $doc))
            >=
            1
        ),
        "Found role=description sections",
    );


    # TEST:$num_with_styles=1;
    if ($fn eq "sections-p-b-i")
    {
        my @elems;

        @elems = $xpc->findnodes(q{//x:div/x:p/x:b}, $doc);
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
        
        @elems = $xpc->findnodes(q{//x:div/x:p/x:i}, $doc);
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

