package XML::Grammar::Fiction::FromProto::Parser::XmlIterator;

use strict;
use warnings;

use Moose;

use XML::Grammar::Fiction::Err;
use XML::Grammar::Fiction::Struct::Tag;
use XML::Grammar::Fiction::Event;

extends("XML::Grammar::Fiction::FromProto::Parser::LineIterator");

has "_tags_stack" =>
(
    isa => "ArrayRef",
    is => "rw",
    default => sub { [] },
    traits => ['Array'],
    handles =>
    {
        '_push_tag' => 'push',
        '_grep_tags_stack' => 'grep',
        '_tag_stack_is_empty' => 'is_empty',
        '_pop_tag' => 'pop',
        '_get_tag' => 'get',
    },
);

has "_events_queue" =>
(
    isa => "ArrayRef[XML::Grammar::Fiction::Event]",
    # isa => "ArrayRef",
    is => "rw", 
    default => sub { []; },
    traits => ['Array'],
    handles =>
    {
        _enqueue_event => 'push',
        _extract_event => 'shift',
    },
);

has '_ret_tag' =>
(
    is => "rw",
    # TODO : add isa.
    predicate => "_has_ret_tag",
    clearer => "_clear_ret_tag",
);

# Whether we are inside a paragraph or not.
has "_in_para" => (isa => "Bool", is => "rw", default => 0,);

sub _get_id_regex
{
    return qr{[a-zA-Z_\-]+};
}

sub _top_tag
{
    my $self = shift;
    return $self->_get_tag(-1);
}

sub _add_to_top_tag
{
    my ($self, $child) = @_;

    $self->_top_tag->append_child($child);

    return;
}

# TODO : Maybe move to a different sub-class or role.
sub _new_empty_list
{
    my $self = shift;
    return $self->_new_list([]);
}

sub _new_node
{
    my $self = shift;
    my $args = shift;

    # t == type
    my $class = 
        "XML::Grammar::Fiction::FromProto::Node::"
        . delete($args->{'t'})
        ;

    return $class->new(%$args);
}


sub _create_elem
{
    my $self = shift;
    my $open = shift;

    my $children = @_ ? shift(@_) : $self->_new_empty_list();

    return
        $self->_new_node(
            {
                t => (
                    $open->name() eq "desc" ? "Description" 
                    : $open->name() eq "innerdesc" ? "InnerDesc"
                    : "Element"
                ),
                name => $open->name(),
                children => $children,
                attrs => $open->attrs(),
            }
        );
}

sub _new_list
{
    my $self = shift;
    my $contents = shift;

    return $self->_new_node(
        {
            t => "List",
            contents => $contents,
        }
    );
}

sub _new_para
{
    my $self = shift;
    my $contents = shift;

    # This is an assert
    if (List::MoreUtils::any 
        { ref($_) ne "" && $_->isa("XML::Grammar::Fiction::FromProto::Node::Saying") }
        @{$contents || []}
        )
    {
        Carp::confess (qq{Para contains a saying.});
    }


    return $self->_new_node(
        {
            t => "Paragraph",
            children => $self->_new_list($contents),
        }
    );
}

sub _new_text
{
    my $self = shift;
    my $contents = shift;

    return $self->_new_node(
        {
            t => "Text",
            children => $self->_new_list($contents),
        }
    );
}

sub _new_comment
{
    my $self = shift;
    my $text = shift;

    return $self->_new_node(
        {
            t => "Comment",
            text => $text,
        }
    );
}

sub _parse_opening_tag_attrs
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    my @attrs;

    my $id_regex = $self->_get_id_regex();

    while ($$l =~ m{\G\s*($id_regex)="([^"]+)"\s*}cg)
    {
        push @attrs, { 'key' => $1, 'value' => $2, };
    }

    return \@attrs;
}

sub _parse_opening_tag
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    my $id_regex = $self->_get_id_regex();

    # This is an assert
    if (!defined($$l))
    {
        Carp::confess (qq{Reached EOF in _parse_opening_tag.});
    }

    # This is an assert
    if (!defined($self->curr_pos()))
    {
        Carp::confess (qq{curr_pos is not defined in _parse_opening_tag.});
    }
    
    if ($$l !~ m{\G<($id_regex)}cg)
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag',
            "Cannot match opening tag.",
        );
    }

    my $id = $1;

    my $attrs = $self->_parse_opening_tag_attrs();

    my $is_standalone = 0;
    if ($$l =~ m{\G\s*/\s*>}cg)
    {
        $is_standalone = 1;
    }
    elsif ($$l !~ m{\G>}g)
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::NoRightAngleBracket',
            "Cannot match the \">\" of the opening tag",
        );
    }
    
    return XML::Grammar::Fiction::Struct::Tag->new(
        name => $id,
        is_standalone => $is_standalone,
        line => $self->line_num(),
        attrs => $attrs,
    );
}

