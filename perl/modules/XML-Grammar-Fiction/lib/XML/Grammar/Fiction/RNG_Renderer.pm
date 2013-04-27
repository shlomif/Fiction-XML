package XML::Grammar::Fiction::RNG_Renderer;

use strict;
use warnings;

our $VERSION = '0.12.5';

=head1 XML::Grammar::Fiction::RNG_Renderer

The base class for the Fiction-XML renderer with the common RNG.

=head1 VERSION

0.11.0

=head1 SYNOPSIS

For internal use.

=cut

use MooX 'late';

extends ("XML::Grammar::FictionBase::XSLT::Converter");

has '+rng_schema_basename' => (default => "fiction-xml.rng");

=head1 METHODS

=head2 rng_schema_basename()

Inherited - (to settle pod-coverage).

=cut

1;

