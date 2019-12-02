package XML::Grammar::Fiction::App::FromProto;

use strict;
use warnings;
use autodie;

use parent 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long qw/ GetOptions /;

use XML::Grammar::Fiction::FromProto              ();
use XML::Grammar::Fiction::FromProto::Parser::QnD ();

=head1 NAME

XML::Grammar::Fiction::App::FromProto - command line app-in-a-module
to convert from a well-formed plaintext format to Fiction-XML.

=head1 SYNOPSIS

    perl -MXML::Grammar::Fiction::App::FromProto -e 'run()' -- \
	-o "$OUTPUT_FILE" "$INPUT_FILE"

=head1 FUNCTIONS

=head2 run()

Call with no arguments to run the application from the commandline.

=cut

sub run
{
    my $output_filename;

    GetOptions( "output|o=s" => \$output_filename, );

    if ( !defined($output_filename) )
    {
        die "Output filename not specified! Use the -o|--output flag!";
    }

    my $converter = XML::Grammar::Fiction::FromProto->new(
        {
            parser_class => "XML::Grammar::Fiction::FromProto::Parser::QnD",
        }
    );

    $converter->_convert_while_handling_errors(
        {
            convert_args => {
                source => { file => shift(@ARGV), },
            },
            output_filename => $output_filename,
        }
    );

    exit(0);
}

1;

