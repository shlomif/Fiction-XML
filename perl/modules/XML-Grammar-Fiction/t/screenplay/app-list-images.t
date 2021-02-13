#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 1;
use XmlGrammarTestXML qw(my_is_xml);
use Path::Tiny qw/ path /;

use XML::LibXML                                          ();
use XML::Grammar::Screenplay::FromProto::API::ListImages ();
use XML::Grammar::Screenplay::FromProto::Parser::QnD     ();

my @tests = (
    qw(
        with-multiple-img-elements
    )
);

# TEST:$num_texts=1

my $image_lister =
    XML::Grammar::Screenplay::FromProto::API::ListImages->new( {} );

foreach my $fn (@tests)
{
    my $got_doc = $image_lister->calc_doc__from_proto_text(
        {
            source => {
                file => "t/screenplay/data/proto-text/$fn.txt",
            },
        }
    );

    # TEST*$num_texts
    is_deeply(
        [ map { $_->uri() } @{ $got_doc->list_images() }, ],
        [ 'david.webp', 'sling.png', 'zebra.jpg', ],
        "image list",
    );
}

1;
