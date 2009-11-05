package XML::Grammar::Fiction::FromProto::Parser::PRD;

use strict;
use warnings;

use base 'XML::Grammar::Fiction::FromProto::Parser';

use Parse::RecDescent;

use Moose;

use XML::Grammar::Fiction::FromProto::Nodes;

has "_p_rd" => ('isa' => "Parse::RecDescent", is => "rw");

sub _init
{
    my $self = shift;

    $self->_p_rd(Parse::RecDescent->new($self->_calc_grammar()));

    return 0;
}

sub _calc_grammar
{
    my $self = shift;

    return <<'EOF';

start : tag  {$thisparser->{ret} = $item[1]; 1 }

text_unit:   tag_or_comment { $item[1] }
           | speech_or_desc { $item[1] }

tag_or_comment:   tag
                | comment

comment:    /<!--(.*?)-->/ms para_sep {
    XML::Grammar::Fiction::FromProto::Node::Comment->new(
        text => $1
    )
    }

para_sep:      /(\n\s*)+/

speech_or_desc:   speech_unit
                | desc_unit

plain_inner_text:  /([^\n<\[\]&]+\n?)+/ { $item[1] }

inner_standalone_tag: /</ id attribute(s?) / *\/ *>/ space
    {
        XML::Grammar::Fiction::FromProto::Node::Element->new(
            name => $item[2],
            children => XML::Grammar::Fiction::FromProto::Node::List->new(
                contents => []
            ),
            attrs => $item[3]
            );
    }


inner_tag:         opening_tag  inner_text closing_tag {
        my ($open, $inside, $close) = @item[1..$#item];
        if ($open->{name} ne $close->{name})
        {
            Carp::confess("Tags do not match: $open->{name} and $close->{name}");
        }
        XML::Grammar::Fiction::FromProto::Node::Element->new(
            name => $open->{name},
            children => XML::Grammar::Fiction::FromProto::Node::List->new(
                contents => $inside
                ),
            attrs => $open->{attrs},
            )
    }

inner_desc:      /\[/ inner_text /\]/ {
        my $inside = $item[2];
        XML::Grammar::Fiction::FromProto::Node::InnerDesc->new(
            children => XML::Grammar::Fiction::FromProto::Node::List->new(
                contents => $inside
                ),
            )
    }

inner_tag_or_desc:    inner_tag
                   |  inner_desc

inner_entity:      /\&\w+;/ {
        my $inside = $item[1];
        HTML::Entities::decode_entities($inside)
    }

inner_text_unit:    plain_inner_text  { [ $item[1] ] }
                 |  inner_tag_or_desc { [ $item[1] ] }
                 |  inner_entity      { [ $item[1] ] }
                 |  inner_standalone_tag { [ $item[1] ] }

inner_text:       inner_text_unit(s) {
        [ map { @{$_} } @{$item[1]} ]
        }

addressing: /^([^:\n\+]+): /ms { $1 }

saying_first_para: addressing inner_text para_sep {
            my ($sayer, $what) = ($item[1], $item[2]);
            +{
             character => $sayer,
             para => XML::Grammar::Fiction::FromProto::Node::Paragraph->new(
                children =>
                XML::Grammar::Fiction::FromProto::Node::List->new(
                    contents => $what,
                    )
                ),
            }
            }

saying_other_para: /^\++: /ms inner_text para_sep {
        XML::Grammar::Fiction::FromProto::Node::Paragraph->new(
            children =>
                XML::Grammar::Fiction::FromProto::Node::List->new(
                    contents => $item[2],
                    ),
        )
    }

speech_unit:  saying_first_para saying_other_para(s?)
    {
    my $first = $item[1];
    my $others = $item[2] || [];
        XML::Grammar::Fiction::FromProto::Node::Saying->new(
            character => $first->{character},
            children => XML::Grammar::Fiction::FromProto::Node::List->new(
                contents => [ $first->{para}, @{$others} ],
                ),
        )
    }

desc_para:  inner_text para_sep { $item[1] }

desc_unit_inner: desc_para(s?) inner_text { [ @{$item[1]}, $item[2] ] }

desc_unit: /^\[/ms desc_unit_inner /\]\s*$/ms para_sep {
        my $paragraphs = $item[2];

        XML::Grammar::Fiction::FromProto::Node::Description->new(
            children => 
                XML::Grammar::Fiction::FromProto::Node::List->new(
                    contents =>
                [
                map { 
                XML::Grammar::Fiction::FromProto::Node::Paragraph->new(
                    children =>
                        XML::Grammar::Fiction::FromProto::Node::List->new(
                            contents => $_,
                            ),
                        )
                } @$paragraphs
                ],
            ),
        )
    }

text: text_unit(s) { XML::Grammar::Fiction::FromProto::Node::List->new(
        contents => $item[1]
        ) }
      | space { XML::Grammar::Fiction::FromProto::Node::List->new(
        contents => []
        ) }

tag: space opening_tag space text space closing_tag space
     {
        my (undef, $open, undef, $inside, undef, $close) = @item[1..$#item];
        if ($open->{name} ne $close->{name})
        {
            Carp::confess("Tags do not match: $open->{name} and $close->{name}");
        }
        XML::Grammar::Fiction::FromProto::Node::Element->new(
            name => $open->{name},
            children => $inside,
            attrs => $open->{attrs},
            );
     }

opening_tag: '<' id attribute(s?) '>'
    { $item[0] = { 'name' => $item[2], 'attrs' => $item[3] }; }

closing_tag: '</' id '>'
    { $item[0] = { 'name' => $item[2], }; }

attribute: space id '="' attributevalue '"' space
    { $item[0] = { 'key' => $item[2] , 'value' => $item[4] }; }

attributevalue: /[^"]+/
    { $item[0] = HTML::Entities::decode_entities($item[1]); }

space: /\s*/

id: /[a-zA-Z_\-]+/

EOF
}

sub process_text
{   
    my ($self, $text) = @_;

    my $rv = $self->_p_rd()->start($text);

    if (!defined($rv))
    {
        return;
    }
    else
    {
        return $self->_p_rd->{ret};
    }
}

1;


=head1 NAME

XML::Grammar::Fiction::FromProto::Parser - base class for parsers of the
ScreenplayXML proto-text.

B<For internal use only>.

=head1 METHODS

=head2 $self->process_text($string)

Processes the text and returns it.

=head2 $self->meta()

Something that L<Moose> adds.

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
