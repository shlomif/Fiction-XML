package XML::Grammar::Screenplay::XSLT::Base;

use Mouse;

extends('XML::Grammar::FictionBase::XSLT::Converter');

has '+rng_schema_basename' => (default => "screenplay-xml.rng");

1;

__END__

=head1 NAME

XML::Grammar::Screenplay::XSLT::Base - base module for XML::Grammar::Screenplay
XSLT conversions.

=head1 VERSION

Version 0.9.1

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
