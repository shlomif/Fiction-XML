package XML::Grammar::Screenplay::App::ToHTML;

use strict;
use warnings;
use autodie;

use base 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long;

use XML::Grammar::Screenplay::ToHTML;

our $VERSION = '0.11.0';

=head1 NAME

XML::Grammar::Screenplay::App::ToHTML - module implementing
a command line application to convert a Screenplay XML file to HTML

=head1 VERSION

0.11.0

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

    my $converter = XML::Grammar::Screenplay::ToHTML->new();

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

