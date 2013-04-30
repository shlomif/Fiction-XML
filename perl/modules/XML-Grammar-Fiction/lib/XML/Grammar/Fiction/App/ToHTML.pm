package XML::Grammar::Fiction::App::ToHTML;

use strict;
use warnings;
use autodie;

use base 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long;

use XML::Grammar::Fiction::ToHTML;

=head1 NAME

XML::Grammar::Fiction::App::ToHTML - command line app-in-a-module to convert
Fiction-XML file to HTML

=head1 VERSION

Version 0.14.3

=cut

our $VERSION = '0.14.3';

=head1 SYNOPSIS

    perl -MXML::Grammar::Fiction::App::ToHTML -e 'run()' -- \
	-o "$OUTPUT_FILE" "$INPUT_FILE"

=head1 FUNCTIONS

=head2 run()

Call with no arguments to run the application from the commandline.

=cut

sub run
{
    my $output_filename;

    GetOptions(
        "output|o=s" => \$output_filename,
    );

    if (!defined($output_filename))
    {
        die "Output filename not specified! Use the -o|--output flag!";
    }

    my $converter = XML::Grammar::Fiction::ToHTML->new();

    my $output_text = $converter->translate_to_html({
            source => { file => shift(@ARGV), },
            output => "string",
        }
    );

    open my $out, ">", $output_filename;
    binmode $out, ":utf8";
    print {$out} $output_text;
    close($out);

    exit(0);
}

1;

