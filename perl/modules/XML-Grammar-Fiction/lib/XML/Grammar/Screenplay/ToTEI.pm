package XML::Grammar::Screenplay::ToTEI;

use strict;
use warnings;

use MooX 'late';

extends('XML::Grammar::Screenplay::XSLT::Base');

has '+xslt_transform_basename' => (default => "screenplay-xml-to-tei.xslt");

=head1 NAME

XML::Grammar::Screenplay::ToTEI - module that converts the Screenplay
XML to TEI (Text Encoding Initiative).

=head1 VERSION

Version 0.12.0

=cut

our $VERSION = '0.12.0';

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage).

=head2 xslt_transform_basename()

Inherited - (to settle pod-coverage).

=head2 $converter->translate_to_tei({source => {file => $filename}, output => "string" })

Does the actual conversion. $filename is the filename to translate (currently
the only available source).

The C<'output'> key specifies the return value. A value of C<'string'> returns
the XML as a string, and a value of C<'xml'> returns the XML as an
L<XML::LibXML> DOM object.

=cut

sub translate_to_tei
{
    my ($self, $args) = @_;

    return $self->perform_translation($args);
}

1;

