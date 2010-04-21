package XML::Grammar::Screenplay::FromProto::Parser::QnD;

use strict;
use warnings;

use Moose;

extends( 'XML::Grammar::Fiction::FromProto::Parser::XmlIterator' );

use XML::Grammar::Fiction::FromProto::Nodes;
use XML::Grammar::Fiction::Struct::Tag;

use List::Util ();
use List::MoreUtils ();

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

around '_parse_closing_tag' => sub {
    my ($orig, $self) = @_;

    my $l = $self->curr_line_ref();

    if ($$l =~ m{\G\]}cg)
    {
        return XML::Grammar::Fiction::Struct::Tag->new(
            name => $self->_get_desc_name(),
            line => $self->line_num(),
        );
    }
    else
    {
        return $self->$orig();
    }
};

around '_parse_opening_tag' => sub {
    my ($orig, $self) = @_;

    my $l = $self->curr_line_ref();

    my $is_start = ($self->curr_pos() == 0);

    if ($$l =~ m{\G\[}cg)
    {
        my $not_inline = 0;
        if ($is_start && $self->_prev_line_is_empty())
        {
            $self->_close_top_tags();
            $not_inline = 1;
        }

        return XML::Grammar::Fiction::Struct::Tag->new(
            name => $not_inline ? "desc" : $self->_get_desc_name(),
            line => $self->line_num(),
            attrs => [],
        );
    }
    else
    {
        return $self->$orig();
    }
};

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
        my $is_saying = $elem->isa("XML::Grammar::Fiction::FromProto::Node::Saying");
        #my $is_para =
        #    (($self->curr_pos() == 0) && 
        #     (${$self->curr_line_ref()} =~ m{\G\n?\z})
        #    );
        # Trying out this one:
        my $is_para = $elem->isa("XML::Grammar::Fiction::FromProto::Node::Paragraph");

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

        if ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Text") &&
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

        return;
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
    XML::Grammar::Fiction::Struct::Tag::Para->new(
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

sub _handle_close_para
{
    my ($self, $event) = @_;

    return $self->_close_para();
}

sub _handle_open_para
{
    my ($self, $event) = @_;

    return $self->_start_para();
}

sub _open_saying
{
    my $self = shift;
    my $event = shift;

    my $new_tag =
        XML::Grammar::Fiction::Struct::Tag->new(
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

    return;
}

sub _handle_saying_event
{
    my ($self, $event) = @_;

    return
        $event->{'type'} eq "open"
        ? $self->_open_saying($event)
        : $self->_close_saying();
}

sub _handle_event
{
    my ($self, $event) = @_;

    if ($self->_is_event_a_para($event))
    {
        $self->_handle_paragraph_event($event);
    }
    elsif ($self->_is_event_a_saying($event))
    {
        $self->_handle_saying_event($event);
    }
    elsif ($self->_is_event_elem($event))
    {
        $self->_handle_elem_event($event);
    }

    return;
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

    if ($open->name() eq "desc")
    {
        $self->_start_para();
    }

    return;
}

before '_handle_close_tag' => sub { 
    my $self = shift;

    $self->_close_top_tags();
};

sub _look_ahead_for_tag
{
    my $self = shift;

    my $l = $self->curr_line_copy();

    my $is_tag_cond = ($$l =~ m{\G([<\[\]])});

    my $is_close = $is_tag_cond && ($$l =~ m{\G(?:</|\])});

    return ($is_tag_cond, $is_close);
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

    my ($l, $p) = $self->curr_line_and_pos();

    if ($$l eq "\n")
    {
        if ($self->_top_is_para())
        {
            $self->_close_para();
        }
        $self->next_line_ref();
        return;
    }
    
    if ($$l =~ m{\G([ \t]+)\n?\z})
    {
        if (length($1))
        {
            $self->_add_to_top_tag( $self->_new_text([" "]) );
        }

        $self->next_line_ref();

        return;
    }
    
    $self->_ret_tag(scalar($self->_look_for_and_handle_tag()));

    return;
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

