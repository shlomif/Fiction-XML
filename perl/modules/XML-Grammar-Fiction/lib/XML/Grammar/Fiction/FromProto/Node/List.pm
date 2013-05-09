package XML::Grammar::Fiction::FromProto::Node::List;

use MooX 'late';

our $VERSION = '0.14.5';

extends("XML::Grammar::Fiction::FromProto::Node");

has 'contents' => (isa => "ArrayRef", is => "rw");

1;

