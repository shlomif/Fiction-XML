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

=head1 VERSION

Version 0.0.4

=cut

our $VERSION = '0.0.4';

sub _curr_line_ref
{
    my $self = shift;

    return \($self->_lines()->[$self->_curr_line_idx()]);
}

sub _curr_line_and_pos
{
    my $self = shift;

    my $l = $self->_curr_line_ref();

    return ($l, pos($$l));
}

sub _next_line_ref
{
    my $self = shift;

    $self->_curr_line_idx($self->_curr_line_idx()+1);

    return $self->_curr_line_ref();
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

    my $l = $self->_curr_line_ref();

    return ($$l =~ $re);
}

sub _line_starts_with
{
    my ($self, $re) = @_;

    my $l = $self->_curr_line_ref();

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

    if (${$self->_curr_line_ref()} =~ m{\A[ \t]})
    {
        XML::Grammar::Fiction::Err::Parse::LeadingSpace->throw(
            error => "Leading space detected in the text.",
            'line' => $self->_get_line_num(),
        );
    }
}

sub _consume
{
    my ($self, $match_regex) = @_;

    my $return_value = "";
    my $l = $self->_curr_line_ref();

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
    my $l = $self->_curr_line_ref();

    LINE_LOOP:
    while (defined($$l))
    {
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

sub _setup_text
{
    my ($self, $text) = @_;

    # We include the lines trailing newlines for safety.
    $self->_lines([split(/^/, $text)]);

    $self->_curr_line_idx(0);

    ${$self->_curr_line_ref()} =~ m{\A}g;

    return;
}

=head1 METHODS

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

