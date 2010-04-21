package XML::Grammar::Screenplay::FromProto;

use strict;
use warnings;

use Carp;

use base 'XML::Grammar::Screenplay::Base';

use XML::Writer;
use HTML::Entities ();

use XML::Grammar::Fiction::FromProto::Nodes;

use Moose;

has "_parser" => ('isa' => "XML::Grammar::Screenplay::FromProto::Parser", 'is' => "rw");
has "_writer" => ('isa' => "XML::Writer", 'is' => "rw");

has '_buffer' => ('isa' => "ScalarRef[Str]", is => "rw");

my $screenplay_ns = q{http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/};

=head1 NAME

XML::Grammar::Screenplay::FromProto - module that converts well-formed
text representing a screenplay to an XML format.

=head1 VERSION

Version 0.0600

=cut

our $VERSION = '0.0600';

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

use Data::Dumper;

sub _output_tag
{
    my ($self, $args) = @_;

    my @start = @{$args->{start}};
    $self->_writer->startTag([$screenplay_ns,$start[0]], @start[1..$#start]);

    $args->{in}->($self, $args);

    $self->_writer->endTag();
}

sub _output_tag_with_childs
{
    my ($self, $args) = @_;

    return 
        $self->_output_tag({
            %$args,
            'in' => sub {
                foreach my $child (@{$args->{elem}->_get_childs()})
                {
                    $self->_write_elem({elem => $child,});
                }
            },
        });
}

sub _handle_text_start
{
    my ($self, $elem) = @_;

    if ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Saying"))
    {
        $self->_output_tag_with_childs(
            {
                start => ["saying", 'character' => $elem->character()],
                elem => $elem,
            },
        );
    }
    elsif ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Description"))
    {
        $self->_output_tag_with_childs(
            {
                start => ["description"],
                elem => $elem,
            },
        );
    }
    elsif ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Text"))
    {
        foreach my $child (@{$elem->_get_childs()})
        {
            $self->_write_elem({ elem => $child,},);
        }
    }
    else
    {
        Carp::confess ("Unknown element class - " . ref($elem) . "!");
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
    elsif ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Paragraph"))
    {
        $self->_output_tag_with_childs(
            {
               start => ["para"],
                elem => $elem,
            },
        );
    }
    elsif ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Element"))
    {
        if (($elem->name() eq "s") || ($elem->name() eq "section"))
        {
            $self->_write_scene({scene => $elem});
        }
        elsif ($elem->name() eq "a")
        {
            $self->_output_tag_with_childs(
                {
                    start => ["ulink", "url" => $elem->lookup_attr("href")],
                    elem => $elem,
                }
            );
        }
        elsif ($elem->name() eq "b")
        {
            $self->_output_tag_with_childs(
                {
                    start => ["bold"],
                    elem => $elem,
                }
            );
        }
        elsif ($elem->name() eq "br")
        {
            $self->_writer->emptyTag("br");
        }
        elsif ($elem->isa("XML::Grammar::Fiction::FromProto::Node::InnerDesc"))
        {
            $self->_output_tag_with_childs(
                {
                    start => ["inlinedesc"],
                    elem => $elem,
                }
            );
        }
    }
    elsif ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Text"))
    {
        $self->_handle_text_start($elem);
    }
    elsif ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Comment"))
    {
        $self->_writer->comment($elem->text());
    }
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

sub convert
{
    my ($self, $args) = @_;

    # These should be un-commented for debugging.
    # local $::RD_HINT = 1;
    # local $::RD_TRACE = 1;
    
    # We need this so P::RD won't skip leading whitespace at lines
    # which are siginificant.  

    my $tree = $self->_calc_tree($args);

    if (!defined($tree))
    {
        Carp::confess("Parsing failed.");
    }

    my $buffer = "";
    $self->_buffer(\$buffer);
    
    my $writer = XML::Writer->new(
        OUTPUT => $self->_buffer(), 
        ENCODING => "utf-8",
        NAMESPACES => 1,
        PREFIX_MAP =>
        {
             $screenplay_ns => "",
        }
    );

    $writer->xmlDecl("utf-8");
    $writer->doctype("document", undef, "screenplay-xml.dtd");
    $writer->startTag([$screenplay_ns, "document"]);
    $writer->startTag([$screenplay_ns, "head"]);
    $writer->endTag();
    $writer->startTag([$screenplay_ns, "body"], "id" => "index",);

    # Now we're inside the body.
    $self->_writer($writer);

    $self->_write_scene({scene => $tree});

    # Ending the body
    $writer->endTag();

    $writer->endTag();
    
    return ${$self->_buffer()};
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-screenplay at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Screenplay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

