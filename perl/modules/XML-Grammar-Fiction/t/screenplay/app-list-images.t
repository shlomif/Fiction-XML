#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 3;
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
    my $full_fn = "t/screenplay/data/proto-text/$fn.txt";
    my $xml_fn  = "t/screenplay/data/xml/$fn.screenplay-xml.xml";
    my $got_doc = $image_lister->calc_doc__from_proto_text(
        {
            source => {
                file => $full_fn,
            },
        }
    );

    my $WANT_IMAGES = [ 'david.webp', 'sling.png', 'zebra.jpg', ];

    # TEST*$num_texts
    is_deeply( [ map { $_->uri() } @{ $got_doc->list_images() }, ],
        $WANT_IMAGES, "image list", );

    # TEST*$num_texts
    is_deeply(
        [
            split /\r?\n/,
            scalar(`$^X -I lib bin/screenplay-text--list-images -- "$full_fn"`)
        ],
        $WANT_IMAGES,
        "image list",
    );

    # TEST*$num_texts
    is_deeply(
        [
            split /\r?\n/,
            scalar(`$^X -I lib bin/screenplay-text--list-images -- "$xml_fn"`)
        ],
        $WANT_IMAGES,
        "xml image list",
    );
}

1;
