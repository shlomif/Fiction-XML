package XML::Grammar::FictionBase::Event;

=head1 NAME

XML::Grammar::FictionBase::Event - a parser event.

B<For internal use only>.

=cut

use strict;
use warnings;

use MooX 'late';

use XML::Grammar::Fiction::FromProto::Node ();

has 'type' => ( isa => "Str", is => "ro" );
has 'tag' => ( isa => "Maybe[Str]", is => "ro", predicate => '_has_tag', );
has 'elem' =>
    ( isa => "Maybe[XML::Grammar::Fiction::FromProto::Node]", is => "ro" );
has 'line_idx' => ( isa => "Maybe[Int]", is => "ro" );
has 'tag_elem' =>
    ( isa => "Maybe[XML::Grammar::Fiction::FromProto::Node]", is => "ro" );

sub is_tag_of_name
{
    my ( $self, $name ) = @_;

    return ( $self->_has_tag() && ( $self->tag() eq $name ) );
}

sub is_open
{
    my $self = shift;

    return ( $self->type() eq "open" );
}

sub is_open_or_close
{
    my $self = shift;
    my $type = $self->type();
    return ( ( $type eq "open" ) || ( $type eq "close" ) );
}

1;

=head1 SLOTS

=head2 $event->elem()

The DOM (Document Object Model) element that the event refers to. See
L<XML::Grammar::Fiction::FromProto::Node> .

=head2 $event->tag_elem()

Extra tag_elem.

=head2 $event->type()

A string specifying the type.

=head2 tag

An optional string (or undef) with the tag name.

=head1 METHODS

=head2 $event->is_tag_of_name($name)

Determines if the $event is a tag and of name $name.

=head2 $event->is_open()

Returns true if the $event 's type is "open".

=head2 $event->is_open_or_close()

Returns true if the $event 's type is either "open" or "close".

=head2 $event->line_idx()

Returns an optional line number.

=head2 $self->meta()

Leftover from Moo.

=cut

