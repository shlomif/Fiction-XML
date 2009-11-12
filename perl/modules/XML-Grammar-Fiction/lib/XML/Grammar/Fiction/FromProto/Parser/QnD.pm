package XML::Grammar::Fiction::FromProto::Parser::QnD;

use strict;
use warnings;

use base 'XML::Grammar::Fiction::FromProto::Parser';

use Moose;

has "_curr_line_idx" => (isa => "Int", is => "rw");
has "_lines" => (isa => "ArrayRef", is => "rw");

use XML::Grammar::Fiction::FromProto::Nodes;

use XML::Grammar::Fiction::Struct::Tag;
use XML::Grammar::Fiction::Err;

=head1 NAME

XML::Grammar::Fiction::FromProto::Parser::QnD - Quick and Dirty parser
for the Fiction-XML proto-text.

B<For internal use only>.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

sub _curr_line :lvalue
{
    my $self = shift;

    return $self->_lines()->[$self->_curr_line_idx()];
}

sub _curr_line_ref
{
    my $self = shift;

    return \($self->_lines()->[$self->_curr_line_idx()]);
}

sub _curr_line_and_pos
{
    my $self = shift;

    my $l = $self->_curr_line_ref();

    return ($l, pos($$l));
}

sub _with_curr_line
{
    my ($self, $sub_ref) = @_;

    return $sub_ref->( $self->_curr_line_ref() );
}

sub _next_line_ref
{
    my $self = shift;

    $self->_curr_line_idx($self->_curr_line_idx()+1);

    return $self->_curr_line_ref();
}

sub _init
{
    my $self = shift;

    return 0;
}

sub _start
{
    my $self = shift;

    return $self->_parse_top_level_tag();
}

# Skip the whitespace.
sub _skip_space
{
    my $self = shift;

    $self->_consume(qr{\s});
}

my $id_regex = '[a-zA-Z_\-]+';


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
    my $children = shift || $self->_new_empty_list();

    return
        $self->_new_node(
            {
                t => "Element",
                name => $open->{name},
                children => $children,
                attrs => $open->{attrs},
            }
        );
}

sub _new_empty_list
{
    my $self = shift;
    return $self->_new_list([]);
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

sub _parse_opening_tag
{
    my $self = shift;

    my ($l, $p) = $self->_curr_line_and_pos();

    if ($$l !~ m{\G<($id_regex)}cg)
    {
        print "Before : " . substr($$l, 0, $p) . "\n";
        Carp::confess("Cannot match opening tag at line " . $self->_get_line_num());
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
                . $self->_get_line_num()
        );
    }
    
    return XML::Grammar::Fiction::Struct::Tag->new(
        name => $id,
        is_standalone => $is_standalone,
        line => $self->_get_line_num(),
        attrs => \@attrs,
    );
}

sub _get_line_num
{
    my $self = shift;

    return $self->_curr_line_idx()+1;
}

sub _parse_closing_tag
{
    my $self = shift;

    my $l = $self->_curr_line_ref();

    if ($$l !~ m{\G</($id_regex)>}g)
    {
        Carp::confess("Cannot match closing tag at line ". $self->_get_line_num());
    }

    return XML::Grammar::Fiction::Struct::Tag->new(
        name => $1,
        line => $self->_get_line_num(),
    )
}

sub _parse_text
{
    my $self = shift;

    my @ret;
    while (defined(my $unit = $self->_parse_text_unit()))
    {
        push @ret, $unit;
    }

    # If it's whitespace - return an empty list.
    if ((scalar(@ret) == 1) && (ref($ret[0]) eq "") && ($ret[0] !~ m{\S}))
    {
        return $self->_new_empty_list();
    }

    return $self->_new_list(\@ret);
}

sub _consume_paragraph
{
    my $self = shift;

    $self->_skip_space();

    return $self->_parse_inner_text();
}

sub _parse_inner_tag
{
    my $self = shift;

    my $open = $self->_parse_opening_tag();

    if ($open->{is_standalone})
    {
        $self->_skip_space();

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
    return $self->_create_elem($open);
}

sub _find_next_inner_text
{
    my $self = shift;

    my $which_tag;
    my $text = "";

    my $l = $self->_curr_line_ref();

    # Apparently, perl does not always returns true in this
    # case, so we need the defined($1) ? $1 : "" workaround.
    $$l =~ m{\G([^\<\[\]\&]*)}cgms;

    $text .= (defined($1) ? $1 : "");

    if ($$l =~ m{\G\&})
    {
        $which_tag = "entity";
    }                
    elsif ($$l =~ m{\G(?:</|\])})
    {
        $which_tag = "close";
    }
    elsif ($$l =~ m{\G<})
    {
        $which_tag = "open_tag";
    }

    return ($which_tag, $text);
}

