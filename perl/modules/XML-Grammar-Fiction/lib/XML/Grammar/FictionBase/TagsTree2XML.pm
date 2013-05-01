package XML::Grammar::FictionBase::TagsTree2XML;

use MooX 'late';

our $VERSION = '0.14.3';

use XML::Writer;
use HTML::Entities ();

sub _get_xml_xml_ns
{
    return "http://www.w3.org/XML/1998/namespace";
}

sub _get_xlink_xml_ns
{
    return "http://www.w3.org/1999/xlink";
}

=head1 NAME

XML::Grammar::FictionBase::TagsTree2XML - base class for the tags-tree
to XML converters.

=head1 VERSION

Version 0.14.3

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

sub _get_initial_writer
{
    my $self = shift;

    my $writer = XML::Writer->new(
        OUTPUT => $self->_buffer(),
        ENCODING => "utf-8",
        NAMESPACES => 1,
        PREFIX_MAP =>
        {
            $self->_get_default_xml_ns() => "",
            $self->_get_xml_xml_ns() => 'xml',
            $self->_get_xlink_xml_ns() => 'xlink',
        },
    );

    $writer->xmlDecl("utf-8");

    return $writer;
}

has "_writer" => (
    'isa' => "Maybe[XML::Writer]",
    'is' => "rw",
    lazy => 1,
    default => sub { return shift->_get_initial_writer(); },
);

sub _get_initial_buffer {
    my $buffer = '';
    return \$buffer;
}

has '_buffer' => (
    is => "rw",
    lazy => 1,
    default => sub { return shift->_get_initial_buffer; },
);

sub _reset_buffer
{
    my $self = shift;

    $self->_buffer($self->_get_initial_buffer());
    $self->_writer($self->_get_initial_writer());

    return;
}

sub _flush_buffer
{
    my $self = shift;

    my $ret = $self->_buffer();
    $self->_reset_buffer();

    return $ret;
}

my %passthrough_elem =
(
    b => sub { return shift->_bold_tag_name(); },
    i => sub { return shift->_italics_tag_name(); },
);

sub _calc_passthrough_cb
{
    my ($self, $name) = @_;

    if (exists($passthrough_elem{$name}))
    {
        return $passthrough_elem{$name};
    }
    else
    {
        return undef();
    }
}

sub _calc_passthrough_name
{
    my ($self, $name, $elem) = @_;

    my $cb = $self->_calc_passthrough_cb($name);

    if (ref($cb) eq 'CODE')
    {
        return $cb->($self, $name, $elem,);
    }
    else
    {
        return $cb;
    }
}

sub _write_elem
{
    my ($self, $args) = @_;

    my $elem = $args->{elem};

    if (ref($elem) eq "")
    {
        $self->_writer->characters($elem);
    }
    else
    {
        return $self->_write_elem_obj($args);
    }
}

sub _write_Element_Paragraph
{
    my ($self, $elem) = @_;

    return $self->_output_tag_with_childs(
        {
            start => [$self->_paragraph_tag()],
            elem => $elem,
        },
    );
}

sub _write_Element_Element
{
    my ($self, $elem) = @_;

    return $self->_write_Element_elem($elem);
}

sub _write_Element_Comment
{
    my ($self, $elem) = @_;

    my $text = $elem->text();

    # To avoid trailing space due to a problem in XML::Writer
    $text =~ s{\A[\r\n]+}{}ms;

    if ($text =~ m{\n\z})
    {
        $text .= ' ';
    }

    $self->_writer->comment($text);
}

sub _calc_write_elem_obj_classes
{
    return [qw(Text Paragraph Element Comment)];
}

sub _output_tag_with_childs
{
    my ($self, $args) = @_;

    return
        $self->_output_tag({
            %$args,
            'in' => sub {
                return $self->_write_elem_childs( $args->{elem} );
            },
        });
}

