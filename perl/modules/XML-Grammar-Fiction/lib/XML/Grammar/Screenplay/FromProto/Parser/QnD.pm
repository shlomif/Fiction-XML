package XML::Grammar::Screenplay::FromProto::Parser::QnD;

use strict;
use warnings;

use Moose;

extends(
    'XML::Grammar::Screenplay::FromProto::Parser',
    'XML::Grammar::Fiction::FromProto::Parser::XmlIterator',
);

use XML::Grammar::Screenplay::FromProto::Nodes;
use XML::Grammar::Screenplay::Struct::Tag;

use List::Util ();
use List::MoreUtils ();

has "_in_para" => (isa => "Bool", is => "rw");
has "_in_saying" => (isa => "Bool", is => "rw");
has "_prev_line_is_empty" => (isa => "Bool", is => "rw", default => 1);

before 'next_line_ref' => sub {
    my $self = shift;

    $self->_prev_line_is_empty($self->curr_line_ref() =~ m{\A\s*\z});

    return;
};

sub _top_is_para
{
    my $self = shift;

    return $self->_in_para() && ($self->_top_tag->name() eq "p");
}


sub _top_is_saying
{
    my $self = shift;

    return $self->_in_saying() && ($self->_top_tag->name() eq "saying");
}

around '_pop_tag' => sub {
    my ($orig, $self) = @_;

    my $open = $self->$orig();

    if ($open->name() eq "saying")
    {
        $self->_in_saying(0);
    }

    return $open;
};

sub _count_tags_in_stack
{
    my $self = shift;
    my $name = shift;

    my @tags = $self->_grep_tags_stack(sub { $_->name() eq $name; });

    return scalar(@tags);
}

after '_push_tag' => sub {
    my $self = shift;

    # This is an assert - it must never happen.
    if ($self->_count_tags_in_stack("p") == 2)
    {
        Carp::confess (qq{Two paragraphs in the tags stack.});
    }

    # This is an assert - it must never happen.
    if ($self->_count_tags_in_stack("saying") == 2)
    {
        Carp::confess (qq{Two sayings in the tags stack at the same time.});
    }
    
    return;
};

sub _init
{
    my $self = shift;

    return 0;
}

my $id_regex = '[a-zA-Z_\-]+';


