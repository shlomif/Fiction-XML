package XML::Grammar::Screenplay::App::ToHTML;

use strict;
use warnings;
use autodie;

use parent 'Exporter';

our @EXPORT = (qw(run));

use Getopt::Long qw/ GetOptions /;

use XML::Grammar::Screenplay::ToHTML ();

=head1 NAME

XML::Grammar::Screenplay::App::ToHTML - module implementing
a command line application to convert a Screenplay XML file to HTML

=head1 FUNCTIONS

=head2 XML::Grammar::Screenplay::App::ToHTML->run(\%args)

Call with no arguments to run the application from the commandline.

%args may contain dom_post_proc (Added at version 0.26.0).

=cut

sub run
{
    my ( $self, $args ) = @_;
    my $output_filename;

    GetOptions( "output|o=s" => \$output_filename, );

    if ( !defined($output_filename) )
    {
        die "Output filename not specified! Use the -o|--output flag!";
    }

    my $converter = XML::Grammar::Screenplay::ToHTML->new();

    my $output_dom = $converter->translate_to_html(
        {
            source => { file => shift(@ARGV), },
            output => "dom",
        }
    );
    if ( defined($args) )
    {
        $args->{dom_post_proc}->(
            +{
                dom => ( \$output_dom ),
            }
        );
    }
    my $chars = $converter->_to_html_stylesheet()->output_as_chars($output_dom);

    $chars =~ s/[ \t]+$//gms;

    open my $out, ">:encoding(UTF-8)", $output_filename;
    print {$out} $chars;
    close($out);

    return;
}

1;
