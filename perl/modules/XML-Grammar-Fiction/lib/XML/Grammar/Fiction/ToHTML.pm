package XML::Grammar::Fiction::ToHTML;

use strict;
use warnings;

use Carp;

use MooX 'late';

use XML::GrammarBase::Role::RelaxNG v0.2.2;
use XML::GrammarBase::Role::XSLT v0.2.2;

with ('XML::GrammarBase::Role::RelaxNG');
with XSLT(output_format => 'html');

has '+module_base' => (default => 'XML-Grammar-Fiction');
has '+rng_schema_basename' => (default => 'fiction-xml.rng');

has '+to_html_xslt_transform_basename' =>
(
    default => 'fiction-xml-to-html.xslt',
);

=head1 NAME

XML::Grammar::Fiction::ToHTML - module that converts the Fiction-XML to HTML.

=head1 VERSION

Version 0.14.7

=cut

our $VERSION = '0.14.7';

=head1 METHODS

=head2 xslt_transform_basename()

Inherited - (to settle pod-coverage).

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=cut

=head2 perform_xslt_translation

See L<XML::GrammarBase::Role::XSLT> . The output_format is C<'html'> .

=head2 translate_to_html

=over 4

=item * my $xhtml_source = $converter->translate_to_html({source => {file => $filename}, output => "string" })

=item * my $xhtml_source = $converter->translate_to_html({source => {string_ref => \$buffer}, output => "string" })

=item * my $xhtml_dom = $converter->translate_to_html({source => {file => $filename}, output => "dom" })

=item * my $xhtml_dom = $converter->translate_to_html({source => {dom => $libxml_dom}, output => "dom" })

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

sub translate_to_html
{
    my ($self, $args) = @_;

    return $self->perform_xslt_translation({output_format => 'html', %{$args}});
}

1;

