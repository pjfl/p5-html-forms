package HTML::Forms::Field::RequestToken;

use HTML::Forms::Constants qw( META NUL TRUE );
use HTML::Forms::Types     qw( Int Str );
use HTML::Forms::Util      qw( get_token verify_token );
use Scalar::Util           qw( blessed );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';

our $class_messages = {
   'token_fail' => 'Submission failed. [_1]. Please reload and try again.',
};

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::RequestToken - Generates request token

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'RequestToken';

=head1 Description

Generates request token

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item default_method

=item has_default_method

Predicate

=cut

has '+default_method' => builder => sub {
   my $self    = shift;
   my $expires = $self->expiration_time;
   my $prefix  = $self->token_prefix;

   return sub { get_token($expires, $prefix) };
};

=item C<noupdate>

=cut

has '+noupdate' => default => TRUE;

=item expiration_time

=cut

has 'expiration_time' => is => 'ro', isa => Int, default => 3600;

=item token_prefix

=cut

has 'token_prefix' => is => 'lazy', isa => Str, builder => 'build_token_prefix';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=cut

sub BUILD {
   my $self = shift;

   $self->default_method;
   return;
}

=item get_class_messages

=cut

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

=item build_token_prefix

=cut

sub build_token_prefix {
   my $self    = shift;
   my $form    = $self->form or return NUL;
   my $ctx     = $form->context or return NUL;
   my $session = $ctx->session;

   return (blessed $session ? $session->serialise : $session->{id}) // NUL;
}

=item validate

=cut

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

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::RequestToken>

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
