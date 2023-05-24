package HTML::Forms::Field::RequestToken;

use HTML::Forms::Constants qw( META NUL TRUE );
use HTML::Forms::Types     qw( Int Str );
use HTML::Forms::Util      qw( get_token verify_token );
use Scalar::Util           qw( blessed );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';

has '+default_method' => builder => sub {
   my $self    = shift;
   my $expires = $self->expiration_time;
   my $prefix  = $self->token_prefix;

   return sub { get_token($expires, $prefix) };
};

has '+noupdate' => default => TRUE;

has '+required' => default => TRUE;

has 'expiration_time' => is => 'ro', isa => Int, default => 3600;

has 'token_prefix' => is => 'lazy', isa => Str, builder => 'build_token_prefix';

our $class_messages = {
   'token_fail' => 'Submission failed. [_1]. Please reload and try again.',
};

sub BUILD {
   my $self = shift;

   $self->default_method;
   return;
}

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

sub build_token_prefix {
   my $self    = shift;
   my $form    = $self->form or return NUL;
   my $ctx     = $form->context or return NUL;
   my $session = $ctx->session;

   return (blessed $session ? $session->serialise : $session->{id}) // NUL;
}

sub validate {
   my ($self, $value) = @_;

   if (my $fail_reason = verify_token($value, $self->token_prefix)) {
      my $message = $self->get_message('token_fail');

      $self->add_error($message, $self->_localise($fail_reason));
   }

   return;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::RequestToken - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::RequestToken;
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
