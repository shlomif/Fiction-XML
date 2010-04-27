package XML::Grammar::Fiction::FromProto::Parser::QnD;

use strict;
use warnings;

use Moose;

extends("XML::Grammar::Fiction::FromProto::Parser::XmlIterator");

use XML::Grammar::Fiction::FromProto::Nodes;

use XML::Grammar::Fiction::Struct::Tag;
use XML::Grammar::Fiction::Err;

=head1 NAME

XML::Grammar::Fiction::FromProto::Parser::QnD - Quick and Dirty parser
for the Fiction-XML proto-text.

B<For internal use only>.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

sub _non_tag_text_unit_consume_regex {
    return qr{(?:\<|^\n?$)}ms;
}

sub _generate_non_tag_text_event
{
    my $self = shift;

    my $is_para = ($self->curr_pos() == 0);

    my $status = $self->_parse_non_tag_text_unit();
    my $elem = $status->{'elem'};
    my $is_para_end = $status->{'para_end'};

    my $in_para = $self->_in_para();
    if ($is_para && !$in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::Fiction::Event->new(
               { type => "open", tag => "para", }
            ),
        );
        $in_para = 1;
    }

    $self->_enqueue_event(
        XML::Grammar::Fiction::Event->new(
            {type => "elem", elem => $elem}
        )
    );

    if ($is_para_end && $in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::Fiction::Event->new(
                { type => "close", tag => "para" }
            )
        );
        $in_para = 0;
    }

    return;
}

before '_generate_text_unit_events' => sub {
    my $self = shift;

    $self->skip_multiline_space() 
};

sub _handle_open_para
{
    my ($self, $event) = @_;

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

    $self->skip_space();

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

