package XML::Grammar::Fiction::FromProto;

use strict;
use warnings;
use autodie;

use Carp;

use MooX 'late';

extends("XML::Grammar::FictionBase::TagsTree2XML");

my $fiction_ns = q{http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/};

=head1 NAME

XML::Grammar::Fiction::FromProto - module that converts well-formed
text representing prose to an XML format.

=head1 VERSION

Version 0.14.8

=cut

our $VERSION = '0.14.8';

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=cut

=head2 $self->convert({ source => { file => $path_to_file } })

Converts the file $path_to_file to XML and returns it. Throws an exception
on failure.

=cut

my %lookup = (map { $_ => $_ } qw( li ol ul ));

around '_calc_passthrough_cb' => sub
{
    my $orig = shift;
    my $self = shift;
    my ($name) = @_;

    if ($lookup{$name})
    {
        return $name;
    }

    return $orig->($self, @_);
};

sub _output_tag_with_childs_and_common_attributes
{
    my ($self, $elem, $tag_name, $args) = @_;

    my $id = $elem->lookup_attr("id");
    my $lang = $elem->lookup_attr("lang");
    my $href = $elem->lookup_attr("href");

    my @attr;

    if (!defined($id))
    {
        if (! $args->{optional_id} )
        {
            Carp::confess($args->{missing_id_msg} || "Unspecified id!");
        }
    }
    else
    {
        push @attr, ([$self->_get_xml_xml_ns, "id"] => $id);
    }

    if (defined($lang))
    {
        push @attr, ([$self->_get_xml_xml_ns, 'lang'] => $lang);
    }

    if (! defined($href))
    {
        if ($args->{required_href})
        {
            Carp::confess(
                $args->{missing_href_msg} || 'Unspecified href in tag!'
            );
        }
    }
    else
    {
        push @attr, ([$self->_get_xlink_xml_ns(), 'href'] => $href);
    }

    return $self->_output_tag_with_childs(
        {
            'start' => [$tag_name, @attr,],
            elem => $elem,
        }
    );
}

sub _paragraph_tag
{
    return "p";
}

sub _handle_elem_of_name_a
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $elem,
        'span',
        {
            optional_id => 1,
            required_href => 1,
            missing_href_msg => 'Unspecified href in a tag.',
        },
    );

    return;
}

sub _handle_elem_of_name_blockquote
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $elem,
        'blockquote',
        {
            optional_id => 1,
        },
    );

    return;
}


sub _handle_elem_of_name_programlisting
{
    my ($self, $elem) = @_;

    my $throw_found_tag_exception = sub {
        XML::Grammar::Fiction::Err::Parse::ProgramListingContainsTags->throw(
            error => "<programlisting> tag cannot contain other tags.",
            line => $elem->open_line(),
        );
    };

    return $self->_output_tag(
        {
            start => ['programlisting'],
            elem => $elem,
            'in' => sub {
                foreach my $child (@{ $elem->_get_childs() })
                {
                    if ($child->_short_isa("Paragraph"))
                    {
                        foreach my $text_node (
                            @{ $child->children()->contents() }
                        )
                        {
                            if ($text_node->_short_isa("Text"))
                            {
                                $self->_write_elem({elem => $text_node});
                            }
                            else
                            {
                                $throw_found_tag_exception->();
                            }
                        }
                    }
                    else
                    {
                        $throw_found_tag_exception->();
                    }
                    # End of paragraph.
                    $self->_writer->characters("\n\n");
                }

                return;
            },
        }
    );

    return;
}

sub _handle_elem_of_name_span
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $elem,
        'span',
        {
            optional_id => 1,
            missing_id_msg => "Unspecified id for span!",
        },
    );

    return;
}

sub _handle_elem_of_name_title
{
    my ($self, $elem) = @_;

    # TODO :
    # Eliminate the Law-of-Demeter-syndrome here.
    my $list = $elem->_get_childs()->[0];

    $self->_output_tag(
        {
            start => ["title"],
            in => sub {
                $self->_write_elem(
                    {
                        elem => $list,
                    }
                ),
            },
        },
    );

    return;
}

sub _bold_tag_name
{
    return "b";
}

sub _italics_tag_name
{
    return "i";
}

sub _write_Element_Text
{
    return shift->_write_elem_childs(@_);
}

sub _write_Element_List
{
    my ($self, $elem) = @_;

    foreach my $child (@{$elem->contents()})
    {
        $self->_write_elem({elem => $child, });
    }

    return;
}

around '_calc_write_elem_obj_classes' => sub
{
    my $orig = shift;
    my $self = shift;

    return ['List', @{$orig->($self)}];
};

sub _write_scene_main
{
    my ($self, $scene) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $scene,
        "section",
        { missing_id_msg => "Unspecified id for scene!", },
    );

    return;
}

sub _write_body
{
    my $self = shift;
    my $args = shift;

    my $body = $args->{'body'};

    my $tag = $body->name;

    if ($tag ne "body")
    {
        confess "Improper body tag - should be '<body>'!";
    }

    $self->_output_tag_with_childs_and_common_attributes(
        $body,
        'body',
        { missing_id_msg => "Unspecified id for body tag!", },
    );

    return;
}

sub _get_default_xml_ns
{
    return $fiction_ns;
}

sub _convert_write_content
{
    my ($self, $tree) = @_;

    my $writer = $self->_writer;

    $writer->startTag([$fiction_ns, "document"], "version" => "0.2");
    $writer->startTag([$fiction_ns, "head"]);
    $writer->endTag();

    $self->_write_body({body => $tree});

    $writer->endTag();

    return;
}

1;

