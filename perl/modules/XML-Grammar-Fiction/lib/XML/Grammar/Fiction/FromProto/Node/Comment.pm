package XML::Grammar::Fiction::FromProto::Node::Comment;

use strict;
use warnings;

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node");

has "text" => ( isa => "Str", is => "rw" );

1;
