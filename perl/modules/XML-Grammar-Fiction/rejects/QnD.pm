package rejects::QnD;

use strict;
use warnings;

# TODO : _parse_saying_first_para and _parse_saying_other_para are
# very similar - abstract them into one function.
sub _parse_saying_first_para
{
    my $self = shift;

    my ($sayer, $what);
    
    ($sayer) = $self->_with_curr_line(
        sub {
            my $l = shift;

            if ($$l !~ /\G([^:\n\+]+): /cgms)
            {
                Carp::confess("Cannot match addressing at line " . $self->_get_line_num());
            }
            my $sayer = $1;

            if ($sayer =~ m{[\[\]]})
            {
                Carp::confess("Tried to put an inner-desc inside an addressing at line " . $self->_get_line_num());
            }

            return ($sayer);
        }
    );

    $what = $self->_parse_inner_text();

    return
    +{
         character => $sayer,
         para => $self->_new_para($what),
    };
}

sub _parse_saying_other_para
{
    my $self = shift;

    $self->_skip_space();

    my $verdict = $self->_with_curr_line(
        sub {
            my $l = shift;

            if ($$l !~ /\G\++: /cgms)
            {
                return;
            }
            else
            {
                return 1;
            }
        }
    );

    if (!defined($verdict))
    {
        return;
    }

    my $what = $self->_parse_inner_text();

    return $self->_new_para($what);
}

sub _parse_speech_unit
{
    my $self = shift;

    my $first = $self->_parse_saying_first_para();

    my @others;
    while (defined(my $other_para = $self->_parse_saying_other_para()))
    {
        push @others, $other_para;
    }

    return
        $self->_new_node({
                t => "Saying",
                character => $first->{character},
                children => 
                    $self->_new_list([ $first->{para}, @others ]),
        });
}

sub _parse_desc_unit
{
    my $self = shift;

    my $start_line = $self->_curr_line_idx();

    # Skip the [
    $self->_with_curr_line(
        sub {
            my $l = shift;

            $$l =~ m{^\[}g;
        }
    );

    my @paragraphs;

    my $is_end = 1;
    my $para;
    PARAS_LOOP:
    while ($is_end && ($para = $self->_consume_paragraph()))
    {
        $self->_with_curr_line(
            sub {
                my $l = shift;

                if ($$l =~ m{\G\]}cg)
                {
                    $is_end = 0;
                }
            }
        );
        push @paragraphs, $para;
    }

    if ($is_end)
    {
        Carp::confess (
            qq{Description ("[ ... ]") that started on line }
            . ($start_line+1) . 
            qq{does not terminate anywhere.}
        );
    }

    return $self->_new_node({
            t => "Description",
            children => $self->_new_list(
            [
                map { 
                $self->_new_para($_),
                } @paragraphs
            ],),
    });
}

