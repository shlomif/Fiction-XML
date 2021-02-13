package XML::Grammar::Screenplay::FromProto::API::ListImages;

use strict;
use warnings;

use MooX 'late';

use XML::LibXML ();

use XML::Grammar::Screenplay::API::ImageListDoc ();
use XML::Grammar::Screenplay::FromProto         ();

sub calc_doc__from_proto_text
{
    my ( $self, $args ) = @_;

    my $ret = XML::Grammar::Screenplay::API::ImageListDoc->new(
        {
            parser_class => 'XML::Grammar::Screenplay::FromProto::Parser::QnD',
            %$args,
        }
    );
    $ret->_xml( $ret->convert($args) );
    my $xml_parser = XML::LibXML->new();
    $xml_parser->validation(0);
    $ret->_dom( $xml_parser->parse_string( $ret->_xml() ) );

    return $ret;
}

1;

# __END__

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 $self->calc_doc__from_proto_text({ %args })

TODO: document.

=head2

=cut
