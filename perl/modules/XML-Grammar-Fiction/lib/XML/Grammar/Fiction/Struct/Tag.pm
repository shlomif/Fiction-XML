package XML::Grammar::Fiction::Struct::Tag;

use strict;
use warnings;

use MooX 'late';

use List::MoreUtils;

use XML::Grammar::Fiction::FromProto::Nodes;

=head1 NAME

XML::Grammar::Fiction::Struct::Tag - information about an XML/SGML opening or
closing tag.

B<For internal use only>.

=head1 VERSION

Version 0.12.4

=cut

our $VERSION = '0.12.4';

has 'name' => (is => "rw", isa => "Str");
has 'line' => (is => "rw", isa => "Int");
has 'is_standalone' => (is => "rw", isa => "Bool");
has 'attrs' => (is => "rw", isa => "ArrayRef");
has 'children' => (
    is => "rw",
    isa => "Maybe[ArrayRef]",
);

sub append_children
{
    my ($self, $children) = @_;

    # This is an assert / sanity check.
    if (List::MoreUtils::any { !defined ($_) } @$children)
    {
        Carp::confess("append_children with undef.");
    }

    push @{$self->children()}, @$children;

    return;
}

sub append_child
{
    my ($self, $child) = @_;

    return $self->append_children( [ $child ] );
}

sub detach_children
{
    my $self = shift;

    my $children = $self->children();

    $self->children(undef);

    return $children;
}

package XML::Grammar::Fiction::Struct::Tag::Para;

use MooX 'late';

extends("XML::Grammar::Fiction::Struct::Tag");

=head1 METHODS

=head2 $self->name()

The tag's name.

=head2 $self->line()

The tag's line number.

=head2 $self->is_standalone()

Determines whether it's a standalone tag or not. (if it's an opening tag).

=head2 $self->attrs()

The attributes of the opening tag in an array.

=head2 $self->children()

A placeholder for the element's children.

=head2 $self->append_children(\@children)

Append more elements to the children.

=head2 $self->append_child($child)

Appends a single child. Uses C<append_children()> .

=head2 my $children = $self->detach_children()

Detaches the children and returns them as an array reference.

=cut

1;

