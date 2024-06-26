package XML::Grammar::Screenplay::App::FromProto;

use strict;
use warnings;
use autodie;

use parent 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long qw/ GetOptions /;

use XML::Grammar::Screenplay::FromProto ();

=head1 NAME

XML::Grammar::Screenplay::App::FromProto - module implementing
a command line application to convert a well-formed text to
Screenplay XML.

=head1 SYNOPSIS

    perl -MXML::Grammar::Screenplay::App::FromProto -e 'run()' -- \
	-o $@ $<

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

    require XML::Grammar::Screenplay::FromProto::Parser::QnD;
    my $converter = XML::Grammar::Screenplay::FromProto->new(
        {
            parser_class => "XML::Grammar::Screenplay::FromProto::Parser::QnD",
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

    return;
}

1;

