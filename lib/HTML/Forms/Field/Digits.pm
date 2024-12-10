package HTML::Forms::Field::Digits;

use HTML::Forms::Constants qw( META );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::PosInteger';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Digits - Digits

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Digits';

=head1 Description

Digits

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item html5_type_attr

=cut

has '+html5_type_attr' => default => 'text';

=item widget

=cut

has '+widget' => default => 'Digits';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item javascript

=cut

sub javascript {
   my ($self, $count) = @_;

   return qq{oninput="} . $self->js_package . qq{.updateDigits('}
        . $self->id . qq{', } . $count . qq{)"};
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::PosInteger>

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