sub _parse_closing_tag
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    my $id_regex = $self->_get_id_regex();

    if ($$l !~ m{\G</($id_regex)>}g)
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::WrongClosingTagSyntax',
            "Cannot match closing tag",
        );
    }

    return XML::Grammar::Fiction::Struct::Tag->new(
        name => $1,
        line => $self->line_num(),
    );
}

sub _check_for_open_tag
{
    my $self = shift;

    if ($self->_tag_stack_is_empty())
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag',
            "Cannot match opening tag.",
        );
    }

    return;
}

sub _is_event_a_saying
{
    my ($self, $event) = @_;

    return $event->is_tag_of_name("saying");
}

sub _is_event_a_para
{
    my ($self, $event) = @_;

    return $event->is_tag_of_name("para");
}

sub _is_event_elem
{
    my ($self, $event) = @_;

    return $event->type() eq "elem";
}

sub _handle_event
{
    my ($self, $event) = @_;

    if ((! $self->_check_and_handle_tag_event($event))
        && $self->_is_event_elem($event)
    )
    {
        $self->_handle_elem_event($event);
    }

    return;
}

sub _check_and_handle_tag_event
{
    my ($self, $event) = @_;

    foreach my $tag_name (@{$self->_list_valid_tag_events()})
    {
        if ($event->is_tag_of_name($tag_name))
        {
            my $type = $event->is_open() ? "open" : "close";
            
            my $method = "_handle_${type}_${tag_name}";

            $self->$method($event);

            return 1;
        }
    }

    return;
}

sub _handle_para_event
{
    my ($self, $event) = @_;

    return
          $event->is_open()
        ? $self->_handle_open_para($event)
        : $self->_handle_close_para($event)
        ;
}

sub _handle_elem_event
{
    my ($self, $event) = @_;

    $self->_add_to_top_tag( $event->elem());

    return;
}

sub _handle_non_tag_text
{
    my $self = shift;

    $self->_check_for_open_tag();

    my $contents = $self->_parse_text();

    foreach my $event (@$contents)
    {
        $self->_handle_event($event);
    }

    return;
}


sub _look_for_and_handle_tag
{
    my $self = shift;

    my ($is_tag_cond, $is_close) = $self->_look_ahead_for_tag();

    # Check if it's a closing tag.
    if ($is_close)
    {
        return $self->_handle_close_tag();
    }
    elsif ($is_tag_cond)
    {
        $self->_handle_open_tag();
    }
    else
    {
        $self->_handle_non_tag_text();
    }
    return;
}

sub _merge_tag
{
    my $self = shift;
    my $open_tag = shift;

    my $new_elem = 
        $self->_create_elem(
            $open_tag, 
            $self->_new_list($open_tag->detach_children()),
        );

    if (! $self->_tag_stack_is_empty())
    {
        $self->_add_to_top_tag($new_elem);
        return;
    }
    else
    {
        return $new_elem;
    }
}

sub _handle_close_tag
{
    my $self = shift;

    my $close = $self->_parse_closing_tag();

    my $open = $self->_pop_tag();

    if ($open->name() ne $close->name())
    {
        XML::Grammar::Fiction::Err::Parse::TagsMismatch->throw(
            error => "Tags do not match",
            opening_tag => $open,
            closing_tag => $close,
        );
    }

    return $self->_merge_tag($open);
}

sub _look_ahead_for_comment
{
    my $self = shift;

    if ($self->curr_line_continues_with(qr{<!--}))
    {
        my $text = $self->consume_up_to(qr{-->});

        $self->_add_to_top_tag(
            $self->_new_comment($text),
        );

        return 1;
    }
    else
    {
        return;
    }
}

sub _parse_non_tag_text_unit
{
    my $self = shift;

    my $text = $self->consume_up_to($self->_non_tag_text_unit_consume_regex);

    my $l = $self->curr_line_ref();

    my $ret_elem = $self->_new_text([$text]);
    my $is_para_end = 0;

    # Demote the cursor to before the < of the tag.
    #
    if (pos($$l) > 0)
    {
        pos($$l)--;
        if (substr($$l, pos($$l), 1) eq "\n")
        {
            $is_para_end = 1;
        }
    }
    else
    {
        $is_para_end = 1;
    }
    
    if ($text !~ /\S/)
    {
        return;
    }
    else
    {
        return
        {
            elem => $ret_elem,
            para_end => $is_para_end,
        };
    }
}

