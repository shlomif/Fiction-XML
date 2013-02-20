package XML::Grammar::FictionBase::FromProto::Parser::LineIterator;

use strict;
use warnings;

use MooX 'late';

use XML::Grammar::Fiction::Err;

extends("XML::Grammar::Fiction::FromProto::Parser");

has "_curr_line_idx" => (isa => "Int", is => "rw", reader => "line_idx",);
has "_lines" => (isa => "ArrayRef", is => "rw");

=head1 NAME

XML::Grammar::FictionBase::FromProto::Parser::LineIterator - line iterator base
class for the parser.

B<For internal use only>.

=cut

our $VERSION = '0.11.1';

=head1 VERSION

Version 0.11.1

=head1 SYNOPSIS

B<TODO:> write one.

=head1 DESCRIPTION

This is a line iterator that is useful to handle text (e.g: out of a file)
and process it incrementally.

=head1 METHODS

=head2 $self->setup_text($multi_line_text)

Use $multi_line_text as the text to process, populate the lines array
with it and reset the other variables.

=cut

sub setup_text
{
    my ($self, $text) = @_;

    # We include the lines trailing newlines for safety.
    $self->_lines([split(/^/, $text)]);

    $self->_curr_line_idx(0);

    ${$self->curr_line_ref()} =~ m{\A}g;

    return;
}

=head2 $line_ref = $self->curr_line_ref()

Returns a reference to the current line (a string).

For example:

    my $l_ref = $self->curr_line_ref();

    if ($$l_ref !~ m{\G<tag>}g)
    {
        die "Could not match tag.";
    }

=cut

sub curr_line_ref
{
    my $self = shift;

    return \($self->_lines()->[$self->_curr_line_idx()]);
}

=head2 my $pos = $self->curr_pos()

Returns the current position (using pos($$l)) of the current line.

=cut

sub curr_pos
{
    my $self = shift;

    return pos(${$self->curr_line_ref()});
}

=head2 $self->at_line_start()

Returns if at start of line (curr_pos == 0).

=cut

sub at_line_start
{
    my $self = shift;

    return ($self->curr_pos == 0);
}

=head2 my ($line_ref, $pos) = $self->curr_line_and_pos();

Convenience method to return the line reference and the position.

For example:

    # Check for a tag.
    my ($l_ref, $p) = $self->curr_line_and_pos();

    my $is_tag_cond = ($$l_ref =~ m{\G<}cg);
    my $is_close = $is_tag_cond && ($$l_ref =~ m{\G/}cg);

    pos($$l) = $p;

    return ($is_tag_cond, $is_close);

=cut

sub curr_line_and_pos
{
    my $self = shift;

    return ($self->curr_line_ref(), $self->curr_pos());
}

=head2 my $line_copy_ref = $self->curr_line_copy()

Returns a reference to a copy of the current line that is allowed to be
tempered with (by assigning to pos() or in a different way.). The line is
returned as a reference so to avoid destroying its pos() value.

For example:

    sub _look_ahead_for_tag
    {
        my $self = shift;

        my $l = $self->curr_line_copy();

        my $is_tag_cond = ($$l =~ m{\G<}cg);
        my $is_close = $is_tag_cond && ($$l =~ m{\G/}cg);

        return ($is_tag_cond, $is_close);
    }

=cut

sub curr_line_copy
{
    my $self = shift;

    my $l = ${$self->curr_line_ref()} . "";

    pos($l) = $self->curr_pos();

    return \$l;
}

=head2 my $line_ref = $self->next_line_ref()

Advance the line pointer and return the next line.

=cut

sub next_line_ref
{
    my $self = shift;

    $self->_curr_line_idx($self->_curr_line_idx()+1);

    pos(${$self->curr_line_ref()}) = 0;

    return $self->curr_line_ref();
}

=head2 $self->skip_space()

Skip whitespace (spaces and tabs) from the current position onwards.

=cut

# Skip the whitespace.
sub skip_space
{
    my $self = shift;

    $self->consume(qr{[ \t]});

    return;
}

=head2 $self->skip_multiline_space()

Skip multiline space.

=cut

sub skip_multiline_space
{
    my $self = shift;

    if (${$self->curr_line_ref()} =~ m{\G.*?\S})
    {
        return;
    }

    $self->consume(qr{\s});

    return;
}

=head2 $self->curr_line_continues_with($regex)

Matches the current line with $regex starting from the current position and
returns the result. The position remains at the original position if the
regular expression does not match (using C< qr//cg >).

=cut

sub curr_line_continues_with
{
    my ($self, $re) = @_;

    my $l = $self->curr_line_ref();

    return $$l =~ m{\G$re}cg;
}

=head2 my $line_number = $self->line_idx()

Returns the line index as an integer. It starts from 0 for the
first line (like in Perl lines.)

=head2 my $line_number = $self->line_num()

Returns the line number as an integer. It starts from 1 for the
first line (like in file lines.)

=cut

sub line_num
{
    my $self = shift;

    return $self->_curr_line_idx()+1;
}

=head2 $self->consume($regex)

Consume as much text as $regex matches.

=cut

sub _next_line_ref_wo_leading_space
{
    my $self = shift;

    my $l = $self->next_line_ref();

    if (defined($$l))
    {
        $self->_check_if_line_starts_with_whitespace()
    }

    return $l;
}

sub consume
{
    my ($self, $match_regex) = @_;

    my $return_value = "";
    my $l = $self->curr_line_ref();

    while (defined($$l) && ($$l =~ m[\G(${match_regex}*)\z]cgms))
    {
        $return_value .= $$l;
    }
    continue
    {
        $l = $self->_next_line_ref_wo_leading_space();
    }

    if (defined($$l) && ($$l =~ m[\G(${match_regex}*)]cg))
    {
        $return_value .= $1;
    }

    return $return_value;
}

=head2 $self->consume_up_to($regex)

Consume up to the point where $regex matches.

=cut

# TODO : copied and pasted from _consume - abstract
sub consume_up_to
{
    my ($self, $match_regex) = @_;

    my $return_value = "";
    my $l = $self->curr_line_ref();

    LINE_LOOP:
    while (defined($$l))
    {
        # We assign to a scalar for scalar context, but we're not making
        # use of the variable.
        my $verdict = ($$l =~ m[\G(.*?)((?:${match_regex})|\z)]cgms);
        $return_value .= $1;

        # Find if it matched the regex.
        if (length($2) > 0)
        {
            last LINE_LOOP;
        }
    }
    continue
    {
        $l = $self->_next_line_ref_wo_leading_space();
    }

    return $return_value;
}

=head2 $self->throw_text_error($exception_class, $text)

Throws the Error class $exception_class with the text $text (and the current
line number.

=cut

sub throw_text_error
{
    my ($self, $error_class, $text) = @_;

    return $error_class->throw(
        error => $text,
        line => $self->line_num(),
    );
}


sub _check_if_line_starts_with_whitespace
{
    my $self = shift;

    if (${$self->curr_line_ref()} =~ m{\A[ \t]})
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::LeadingSpace',
            "Leading space detected in the text.",
        );
    }
}

=head2 eof()

Returns if the parser reached the end of the file.

=cut

sub eof
{
    my $self = shift;

    return (!defined( ${ $self->curr_line_ref() } ));
}

=head2 $self->meta()

Leftover from Moo.

=cut

1;

