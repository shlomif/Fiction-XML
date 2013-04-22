package XML::Grammar::Fiction::FromProto::Node::Saying;

use MooX 'late';

our $VERSION = '0.12.4';

extends("XML::Grammar::Fiction::FromProto::Node::Text");

has 'character' => (isa => "Str", is => "rw");

1;
