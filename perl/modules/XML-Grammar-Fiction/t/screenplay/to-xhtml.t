#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::XML tests => 3;

use File::Spec;

use XML::LibXML;

use XML::Grammar::Screenplay::ToHTML;

my @tests = (qw(
        with-internal-description
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

# TEST:$num_texts=1

my $converter = XML::Grammar::Screenplay::ToHTML->new({
        data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
    });

foreach my $fn (@tests)
{
    my $xhtml_text = $converter->translate_to_html({
            source => { file => "t/screenplay/data/xml/$fn.xml", },
            output => "string",
        }
        );

    my $parser = XML::LibXML->new();

    $parser->load_ext_dtd(0);

    my $doc = $parser->parse_string($xhtml_text);

    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs('x', q{http://www.w3.org/1999/xhtml});
    # TEST*$num_texts
    is (
        scalar(() = $xpc->find(q{//x:html}, $doc)),
        1,
        "Found one article with id index",
    );

    # TEST*$num_texts
    ok (
        (scalar(() = $xpc->find(q{//x:div[@class='saying']}, $doc))
            >=
            1
        ),
        "Found role=description sections",
    );

    # TEST*$num_texts
    ok (
        (scalar(() = $xpc->find(q{//x:div[@class='saying']/x:p/x:strong[@class='sayer']}, $doc))
            >=
            1
        ),
        "Found role=description sections",
    );

}

1;

