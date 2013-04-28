package XML::Grammar::Screenplay::XSLT::Base;

use MooX 'late';

our $VERSION = '0.14.0';

extends('XML::Grammar::FictionBase::XSLT::Converter');

has '+rng_schema_basename' => (default => "screenplay-xml.rng");

1;

__END__

=head1 NAME

XML::Grammar::Screenplay::XSLT::Base - base module for XML::Grammar::Screenplay
XSLT conversions.

=head1 VERSION

Version 0.14.0

=head1 METHODS

=head2 rng_schema_basename()

Inherited - (to settle pod-coverage).

=cut