sub _new_node
{
    my $self = shift;
    my $args = shift;

    # t == type
    my $class = 
        "XML::Grammar::Screenplay::FromProto::Node::"
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
                name => $open->{name},
                children => $children,
                attrs => $open->{attrs},
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
        { ref($_) ne "" && $_->isa("XML::Grammar::Screenplay::FromProto::Node::Saying") }
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

sub _new_saying
{
    my $self = shift;
    my $sayer = shift;
    my $contents = shift;

    return $self->_new_node(
        {
            t => "Saying",
            character => $sayer,
            children => $self->_new_list($contents),
        }
    );
}

sub _get_desc_name
{
    my $self = shift;

    return ($self->_in_para() ? "innerdesc" : "desc");
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

sub _parse_opening_tag
{
    my $self = shift;

    my $l = $self->curr_line_ref();

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

    my $is_start = ($self->curr_pos() == 0);

    if ($$l =~ m{\G\[}cg)
    {
        my $not_inline = 0;
        if ($is_start && $self->_prev_line_is_empty())
        {
            $self->_close_top_tags();
            $not_inline = 1;
        }

        return XML::Grammar::Screenplay::Struct::Tag->new(
            name => $not_inline ? "desc" : $self->_get_desc_name(),
            line => $self->line_num(),
            attrs => [],
        );
    }

    if ($$l !~ m{\G<($id_regex)}g)
    {
        Carp::confess("Cannot match opening tag at line " . $self->line_num());
    }

    my $id = $1;

    my @attrs;

    while ($$l =~ m{\G\s*($id_regex)="([^"]+)"\s*}cg)
    {
        push @attrs, { 'key' => $1, 'value' => $2, };
    }

    my $is_standalone = 0;

    if ($$l =~ m{\G\s*/\s*>}cg)
    {
        $is_standalone = 1;
    }
    elsif ($$l !~ m{\G>}g)
    {
        Carp::confess (
            "Cannot match the \">\" of the opening tag at line " 
            . $self->line_num()
        );
    }
     
    return XML::Grammar::Screenplay::Struct::Tag->new(
        name => $id,
        is_standalone => $is_standalone,
        line => $self->line_num(),
        attrs => \@attrs,
    );
}

sub _parse_closing_tag
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    if ($$l =~ m{\G\]}cg)
    {
        return XML::Grammar::Screenplay::Struct::Tag->new(
            name => $self->_get_desc_name(),
            line => $self->line_num(),
        );
    }
    elsif ($$l =~ m{\G</($id_regex)>}g)
    {
        return XML::Grammar::Screenplay::Struct::Tag->new(
            name => $1,
            line => $self->line_num(),
        );
    }
    else
    {
        Carp::confess("Cannot match closing tag at line ". $self->line_num());
    }

}

sub _parse_text
{
    my $self = shift;

    my @ret;
    while (defined(my $unit = $self->_parse_text_unit()))
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

sub _parse_inner_tag
{
    my $self = shift;

    my $open = $self->_parse_opening_tag();

    if ($open->{is_standalone})
    {
        # $self->skip_multiline_space();

        return $self->_create_elem($open);
    }

    my $inside = $self->_parse_inner_text();

    my $close = $self->_parse_closing_tag();

    if ($open->{name} ne $close->{name})
    {
        Carp::confess("Opening and closing tags do not match: " 
            . "$open->{name} and $close->{name} on element starting at "
            . "line $open->{line}"
        );
    }
    return $self->_create_elem($open, $self->_new_list($inside));
}

sub _determine_tag
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    return
          ($$l =~ m{\G\[}) ? "open_desc"
        : ($$l =~ m{\G\&}) ? "entity"
        : ($$l =~ m{\G(?:</|\])}) ? "close"
        : ($$l =~ m{\G<}) ? "open_tag"
        : undef
        ;
}

sub _parse_speech_unit
{
    my $self = shift;

    if (${$self->curr_line_ref()} !~ /\G([^:\n]+): /cgms)
    {
        Carp::confess("Cannot match addressing at line " . $self->line_num());
    }

    my $sayer = $1;

    if ($sayer =~ m{[\[\]]})
    {
        Carp::confess("Tried to put an inner-desc inside an addressing at line " . $self->line_num());
    }    

    # All pluses
    if ($sayer =~ m{\A\++\z})
    {
        return { elem => $self->_new_para([]), para_end => 0 };
    }
    else
    {
        return { elem => $self->_new_saying($sayer, []), sayer => $sayer, para_end => 0};
    }
}

sub _parse_non_tag_text_unit
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    if ((pos($$l) == 0) && ($$l =~ m{\A[^\[<][^:]*:}))
    {
        return $self->_parse_speech_unit();
    }

    my $text = $self->consume_up_to(qr{(?:[\<\[\]\&]|^\n?$)}ms);

    $l = $self->curr_line_ref();

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

sub _generate_text_unit_events
{
    my $self = shift;
    
    # $self->skip_multiline_space();

    my $l = $self->curr_line_ref();
    if ($$l =~ m{\G[<\[\]\&]})
    {
        # If it's a tag.

        # TODO : implement the comment handling.
        # We have a tag.

        # If it's an entity, then parse it.
        if ($$l =~ m{\G\&})
        {
            if ($$l !~ m{\G(\&\w+;)}g)
            {
                Carp::confess("Cannot match entity (e.g: \"&quot;\") at line " .
                    $self->line_num()
                );
            }

            my $entity = $1;

            $self->_enqueue_event(
                {
                    type => "elem",
                    elem => $self->_new_text(
                        [HTML::Entities::decode_entities($entity)]
                    ),
                },
            );

            return;
        }
        # If it's a closing tag - then backtrack.
        if ($$l =~ m{\G(</|\])})
        {
            $self->_enqueue_event({'type' => "close"});
            return;
        }
        else
        {
            $self->_enqueue_event({'type' => "open"});
            return;
        }
    }
    else
    {

        my $status = $self->_parse_non_tag_text_unit();

        if (!defined($status))
        {
            return;
        }

        my $elem = $status->{'elem'};
        my $is_para_end = $status->{'para_end'};
        my $is_saying = $elem->isa("XML::Grammar::Screenplay::FromProto::Node::Saying");
        #my $is_para =
        #    (($self->curr_pos() == 0) && 
        #     (${$self->curr_line_ref()} =~ m{\G\n?\z})
        #    );
        # Trying out this one:
        my $is_para = $elem->isa("XML::Grammar::Screenplay::FromProto::Node::Paragraph");

        my $in_para = $self->_in_para();
        my $was_already_enqueued = 0;

        if ( ($is_saying || $is_para) && $in_para)
        {
            $self->_enqueue_event({type => "close", tag => "para"});
            $in_para = 0;
        }
        
        if ( $is_saying && $self->_in_saying())
        {
            $self->_enqueue_event({type => "close", tag => "saying"});
        }

        if ($is_saying)
        {
            $self->_enqueue_event(
                {type => "open", tag => "saying", _elem => $elem, },
            );
            $was_already_enqueued = 1;

            $self->_enqueue_event({type => "open", tag => "para"});
            $in_para = 1;
        }
        elsif ($is_para && !$in_para)
        {
            $self->_enqueue_event({type => "open", tag => "para"});
            $in_para = 1;
        }

        if ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::Text") &&
            !$was_already_enqueued)
        {
            if (!$in_para)
            {
                $self->_enqueue_event({type => "open", tag => "para"});
                $in_para = 1;
            }
            $self->_enqueue_event({type => "elem", elem => $elem, });
            $was_already_enqueued = 1;
        }

        if ($is_para_end && $in_para)
        {
            # $self->_enqueue_event({ type => "close", tag => "para" });
            $in_para = 0;
        }

        return;
    }
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

    if (@{$self->_tags_stack()})
    {
        $self->_add_to_top_tag($new_elem);
        return;
    }
    else
    {
        return $new_elem;
    }
}

