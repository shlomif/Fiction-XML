package XML::Grammar::FictionBase::XSLT::Converter;

use strict;
use warnings;

use Carp;
use File::Spec;

use File::ShareDir ':ALL';

use XML::LibXML;
use XML::LibXSLT;

use MooX 'late';

has '_data_dir' =>
(
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_data_dir();
    },
);

has '_data_dir_from_input' =>
(
    isa => 'Str',
    is => 'rw',
    init_arg => 'data_dir',
);

has '_rng' =>
(
    isa => 'XML::LibXML::RelaxNG',
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_rng();
    },
);

sub _calc_rng
{
    my $self = shift;

    return
        XML::LibXML::RelaxNG->new(
            location =>
            File::Spec->catfile(
                $self->_data_dir(),
                $self->rng_schema_basename(),
            ),
        );
}

has '_xml_parser' =>
(
    isa => 'XML::LibXML',
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_xml_parser();
    },
);

sub _calc_xml_parser
{
    my $self = shift;

    return XML::LibXML->new();
}

has '_xslt_processor' =>
(
    isa => "XML::LibXSLT",
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_xslt_processor();
    },
);

sub _calc_xslt_processor
{
    my ($self) = @_;

    return XML::LibXSLT->new();
}

has '_stylesheet' =>
(
    isa => "XML::LibXSLT::StylesheetWrapper",
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_stylesheet();
    },
);

sub _calc_stylesheet
{
    my ($self) = @_;

    my $style_doc = $self->_xml_parser()->parse_file(
            File::Spec->catfile(
                $self->_data_dir(),
                $self->xslt_transform_basename(),
            ),
        );

    return $self->_xslt_processor->parse_stylesheet($style_doc);
}

has 'rng_schema_basename' => (is => 'ro', isa => 'Str', required => 1,);
has 'xslt_transform_basename' => (is => 'ro', isa => 'Str', required => 1,);

=head1 NAME

XML::Grammar::FictionBase::XSLT::Converter - base module that converts an XML
file to a different XML file using an XSLT transform.

=head1 VERSION

Version 0.14.0

=cut

our $VERSION = '0.14.0';

=head1 METHODS

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=head2 rng_schema_basename()

Inherited - (to settle pod-coverage.).

=head2 xslt_transform_basename()

Inherited - (to settle pod-coverage.).

=cut

sub _calc_data_dir
{
    my ($self) = @_;

    return $self->_data_dir_from_input() || dist_dir( 'XML-Grammar-Fiction');
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

1;

