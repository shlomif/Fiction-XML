package XML::Grammar::FictionBase::XSLT::Converter;

use strict;
use warnings;

use Carp;
use File::Spec;

use File::ShareDir ':ALL';

use XML::LibXML;
use XML::LibXSLT;

use MooX 'late';

has '_data_dir' => (isa => 'Str', is => 'rw');
has '_data_dir_from_input' => (isa => 'Str', is => 'rw', init_arg => 'data_dir',);
has '_rng' => (isa => 'XML::LibXML::RelaxNG', is => 'rw');
has '_xml_parser' => (isa => "XML::LibXML", is => 'rw');
has '_stylesheet' => (isa => "XML::LibXSLT::StylesheetWrapper", is => 'rw');
has 'rng_schema_basename' => (is => 'ro', isa => 'Str', required => 1,);
has 'xslt_transform_basename' => (is => 'ro', isa => 'Str', required => 1,);

=head1 NAME

XML::Grammar::FictionBase::XSLT::Converter - base module that converts an XML
file to a different XML file using an XSLT transform.

=head1 VERSION

Version 0.9.3

=cut

our $VERSION = '0.9.3';

=head1 METHODS

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=head2 BUILD()

Internal - (to settle pod-coverage.).

=head2 rng_schema_basename()

Inherited - (to settle pod-coverage.).

=head2 xslt_transform_basename()

Inherited - (to settle pod-coverage.).

=cut

sub BUILD
{
    my ($self) = @_;

    my $data_dir = $self->_data_dir_from_input() ||
        dist_dir( 'XML-Grammar-Fiction');

    $self->_data_dir($data_dir);

    my $rngschema =
        XML::LibXML::RelaxNG->new(
            location =>
            File::Spec->catfile(
                $self->_data_dir(),
                $self->rng_schema_basename(),
            ),
        );

    $self->_rng($rngschema);

    $self->_xml_parser(XML::LibXML->new());

    my $xslt = XML::LibXSLT->new();

    my $style_doc = $self->_xml_parser()->parse_file(
            File::Spec->catfile(
                $self->_data_dir(),
                $self->xslt_transform_basename(),
            ),
        );

    $self->_stylesheet($xslt->parse_stylesheet($style_doc));

    return 0;
}

=head2 $converter->perform_translation

=over 4

=item * my $final_source = $converter->perform_translation({source => {file => $filename}, output => "string" })

=item * my $final_source = $converter->perform_translation({source => {string_ref => \$buffer}, output => "string" })

=item * my $final_dom = $converter->perform_translation({source => {file => $filename}, output => "dom" })

=item * my $final_dom = $converter->perform_translation({source => {dom => $libxml_dom}, output => "dom" })

=back

Does the actual conversion. The C<'source'> argument points to a hash-ref with
keys and values for the source. If C<'file'> is specified there it points to the
filename to translate (currently the only available source). If
C<'string_ref'> is specified it points to a reference to a string, with the
contents of the source XML. If C<'dom'> is specified then it points to an XML
DOM as parsed or constructed by XML::LibXML.

The C<'output'> key specifies the return value. A value of C<'string'> returns
the XML as a string, and a value of C<'dom'> returns the XML as an
L<XML::LibXML> DOM object.

=cut

sub _undefize
{
    my $v = shift;

    return defined($v) ? $v : "(undef)";
}

sub _calc_and_ret_dom_without_validate
{
    my $self = shift;
    my $args = shift;

    my $source = $args->{source};

    return
          exists($source->{'dom'})
        ? $source->{'dom'}
        : exists($source->{'string_ref'})
        ? $self->_xml_parser()->parse_string(${$source->{'string_ref'}})
        : $self->_xml_parser()->parse_file($source->{'file'})
        ;
}

sub _get_dom_from_source
{
    my $self = shift;
    my $args = shift;

    my $source_dom = $self->_calc_and_ret_dom_without_validate($args);

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
        confess "RelaxNG validation failed [\$ret_code == "
            . _undefize($ret_code) . " ; $@]"
            ;
    }

    return $source_dom;
}

sub perform_translation
{
    my ($self, $args) = @_;

    my $source_dom = $self->_get_dom_from_source($args);

    my $stylesheet = $self->_stylesheet();

    my $results = $stylesheet->transform($source_dom);

    my $medium = $args->{output};

    if ($medium eq "string")
    {
        return $stylesheet->output_string($results);
    }
    elsif ($medium eq "dom")
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
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fiction>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

1;

