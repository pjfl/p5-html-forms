package HTML::Forms::Field::Reset;

use HTML::Forms::Constants qw( FALSE META );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::NoValue';

has '+do_label' => default => FALSE;

has '+type_attr' => default => 'reset';

has '+value' => default => 'Reset';

has '+widget' => default => 'Reset';

has '+wrapper_class' => default => 'input-button';

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Reset - Reset button

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Reset';

=head1 Description

Reset button

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item value

=item has_value

Predicate

=back

=head1 Subroutines/Methods

Defines no methods

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::NoValue>

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
