package XML::Grammar::Fiction::FromProto::Node::Comment;

use MooX 'late';

our $VERSION = '0.12.3';

extends("XML::Grammar::Fiction::FromProto::Node");

has "text" => (isa => "Str", is => "rw");

1;
