package XML::Grammar::Screenplay::Base;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Screenplay::Base - base class for XML::Grammar::Screenplay
classes.

=head1 METHODS

=head2 $package->new({%args});

Constructs a new package

=cut

sub new
{
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->_init(@_);

    return $self;
}

1;