sub _parse_text_unit
{
    my $self = shift;

    if (defined(my $event = $self->_extract_event()))
    {
        return $event;
    }
    else
    {
        $self->_generate_text_unit_events();
        return $self->_extract_event();
    }
}

sub _parse_text
{
    my $self = shift;

    my @ret;
    while (my $unit = $self->_parse_text_unit())
    {
        push @ret, $unit;
        my $type = $unit->{'type'};
        if (($type eq "close") || ($type eq "open"))
        {
            push @ret, @{$self->_events_queue()};
            $self->_events_queue([]);
            return \@ret;
        }
    }

    return \@ret;
}

sub _look_for_tag_opener
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    if ($$l =~ m{\G(\&|<(?:/)?)}cg)
    {
        return $1;
    }
    else
    {
        return;
    }
}

sub _is_closing_tag { 
    my $self = shift;
    my $tag_start = shift;

    return $tag_start =~ m{/};
}

sub _generate_tag_event
{
    my $self = shift;

    my $l = $self->curr_line_ref();
    my $orig_pos = pos($$l);

    if (defined(my $tag_start = $self->_look_for_tag_opener()))
    {
        # If it's a tag.

        # TODO : implement the comment handling.
        # We have a tag.

        pos($$l) = $orig_pos;

        if ($$l =~ m{\G\&})
        {
            if ($$l !~ m/\G(\&#?\w+;)/g)
            {
                Carp::confess("Cannot match entity (e.g: \"&quot;\") at line " .
                    $self->line_num()
                );
            }

            my $entity = $1;

            $self->_enqueue_event(
                XML::Grammar::Fiction::Event->new(
                    {
                        type => "elem",
                        elem => $self->_new_text(
                            [HTML::Entities::decode_entities($entity)]
                        ),
                    },
                )
            );

            return;
        }

        $self->_enqueue_event(
            XML::Grammar::Fiction::Event->new(
                {'type' => ($self->_is_closing_tag($tag_start) ? "close" : "open")}
            ),
        );

        return 1;
    }
    else
    {
        return;
    }
}

sub _handle_open_tag
{
    my $self = shift;

    my $open = $self->_parse_opening_tag();

    $open->children([]);

    # TODO : add the check for is_standalone in XML-Grammar-Fiction
    # too.
    if ($open->is_standalone())
    {
        if (defined($self->_merge_tag($open)))
        {
            Carp::confess ("Top element/tag cannot be standalone.");
        }
        else
        {
            return;
        }
    }

    $self->_push_tag($open);

    return;
}

sub _generate_text_unit_events
{
    my $self = shift;
    
    # $self->skip_multiline_space();

    if (! $self->_generate_tag_event())
    {
        $self->_generate_non_tag_text_event();
    }

    return;
}

sub _flush_ret_tag
{
    my $self = shift;

    my $ret = $self->_ret_tag();

    $self->_clear_ret_tag();

    return $ret;
}

sub _main_loop
{
    my $self = shift;

    while (! defined($self->_ret_tag()))
    {
        $self->_main_loop_iter();
    }

    return;
}

sub _parse_all
{
    my $self = shift;

    $self->_main_loop();

    return $self->_flush_ret_tag();
}

sub _main_loop_iter
{
    my $self = shift;

    # This is an assert.
    if (!defined(${$self->curr_line_ref()}) && (! @{$self->_events_queue()}))
    {
        Carp::confess (qq{Reached EOF.});
    }
    
    if ($self->_look_ahead_for_comment())
    {
        return;
    }

    return $self->_main_loop_iter_body();
}

sub _attempt_to_calc_new_ret_tag
{
    my $self = shift;
    
    $self->_ret_tag(scalar($self->_look_for_and_handle_tag()));

    return;
}

sub _main_loop_iter_body
{
    my $self = shift;

    if ($self->_main_loop_iter_body_prelude())
    {
        $self->_attempt_to_calc_new_ret_tag();
    }

    return;
}

=head1 NAME

XML::Grammar::Fiction::FromProto::Parser::XmlIterator - line iterator base
class with some nested XMLisms.

B<For internal use only>.

=cut

our $VERSION = '0.4.1';

=head1 VERSION

Version 0.4.1

=head1 SYNOPSIS

B<TODO:> write one.

=head1 DESCRIPTION

This is a line iterator with some features for parsing, nested, 
XML-like grammars.

=head1 METHODS

=head2 $self->process_text($string)

Processes the text and returns the parse tree.

=cut

sub process_text
{   
    my ($self, $text) = @_;

    $self->setup_text($text);

    return $self->_parse_all();
}

=head2 $self->meta()

Leftover from Moose.

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

