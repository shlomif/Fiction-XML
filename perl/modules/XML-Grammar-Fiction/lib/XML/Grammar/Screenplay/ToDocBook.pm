package XML::Grammar::Screenplay::ToDocBook;

use MooX 'late';

use XML::GrammarBase::Role::RelaxNG;
use XML::GrammarBase::Role::XSLT;

with ('XML::GrammarBase::Role::RelaxNG');
with XSLT(output_format => 'docbook');

has '+module_base' => (default => 'XML-Grammar-Fiction');
has '+rng_schema_basename' => (default => 'screenplay-xml.rng');

has '+to_docbook_xslt_transform_basename' =>
(
    default => 'screenplay-xml-to-docbook.xslt',
);

=head1 NAME

XML::Grammar::Screenplay::ToDocBook - module that converts the Screenplay
XML to DocBook.

=head1 METHODS

=head2 xslt_transform_basename()

Inherited - (to settle pod-coverage).

=head1 VERSION

Version 0.14.0

=cut

our $VERSION = '0.14.0';

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=cut

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

    return $self->perform_xslt_translation(
        {output_format => 'docbook', %{$args}}
    );
}

1;

