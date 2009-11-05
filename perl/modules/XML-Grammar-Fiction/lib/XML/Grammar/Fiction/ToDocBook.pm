package XML::Grammar::Fiction::ToDocBook;

use strict;
use warnings;

use Carp;
use File::Spec;

use XML::LibXSLT;

use XML::Grammar::Fiction::ConfigData;

use XML::LibXML;
use XML::LibXSLT;

use base 'XML::Grammar::Fiction::Base';

use Moose;


has '_data_dir' => (isa => 'Str', is => 'rw');
has '_dtd' => (isa => 'XML::LibXML::Dtd', is => 'rw');
has '_xml_parser' => (isa => "XML::LibXML", is => 'rw');
has '_stylesheet' => (isa => "XML::LibXSLT::StylesheetWrapper", is => 'rw');

=head1 NAME

XML::Grammar::Fiction::ToDocBook - module that converts the Screenplay
XML to DocBook.

=head1 VERSION

Version 0.0600

=cut

our $VERSION = '0.0600';

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=cut

sub _init
{
    my ($self, $args) = @_;

    my $data_dir = $args->{'data_dir'} ||
        XML::Grammar::Fiction::ConfigData->config('extradata_install_path')->[0];

    $self->_data_dir($data_dir);

    my $dtd =
        XML::LibXML::Dtd->new(
            "Screenplay XML 0.1.0",
            File::Spec->catfile(
                $self->_data_dir(), 
                "screenplay-xml.dtd"
            ),
        );

    $self->_dtd($dtd);

    $self->_xml_parser(XML::LibXML->new());

    my $xslt = XML::LibXSLT->new();

    my $style_doc = $self->_xml_parser()->parse_file(
            File::Spec->catfile(
                $self->_data_dir(), 
                "fiction-xml-to-docbook.xslt"
            ),
        );

    $self->_stylesheet($xslt->parse_stylesheet($style_doc));

    return 0;
}

=head2 $converter->translate_to_docbook({source => {file => $filename}, output => "string" })

Does the actual conversion. $filename is the filename to translate (currently
the only available source). 

The C<'output'> key specifies the return value. A value of C<'string'> returns 
the XML as a string, and a value of C<'xml'> returns the XML as an 
L<XML::LibXML> DOM object.

=cut

sub translate_to_docbook
{
    my ($self, $args) = @_;

    my $source_dom =
        $self->_xml_parser()->parse_file($args->{source}->{file})
        ;

    my $stylesheet = $self->_stylesheet();

    my $results = $stylesheet->transform($source_dom);

    my $medium = $args->{output};

    if ($medium eq "string")
    {
        return $stylesheet->output_string($results);
    }
    elsif ($medium eq "xml")
    {
        return $results;
    }
    else
    {
        confess "Unknown medium";
    }
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-fiction at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Screenplay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

