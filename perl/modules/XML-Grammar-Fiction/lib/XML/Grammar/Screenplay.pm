package XML::Grammar::Screenplay;

use warnings;
use strict;

=head1 NAME

XML::Grammar::Screenplay - CPAN distribution implementing an XML grammar for 
screenplays.

=head1 VERSION

Version 0.1.7

=cut

our $VERSION = '0.1.7';

=head1 SYNOPSIS

See L<XML::Grammar::Screenplay::FromProto>, 
L<XML::Grammar::Screenplay::ToDocBook> and
L<XML::Grammar::Screenplay::ToHTML>.

=head1 DESCRIPTION

XML::Grammar::Screenplay is a Perl module for:

=over 4

=item 1. Converting a well-formed plain text format to a specialized XML format.

=item 2. Converting the XML to DocBook/XML or directly to HTML for rendering.

=back

The best way to use it non-programatically is using
L<XML::Grammar::Screenplay::App::FromProto>,
L<XML::Grammar::Screenplay::App::ToDocBook> and
L<XML::Grammar::Screenplay::App::ToHTML>, which are modules implementing
command line applications for their processing.

The rest of this page will document the syntax of the custom textual format.

=head1 FORMAT

=head2 Scenes

Scenes are placed in XML-like tags of C<< <section> ... </section> >> or
abbreviated as C<< <s> ... </s> >>. Opening tags in the format may have 
attributes whose keys are plaintext and whose values are surrounded by
double quotes. (Single-quotes are not supported).

The scene tag must have an C<id> attribute (for anchors, etc.) and could
have an optional C<title> attribute. If the title is not specified, it will
default to the ID.

Scenes may be B<nested>. There cannot be any sayings or descriptions (see below)
except inside scenes.

=head2 Text

Text is any of:

=over 4

=item 1. Plaintext

Regular text

=item 2. XML-like tags.

Supported tags are C<< <b> >> for bold text, C<< <i> >> for italics,
C<< <a href="..."> >> for hyperlinks, and an empty C<< <br /> >> tag for line-breaks.

=item 3. Entities

The text format supports SGML-like entities such as C<< &amp; >>,
C<< &lt; >>, C<< &quot; >> and all other entities that are supported by 
L<HTML::Entities>.

=item 4. Text between [ ... ]

Text between square brackets (C<[ ... ]>) is reserved for descriptions
or inline descriptions (see below).

=back 

=head2 Sayings

The first paragraph when a character talks starts with the name of the
character followed by a colon (C<:>) and the rest of the text. Like this:

    David: Goliath, I'm going to kill you! You'll see -
    I will.

If a character says more than one paragraph, the next paragraph should start
with any number of "+"-signs followed by a colon:

    David: Goliath, I'm going to kill you! You'll see -
    I will.

    ++++: I will sling you and bing you till infinity!

=head2 Descriptions.

Descriptions that are not part of saying start with a C<[> at the first
character of a line and extend till the next C<]>. They can span several
paragraphs.

There are also internal descriptions to the saying which are placed
inside the paragraph of the saying and describe what happens while the
character talks. 

=head2 EXAMPLES

Examples can be found in the C<t/data> directory, and here:

=over 4

=item * The One with the Fountainhead

L<http://www.shlomifish.org/humour/TOWTF/>

=item * Humanity - The Movie

L<http://www.shlomifish.org/humour/humanity/>

=item * Star Trek - "We The Living Dead"

L<http://www.shlomifish.org/humour/Star-Trek/We-the-Living-Dead/>

=back

=head1 DEBUGGING

When trying to convert the well-formed text to XML, one will often 
encounter an obscure "Parse Error". This is caused by L<Parse::RecDescent>,
which is used for parsing. The best way I found to deal with it is to
gradually eliminate parts of the document until the offending markup is
isolated.

In the future, I plan on writing a custom parser that will provide better
diagnostics and will hopefully also be faster.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-screenplay at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Screenplay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

=over 4

=item * Empty

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Screenplay

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Screenplay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Screenplay>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Screenplay>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Screenplay>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

