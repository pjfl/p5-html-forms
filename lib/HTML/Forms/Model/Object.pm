package HTML::Forms::Model::Object;

use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Model::Object - Model for updating the item object

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Model::Object';

=head1 Description

Model for updating the item object

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item update_model

   $self->update_model;

If the item supplied to the form has attributes whose names match the field
names then the item attribute is updated with the field value

=cut

sub update_model {
   my $self = shift;
   my $item = $self->item or return;

   for my $field ($self->all_fields) {
      my $name = $field->name;

      $item->$name( $field->value ) if $item->can( $name );
   }

   return;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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
