package XML::Grammar::Fiction::Struct::Tag;

use strict;
use warnings;

use Moose;


=head1 NAME

XML::Grammar::Fiction::Struct::Tag - information about an XML/SGML opening or 
closing tag.

B<For internal use only>.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

has 'name' => (is => "rw", isa => "Str");
has 'line' => (is => "rw", isa => "Int");
has 'is_standalone' => (is => "rw", isa => "Bool");
has 'attrs' => (is => "rw", isa => "ArrayRef");

=head1 METHODS

=head2 $self->name()

The tag's name.

=head2 $self->line()

The tag's line number.

=head2 $self->is_standalone()

Determines whether it's a standalone tag or not. (if it's an opening tag).

=head2 $self->attrs()

The attributes of the opening tag in an array.

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

