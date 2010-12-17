package XML::Grammar::Fiction::FromProto::Nodes;

use strict;
use warnings;

use List::Util ();

=head1 NAME

XML::Grammar::Fiction::FromProto::Nodes - contains several nodes for
use in XML::Grammar::Fiction::FromProto.

=head1 VERSION

Version 0.1.3

=cut

our $VERSION = '0.1.3';

package XML::Grammar::Fiction::FromProto::Node;

use Moose;

sub _short_isa
{
    my $self = shift;
    my $isa_classish = shift;

    return
        $self->isa(
            "XML::Grammar::Fiction::FromProto::Node::$isa_classish"
        );
}

package XML::Grammar::Fiction::FromProto::Node::WithContent;

use Moose;

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

package XML::Grammar::Fiction::FromProto::Node::Element;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node::WithContent");

has 'name' => (isa => 'Str', is => 'rw');
has 'attrs' => (isa => 'ArrayRef', is => 'rw');

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

package XML::Grammar::Fiction::FromProto::Node::List;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node");

has 'contents' => (isa => "ArrayRef", is => "rw");

package XML::Grammar::Fiction::FromProto::Node::Text;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node::WithContent");

package XML::Grammar::Fiction::FromProto::Node::Saying;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node::Text");

has 'character' => (isa => "Str", is => "rw");

package XML::Grammar::Fiction::FromProto::Node::Description;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node::Text");

package XML::Grammar::Fiction::FromProto::Node::Paragraph;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node::Element");

package XML::Grammar::Fiction::FromProto::Node::InnerDesc;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node::Element");

sub name
{
    return "inlinedesc";
}

package XML::Grammar::Fiction::FromProto::Node::Comment;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Node");

has "text" => (isa => "Str", is => "rw");

1;

=head1 DESCRIPTION

Contains several nodes.

=cut

