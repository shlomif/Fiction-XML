#! /usr/bin/env perl
#
# Short description for fork_data_file.pl
#
# Version 0.0.1
# Copyright (C) 2021 Shlomi Fish < https://www.shlomifish.org/ >
#
# Licensed under the terms of the MIT license.

use strict;
use warnings;
use 5.014;
use autodie;

use Path::Tiny   qw/ path tempdir tempfile cwd /;
use Getopt::Long qw/ GetOptions /;

my $from;
my $to_bn;

GetOptions( "from=s" => \$from, "to=s" => \$to_bn, )
    or die $!;

$from = path($from);
my $bn = $from->basename();
$bn =~ s/\. (?: txt | xhtml | xml ) \z//msx
    or die "wrong '$bn'";

$to_bn =~ m/\A [a-zA-Z0-9_\-]+ \z/msx
    or die "wrong --to '$to_bn'";

my @generated;
use Docker::CLI::Wrapper::Container v0.0.4 ();
my $container = "foo";
my $sys       = "sys";
my $obj       = Docker::CLI::Wrapper::Container->new(
    { container => $container, sys => $sys, }, );
foreach my $rec (
    {
        prefix => "proto-text",
        ext    => "txt",
    },
    {
        prefix => "xhtml",
        ext    => "xhtml",
    },
    {
        prefix => "xml",
        ext    => "xml",
    },
    )
{
    my $prefix = $rec->{prefix};
    my $ext    = "." . $rec->{ext};
    my $dir    = path("./t/screenplay/data/")->child($prefix);
    my $f      = $dir->child( $bn . $ext );
    my $t      = $dir->child( $to_bn . $ext );
    $f->copy($t);
    $obj->do_system( { cmd => [ "git", "add", "$t", ] } );
    push @generated, $t;
}
$obj->do_system( { cmd => [ ( split /\s+/, $ENV{EDITOR} ), @generated, ] } );

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2

=head2

=cut
