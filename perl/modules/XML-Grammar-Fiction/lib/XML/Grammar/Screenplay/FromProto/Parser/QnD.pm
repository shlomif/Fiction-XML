package XML::Grammar::Screenplay::FromProto::Parser::QnD;

use strict;
use warnings;

use MooX 'late';

extends( 'XML::Grammar::FictionBase::FromProto::Parser::XmlIterator' );

use XML::Grammar::Fiction::Struct::Tag;
use XML::Grammar::FictionBase::Event;

use List::Util ();
use List::MoreUtils ();

our $VERSION = '0.14.1';

has "_in_saying" => (isa => "Bool", is => "rw");
has "_prev_line_is_empty" => (isa => "Bool", is => "rw", default => 1);
has '_is_start' => (isa => 'Bool', is => 'rw');

before 'next_line_ref' => sub {
    my $self = shift;

    $self->_prev_line_is_empty(scalar(${$self->curr_line_ref()} =~ m{\A\s*\z}));

    return;
};

sub _top_is_para
{
    my $self = shift;

    return $self->_in_para() && ($self->_top_is('p'));
}


sub _top_is_saying
{
    my $self = shift;

    return $self->_in_saying() && ($self->_top_is('saying'));
}

sub _top_is
{
    my ($self, $want_name) = @_;

    return ($self->_top_tag->name eq $want_name);
}

sub _top_is_desc
{
    my $self = shift;

    return $self->_top_is('desc');
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

sub _create_closing_desc_tag {
    my $self = shift;

    return XML::Grammar::Fiction::Struct::Tag->new(
        name => $self->_get_desc_name(),
        line => $self->line_num(),
    );
}

sub _detect_closing_desc_tag
{
    my $self = shift;

    return (${ $self->curr_line_ref() } =~ m{\G\]}cg);
}

around '_parse_closing_tag' => sub {
    my ($orig, $self) = @_;

    return
        $self->_detect_closing_desc_tag
        ? $self->_create_closing_desc_tag
        : $self->$orig();
};

sub _detect_open_desc_tag
{
    my $self = shift;

    return (${ $self->curr_line_ref } =~ m{\G\[}cg);
}

sub _create_open_desc_tag
{
    my ($self) = @_;

    my $not_inline = 0;
    if ($self->_is_start && $self->_prev_line_is_empty())
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

sub _set_is_start
{
    my $self = shift;

    $self->_is_start($self->at_line_start);

    return;
}

around '_parse_opening_tag' => sub {
    my ($orig, $self) = @_;

    $self->_set_is_start;

    return
        $self->_detect_open_desc_tag
        ? $self->_create_open_desc_tag
        : $self->$orig();
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

sub _non_tag_text_unit_consume_regex
{
    return qr{(?:[\<\[\]]|^\n?$)}ms;
}

sub _is_there_a_speech_unit
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    return
    (
        $self->at_line_start()
        && (! $self->_top_is_desc())
        && ($$l =~ m{\A[^\[<][^:]*:})
    );
}

around '_parse_non_tag_text_unit' => sub {
    my ($orig, $self) = @_;

    return
    (
        $self->_is_there_a_speech_unit()
        ? $self->_parse_speech_unit()
        : $self->$orig()
    );
};

sub _look_for_tag_opener
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    if ($$l =~ m{\G([<\[\]])})
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

    return (${$self->curr_line_ref()} =~ m{\G(</|\])});
}

sub _generate_non_tag_text_event
{
    my $self = shift;
    my $status = $self->_parse_non_tag_text_unit();

    if (!defined($status))
    {
        return;
    }

    my $elem = $status->{'elem'};
    my $is_para_end = $status->{'para_end'};
    my $is_saying = $elem->isa("XML::Grammar::Fiction::FromProto::Node::Saying");
    my $is_para = $elem->isa("XML::Grammar::Fiction::FromProto::Node::Paragraph");

    my $in_para = $self->_in_para();
    my $was_already_enqueued = 0;

    if ( ($is_saying || $is_para) && $in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "close", tag => "para"}
            )
        );
        $in_para = 0;
    }

    if ( $is_saying && $self->_in_saying())
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "close", tag => "saying"}
            )
        );
    }

    if ($is_saying)
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "open", tag => "saying", tag_elem => $elem, },
            ),
        );
        $was_already_enqueued = 1;

        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "open", tag => "para"}
            )
        );
        $in_para = 1;
    }
    elsif ($is_para && !$in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "open", tag => "para"}
            ),
        );
        $in_para = 1;
    }

    if ($elem->isa("XML::Grammar::Fiction::FromProto::Node::Text") &&
        !$was_already_enqueued)
    {
        if (!$in_para)
        {
            $self->_enqueue_event(
                XML::Grammar::FictionBase::Event->new(
                    {type => "open", tag => "para"},
                )
            );
            $in_para = 1;
        }
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "elem", elem => $elem, }
            )
        );
        $was_already_enqueued = 1;
    }

    return;
}

