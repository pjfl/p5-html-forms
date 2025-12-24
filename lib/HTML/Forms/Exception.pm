package HTML::Forms::Exception;

use HTTP::Status          qw( HTTP_NOT_FOUND );
use HTML::Forms::Types    qw( Int );
use Unexpected::Functions qw( has_exception );
use Moo;

extends 'Unexpected';
with    'Unexpected::TraitFor::ErrorLeader';
with    'Unexpected::TraitFor::ExceptionClasses';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Exception - Exceptions used in this distribution

=head1 Synopsis

   use HTML::Forms::Exception;

=head1 Description

Exceptions used in this distribution

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<rv>

An immutable integer which default to C<1>. The return value

=cut

has 'rv' => is => 'ro', isa => Int, default => 1;

my $class = __PACKAGE__;

has '+class' => default => $class;

=back

=head1 Subroutines/Methods

Defines the following exceptions

=over 3

=item C<HTML::Forms::Exception>

Defines the class name as an exception class. This can be inherited by the
other exceptions defined here providing them with a common parent

=cut

has_exception $class;

=item C<BadToken>

The C<CSRF> token was bad

=cut

has_exception 'BadToken' => parent => [$class],
   error => 'CSRF verification failed: [_1]';

=item C<NotFound>

Path to a file not found

=cut

has_exception 'NotFound' => parent => [$class],
   error => 'Path [_1] not found. [_2]', rv => HTTP_NOT_FOUND;

=item C<PackageUndefined>

Undefined package

=cut

has_exception 'PackageUndefined' => parent => [$class],
   error => 'Package [_1] not defined in [_2].';

=item C<ReadFailed>

Attempt to read the path failed

=cut

has_exception 'ReadFailed' => parent => [$class],
   error => 'Path [_1] read failed. [_2]';

=item C<UnknownPackage>

The request package was unknown

=cut

has_exception 'UnknownPackage' => parent => [$class],
   error => 'Package [_1] not found.';

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Forms.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
