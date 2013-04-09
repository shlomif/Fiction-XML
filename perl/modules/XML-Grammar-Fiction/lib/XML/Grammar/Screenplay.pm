package XML::Grammar::Screenplay;

use warnings;
use strict;

=encoding utf8

=head1 NAME

XML::Grammar::Screenplay - CPAN distribution implementing an XML grammar for
screenplays.

=head1 VERSION

Version 0.12.2

=cut

our $VERSION = '0.12.2';

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

=head3 Comprehensive Example

    <s id="top">

    <s id="david_and_goliath">

    [David and <a href="http://en.wikipedia.org/wiki/Goliath">Goliath</a> are
    standing by each other.]

    David: I will kill you.

    Goliath: no way, you little idiot!

    David: yes way!

    ++++: In the name of <a href="http://real-allah.tld/">Allah, the
    <b>merciful</b>, real merciful</a>, I will show you
    the [sarcastically] power of my sling.

    ++: I shall sling you and bing you till infinity.

    [David takes his sling.]

    Goliath: I'm still <a href="http://wait.tld/">waiting</a>.

    David: so you are.

    [David puts a stone in his sling and shoots Goliath. He hits.]

    David: as is written in the wikipedia [See <a href="http://wiki.tld/">the
    Wiki site</a> for more information], you are now dead, having been shot with
    my sling.

    </s>

    </s>

=head3 More Examples

Other examples can be found in the C<t/data> directory, and here:

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

=cut

1;

