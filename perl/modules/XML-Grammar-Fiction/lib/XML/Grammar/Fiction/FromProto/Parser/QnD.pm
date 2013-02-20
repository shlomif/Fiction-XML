package XML::Grammar::Fiction::FromProto::Parser::QnD;

use strict;
use warnings;

use MooX 'late';

extends("XML::Grammar::FictionBase::FromProto::Parser::XmlIterator");

use XML::Grammar::Fiction::FromProto::Nodes;

use XML::Grammar::Fiction::Struct::Tag;
use XML::Grammar::Fiction::Err;
use XML::Grammar::FictionBase::Event;

=head1 NAME

XML::Grammar::Fiction::FromProto::Parser::QnD - Quick and Dirty parser
for the Fiction-XML proto-text.

B<For internal use only>.

=head1 VERSION

Version 0.11.1

=cut

our $VERSION = '0.11.1';

sub _non_tag_text_unit_consume_regex {
    return qr{(?:[\<]|^\n?$)}ms;
}

sub _generate_non_tag_text_event
{
    my $self = shift;

    my $is_para = $self->at_line_start;

    my $status = $self->_parse_non_tag_text_unit();

    if (!defined($status))
    {
        return;
    }

    my $elem = $status->{'elem'};
    my $is_para_end = $status->{'para_end'};

    my $in_para = $self->_in_para();
    if ($is_para && !$in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
               { type => "open", tag => "para", }
            ),
        );
        $in_para = 1;
    }

    if (my ($rest) = $elem->get_text() =~ m{\A\+(.*)}ms)
    {
        if ( length($rest) )
        {
            $self->throw_text_error(
                'XML::Grammar::Fiction::Err::Parse::ParaOpenPlusNotFollowedByTag',
                "Got a paragraph opening plus sign not followed by a tag.",
            );
        }
        # Else - do nothing - just ignore the + sign before the
        # style tag.
    }
    else
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "elem", elem => $elem}
            )
        );
    }

    if ($is_para_end && $in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                { type => "close", tag => "para" }
            )
        );
        $in_para = 0;
    }

    return;
}

before '_generate_text_unit_events' => sub {
    my $self = shift;

    $self->skip_multiline_space();

    return;
};

sub _calc_open_para
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

sub _handle_open_para
{
    my ($self, $event) = @_;

    $self->_push_tag($self->_calc_open_para());

    $self->_in_para(1);

    return;
}

sub _handle_close_para
{
    my ($self, $event) = @_;

    my $open = $self->_pop_tag;

    my $new_elem =
        $self->_new_para(
            $open->detach_children(),
        );

    $self->_add_to_top_tag($new_elem);

    $self->_in_para(0);

    return;
}

sub _list_valid_tag_events
{
    return [qw(para)];
}

before '_handle_close_tag' => sub {
    my $self = shift;

    $self->skip_space();
};

sub _look_ahead_for_tag
{
    my $self = shift;

    my $l = $self->curr_line_copy();

    my $is_tag_cond = ($$l =~ m{\G<}cg);
    my $is_close = $is_tag_cond && ($$l =~ m{\G/}cg);

    return ($is_tag_cond, $is_close);
}

sub _main_loop_iter_body_prelude
{
    my $self = shift;

    # $self->skip_space();

    return 1;
}

before '_parse_all' => sub {
    my $self = shift;

    $self->skip_space();

    return;
};

=head1 METHODS

=head2 $self->process_text($string)

Processes the text and returns the parse tree.

=head2 $self->meta()

Leftover from Moo.

=cut

1;

