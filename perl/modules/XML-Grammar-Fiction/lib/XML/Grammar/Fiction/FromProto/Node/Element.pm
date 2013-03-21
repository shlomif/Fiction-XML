package XML::Grammar::Fiction::FromProto::Node::Element;

=head1 NAME

XML::Grammar::Fiction::FromProto::Nodes - contains several nodes for
use in XML::Grammar::Fiction::FromProto.

=head1 VERSION

Version 0.11.1

=cut

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node::WithContent");

has 'name' => (isa => 'Str', is => 'rw');
has 'attrs' => (isa => 'ArrayRef', is => 'rw');
has 'open_line' => (isa => 'Maybe[Int]', is => 'rw');

=head1 METHODS

=head2 lookup_attr

Internal use.

=cut

sub lookup_attr
{
    my ($self, $attr_name) = @_;

    my $pair = List::Util::first { $_->{key} eq $attr_name } (@{$self->attrs()});

    if (!defined($pair))
    {
        return undef;
    }
    else
    {
        return $pair->{value};
    }
}

1;
