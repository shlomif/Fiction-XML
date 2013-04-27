package XML::Grammar::Screenplay::FromProto;

use MooX 'late';

extends("XML::Grammar::FictionBase::TagsTree2XML");

my $screenplay_ns = q{http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/};

=head1 NAME

XML::Grammar::Screenplay::FromProto - module that converts well-formed
text representing a screenplay to an XML format.

=head1 VERSION

Version 0.12.5

=cut

our $VERSION = '0.12.5';

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=cut

sub _init
{
    my ($self, $args) = @_;

    local $Parse::RecDescent::skip = "";

    my $parser_class =
        ($args->{parser_class} || "XML::Grammar::Screenplay::FromProto::Parser::QnD");

    $self->_parser(
        $parser_class->new()
    );

    return 0;
}

=head2 $self->convert({ source => { file => $path_to_file } })

Converts the file $path_to_file to XML and returns it.

=cut

sub _output_tag
{
    my ($self, $args) = @_;

    my @start = @{$args->{start}};
    $self->_writer->startTag([$screenplay_ns,$start[0]], @start[1..$#start]);

    $args->{in}->($self, $args);

    $self->_writer->endTag();
}

sub _handle_text_start
{
    my ($self, $elem) = @_;

    if ($elem->_short_isa("Saying"))
    {
        $self->_output_tag_with_childs(
            {
                start => ["saying", 'character' => $elem->character()],
                elem => $elem,
            },
        );

        return;
    }
    elsif ($elem->_short_isa("Description"))
    {
        $self->_output_tag_with_childs(
            {
                start => ["description"],
                elem => $elem,
            },
        );

        return;
    }
    elsif ($elem->_short_isa("Text"))
    {
        $self->_write_elem_childs($elem);

        return;
    }
    else
    {
        Carp::confess ("Unknown element class - " . ref($elem) . "!");
    }
}

sub _paragraph_tag
{
    return "para";
}

sub _write_Element_Text
{
    my ($self, $elem) = @_;

    return $self->_handle_text_start($elem);
}

sub _handle_elem_of_name_img
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => [
                "image",
                "url" => $elem->lookup_attr("src"),
                "alt" => $elem->lookup_attr("alt"),
                "title" => $elem->lookup_attr("title"),
            ],
            elem => $elem,
        }
    );

    return;
}

sub _handle_elem_of_name_a
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => ["ulink", "url" => $elem->lookup_attr("href")],
            elem => $elem,
        }
    );

    return;
}

sub _handle_elem_of_name_section
{
    my ($self, $elem) = @_;

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

sub _write_scene
{
    my ($self, $args) = @_;

    my $scene = $args->{scene};

    my $tag = $scene->name;

    if (($tag eq "s") || ($tag eq "scene"))
    {
        my $id = $scene->lookup_attr("id");

        if (!defined($id))
        {
            Carp::confess("Unspecified id for scene!");
        }

        my $title = $scene->lookup_attr("title");
        my @t = (defined($title) ? (title => $title) : ());

        $self->_output_tag_with_childs(
            {
                'start' => ["scene", id => $id, @t],
                elem => $scene,
            }
        );
    }
    else
    {
        confess "Improper scene tag - should be '<s>' or '<scene>'!";
    }

    return;
}

sub _read_file
{
    my ($self, $filename) = @_;

    open my $in, "<", $filename or
        confess "Could not open the file \"$filename\" for slurping.";
    binmode $in, ":utf8";
    my $contents;
    {
        local $/;
        $contents = <$in>;
    }
    close($in);

    return $contents;
}

sub _calc_tree
{
    my ($self, $args) = @_;

    my $filename = $args->{source}->{file} or
        confess "Wrong filename given.";

    return $self->_parser->process_text($self->_read_file($filename));
}

sub _get_default_xml_ns
{
    return $screenplay_ns;
}

sub _convert_write_content
{
    my ($self, $tree) = @_;

    my $writer = $self->_writer;

    $writer->startTag([$screenplay_ns, "document"]);
    $writer->startTag([$screenplay_ns, "head"]);
    $writer->endTag();
    $writer->startTag([$screenplay_ns, "body"], "id" => "index",);

    $self->_write_scene({scene => $tree});

    # Ending the body
    $writer->endTag();

    $writer->endTag();

    return;
}

1;

