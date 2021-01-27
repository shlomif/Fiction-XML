package rejects::Fiction_FromProto;

use strict;
use warnings;

=begin foo

    my $title =
        first
        { $_->name() eq "title" }
        @{$body->_get_childs()}
        ;

    my @t =
    (
          defined($title)
        ? (title => $title->_first())
        : ()
    );

=end foo

=cut
