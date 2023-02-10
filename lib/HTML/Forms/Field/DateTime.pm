package HTML::Forms::Field::DateTime;

use HTML::Forms::Constants qw( DATE_FMT DATE_MATCH META TIME_FMT TIME_MATCH );
use HTML::Forms::Types     qw( Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Date';

has '+default' => default => sub { shift->_now_dt->truncate( to => 'minute' ) };

has '+format' => is => 'lazy', isa => Str, default => DATE_FMT . 'T' . TIME_FMT;

has '+html5_type_attr' => default => 'datetime-local';

has '+pattern' => default => DATE_MATCH . 'T' . TIME_MATCH;

has '+size' => default => 19;

has '+type_attr' => default => 'datetime-local';

has '+wrapper_class' => default => 'input-datetime';

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::DateTime - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::DateTime;
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
