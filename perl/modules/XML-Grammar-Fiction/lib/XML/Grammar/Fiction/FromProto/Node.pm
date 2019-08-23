package XML::Grammar::Fiction::FromProto::Node;

use strict;
use warnings;

use List::Util ();

=head1 NAME

XML::Grammar::Fiction::FromProto::Node - contains several nodes for
use in XML::Grammar::Fiction::FromProto.

=cut

use MooX 'late';

sub _short_isa
{
    my $self = shift;
    my $isa_classish = shift;

    return
        $self->isa(
            "XML::Grammar::Fiction::FromProto::Node::$isa_classish"
        );
}

1;

=head1 DESCRIPTION

Contains several nodes.

=cut

