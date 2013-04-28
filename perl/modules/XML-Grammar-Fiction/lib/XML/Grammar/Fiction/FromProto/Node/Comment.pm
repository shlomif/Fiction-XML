package XML::Grammar::Fiction::FromProto::Node::Comment;

use MooX 'late';

our $VERSION = '0.14.0';

extends("XML::Grammar::Fiction::FromProto::Node");

has "text" => (isa => "Str", is => "rw");

1;
