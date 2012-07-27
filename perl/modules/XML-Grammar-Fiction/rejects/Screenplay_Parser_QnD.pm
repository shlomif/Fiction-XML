package rejects::Screenplay_Parser_QnD;

use strict;
use warnings;

sub _parse_inner_tag
{
    my $self = shift;

    my $open = $self->_parse_opening_tag();

    if ($open->is_standalone())
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

