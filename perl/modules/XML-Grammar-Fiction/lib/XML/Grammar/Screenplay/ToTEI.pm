package XML::Grammar::Screenplay::ToTEI;

use strict;
use warnings;

use Carp;
use File::Spec;

use XML::LibXSLT;

use File::ShareDir ':ALL';

use XML::LibXML;
use XML::LibXSLT;

use Moose;

extends('XML::Grammar::FictionBase::XSLT::Converter');

has '+rng_basename' => (default => "screenplay-xml.rng");
has '+xslt_basename' => (default => "screenplay-xml-to-tei.xslt");

=head1 NAME

XML::Grammar::Screenplay::ToTEI - module that converts the Screenplay
XML to TEI (Text Encoding Initiative).

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

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
        dist_dir( 'XML-Grammar-Fiction');

    $self->_data_dir($data_dir);

    my $rngschema =
        XML::LibXML::RelaxNG->new(
            location =>
            File::Spec->catfile(
                $self->_data_dir(), 
                "screenplay-xml.rng"
            ),
        );

    $self->_rng($rngschema);

    $self->_xml_parser(XML::LibXML->new());

    my $xslt = XML::LibXSLT->new();

    my $style_doc = $self->_xml_parser()->parse_file(
            File::Spec->catfile(
                $self->_data_dir(), 
                "screenplay-xml-to-tei.xslt"
            ),
        );

    $self->_stylesheet($xslt->parse_stylesheet($style_doc));

    return 0;
}

=head2 $converter->translate_to_tei({source => {file => $filename}, output => "string" })

Does the actual conversion. $filename is the filename to translate (currently
the only available source). 

The C<'output'> key specifies the return value. A value of C<'string'> returns 
the XML as a string, and a value of C<'xml'> returns the XML as an 
L<XML::LibXML> DOM object.

=cut

sub translate_to_tei
{
    my ($self, $args) = @_;

    return $self->perform_translation($args);
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

