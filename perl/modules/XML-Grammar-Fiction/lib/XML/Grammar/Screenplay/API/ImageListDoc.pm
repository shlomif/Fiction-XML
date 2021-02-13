package XML::Grammar::Screenplay::API::ImageListDoc;

use strict;
use warnings;

use MooX 'late';

use XML::Grammar::Screenplay::FromProto::Parser::QnD ();

extends('XML::Grammar::Screenplay::FromProto');

has ['_dom'] => ( is => 'rw' );
has ['_xml'] => ( is => 'rw' );

sub list_images
{
    my ($self) = @_;
    my %found;

    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs( 's',
q{http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/}
    );
    foreach
        my $img ( $xpc->find( q{//s:image}, $self->_dom() )->get_nodelist() )
    {
        ++$found{ $img->getAttribute('url') };
    }

    return [
        map {
            XML::Grammar::Screenplay::API::ImageListDoc::_Record->new(
                {
                    _uri => $_,
                }
            )
            }
            sort keys(%found)
    ];
}

1;

package XML::Grammar::Screenplay::API::ImageListDoc::_Record;

use MooX 'late';

has '_uri' => ( is => 'ro' );

sub uri
{
    my ( $self, ) = @_;

    return $self->_uri();
}

1;

# __END__
# # Below is stub documentation for your module. You'd better edit it!

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 my $aref = $self->list_images()

=head2

=cut

