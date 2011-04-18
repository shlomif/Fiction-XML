package XML::Grammar::Fiction::App::ToHTML;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long;

use XML::Grammar::Fiction::ToHTML;

=head1 NAME

XML::Grammar::Fiction::App::ToHTML - command line app-in-a-module to convert
Fiction-XML file to HTML

=head1 VERSION

Version 0.1.7

=cut

our $VERSION = '0.1.7';

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


=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-fiction at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fiction>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

