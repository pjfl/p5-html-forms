package HTML::Forms::Role::ToggleRequired;

use namespace::autoclean;

use Moo::Role;

around 'validate_form' => sub {
   my ($orig, $self) = @_;

   my @modified_fields;

   for my $field ($self->fields) {
      next unless $field->can( 'get_disabled_fields' );

      my $params = $self->params->{ $field->full_name };
      my $disabled_fields = $field->get_disabled_fields( $params );

      for my $disable_field (@{ $disabled_fields }) {
         my $field_obj = $self->field( $disable_field ) or next;

         # If we have disabled a field group then disable the requires in
         # all fields belonging to the field group
         if ($field_obj->isa( 'HTML::Forms::Field::Group' )) {
            for my $sub_field ($self->form->sorted_fields) {
               next unless $sub_field->can( 'field_group' )
                  && $sub_field->field_group eq $field_obj->full_accessor
                  && $sub_field->required;

               $sub_field->required(0);
               push @modified_fields, $sub_field;
            }
         }
         elsif ($field_obj->required) {
            $field_obj->required(0);
            push @modified_fields, $field_obj;
         }
      }
   }

   $orig->( $self );

   $_->required(1) for (@modified_fields);

   return;
};

1;

__END__

=pod

=encoding utf-8

=head1 Name

[% module %] - [% abstract %]

=head1 Synopsis

   use [% module %];
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
http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% distname %].
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

[% author %], C<< <[% author_email %]> >>

=head1 License and Copyright

Copyright (c) [% copyright_year %] [% copyright %]. All rights reserved

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
