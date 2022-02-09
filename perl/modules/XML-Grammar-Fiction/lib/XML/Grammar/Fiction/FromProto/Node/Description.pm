package XML::Grammar::Fiction::FromProto::Node::Description;

use strict;
use warnings;

use MooX 'late';

extends("XML::Grammar::Fiction::FromProto::Node::Text");

around 'get_text' => sub {
    my $orig = shift;
    my $self = shift;

    my $ret = ( $orig->( $self, @_ ) );
    $ret =~ s#[ \t]+$##gms;
    return $ret;
};

1;
