package XML::Grammar::Fiction::FromProto::Node::WithContent;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Fiction::FromProto::Node::WithContent - contains a node
with content.

=head1 VERSION

Version 0.14.10

=head1 METHODS

=head2 children()

TODO FILL IN.

=cut

our $VERSION = '0.14.10';

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node");

has 'children' => (
    is => 'rw'
);

sub _get_childs
{
    my $self = shift;

    my $childs = $self->children->contents();

    return $childs || [];
}

1;
