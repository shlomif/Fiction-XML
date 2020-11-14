use strict;
use warnings;

use utf8;

use Test::More tests => 1;

use XML::Grammar::FictionBase::FromProto::Parser::XmlIterator ();

{
    my $text = <<"EOF";
<s id="top" title="Quick&amp;Dirty">

</s>
EOF

    my $parser = XML::Grammar::FictionBase::FromProto::Parser::XmlIterator->new;

    $parser->setup_text($text);

    my $tag = $parser->_parse_opening_tag();

    # TEST
    is_deeply(
        [ grep { $_->{'key'} eq "title" } @{ $tag->attrs() } ],
        [ +{ key => 'title', value => "Quick&Dirty" } ],
        qq#handle SGML entities - "&amp;"#,
    )
}
