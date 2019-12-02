package XML::Grammar::Fiction::FromProto::Node::Saying;

use strict;
use warnings;

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node::Text");

has 'character' => ( isa => "Str", is => "rw" );

1;
