package XML::Grammar::Fiction::RNG_Renderer;

use strict;
use warnings;

=head1 XML::Grammar::Fiction::RNG_Renderer

The base class for the Fiction-XML renderer with the common RNG.

=head1 SYNOPSIS

For internal use.

=cut

use MooX 'late';

extends ("XML::Grammar::FictionBase::XSLT::Converter");

has '+rng_schema_basename' => (default => "fiction-xml.rng");

=head1 METHODS

=head2 rng_schema_basename()

Inherited - (to settle pod-coverage).

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

Copyright 2007 Shlomi Fish.

This program is released under the following license: MIT X11.

=cut

1;

