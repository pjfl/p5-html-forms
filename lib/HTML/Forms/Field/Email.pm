package HTML::Forms::Field::Email;

use Email::Valid;
use HTML::Forms::Constants qw( META );
use HTML::Forms::Types     qw( Bool HashRef );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

has 'email_valid_params' => is => 'rw', isa => HashRef;

has 'preserve_case' => is => 'rw', isa => Bool;

has '+html5_type_attr' => default => 'email';

has '+wrapper_class' => default => 'input-email';

our $class_messages = {
   'email_format' => 'Email should be of the format [_1]',
};

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

apply([
   {
      transform => sub {
         my ($value, $field) = @_;

         return $field->preserve_case ? $value : lc $value;
      }
   },
   {
      check => sub {
         my ($value, $field) = @_;

         my $checked = Email::Valid->address(
            %{ $field->email_valid_params || {} }, -address => $value,
         );

         $field->value($checked) if $checked;
      },
      message => sub {
         my ($value, $field) = @_;

         return [$field->get_message('email_format'), 'someuser@example.com'];
      }
   }
]);

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Email - An email address

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Email';

=head1 Description

An email address

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item email_valid_params

=item preserve_case

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item get_class_messages

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
