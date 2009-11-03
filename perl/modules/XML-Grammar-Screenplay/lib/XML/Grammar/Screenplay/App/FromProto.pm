package XML::Grammar::Screenplay::App::FromProto;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long;

use XML::Grammar::Screenplay::FromProto;
use XML::Grammar::Screenplay::FromProto::Parser::QnD;

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

    GetOptions(
        "output|o=s" => \$output_filename,
    );

    if (!defined($output_filename))
    {
        die "Output filename not specified! Use the -o|--output flag!";
    }

    my $converter = XML::Grammar::Screenplay::FromProto->new({
        parser_class => "XML::Grammar::Screenplay::FromProto::Parser::QnD",
    });

    my $output_xml = $converter->convert({
            source => { file => shift(@ARGV), },
        }
    );

    open my $out, ">", $output_filename;
    binmode $out, ":utf8";
    print {$out} $output_xml;
    close($out);

    exit(0);
}


=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-screenplay at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Screenplay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

