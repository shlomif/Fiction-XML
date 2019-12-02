package XML::Grammar::Screenplay::FromProto;

use strict;
use warnings;
use autodie;

use Carp ();

use MooX 'late';

extends("XML::Grammar::FictionBase::TagsTree2XML");

my $screenplay_ns =
q{http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/};

=head1 NAME

XML::Grammar::Screenplay::FromProto - module that converts well-formed
text representing a screenplay to an XML format.

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=head2 $self->convert({ source => { file => $path_to_file } })

Converts the file $path_to_file to XML and returns it.

=cut

sub _write_Element_Text
{
    my ( $self, $elem ) = @_;

    if ( $elem->_short_isa("Saying") )
    {
        $self->_output_tag_with_childs(
            {
                start => [ "saying", 'character' => $elem->character() ],
                elem  => $elem,
            },
        );

        return;
    }
    elsif ( $elem->_short_isa("Description") )
    {
        $self->_output_tag_with_childs(
            {
                start => ["description"],
                elem  => $elem,
            },
        );

        return;
    }
    else
    {
        $self->_write_elem_childs($elem);

        return;
    }
}

sub _paragraph_tag
{
    return "para";
}

sub _handle_elem_of_name_img
{
    my ( $self, $elem ) = @_;

    $self->_output_tag_with_childs(
        {
            start => [
                "image",
                "url"   => $elem->lookup_attr("src"),
                "alt"   => $elem->lookup_attr("alt"),
                "title" => $elem->lookup_attr("title"),
            ],
            elem => $elem,
        }
    );

    return;
}

sub _handle_elem_of_name_a
{
    my ( $self, $elem ) = @_;

    $self->_output_tag_with_childs(
        {
            start => [ "ulink", "url" => $elem->lookup_attr("href") ],
            elem  => $elem,
        }
    );

    return;
}

sub _handle_elem_of_name_section
{
    my ( $self, $elem ) = @_;

    return $self->_handle_elem_of_name_s($elem);
}

sub _bold_tag_name
{
    return "bold";
}

sub _italics_tag_name
{
    return "italics";
}

sub _write_scene_main
{
    my ( $self, $scene ) = @_;

    my $id = $scene->lookup_attr("id");

    if ( !defined($id) )
    {
        Carp::confess("Unspecified id for scene!");
    }

    my $title = $scene->lookup_attr("title");
    my @t     = ( defined($title) ? ( title => $title ) : () );

    $self->_output_tag_with_childs(
        {
            'start' => [ "scene", id => $id, @t ],
            elem    => $scene,
        }
    );

    return;
}

sub _get_default_xml_ns
{
    return $screenplay_ns;
}

sub _convert_write_content
{
    my ( $self, $tree ) = @_;

    my $writer = $self->_writer;

    $writer->startTag( [ $screenplay_ns, "document" ] );
    $writer->startTag( [ $screenplay_ns, "head" ] );
    $writer->endTag();
    $writer->startTag( [ $screenplay_ns, "body" ], "id" => "index", );

    $self->_write_scene( { scene => $tree } );

    # Ending the body
    $writer->endTag();

    $writer->endTag();

    return;
}

1;