sub _close_saying
{
    my $self = shift;
    my $open = $self->_pop_tag();

    # This is an assert.
    if ($open->name() ne "saying")
    {
        Carp::confess (qq{Not a saying tag.});    
    }
    
    my $new_elem =
        $self->_new_saying(
            (List::Util::first
                { $_->{key} eq "character"}
                @{$open->attrs()}
            )->{value},
            $open->detach_children(),
        );

    $self->_add_to_top_tag($new_elem);

    return;
}

sub _close_para
{
    my $self = shift;
    my $open = $self->_pop_tag();

    # This is an assert.
    if ($open->name() ne "p")
    {
        Carp::confess (qq{Not a para tag.});    
    }

    my $children = $open->detach_children();

    # Filter away empty paragraphs.
    if (defined($children) && @$children)
    {
        my $new_elem =
            $self->_new_para(
                $children
            );

        $self->_add_to_top_tag($new_elem);
    }

    $self->_in_para(0);

    return;
}

sub _start_para
{
    my $self = shift;

    my $new_elem = 
    XML::Grammar::Screenplay::Struct::Tag::Para->new(
        name => "p",
        is_standalone => 0,
        line => $self->line_num(),
        attrs => [],
    );

    $new_elem->children([]);

    $self->_push_tag($new_elem);

    $self->_in_para(1);

    return;
}

sub _close_top_tags
{
    my $self = shift;

    if ($self->_top_is_para())
    {
        $self->_close_para();
    }

    if ($self->_top_is_saying())
    {
        $self->_close_saying();
    }

    return;
}

