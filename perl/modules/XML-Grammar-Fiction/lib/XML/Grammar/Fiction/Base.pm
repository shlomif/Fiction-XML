package XML::Grammar::Fiction::Base;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Fiction::Base - base class for XML::Grammar::Fiction
classes.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

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

