package XML::Grammar::FictionBase::Event;

=head1 NAME

XML::Grammar::FictionBase::Event - a parser event.

B<For internal use only>.

=cut

use MooX 'late';

use XML::Grammar::Fiction::FromProto::Nodes;

has 'type' => (isa => "Str", is => "ro");
has 'tag' => (isa => "Maybe[Str]", is => "ro", predicate => '_has_tag',);
has 'elem' => (isa => "Maybe[XML::Grammar::Fiction::FromProto::Node]", is => "ro");
has 'tag_elem' => (isa => "Maybe[XML::Grammar::Fiction::FromProto::Node]", is => "ro");

sub is_tag_of_name
{
    my ($self, $name) = @_;

    return ($self->_has_tag() && ($self->tag() eq $name));
}

sub is_open
{
    my $self = shift;

    return ($self->type() eq "open");
}

sub is_open_or_close
{
    my $self = shift;

    return (($self->type() eq "open") || ($self->type() eq "close"));
}

1;

=head1 SLOTS

=head2 $event->elem()

The DOM (Document Object Model) element that the event refers to. See
L<XML::Grammar::Fiction::FromProto::Node> .

=head2 $event->tag_elem()

Extra tag_elem.

=head2 $event->type()

A string specifying the type.

=head2 tag

An optional string (or undef) with the tag name.

=head1 METHODS

=head2 $event->is_tag_of_name($name)

Determines if the $event is a tag and of name $name.

=head2 $event->is_open()

Returns true if the $event 's type is "open".

=head2 $event->is_open_or_close()

Returns true if the $event 's type is either "open" or "close".

=head2 $self->meta()

Leftover from Mouse.

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

