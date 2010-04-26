use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use XML::Grammar::Fiction::Builder;

my $builder = XML::Grammar::Fiction::Builder->new(
    module_name         => 'XML::Grammar::Fiction',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/XML/Grammar/Fiction.pm',
    build_requires => {
        'Config' => 0,
        'File::Find' => 0,
        'File::Spec' => 0,
        'strict' => 0,
        'Test::More' => 0,
        'Test::XML' => 0,
        'warnings' => 0,
        'XML::LibXML' => 0,
    },
    requires => 
    {
        'Carp' => 0,
        'Data::Dumper' => 0,
        'Exception::Class' => 0,
        'Getopt::Long' => 0,
        'HTML::Entities' => 0,
        'List::Util' => 0,
        'Moose' => 0,
        'Parse::RecDescent' => 0,
        'strict' => 0,
        'warnings' => 0,
        'XML::LibXML' => 0,
        'XML::LibXSLT' => 0,
        'XML::Writer' => 0,
    },
    add_to_cleanup      => [ 'XML-Grammar-Fiction-*' ],
    create_makefile_pl => 'passthrough',
    meta_merge =>
    {
        resources =>
        {
            repository => "https://svn.berlios.de/svnroot/repos/web-cpan/XML-Grammar-Fiction/",
            homepage => "http://web-cpan.berlios.de/modules/XML-Grammar-Fiction/",
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
            "fiction",
            "story",
            "stories",
            "noveilla",
            "noveillas",
            "novels",
            "novel",
            "writing",
            "xml",
            "xml-libxml",
            "xslt",
        ],
    },
    # In order to run the screenplay tests.
    test_files => "t/*.t t/*/*.t",
);

$builder->create_build_script();
