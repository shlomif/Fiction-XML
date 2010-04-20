package XML::Grammar::Fiction::FromProto::Parser::XmlIterator;

use strict;
use warnings;

use Moose;

use XML::Grammar::Fiction::Err;

extends("XML::Grammar::Fiction::FromProto::Parser::LineIterator");

has "_tags_stack" =>
(
    isa => "ArrayRef",
    is => "rw",
    default => sub { [] },
    traits => ['Array'],
    handles =>
    {
        '_push_tag' => 'push',
        '_grep_tags_stack' => 'grep',
        '_tag_stack_is_empty' => 'is_empty',
        '_pop_tag' => 'pop',
        '_get_tag' => 'get',
    },
);

has "_events_queue" =>
(
    isa => "ArrayRef",
    is => "rw", 
    default => sub { []; },
    traits => ['Array'],
    handles =>
    {
        _enqueue_event => 'push',
        _extract_event => 'shift',
    },
);

sub _top_tag
{
    my $self = shift;
    return $self->_get_tag(-1);
}

sub _add_to_top_tag
{
    my ($self, $child) = @_;

    $self->_top_tag->append_child($child);

    return;
}

# TODO : Maybe move to a different sub-class or role.
sub _new_empty_list
{
    my $self = shift;
    return $self->_new_list([]);
}

sub _check_for_open_tag
{
    my $self = shift;

    if ($self->_tag_stack_is_empty())
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag',
            "Cannot match opening tag.",
        );
    }

    return;
}

sub _is_event_a_saying
{
    my ($self, $event) = @_;

    return exists($event->{'tag'}) && ($event->{'tag'} eq "saying");
}

sub _is_event_a_para
{
    my ($self, $event) = @_;

    return exists($event->{'tag'}) && ($event->{'tag'} eq "para");
}

sub _is_event_elem
{
    my ($self, $event) = @_;

    return $event->{'type'} eq "elem";
}

sub _handle_paragraph_event
{
    my ($self, $event) = @_;

    return
          $event->{'type'} eq "open"
        ? $self->_handle_open_para($event)
        : $self->_handle_close_para($event)
        ;
}

sub _handle_elem_event
{
    my ($self, $event) = @_;

    $self->_add_to_top_tag( $event->{'elem'});

    return;
}

sub _handle_non_tag_text
{
    my $self = shift;

    $self->_check_for_open_tag();

    my $contents = $self->_parse_text();

    foreach my $event (@$contents)
    {
        $self->_handle_event($event);
    }

    return;
}


sub _look_for_and_handle_tag
{
    my $self = shift;

    my ($is_tag_cond, $is_close) = $self->_look_ahead_for_tag();

    # Check if it's a closing tag.
    if ($is_close)
    {
        return $self->_handle_close_tag();
    }
    elsif ($is_tag_cond)
    {
        $self->_handle_open_tag();
    }
    else
    {
        $self->_handle_non_tag_text();
    }
    return;
}

=head1 NAME

XML::Grammar::Fiction::FromProto::Parser::XmlIterator - line iterator base
class with some nested XMLisms.

B<For internal use only>.

=cut

our $VERSION = '0.0.4';

=head1 VERSION

Version 0.0.4

=head1 SYNOPSIS

B<TODO:> write one.

=head1 DESCRIPTION

This is a line iterator with some features for parsing, nested, 
XML-like grammars.

=head1 METHODS

=head2 $self->process_text($string)

Processes the text and returns the parse tree.

=cut

sub process_text
{   
    my ($self, $text) = @_;

    $self->setup_text($text);

    return $self->_parse_all();
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