sub _write_elem_childs
{
    my ($self, $elem) = @_;

    foreach my $child (@{$elem->_get_childs()})
    {
        $self->_write_elem({ elem => $child,},);
    }

    return;
}

sub _write_elem_obj
{
    my ($self, $args) = @_;

    my $elem = $args->{elem};

    foreach my $class (@{$self->_calc_write_elem_obj_classes()})
    {
        if ($elem->_short_isa($class))
        {
            my $meth = "_write_Element_$class";
            $self->$meth($elem);
            return;
        }
    }

    Carp::confess("Class of element not detected - " . ref($elem) . "!");
}

sub _write_Element_elem
{
    my ($self, $elem) = @_;

    my $name = $elem->name();

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
    elsif (defined(my $out_name = $self->_calc_passthrough_name($name, $elem)))
    {
        return $self->_output_tag_with_childs(
            {
                start => [$out_name],
                elem => $elem,
            }
        );
    }
    else
    {
        my $method = "_handle_elem_of_name_$name";

        $self->$method($elem);

        return;
    }
}

sub _handle_elem_of_name_s
{
    my ($self, $elem) = @_;

    $self->_write_scene({scene => $elem});
}

sub _handle_elem_of_name_br
{
    my ($self, $elem) = @_;

    $self->_writer->emptyTag("br");

    return;
}

sub _output_tag
{
    my ($self, $args) = @_;

    my @start = @{$args->{start}};
    $self->_writer->startTag([$self->_get_default_xml_ns(),$start[0]], @start[1..$#start]);

    $args->{in}->($self, $args);

    $self->_writer->endTag();
}

sub _convert_while_handling_errors
{
    my ($self, $args) = @_;

    eval {
        my $output_xml = $self->convert(
            $args->{convert_args},
        );

        open my $out, ">", $args->{output_filename};
        binmode $out, ":utf8";
        print {$out} $output_xml;
        close($out);
    };

    # Error handling.

    my $e;
    if ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::TagsMismatch"))
    {
        warn $e->error(), "\n";
        warn "Open: ", $e->opening_tag->name(),
            " at line ", $e->opening_tag->line(), "\n"
            ;
        warn "Close: ",
            $e->closing_tag->name(), " at line ",
            $e->closing_tag->line(), "\n";

        exit(-1);
    }
    elsif ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::LineError"))
    {
        warn $e->error(), "\n";
        warn "At line ", $e->line(), "\n";
        exit(-1);
    }
    elsif ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::TagNotClosedAtEOF"))
    {
        warn $e->error(), "\n";
        warn "Open: ", $e->opening_tag->name(),
            " at line ", $e->opening_tag->line(), "\n"
            ;

        exit(-1);
    }
    elsif ($e = Exception::Class->caught())
    {
        if (ref($e))
        {
            $e->rethrow();
        }
        else
        {
            die $e;
        }
    }

    return;
}

sub _read_file
{
    my ($self, $filename) = @_;

    open my $in, "<", $filename or
        Carp::confess("Could not open the file \"$filename\" for slurping.");
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

sub _write_scene
{
    my ($self, $args) = @_;

    my $scene = $args->{scene};

    my $tag = $scene->name;

    if (($tag eq "s") || ($tag eq "scene"))
    {
        $self->_write_scene_main($scene);
    }
    else
    {
        confess "Improper scene tag - should be '<s>' or '<scene>'!";
    }

    return;
}

=head2 $self->convert({ source => { file => $path_to_file } })

Converts the file $path_to_file to XML and returns it. Throws an exception
on failure.

=cut

sub convert
{
    my ($self, $args) = @_;

    my $tree = $self->_calc_tree($args);
    if (!defined($tree))
    {
        Carp::confess("Parsing failed.");
    }

    $self->_convert_write_content($tree);

    return ${$self->_flush_buffer()};
}

=head2 meta()

Internal - (to settle pod-coverage.).

=cut

1;

