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

sub _handle_elem_of_name_code_blk
{
    my ( $self, $elem ) = @_;

    my $good = sub {
        my ( $k, $v ) = @_;
        my $input_v = $elem->lookup_attr($k);
        die
"wrong value \"$input_v\" for attribute \"$k\" for element \"<code_blk>\""
            if ( ref($v) eq "" ? ( $v ne $input_v ) : ( $input_v !~ /$v/ ) );
        return ( $k, $input_v );
    };

    my $out_cb = sub {
        $self->_output_tag(
            {
                start => [
                    "code_blk",
                    $good->( "syntax",   "text" ),
                    $good->( "tag_role", qr#\A(?:asciiart|code_block)\z#, ),
                    $good->( "title",    qr#.#ms ),
                    $good->( "alt",      qr#.#ms ),
                ],
                in => sub {
                    my $inner_text = $elem->_first()->_first();

                    foreach my $cnt ( 1 .. 2 )
                    {
                        my $x;

                        eval { $x = $inner_text->_first(); };

                        if ($x)
                        {
                            $inner_text = $x;
                        }

                    }
                    die if ( ref($inner_text) ne "" );
                    $inner_text =~ s/\A(?:\r?\n)*//ms;
                    $inner_text =~ s/(?:^\r?\n)*\z//ms;
                    my @lines = split /^/ms, $inner_text;
                LINES:
                    foreach my $l (@lines)
                    {
                        # next LINES if $l =~ /\A\r?\n/
                        $l =~ s#^\|##ms
                            or die qq#code_blk line did not start with a '|'#;
                    }
                    return $self->_write_elem(
                        {
                            elem => ( join "", @lines )
                        }
                    );
                },
            }
        );
    };
    return (
        ( $self->_writer->within_element( $self->_paragraph_tag ) )
        ? $out_cb->()
        : $self->_output_tag(
            {
                start => [ $self->_paragraph_tag, ],
                in    => $out_cb,
            }
        )
    );

    return;
}

sub _handle_elem_of_name_img
{
    my ( $self, $elem ) = @_;

    my $image_cb = sub {
        return $self->_output_tag_with_childs(
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
    };

    return (
        ( $self->_writer->within_element( $self->_paragraph_tag ) )
        ? $image_cb->()
        : $self->_output_tag(
            {
                start => [ "para", ],
                in    => $image_cb,
            }
        )
    );

}

sub _handle_elem_of_name_q
{
    my ( $self, $elem ) = @_;

    my $q_cb = sub {
        return $self->_output_tag_with_childs(
            {
                start => [ "q", ],
                elem  => $elem,
            }
        );
    };

    return (
        ( $self->_writer->within_element( $self->_paragraph_tag ) )
        ? $q_cb->()
        : do
        {
            Carp::confess("<q> element not at toplevel!");
            $self->_output_tag(
                {
                    start => [ "para", ],
                    in    => $q_cb,
                }
            );
        }
    );

}

sub _handle_elem_of_name_a
{
    my ( $self, $elem ) = @_;

    $self->_output_tag_with_childs(
        {
            start => [
                "a",
                [ "http://www.w3.org/1999/xlink", "href" ],
                $elem->lookup_attr("href"),
            ],
            elem => $elem,
        }
    );

    return;
}

sub _handle_elem_of_name_blockquote
{
    my ( $self, $elem ) = @_;

    return $self->_handle_elem_of_name_s($elem);
}

sub _handle_elem_of_name_section
{
    my ( $self, $elem ) = @_;

    return $self->_handle_elem_of_name_s($elem);
}

sub _handle_elem_of_name_strong
{
    my ( $self, $elem ) = @_;

    $self->_output_tag_with_childs(
        {
            start => [ "strong", ],
            elem  => $elem,
        }
    );

    return;
}

sub _bold_tag_name
{
    return "bold";
}

sub _italics_tag_name
{
    return "italics";
}

sub _write_blockquote_main
{
    my ( $self, $scene ) = @_;

    warn "\<_write_blockquote_main\>";
    if ( $self->_writer->within_element( $self->_paragraph_tag ) )
    {
        Carp::confess("in para");
        exit(-1);
    }

    my $id = $scene->lookup_attr("id");

    $self->_output_tag_with_childs(
        {
            'start' => [ "blockquote", ],
            elem    => $scene,
        }
    );

    return;
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
    my $lang  = $scene->lookup_attr("lang");
    my @t     = ( defined($title) ? ( title => $title ) : () );
    if ( defined($lang) )
    {
        push @t, ( [ $self->_get_xml_xml_ns, 'lang' ] => $lang );
    }

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
