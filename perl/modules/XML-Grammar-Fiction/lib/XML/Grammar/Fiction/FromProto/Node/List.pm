package XML::Grammar::Fiction::FromProto::Node::List;

use strict;
use warnings;

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node");

has 'contents' => ( isa => "ArrayRef", is => "rw" );

1;

