use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use XML::Grammar::Builder;

my $builder = XML::Grammar::Builder->new(
    module_name         => 'XML::Grammar::Screenplay',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/XML/Grammar/Screenplay.pm',
    build_requires => {
        'File::Find' => 0,
        'Test::More' => 0,
        'Test::XML' => 0,
    },
    requires => 
    {
        'Carp' => 0,
        'Data::Dumper' => 0,
        'HTML::Entities' => 0,
        'List::Util' => 0,
        'Moose' => 0,
        'Parse::RecDescent' => 0,
        'warnings' => 0,
        'XML::LibXSLT' => 0,
        'XML::Writer' => 0,
    },
    add_to_cleanup      => [ 'XML-Grammar-Screenplay-*' ],
    create_makefile_pl => 'passthrough',
    meta_merge =>
    {
        resources =>
        {
            repository => "https://svn.berlios.de/svnroot/repos/web-cpan/XML-Grammar-Screenplay/",
            homepage => "http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/",
        },
        keywords =>
        [
            "authoring",
            "cinema",
            "creative writing",
            "films",
            "grammar",
            "movies",
            "parsing",
            "screenplay",
            "screenplays",
            "script",
            "scripts",
            "writing",
            "xml",
            "xml-libxml",
            "xslt",
        ],
    },
);

$builder->create_build_script();