sub _handle_event
{
    my ($self, $event) = @_;

    if ($self->_is_event_a_para($event))
    {
        if ($event->{'type'} eq "open")
        {
            $self->_start_para();
        }
        else
        {
            $self->_close_para();
        }
    }
    elsif (  exists($event->{'tag'})
        && $event->{'tag'} eq "saying"
    )
    {
        if ($event->{'type'} eq "open")
        {
            my $new_tag =
                XML::Grammar::Screenplay::Struct::Tag->new(
                    {
                        name => "saying",
                        is_standalone => 0,
                        # TODO : propagate the correct line_num
                        # from the called-to layers.
                        line => $self->line_num(),
                        attrs => [{key => "character", value => $event->{_elem}->character()}],
                    }
                );

            $new_tag->children([]);

            $self->_push_tag($new_tag);

            $self->_in_saying(1);
        }
        else
        {
            $self->_close_saying();
        }
    }
    elsif ($event->{'type'} eq "elem")
    {
        $self->_add_to_top_tag( $event->{'elem'} );
    }

    return;
}

sub _parse_all
{
    my $self = shift;

    # $self->skip_multiline_space();

    $self->_in_para(0);

    my $run_once = 1;

    my $ret_tag;


    TAGS_LOOP:
    while ($run_once || @{$self->_tags_stack()})
    {
        $run_once = 0;

        # This is an assert.
        if (!defined(${$self->curr_line_ref()}) && (! @{$self->_events_queue()}))
        {
            Carp::confess (qq{Reached EOF.});
        }
        

        if ($self->curr_line_continues_with(qr{<!--}))
        {
            my $text = $self->consume_up_to(qr{-->});

            $self->_add_to_top_tag( $self->_new_comment($text) );
            redo TAGS_LOOP;
        }


        my ($l, $p) = $self->curr_line_and_pos();

        if ($$l eq "\n")
        {
            if ($self->_top_is_para())
            {
                $self->_close_para();
            }
            $self->next_line_ref();
            next TAGS_LOOP;
        }
        
        if ($$l =~ m{\G([ \t]+)\n?\z})
        {
            if (length($1))
            {
                $self->_add_to_top_tag( $self->_new_text([" "]) );
            }

            $self->next_line_ref();

            next TAGS_LOOP;            
        }
        
        my $is_tag_cond = ($$l =~ m{\G([<\[\]])});

        my $is_close = $is_tag_cond && ($$l =~ m{\G(?:</|\])});

        # Check if it's a closing tag.
        if ($is_close)
        {
            $self->_close_top_tags();

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

            if (defined(my $top_elem = $self->_merge_tag($open)))
            {
                $ret_tag = $top_elem;
                last TAGS_LOOP;
            }
            else
            {
                redo TAGS_LOOP;
            }
        }
        elsif ($is_tag_cond)
        {
            my $open = $self->_parse_opening_tag();

            $open->children([]);

            # TODO : add the check for is_standalone in XML-Grammar-Fiction
            # too.
            if ($open->is_standalone())
            {
                if (defined(my $top_elem = $self->_merge_tag($open)))
                {
                    $ret_tag = $top_elem;
                    last TAGS_LOOP;
                }
                else
                {
                    redo TAGS_LOOP;
                }
            }
            $self->_push_tag($open);

            if ($open->name() eq "desc")
            {
                $self->_start_para();
            }
        }
        else
        {
            $self->_handle_non_tag_text();
        }
    }

    return $ret_tag;
}

=head1 NAME

XML::Grammar::Screenplay::FromProto::Parser::QnD - Quick and Dirty parser
for the Screenplay-XML proto-text.

B<For internal use only>.

=head1 METHODS

=head2 $self->process_text($string)

Processes the text and returns the parse tree.

=head2 $self->meta()

Leftover from Moose.

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

