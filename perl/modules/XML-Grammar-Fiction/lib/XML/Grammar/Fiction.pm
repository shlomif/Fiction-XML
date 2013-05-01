package XML::Grammar::Fiction;

use warnings;
use strict;

=encoding utf8

=head1 NAME

XML::Grammar::Fiction - CPAN distribution implementing an XML grammar
and a lightweight markup language for stories, novels and other fiction.

=head1 VERSION

Version 0.14.4

=cut

our $VERSION = '0.14.4';

=head1 SYNOPSIS

See L<XML::Grammar::Fiction::FromProto>,
L<XML::Grammar::Fiction::ToDocBook> and
L<XML::Grammar::Fiction::ToHTML>.

=head1 DESCRIPTION

XML::Grammar::Fiction is a CPAN distribution that facilitates writing prose
fiction (= stories, novels, novellas, etc.). What it does is:

=over 4

=item 1. Convert a well-formed plain text format to a specialized XML format.

=item 2. Convert the XML to DocBook/XML or directly to HTML for rendering.

=back

The best way to use it non-programatically is using
L<XML::Grammar::Fiction::App::FromProto>,
L<XML::Grammar::Fiction::App::ToDocBook> and
L<XML::Grammar::Fiction::App::ToHTML>, which are modules implementing
command line applications for their processing.

In order to be able to share the common code and functionality more easily,
then L<XML::Grammar::Screenplay>, which provides similar XML grammar and
text-based markup language for writing screenplays, is now included in this
CPAN distribution, and you can refer to its documentation as well:
L<XML::Grammar::Screenplay> .

The rest of this page will document the syntax of the custom textual format.

=head1 FORMAT

=head2 Sections

Sections are placed in XML-like tags of C<< <section> ... </section> >> or
abbreviated as C<< <s> ... </s> >>. Opening tags in the format may have
attributes whose keys are plaintext and whose values are surrounded by
double quotes. (Single-quotes are not supported).

The section tag must have an C<id> attribute (for anchors, etc.) and could
contain an optional (but highly recommended) C<< <title> >> sub-tag. If the
title is not specified, it will default to the ID.

Sections may be B<nested>.

=head2 Text

Text is any of:

=over 4

=item 1. Plaintext

Regular text

=item 2. XML-like tags.

Supported tags are C<< <b> >> for bold text, and C<< <i> >> for italic
text.

=item 3. Entities

The text format supports SGML-like entities such as C<< &amp; >>,
C<< &lt; >>, C<< &quot; >> and all other entities that are supported by
L<HTML::Entities>.

=item 4. Supported initial characters

The following characters can start a regular paragraph:

=over 4

=item * Any alphanumeric character.

=item * Some special characters:

The characters C<"> (double quotes), C<'> (single quotes), etc. are supported.

=item * XML/SGML entities.

XML/SGML entities are also supported at the start.

=back

All other characters are reserved for special markup in the future. If you
need to use them at the beginning of the paragraph you can escape them with
a backslash (C<\>) or their SGML/XML entity (e.g: C<&qout;>).

=back

=head2 Types of top-level items.

=head3 Paragraphs

These are not delimited by anything - just a paragraph of text not containing
an empty line. If a paragraph starts with a Plus sign ( C<+> ) then it is
immediately expected to be followed by a styling tag (as opposed to a

=head3 <ol>

This is an ordered list with <li>s, similar to its purpose in XHTML.

=head3 <ul>

An unordered list.

=head2 EXAMPLES

=head3 Examples Document.

    <body id="index" lang="en-UK">

    <title>David vs. Goliath - Part I</title>

    <s id="top">

    <title>The Top Section</title>

    <!-- David has Green hair here -->

    King <a href="http://en.wikipedia.org/wiki/David">David</a> and Goliath
    were standing by each other.

    David said unto Goliath: “I will shoot you. I <b>swear</b> I will”

    <s id="goliath">

    <title>Goliath's Response</title>

    <!-- Goliath has to reply to that. -->

    Goliath was not amused.

    He said to David: “Oh, really. <i>David</i>, the red-headed!”.

    </s>

    </s>

    </body>


=head3 Other Examples

Examples can be found in the C<t/data> directory, and here:

=over 4

=item * The Pope Died on Sunday (Hebrew version)

L<http://www.shlomifish.org/humour/Pope/>

=item * The Enemy and How I Helped to Fight it (Hebrew version)

L<http://www.shlomifish.org/humour/TheEnemy/>

=item * The Human Hacking Field Guide (Hebrew version)

L<http://www.shlomifish.org/humour/human-hacking/>

=back

=head1 MOTIVATION

I (= Shlomi Fish) originated this CPAN distribution (after forking
L<XML:Grammar::Screenplay> which was similar enough) so I'll have a convenient
way to edit a story I'm writing in Hebrew and similar fiction, as
OpenOffice.org caused me many problems, and I found editing bi-directional
DocBook/XML to be painful with either gvim or KDE 4's kate, so I opted for a
more plain-texty format.

I hope a lightweight markup language like that for fiction (and possibly
other types of manuscripts) will prove useful for other writers. At the
moment, a lot of stuff in the proto-text format is subject to change,
so you'll need to accept that some modifications to your sources will be
required in the future. I hope you still find it useful and let me know
if you need any feature or bug-fix.

=cut

1;