sub _handle_close_saying
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

sub _assert_top_is_para
{
    my ($self, $open) = @_;

    if ($open->name() ne "p")
    {
        Carp::confess (qq{Not a para tag.});
    }

    return;
}

sub _process_closed_para
{
    my ($self, $open) = @_;

    my $children = $open->detach_children();

    # Filter away empty paragraphs.
    if (defined($children) && @$children)
    {
        $self->_add_to_top_tag(
            $self->_new_para(
                $children
            )
        );
    }

    return;
}

sub _close_para
{
    my $self = shift;

    my $open = $self->_pop_tag();

    $self->_assert_top_is_para($open);

    $self->_process_closed_para($open);

    $self->_in_para(0);

    return;
}

sub _create_start_para
{
    my $self = shift;

    return
        XML::Grammar::Fiction::Struct::Tag::Para->new(
            name => "p",
            is_standalone => 0,
            line => $self->line_num(),
            attrs => [],
            children => [],
        );
}

sub _start_para
{
    my $self = shift;

    $self->_push_tag($self->_create_start_para());

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
        $self->_handle_close_saying();
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

sub _create_open_saying_tag
{
    my $self = shift;
    my $event = shift;

    return
        XML::Grammar::Fiction::Struct::Tag->new(
            {
                name => "saying",
                is_standalone => 0,
                # TODO : propagate the correct line_num
                # from the called-to layers.
                line => $self->line_num(),
                attrs => [{key => "character", value => $event->tag_elem->character()}],
                children => [],
            }
        );
}

sub _handle_open_saying
{
    my ($self, $event) = @_;

    $self->_push_tag($self->_create_open_saying_tag($event));

    $self->_in_saying(1);

    return;
}

sub _handle_saying_event
{
    my ($self, $event) = @_;

    return
        $event->is_open()
        ? $self->_handle_open_saying($event)
        : $self->_handle_close_saying();
}

sub _list_valid_tag_events
{
    return [qw(para saying)];
}

after '_handle_open_tag' => sub {
    my $self = shift;

    if ($self->_top_is_desc)
    {
        $self->_start_para();
    }

    return;
};

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

sub _main_loop_iter_on_empty_line
{
    my $self = shift;

    if ($self->_top_is_para())
    {
        $self->_close_para();
    }

    $self->next_line_ref();

    return;
}

sub _main_loop_iter_on_whitepsace
{
    my $self = shift;

    $self->_add_to_top_tag( $self->_new_text([" "]) );

    $self->next_line_ref();

    return;
}

sub _main_loop_iter_body_prelude
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    return
    (
        ($$l eq "\n")
        ? $self->_main_loop_iter_on_empty_line
        : ($$l =~ m{\G[ \t]+\n?\z})
        ? $self->_main_loop_iter_on_whitepsace
        : 1
    );
}


=head1 NAME

XML::Grammar::Screenplay::FromProto::Parser::QnD - Quick and Dirty parser
for the Screenplay-XML proto-text.

B<For internal use only>.

=head1 VERSION

0.11.0

=head1 METHODS

=head2 $self->process_text($string)

Processes the text and returns the parse tree.

=head2 $self->meta()

Leftover from Moo.

=head2 $self->next_line_ref

Leftover from Moo.

=cut

1;

