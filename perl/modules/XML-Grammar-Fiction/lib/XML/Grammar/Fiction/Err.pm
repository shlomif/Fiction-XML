package XML::Grammar::Fiction::Err;

use strict;
use warnings;


=head1 NAME

XML::Grammar::Fiction::Err - Exception::Class-based exceptions used by
XML::Grammar::Fiction

=head1 VERSION

Version 0.14.0

=cut

our $VERSION = '0.14.0';

use Exception::Class
    (
        "XML::Grammar::Fiction::Err::Base",
        "XML::Grammar::Fiction::Err::Base::WithOpenTag" =>
        {
            isa => "XML::Grammar::Fiction::Err::Base",
            fields => [qw(opening_tag)],
        },
        "XML::Grammar::Fiction::Err::Parse::TagsMismatch" =>
        {
            isa => "XML::Grammar::Fiction::Err::Base::WithOpenTag",
            fields => [qw(opening_tag closing_tag)],
        },
        "XML::Grammar::Fiction::Err::Parse::LineError" =>
        {
            isa => "XML::Grammar::Fiction::Err::Base",
            fields => [qw(line)],
        },
        "XML::Grammar::Fiction::Err::Parse::LeadingSpace" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::NoRightAngleBracket" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::WrongClosingTagSyntax" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::ProgramListingContainsTags" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::ParaOpenPlusNotFollowedByTag" =>
        {
            isa => "XML::Grammar::Fiction::Err::Parse::LineError",
        },
        "XML::Grammar::Fiction::Err::Parse::TagNotClosedAtEOF" =>
        {
            isa => "XML::Grammar::Fiction::Err::Base::WithOpenTag",
        },
    )
    ;
1;

=head1 SYNOPSIS

    use XML::Grammar::Fiction::Err;

    .
    .
    .
    XML::Grammar::Fiction::Err::Parse::TagsMismatch->throw(
        error => "Tags mismatch",
        opening_tag => Tag->new(...),
        closing_tag => Tag->new(...),
    );

=head1 DESCRIPTION

These are exceptions for L<XML::Grammar::Fiction> based on L<Exception::Class>

=cut

