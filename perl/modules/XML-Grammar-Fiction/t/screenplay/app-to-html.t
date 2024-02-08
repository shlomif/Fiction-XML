#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec ();

use Path::Tiny qw/ path tempdir tempfile cwd /;

my $dir = tempdir();

my $fh = $dir->child("output.xhtml");

use Config;

{
    local %ENV = %ENV;
    my @p5lib = split( $Config{'path_sep'}, $ENV{'PERL5LIB'} );
    $ENV{'PERL5LIB'} = join(
        $Config{'path_sep'},
        File::Spec->rel2abs(
            File::Spec->catdir( File::Spec->curdir(),
                "t", "lib", "run-test-1", )
        ),
        @p5lib
    );

    # TEST
    ok(
        !system(
            $^X,
            "-MXML::Grammar::Screenplay::App::ToHTML",
            "-e",
            "run()",
            "--",
            "-o",
            "$fh",
            cwd()->child( "t", "screenplay", "data", "xml", "nested-s.xml" )
                ->stringify(),
        ),
        "Testing App::ToHTML",
    );
}

1;
