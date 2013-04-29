package XML::Grammar::Fiction::FromProto::Node::WithContent;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Fiction::FromProto::Node::WithContent - contains a node
with content.

=head1 VERSION

Version 0.14.1

=cut

our $VERSION = '0.14.1';

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node");

has 'children' => (
    isa => 'XML::Grammar::Fiction::FromProto::Node::List',
    is => 'rw'
);

sub _get_childs
{
    my $self = shift;

    my $childs = $self->children->contents();

    return $childs || [];
}

1;
