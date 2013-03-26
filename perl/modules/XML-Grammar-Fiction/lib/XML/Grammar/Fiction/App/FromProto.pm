package XML::Grammar::Fiction::App::FromProto;

use strict;
use warnings;
use autodie;

use base 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long;

use Exception::Class;

use XML::Grammar::Fiction::FromProto;
use XML::Grammar::Fiction::FromProto::Parser::QnD;


=head1 NAME

XML::Grammar::Fiction::App::FromProto - command line app-in-a-module
to convert from a well-formed plaintext format to Fiction-XML.

=head1 VERSION

Version 0.12.1

=cut

our $VERSION = '0.12.1';

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

    GetOptions(
        "output|o=s" => \$output_filename,
    );

    if (!defined($output_filename))
    {
        die "Output filename not specified! Use the -o|--output flag!";
    }

    my $converter = XML::Grammar::Fiction::FromProto->new({
        parser_class => "XML::Grammar::Fiction::FromProto::Parser::QnD",
    });

    eval {
        my $output_xml = $converter->convert({
                source => { file => shift(@ARGV), },
            }
        );

        open my $out, ">", $output_filename;
        binmode $out, ":utf8";
        print {$out} $output_xml;
        close($out);
    };

    # Error handling.

    my $e;
    if ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::TagsMismatch"))
    {
        warn $e->error(), "\n";
        warn "Open: ", $e->opening_tag->name(),
            " at line ", $e->opening_tag->line(), "\n"
            ;
        warn "Close: ",
            $e->closing_tag->name(), " at line ",
            $e->closing_tag->line(), "\n";

        exit(-1);
    }
    elsif ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::LineError"))
    {
        warn $e->error(), "\n";
        warn "At line ", $e->line(), "\n";
        exit(-1);
    }
    elsif ($e = Exception::Class->caught())
    {
        if (ref($e))
        {
            $e->rethrow();
        }
        else
        {
            die $e;
        }
    }

    exit(0);
}

1;

