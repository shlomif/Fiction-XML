#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Grammar::Screenplay' );
}

diag( "Testing XML::Grammar::Screenplay $XML::Grammar::Screenplay::VERSION, Perl $], $^X" );
