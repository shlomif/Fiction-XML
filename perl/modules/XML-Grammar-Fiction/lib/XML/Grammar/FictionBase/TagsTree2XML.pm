package XML::Grammar::FictionBase::TagsTree2XML;

use Moose;

use XML::Writer;
use HTML::Entities ();

use XML::Grammar::Fiction::FromProto::Nodes;


=head1 NAME

XML::Grammar::FictionBase::TagsTree2XML - base class for the tags-tree
to XML converters.

=head1 VERSION

Version 0.0.4

=cut

has '_parser_class' =>
(
    is => "ro",
    isa => "Str",
    init_arg => "parser_class",
    default => "XML::Grammar::Fiction::FromProto::Parser::QnD",
);

has "_parser" => (
    'isa' => "XML::Grammar::Fiction::FromProto::Parser", 
    'is' => "rw",
    lazy => 1,
    default => sub { 
        my $self = shift; 
        return $self->_parser_class->new();
    },
);

has "_writer" => ('isa' => "XML::Writer", 'is' => "rw");

has '_buffer' => ('isa' => "ScalarRef[Str]", is => "rw");


=head2 meta()

Internal - (to settle pod-coverage.).

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

Copyright 2010, Shlomi Fish.

This program is released under the following license: MIT X11.

=cut

1;

