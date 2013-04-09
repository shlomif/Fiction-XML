package XML::Grammar::Fiction::FromProto::Nodes;

use strict;
use warnings;

use List::Util ();

use XML::Grammar::Fiction::FromProto::Node;

=head1 NAME

XML::Grammar::Fiction::FromProto::Nodes - contains several nodes for
use in XML::Grammar::Fiction::FromProto.

=head1 VERSION

Version 0.12.2

=cut

our $VERSION = '0.12.2';

use XML::Grammar::Fiction::FromProto::Node::WithContent;
use XML::Grammar::Fiction::FromProto::Node::Element;
use XML::Grammar::Fiction::FromProto::Node::List;
use XML::Grammar::Fiction::FromProto::Node::Text;
use XML::Grammar::Fiction::FromProto::Node::Saying;
use XML::Grammar::Fiction::FromProto::Node::Description;
use XML::Grammar::Fiction::FromProto::Node::Paragraph;
use XML::Grammar::Fiction::FromProto::Node::InnerDesc;
use XML::Grammar::Fiction::FromProto::Node::Comment;

1;

=head1 DESCRIPTION

Contains several nodes.

=cut

