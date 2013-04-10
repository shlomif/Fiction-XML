package XML::Grammar::Screenplay;

use strict;
use warnings;

=head1 DEBUGGING

When trying to convert the well-formed text to XML, one will often
encounter an obscure "Parse Error". This is caused by L<Parse::RecDescent>,
which is used for parsing. The best way I found to deal with it is to
gradually eliminate parts of the document until the offending markup is
isolated.

In the future, I plan on writing a custom parser that will provide better
diagnostics and will hopefully also be faster.

=cut

