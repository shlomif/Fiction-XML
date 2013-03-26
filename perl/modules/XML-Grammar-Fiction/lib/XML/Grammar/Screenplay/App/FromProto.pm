package XML::Grammar::Screenplay::App::FromProto;

use strict;
use warnings;
use autodie;

use base 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long;

use XML::Grammar::Screenplay::FromProto;
use XML::Grammar::Screenplay::FromProto::Parser::QnD;

our $VERSION = '0.12.1';

=head1 NAME

XML::Grammar::Screenplay::App::FromProto - module implementing
a command line application to convert a well-formed text to
Screenplay XML.

=head1 VERSION

0.11.0

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

1;

