package HTML::Forms::Field::Password;

use HTML::Forms::Constants qw( META TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

has 'ne_username' => is => 'rw', isa => Str;

has '+html5_type_attr' => default => 'password';

has '+password' => default => TRUE;

has '+type_attr' => default => 'password';

has '+widget' => 'Password';

our $class_messages = {
   'required' => 'Please enter a password in this field',
   'password_ne_username' => 'Password must not match [_1]',
};

after 'validate_field' => sub {
   my $self = shift;

   if (!$self->required && !(defined $self->value && length $self->value)) {
      $self->noupdate(TRUE);
      $self->clear_errors;
   }

   return;
};

sub get_class_messages {
   my $self     = shift;
   my $messages = { %{ $self->next::method }, %{ $class_messages  } };

   $messages->{required} = $self->required_message if $self->required_message;

   return $messages;
}

sub validate {
   my $self = shift;

   return unless $self->next::method;

   if ($self->form && $self->ne_username) {
      my $username = $self->form->get_param( $self->ne_username );

      return $self->add_error(
         $self->get_message('password_ne_username'), $self->ne_username
      ) if $username && $username eq $self->value;
   }

   return TRUE;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Password - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::Password;
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
