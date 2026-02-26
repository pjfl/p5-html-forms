package HTML::Forms::Field::Password;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( HashRef Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

our $class_messages = {
   'required' => 'Please enter a password in this field',
   'minlength' => 'Passwords must be at least [_1] characters long',
   'no_numbers' => 'Password must contain at least one digit',
   'no_punctuation' =>
      'Passwords must contain at least one punctuation character',
   'not_mixed_case' => 'Passwords must be mixed case',
   'password_ne_username' => 'Password must not match [_1]',
};

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Password - Password field

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Password';

=head1 Description

Password field

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item ne_username

=cut

has 'ne_username' => is => 'rw', isa => Str;

=item html5_type_attr

=cut

has '+html5_type_attr' => default => 'password';

=item password

=cut

has '+password' => default => TRUE;

=item password_options

=cut

has 'password_options' => is => 'rw', isa => HashRef, default => sub { {} };

=item type_attr

=cut

has '+type_attr' => default => 'password';

=item widget

=cut

has '+widget' => default => 'Password';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-password';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item validate_field

=cut

after 'validate_field' => sub {
   my $self = shift;

   if (!$self->required && !(defined $self->value && length $self->value)) {
      $self->noupdate(TRUE);
      $self->clear_errors;
   }

   return;
};

=item get_class_messages

=cut

sub get_class_messages {
   my $self     = shift;
   my $messages = { %{ $self->next::method }, %{ $class_messages  } };

   $messages->{required} = $self->required_message if $self->required_message;

   return $messages;
}

=item validate

=cut

sub validate {
   my $self = shift;

   return unless $self->next::method;

   my $value  = $self->value;
   my $minlen = $self->element_attr->{minlength};

   if ($minlen && length $value < $minlen) {
      $self->add_error($self->get_message('minlength'), $minlen);
   }

   if ($self->form && $self->ne_username) {
      my $username = $self->form->get_param( $self->ne_username );
      my $message  = $self->get_message('password_ne_username');

      $self->add_error($message, $self->ne_username)
         if $username && $username eq $value;
   }

   if (exists $self->password_options->{mixed_case}) {
      $self->add_error($self->get_message('not_mixed_case'))
         unless $value =~ m{ [a-z]+ }mx && $value =~ m{ [A-Z]+ }mx;
   }

   if (exists $self->password_options->{with_numbers}) {
      $self->add_error($self->get_message('no_numbers'))
         unless $value =~ m{ [0-9]+ }mx;
   }

   if (exists $self->password_options->{with_punctuation}) {
      (my $copy = $value) =~ s{ [a-zA-Z0-9] }{}gmx;

      $self->add_error($self->get_message('no_punctuation'))
         unless length $copy > 0;
   }

   return !$self->has_errors ? TRUE : FALSE;
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Text>

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
