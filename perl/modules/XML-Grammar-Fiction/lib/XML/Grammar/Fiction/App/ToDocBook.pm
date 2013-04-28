package XML::Grammar::Fiction::App::ToDocBook;

use strict;
use warnings;
use autodie;

use base 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long;

use XML::Grammar::Fiction::ToDocBook;

=head1 NAME

XML::Grammar::Fiction::App::ToDocBook - command line app-in-a-module
to convert a Fiction XML file to DocBook 5.

=head1 VERSION

Version 0.14.0

=cut

our $VERSION = '0.14.0';

=head1 SYNOPSIS

    perl -MXML::Grammar::Fiction::App::ToDocBook -e 'run()' -- \
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

    my $converter = XML::Grammar::Fiction::ToDocBook->new();

    my $output_text = $converter->translate_to_docbook({
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

