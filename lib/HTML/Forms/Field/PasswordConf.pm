package HTML::Forms::Field::PasswordConf;

use HTML::Forms::Constants qw( META NUL TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

has 'pass_conf_message' => is => 'ro', isa => Str;

has 'password_field' => is => 'ro', isa => Str, default => 'password';

has '+html5_type_attr' => default => 'password';

has '+password' => default => TRUE;

has '+required' => default => TRUE;

has '+type_attr' => default => 'password';

has '+widget' => default => 'Password';

has '+wrapper_class' => default => 'input-password';

our $class_messages = {
   required => 'Please enter a password confirmation',
   pass_not_matched => 'The password confirmation does not match the password',
};

sub get_class_messages {
   my $self     = shift;
   my $messages = { %{ $self->next::method }, %{ $class_messages  } };

   $messages->{pass_not_matched} = $self->pass_conf_message
      if $self->pass_conf_message;

   return $messages;
}

sub validate {
   my $self     = shift;
   my $password = $self->form->field( $self->password_field )->value || NUL;

   if ($password ne $self->value) {
      return $self->add_error($self->get_message('pass_not_matched'));
   }

   return TRUE;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::PasswordConf - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::PasswordConf;
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
