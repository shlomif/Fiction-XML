package XML::Grammar::Fiction::FromProto::Node::WithContent;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Fiction::FromProto::Nodes - contains several nodes for
use in XML::Grammar::Fiction::FromProto.

=head1 VERSION

Version 0.12.4

=cut

our $VERSION = '0.12.4';

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
