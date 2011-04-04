package XML::Grammar::Fiction::Err;

use strict;
use warnings;


=head1 NAME

XML::Grammar::Fiction::Err - Exception::Class-based exceptions used by
XML::Grammar::Fiction

=head1 VERSION

Version 0.1.5

=cut

our $VERSION = '0.1.5';

use Exception::Class
    (
        "XML::Grammar::Fiction::Err::Base",
        "XML::Grammar::Fiction::Err::Parse::TagsMismatch" =>
        {
            isa => "XML::Grammar::Fiction::Err::Base", 
            fields => [qw(opening_tag closing_tag)],
        },
        "XML::Grammar::Fiction::Err::Parse::LineError" =>
        {
            isa => "XML::Grammar::Fiction::Err::Base",
            fields => [qw(line)],
        },
        "XML::Grammar::Fiction::Err::Parse::LeadingSpace" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },        
        "XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::NoRightAngleBracket" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::WrongClosingTagSyntax" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
    )
    ;
1;

=head1 SYNOPSIS

    use XML::Grammar::Fiction::Err;

    .
    .
    .
    XML::Grammar::Fiction::Err::Parse::TagsMismatch->throw(
        error => "Tags mismatch",
        opening_tag => Tag->new(...),
        closing_tag => Tag->new(...),
    );

=head1 DESCRIPTION

These are exceptions for L<XML::Grammar::Fiction> based on L<Exception::Class>

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

Copyright (c) 2007, 2009 Shlomi Fish.

This program is released under the following license: MIT X11:
L<http://www.opensource.org/licenses/mit-license.php> .

=head2 LICENSE

Copyright (c) 2007, 2009 Shlomi Fish.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut

