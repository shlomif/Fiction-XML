package XML::Grammar::Fiction::FromProto::Node::Text;

use strict;
use warnings;

our $VERSION = '0.14.2';

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node::WithContent");

=head1 METHODS

=head2 $self->get_text($regex)

Internal use.

=cut

sub get_text
{
    my ($self, $re) = @_;

    return $self->children->contents->[0];
}

1;

