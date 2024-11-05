package XML::Grammar::Screenplay::API::Concat;

use strict;
use warnings;
use autodie;
use 5.014;

use MooX 'late';

use Carp        ();
use XML::LibXML ();

my $SCREENPLAY_XML_NS =
"http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/";

sub _get_xpc
{
    my ( $elem, ) = @_;

    my $xpc = XML::LibXML::XPathContext->new($elem);
    $xpc->registerNs( "sp", $SCREENPLAY_XML_NS );

    return $xpc;
}

sub concat
{
    my ( $self, $args ) = @_;
    my $inputs = $args->{inputs};

    my $parser  = XML::LibXML->new();
    my $new_xml = $parser->parse_string(
qq#<document xmlns="$SCREENPLAY_XML_NS"><head></head><body id="index"></body></document>#
    );
    my $root        = $new_xml->documentElement();
    my $root_xpc    = _get_xpc($root);
    my ($root_body) = $root_xpc->findnodes('./sp:body');

    my $id_differentiator_counters = +{};
    my $chapter_idx                = 0;
    foreach my $src (@$inputs)
    {
        my $this_chapter_idx = ( ++$chapter_idx );
        my $src_type         = $src->{type};
        if ( $src_type ne 'file' )
        {
            Carp::confess(qq#Unknown input type "$src_type"#);
        }
        my $src_fn = $src->{filename};
        my $input  = $parser->parse_file($src_fn);
        my $doc    = $input->documentElement();
        my $xpc    = _get_xpc($doc);
        my @el     = $xpc->findnodes("//sp:document/sp:body/sp:scene");
        my $dest_xml;

        if ( not @el )
        {
            Carp::confess(q#no scenes found in "$src_fn"#);
        }
        elsif ( 1 == @el )
        {
            $dest_xml = $el[0];

            # @el = $xpc->findnodes("//sp:document/sp:body/sp:scene/sp:scene");
        }
        else
        {
            $dest_xml = $parser->parse_string(
qq#<scene xmlns="$SCREENPLAY_XML_NS" id="chapter_$this_chapter_idx" title="Chapter $this_chapter_idx"></scene>#
            );
            foreach my $el (@el)
            {
                $dest_xml->documentElement()
                    ->appendWellBalancedChunk( $el->toString() );
            }
        }

        foreach my $el ($dest_xml)
        {
            my $xpc   = _get_xpc($el);
            my @idels = $xpc->findnodes("//sp:scene[\@id]");
            foreach my $id_el (@idels)
            {
                my $old_id = $id_el->getAttribute('id');
                if ( exists $id_differentiator_counters->{$old_id} )
                {
                    my $new_idx = $id_differentiator_counters->{$old_id}++;
                    my $new_id  = sprintf( "%s_%d", $old_id, $new_idx );
                    $id_el->setAttribute( 'id', $new_id );
                }
                else
                {
                    $id_differentiator_counters->{$old_id} = 1;
                }
            }
        }

        $root_body->appendWellBalancedChunk(

            # $dest_xml->documentElement()->toString() );
            $dest_xml->toString()
        );
    }

    return +{ xml => $new_xml, };
}

1;

__END__


__END__

=encoding utf8

=head1 NAME

XML::Grammar::Screenplay::API::Concat - concatenate several screenplay-xml files.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 my $rec = $obj->concat({ inputs => [@inputs] })

=head2

=cut
