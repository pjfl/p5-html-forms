package HTML::Forms::Field::RequestToken;

use Crypt::CBC;
use MIME::Base64           qw( decode_base64 encode_base64 );
use HTML::Forms::Constants qw( BANG META NUL SECRET TRUE );
use HTML::Forms::Types     qw( Int Str );
use Scalar::Util           qw( weaken );
use Try::Tiny;
use Type::Utils            qw( class_type );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';

has 'cipher' =>
   is      => 'lazy',
   isa     => class_type('Crypt::CBC'),
   builder => sub {
      my $self = shift;

      return Crypt::CBC->new(
         -cipher => $self->crypto_cipher_type,
         -header => 'salt',
         -key    => $self->crypto_key,
         -pbkdf  =>'pbkdf2',
         -salt   => TRUE,
      );
   };

has 'crypto_cipher_type' => is => 'ro', isa => Str, default => 'Blowfish';

has 'crypto_key' => is => 'ro', isa => Str, builder => 'build_crypto_key';

has 'expiration_time' => is => 'ro', isa => Int, default => 3600;

has 'token_prefix' => is => 'lazy', isa => Str, builder => 'build_token_prefix';

has '+default_method' => default => sub {
   my $self = shift; weaken $self; return sub { $self->_get_token };
};

has '+required' => default => TRUE;

our $class_messages = {
   'token_fail' => 'Submission failed. [_1]. Please reload and try again.',
};

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

sub build_crypto_key {
   return SECRET;
}

sub build_token_prefix {
   my $self = shift;
   my $form = $self->form or return NUL;
   my $ctx  = $form->context or return NUL;
   my $id   = $ctx->session->{id} // NUL;

   return $id;
}

sub validate {
   my ($self, $value) = @_;

   if (my $fail_reason = $self->_verify_token($value)) {
      $self->add_error(
         $self->get_message('token_fail'), $self->_localise($fail_reason)
      );
   }

   return;
}

sub _get_token {
   my $self   = shift;
   my $prefix = $self->token_prefix;

   $prefix .= BANG if $prefix;

   my $value  = $prefix . (time + $self->expiration_time);
   my $token  = encode_base64($self->cipher->encrypt($value));

   $token =~ s{[\s\r\n]+}{}gmx;
   return $token;
}

sub _verify_token {
   my ($self, $token) = @_;

   return 'No token found' unless $token;

   my $value;

   try {
      $value = $self->cipher->decrypt(decode_base64($token));

      if (my $prefix = $self->token_prefix) {
         $prefix .= BANG;

         return 'Bad token prefix' unless $value =~ s{\A\Q$prefix\E}{}mx;
      }
   }
   catch {};

   return 'Bad token decrypt'    unless defined $value;
   return 'Bad token time value' unless $value =~ m{ \A \d+ \z }mx;
   return 'Request token to old' if time > $value;
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
