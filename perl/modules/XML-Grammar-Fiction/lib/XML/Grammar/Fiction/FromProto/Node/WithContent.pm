package XML::Grammar::Fiction::FromProto::Node::WithContent;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Fiction::FromProto::Node::WithContent - contains a node
with content.

=cut

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node");

has 'children' => (
    isa => 'XML::Grammar::Fiction::FromProto::Node::List',
    is  => 'rw'
);

sub _get_childs
{
    my $self = shift;

    my $childs = $self->children->contents();

    return $childs || [];
}

sub _first
{
    my ($self) = @_;

    return $self->_get_childs()->[0];
}

1;
