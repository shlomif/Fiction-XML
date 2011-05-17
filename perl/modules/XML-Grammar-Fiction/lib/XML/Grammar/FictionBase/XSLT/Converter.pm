package XML::Grammar::FictionBase::XSLT::Converter;

use strict;
use warnings;

use Carp;
use File::Spec;

use File::ShareDir ':ALL';

use XML::LibXML;
use XML::LibXSLT;

use base 'XML::Grammar::Screenplay::Base';

use Moose;

has '_data_dir' => (isa => 'Str', is => 'rw');
has '_rng' => (isa => 'XML::LibXML::RelaxNG', is => 'rw');
has '_xml_parser' => (isa => "XML::LibXML", is => 'rw');
has '_stylesheet' => (isa => "XML::LibXSLT::StylesheetWrapper", is => 'rw');
has 'rng_basename' => (is => 'ro', isa => 'Str',);
has 'xslt_basename' => (is => 'ro', isa => 'Str',);

=head1 NAME

XML::Grammar::FictionBase::XSLT::Converter - base module that converts an XML 
file to a different XML file using an XSLT transform.

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
                $self->rng_basename(),
            ),
        );

    $self->_rng($rngschema);

    $self->_xml_parser(XML::LibXML->new());

    my $xslt = XML::LibXSLT->new();

    my $style_doc = $self->_xml_parser()->parse_file(
            File::Spec->catfile(
                $self->_data_dir(), 
                $self->xslt_basename(),
            ),
        );

    $self->_stylesheet($xslt->parse_stylesheet($style_doc));

    return 0;
}

=head2 $converter->perform_translation({source => {file => $filename}, output => "string" })

Does the actual conversion. $filename is the filename to translate (currently
the only available source). 

The C<'output'> key specifies the return value. A value of C<'string'> returns 
the XML as a string, and a value of C<'xml'> returns the XML as an 
L<XML::LibXML> DOM object.

=cut

sub perform_translation
{
    my ($self, $args) = @_;

    my $source_dom =
        $self->_xml_parser()->parse_file($args->{source}->{file})
        ;

    my $ret_code;

    eval
    {
        $ret_code = $self->_rng()->validate($source_dom);
    };

    if (defined($ret_code) && ($ret_code == 0))
    {
        # It's OK.
    }
    else
    {
        confess "RelaxNG validation failed [\$ret_code == $ret_code ; $@]";
    }

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

1;

