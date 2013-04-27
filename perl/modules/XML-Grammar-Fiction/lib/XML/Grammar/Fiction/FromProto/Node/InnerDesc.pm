package XML::Grammar::Fiction::FromProto::Node::InnerDesc;

use MooX 'late';

our $VERSION = '0.12.5';

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
