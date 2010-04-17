package XML::Grammar::Fiction::FromProto::Parser::LineIterator;

use strict;
use warnings;

use Moose;

use XML::Grammar::Fiction::Err;

extends("XML::Grammar::Fiction::FromProto::Parser");

has "_curr_line_idx" => (isa => "Int", is => "rw");
has "_lines" => (isa => "ArrayRef", is => "rw");

=head1 NAME

XML::Grammar::Fiction::FromProto::Parser::LineIterator - line iterator base
class for the parser.

B<For internal use only>.

=cut

our $VERSION = '0.0.4';

=head1 VERSION

Version 0.0.4

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

=head2 $self->throw_text_error($exception_class, $text)

Throws the Error class $exception_class with the text $text (and the current
line number.

=cut

sub throw_text_error
{
    my ($self, $error_class, $text) = @_;

    return $error_class->throw(
        error => $text,
        line => $self->_get_line_num(),    
    );
}

sub _next_line_ref
{
    my $self = shift;

    $self->_curr_line_idx($self->_curr_line_idx()+1);

    return $self->curr_line_ref();
}

# Skip the whitespace.
sub _skip_space
{
    my $self = shift;

    $self->_consume(qr{[ \t]});
}

sub _curr_line_matches
{
    my $self = shift;
    my $re = shift;

    my $l = $self->curr_line_ref();

    return ($$l =~ $re);
}

sub _line_starts_with
{
    my ($self, $re) = @_;

    my $l = $self->curr_line_ref();

    return $$l =~ m{\G$re}cg;
}

sub _get_line_num
{
    my $self = shift;

    return $self->_curr_line_idx()+1;
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

sub _consume
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
        $l = $self->_next_line_ref();
        $self->_check_if_line_starts_with_whitespace();
    }

    if (defined($$l) && ($$l =~ m[\G(${match_regex}*)]cg))
    {
        $return_value .= $1;
    }

    return $return_value;
}

# TODO : copied and pasted from _consume - abstract
sub _consume_up_to
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
        $l = $self->_next_line_ref();
        $self->_check_if_line_starts_with_whitespace();
    }

    return $return_value;
}

=head2 $self->meta()

Leftover from Moose.

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

