package XML::Grammar::Fiction::FromProto;

use strict;
use warnings;

use Carp;
use HTML::Entities ();
use XML::Writer;

use Moose;

extends("XML::Grammar::FictionBase::TagsTree2XML");

use List::Util (qw(first));

my $fiction_ns = q{http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/};
my $xml_ns = "http://www.w3.org/XML/1998/namespace";
my $xlink_ns = "http://www.w3.org/1999/xlink";

=head1 NAME

XML::Grammar::Fiction::FromProto - module that converts well-formed
text representing prose to an XML format.

=head1 VERSION

Version 0.6.0

=cut

our $VERSION = '0.6.0';

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

use Data::Dumper;

sub _output_tag
{
    my ($self, $args) = @_;

    my @start = @{$args->{start}};
    $self->_writer->startTag([$fiction_ns,$start[0]], @start[1..$#start]);

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

sub _get_text_start
{
    my ($self, $elem) = @_;

    if ($elem->_short_isa("Saying"))
    {
        return ["saying", 'character' => $elem->character()];
    }
    elsif ($elem->_short_isa("Description"))
    {
        return ["description"];
    }
    else
    {
        Carp::confess ("Unknown element class - " . ref($elem) . "!");
    }
}

sub _paragraph_tag
{
    return "p";
}

sub _handle_elem_of_name_a
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start =>
            [
                "span",
                [$xlink_ns, "href"] => $elem->lookup_attr("href"),
            ],
            elem => $elem,
        }
    );

    return;
}

sub _handle_elem_of_name_blockquote
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => ['blockquote'],
            elem => $elem,
        }
    );

    return;
}


sub _handle_elem_of_name_li
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => ['li'],
            elem => $elem,
        }
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

sub _handle_elem_of_name_ol
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => ['ol'],
            elem => $elem,
        }
    );

    return;
}

sub _handle_elem_of_name_ul
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => ['ul'],
            elem => $elem,
        }
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

sub _handle_text_start
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs(
        {
            start => $self->_get_text_start($elem),
            elem => $elem,
        },
    );

    return;
}

sub _write_elem
{
    my ($self, $args) = @_;

    my $elem = $args->{elem};

    if (ref($elem) eq "")
    {
        $self->_writer->characters($elem);
    }
    elsif ($elem->_short_isa("Text"))
    {
        foreach my $child (@{$elem->_get_childs()})
        {
            $self->_write_elem({ elem => $child,},);
        }
    }
    elsif ($elem->_short_isa("Paragraph"))
    {
        $self->_output_tag_with_childs(
            {
                start => [$self->_paragraph_tag()],
                elem => $elem,
            },
        );
    }
    elsif ($elem->_short_isa("List"))
    {
        foreach my $child (@{$elem->contents()})
        {
            $self->_write_elem({elem => $child, });
        }
    }
    elsif ($elem->_short_isa("Element"))
    {
        $self->_write_Element_elem($elem);
    }
    elsif ($elem->_short_isa("Text"))
    {
        $self->_handle_text_start($elem);
    }
    elsif ($elem->_short_isa("Comment"))
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
        # TODO : abstract with _write_body.
        my $id = $scene->lookup_attr("id");
        my $lang = $scene->lookup_attr("lang");

        if (!defined($id))
        {
            Carp::confess("Unspecified id for scene!");
        }

        my @lang_attr;

        if (defined($lang))
        {
            push @lang_attr, ([$xml_ns, 'lang'] => $lang);
        }

        $self->_output_tag_with_childs(
            {
                'start' => ["section", [$xml_ns, "id"] => $id, @lang_attr,],
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

    # TODO : abstract with _write_scene.
    my $id = $body->lookup_attr("id");
    my $lang = $body->lookup_attr("lang");
=begin foo

    my $title =
        first
        { $_->name() eq "title" }
        @{$body->_get_childs()}
        ;

    my @t = 
    (
          defined($title)
        ? (title => $title->_get_childs()->[0])
        : ()
    );

=end foo

=cut

    my @lang_attr;

    if (defined($lang))
    {
        push @lang_attr, ([$xml_ns, 'lang'] => $lang);
    }

    $self->_output_tag_with_childs(
        {
            'start' => ["body", [$xml_ns, "id"] => $id, @lang_attr,],
            elem => $body,
        }
    );

    return;
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
    my $writer = XML::Writer->new(
        OUTPUT => \$buffer, 
        ENCODING => "utf-8",
        NAMESPACES => 1,
        PREFIX_MAP =>
        {
             $fiction_ns => q{},
             $xml_ns => 'xml',
             $xlink_ns => 'xlink',
        }
    );

    $writer->xmlDecl("utf-8");
    $writer->startTag([$fiction_ns, "document"], "version" => "0.2");
    $writer->startTag([$fiction_ns, "head"]);
    $writer->endTag();

    # Now we're inside the body.
    $self->_writer($writer);

    $self->_write_body({body => $tree});

    $writer->endTag();
    
    return $buffer;
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-fiction at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fiction>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

