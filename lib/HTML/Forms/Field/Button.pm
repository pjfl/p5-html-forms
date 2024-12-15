package HTML::Forms::Field::Button;

use HTML::Forms::Constants qw( DOT FALSE NUL );
use HTML::Forms::Types     qw( Str );
use Moo;

extends 'HTML::Forms::Field::NoValue';

has 'display_as' => is => 'lazy', isa => Str, default => sub { shift->label };

has '+do_label' => default => FALSE;

has '+html5_type_attr' => default => 'submit';

has '+type_attr' => default => 'submit';

has '+widget' => default => 'Button';

has '+wrapper_class' => default => 'input-button';

sub _build_id {
   my $self   = shift;
   my $form   = $self->form;
   my $prefix = $form && $form->html_prefix ? $form->name . DOT : NUL;

   return $prefix . $self->full_name;
}

sub _build_label {
   return 'Submit';
}

sub html_element {
   return 'button';
}

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

=item display_as

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item html_element

=back

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
