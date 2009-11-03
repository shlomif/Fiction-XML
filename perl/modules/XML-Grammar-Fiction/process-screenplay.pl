#!/usr/bin/perl

use strict;
use warnings;

use XML::Grammar::Screenplay::FromProto;
use Getopt::Long;
use Carp;

# local $::RD_TRACE = 1;

my $output_fn;

GetOptions(
    "output|o=s" => \$output_fn,
);

my $filename = shift(@ARGV);

my $grammar = XML::Grammar::Screenplay::FromProto->new();

my $got_xml = $grammar->convert(
    {
        source =>
        {
            file => $filename,
        },
    }

);

if (defined($output_fn))
{
    open my $out, ">", $output_fn
        or confess "Cannot open file \"$output_fn\" for writing!";
    print {$out} $got_xml;
    close($out)
}
else
{
    print $got_xml;
}