sub _parse_inner_text
{
    my $self = shift;

    my @contents;

    my $start_line = $self->_curr_line_idx();

    my $curr_text = "";

    CONTENTS_LOOP:
    while ($self->_curr_line() ne "\n")
    {
        my ($which_tag, $text_to_append) = $self->_find_next_inner_text();

        $curr_text .= $text_to_append;

        push @contents, $curr_text;

        $curr_text = "";

        if (!defined($which_tag))
        {
            # Do nothing - a tag was not detected.
        }
        else
        {
            if ($which_tag eq "open_tag")
            {
                push @contents, $self->_parse_inner_tag();

                # Avoid skipping to the next line.
                # Gotta love teh Perl!
                redo CONTENTS_LOOP;
            }
            elsif ($which_tag eq "close")
            {
                last CONTENTS_LOOP;
            }
            elsif ($which_tag eq "entity")
            {
                my $l = $self->_curr_line_ref();

                if (my ($text) = ($$l =~ m{\G(\&\w+;)}g))
                {
                    push @contents, HTML::Entities::decode_entities($text);
                }
                else
                {
                    Carp::confess("Cannot match entity (e.g: \"&quot;\") at line " .
                        $self->_get_line_num()
                    );
                }

                redo CONTENTS_LOOP;
            }
        }
    }
    continue
    {
        if (!defined(${$self->_next_line_ref()}))
        {
            Carp::confess 
            (
                "End of file in an addressing paragraph starting at "
                . ($start_line+1)
            );
        }
    }

    if (length($curr_text) > 0)
    {
        push @contents, $curr_text;
    }

    return \@contents;
}

sub _parse_non_tag_text_unit
{
    my $self = shift;

    my $l = $self->_curr_line_ref();

    if (pos($$l) < length($$l))
    {
        my $text = $self->_consume_up_to(qr{(?:\<|^\n?$)}ms);

        $l = $self->_curr_line_ref();

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

        return
        {
            elem => $ret_elem,
            para_end => $is_para_end,
        };
    }
    else
    {
        Carp::confess ("Line " . $self->_get_line_num() . 
            " has leading whitespace."
            );
    }
}

sub _parse_text_unit
{
    my $self = shift;

    my $space = $self->_consume(qr{\s});

    my $l = $self->_curr_line_ref();
    my $orig_pos = pos($$l);

    if ($$l =~ m{\G<}cg)
    {
        # If it's a tag.

        # TODO : implement the comment handling.
        # We have a tag.

        my $is_closing_tag = ($$l =~ m{\G/}cg);
        pos($$l) = $orig_pos;

        # If it's a closing tag - then backtrack.
        if ($is_closing_tag)
        {
            return undef;
        }
        else
        {
            return $self->_parse_top_level_tag();
        }
    }
    else
    {
        my @ret;

        my $status;

        my $is_para = (pos($$l) == 0);

        PARSE_NON_TAG_TEXT_UNIT:
        while (my $status = $self->_parse_non_tag_text_unit())
        {
            my $elem = $status->{'elem'};
            my $is_para_end = $status->{'para_end'};

            push @ret, $elem;
            if ($is_para_end)
            {
                last PARSE_NON_TAG_TEXT_UNIT;
            }
            else
            {
                if (defined(my $text_unit = $self->_parse_text_unit()))
                {
                    push @ret, $text_unit;
                }
                else
                {
                    last PARSE_NON_TAG_TEXT_UNIT;
                }
            }
        }
        return
            $is_para 
            ? $self->_new_para(\@ret)
            : $self->_new_list(\@ret)
            ;
    }
}

sub _curr_line_matches
{
    my $self = shift;
    my $re = shift;

    my $l = $self->_curr_line_ref();

    return ($$l =~ $re);
}

sub _line_starts_with
{
    my ($self, $re) = @_;

    my $l = $self->_curr_line_ref();

    return $$l =~ m{\G$re}cg;
}

sub _parse_top_level_tag
{
    my $self = shift;

    $self->_skip_space();

    if ($self->_line_starts_with(qr{<!--}))
    {
        my $text = $self->_consume_up_to(qr{-->});

        return $self->_new_node({ t => "Comment", text => $text, });
    }

    my $open = $self->_parse_opening_tag();

    $self->_skip_space();

    my $inside = $self->_parse_text();

    $self->_skip_space();

    my $close = $self->_parse_closing_tag();

    $self->_skip_space();

    if ($open->name() ne $close->name())
    {
        XML::Grammar::Fiction::Err::Parse::TagsMismatch->throw(
            error => "Tags do not match",
            opening_tag => $open,
            closing_tag => $close,
        );
    }

    return $self->_create_elem($open, $inside);
}

sub _consume
{
    my ($self, $match_regex) = @_;

    my $return_value = "";
    my $l = $self->_curr_line_ref();

    while (defined($$l) && ($$l =~ m[\G(${match_regex}*)\z]cgms))
    {
        $return_value .= $$l;
    }
    continue
    {
        $l = $self->_next_line_ref();
    }

    if (defined($$l) && ($$l =~ m[\G(${match_regex}*)]cg))
    {
        $return_value .= $1;
    }

    return $return_value;
}

# TODO : copied and pasted from _consume - abstract
sub _consume_up_to
{
    my ($self, $match_regex) = @_;

    my $return_value = "";
    my $l = $self->_curr_line_ref();

    LINE_LOOP:
    while (defined($$l))
    {
        my $verdict = ($$l =~ m[\G(.*?)((?:${match_regex})|\z)]cgms);
        $return_value .= $1;
        
        # Find if it matched the regex.
        if (length($2) > 0)
        {
            last LINE_LOOP;
        }
    }
    continue
    {
        $l = $self->_next_line_ref();
    }

    return $return_value;
}

sub _setup_text
{
    my ($self, $text) = @_;

    # We include the lines trailing newlines for safety.
    # $self->_lines([$text =~ m{\A([^\n]*\n?)*\z}ms]);
    $self->_lines([split(/^/, $text)]);

    $self->_curr_line_idx(0);

    ${$self->_curr_line_ref()} =~ m{\A}g;

    return;
}

sub process_text
{   
    my ($self, $text) = @_;

    $self->_setup_text($text);

    return $self->_start();
}

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

