package HTML::Forms::Field::Checkbox;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Checkbox - Checkboxes

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Checkbox';

=head1 Description

Checkboxes

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item checkbox_value

=cut

has 'checkbox_value' => is => 'rw', default => TRUE;

=item html5_type_attr

=cut

has '+html5_type_attr' => default => 'checkbox';

=item input_without_param

=item has_input_without_param

Predicate

=cut

has '+input_without_param' => default => FALSE;

=item option_label

=cut

has 'option_label' => is => 'rw';

=item option_wrapper

=cut

has 'option_wrapper' => is => 'rw';

=item type_attr

=cut

has '+type_attr' => default => 'checkbox';

=item widget

=cut

has '+widget' => default => 'Checkbox';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-checkbox';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=cut

around 'BUILD' => sub {
   my ($orig, $self) = @_;

   $self->add_label_class('label-checkbox');
   $orig->($self);
   return;
};

=item validate

=cut

sub validate {
    my $self = shift;

    $self->add_error($self->get_message('required'), $self->loc_label)
       if $self->required && !$self->value;

    return;
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field>

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
