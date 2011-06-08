package XML::Grammar::Fiction::ToHTML;

use strict;
use warnings;

use Carp;

use Moose;

extends( 'XML::Grammar::Fiction::RNG_Renderer' );

=head1 NAME

XML::Grammar::Fiction::ToHTML - module that converts the Fiction-XML to HTML.

=head1 VERSION

Version 0.8.0

=cut

our $VERSION = '0.8.0';

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=cut
has '+xslt_transform_basename' => (default => "fiction-xml-to-html.xslt", );

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

    return $self->perform_translation($args);
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

