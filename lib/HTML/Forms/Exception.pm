package HTML::Forms::Exception;

use HTML::Forms::Types    qw( Int );
use HTTP::Status          qw( HTTP_NOT_FOUND );
use Unexpected::Functions qw( has_exception );
use Moo;

extends 'Unexpected';
with    'Unexpected::TraitFor::ErrorLeader';
with    'Unexpected::TraitFor::ExceptionClasses';

has 'rv' => is => 'ro', isa => Int, default => 1;

my $class = __PACKAGE__;

has '+class' => default => $class;

has_exception $class;

has_exception 'BadToken' => parent => [$class],
   error => 'CSRF verification failed: [_1]';

has_exception 'NotFound' => parent => [$class],
   error => 'Path [_1] not found. [_2]', rv => HTTP_NOT_FOUND;

has_exception 'PackageUndefined' => parent => [$class],
   error => 'Package [_1] not defined in [_2].';

has_exception 'ReadFailed' => parent => [$class],
   error => 'Path [_1] read failed. [_2]';

has_exception 'UnknownPackage' => parent => [$class],
   error => 'Package [_1] not found.';

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Exception - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Exception;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

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
