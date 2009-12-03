package XML::Grammar::Fiction::RendererBase;

use strict;
use warnings;

sub _init
{
    my ($self, $args) = @_;

    $self->_data_dir($args->{'data_dir'} || $self->_get_default_data_dir());

    $self->_rng($self->_get_rng_schema());

    $self->_xml_parser(XML::LibXML->new());

    $self->_stylesheet($self->_get_stylesheet());

    return 0;
}

1;

