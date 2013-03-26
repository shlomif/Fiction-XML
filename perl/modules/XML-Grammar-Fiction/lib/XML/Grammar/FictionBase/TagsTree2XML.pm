package XML::Grammar::FictionBase::TagsTree2XML;

use MooX 'late';

use XML::Writer;
use HTML::Entities ();

use XML::Grammar::Fiction::FromProto::Nodes;


=head1 NAME

XML::Grammar::FictionBase::TagsTree2XML - base class for the tags-tree
to XML converters.

=head1 VERSION

Version 0.12.1

=cut

has '_parser_class' =>
(
    is => "ro",
    isa => "Str",
    init_arg => "parser_class",
    default => "XML::Grammar::Fiction::FromProto::Parser::QnD",
);

has "_parser" => (
    'isa' => "XML::Grammar::Fiction::FromProto::Parser",
    'is' => "rw",
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->_parser_class->new();
    },
);

has "_writer" => ('isa' => "XML::Writer", 'is' => "rw");

sub _write_Element_elem
{
    my ($self, $elem) = @_;

    if ($elem->_short_isa("InnerDesc"))
    {
        $self->_output_tag_with_childs(
            {
                start => ["inlinedesc"],
                elem => $elem,
            }
        );
        return;
    }
    else
    {
        my $method = "_handle_elem_of_name_" . $elem->name();

        $self->$method($elem);

        return;
    }
}

sub _handle_elem_of_name_s
{
    my ($self, $elem) = @_;

    $self->_write_scene({scene => $elem});
}

sub _handle_elem_of_name_b
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => [$self->_bold_tag_name()],
            elem => $elem,
        }
    );
}

sub _handle_elem_of_name_br
{
    my ($self, $elem) = @_;

    $self->_writer->emptyTag("br");

    return;
}

sub _handle_elem_of_name_i
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => [$self->_italics_tag_name],
            elem => $elem,
        }
    );

    return;
}
=head2 meta()

Internal - (to settle pod-coverage.).

=cut

1;

