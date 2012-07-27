package XML::Grammar::Screenplay::ToDocBook;

use Mouse;

extends('XML::Grammar::Screenplay::XSLT::Base');

has '+xslt_transform_basename' => (default => "screenplay-xml-to-docbook.xslt");

=head1 NAME

XML::Grammar::Screenplay::ToDocBook - module that converts the Screenplay
XML to DocBook.

=head1 VERSION

Version 0.9.0

=cut

our $VERSION = '0.9.0';

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

