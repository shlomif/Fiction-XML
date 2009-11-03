#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Grammar::Fiction' );
}

diag( "Testing XML::Grammar::Fiction $XML::Grammar::Fiction::VERSION, Perl $], $^X" );
