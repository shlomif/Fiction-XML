package XML::Grammar::Fiction::FromProto::Node::InnerDesc;

use strict;
use warnings;

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node::Element");

=head1 METHODS

=head2 name

Internal use.

=cut

sub name
{
    return "inlinedesc";
}

1;
