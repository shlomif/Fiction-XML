package XML::Grammar::Fiction::FromProto::Node::Saying;

use MooX 'late';

our $VERSION = '0.14.6';

extends("XML::Grammar::Fiction::FromProto::Node::Text");

has 'character' => (isa => "Str", is => "rw");

1;
