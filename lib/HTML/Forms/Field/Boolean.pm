package HTML::Forms::Field::Boolean;

use HTML::Forms::Constants qw( FALSE TRUE );
use Moo;

extends 'HTML::Forms::Field::Checkbox';

has '+wrapper_class' => default => 'input-boolean';

around 'value' => sub {
   my ($orig, $self, @args) = @_;

   return $orig->($self, @args) ? TRUE : FALSE;
};

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Button - Button

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Button';

=head1 Description

Button

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item wrapper_class

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item value

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Checkbox>

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
