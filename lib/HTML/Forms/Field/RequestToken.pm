package HTML::Forms::Field::RequestToken;

use Crypt::CBC;
use MIME::Base64           qw( decode_base64 encode_base64 );
use HTML::Forms::Constants qw( META NUL TRUE );
use HTML::Forms::Types     qw( Int Str );
use Try::Tiny;
use Type::Utils            qw( class_type );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';

has 'cipher' =>
   is      => 'lazy',
   isa     => class_type('Crpyt::CBC'),
   builder => sub {
      my $self = shift;

      return Crypt::CBC->new(
         -cipher => $self->crypto_cipher_type,
         -header => 'salt',
         -key    => $self->crypto_key,
         -salt   => TRUE,
      );
   };

has 'crypto_cipher_type' => is => 'rw', isa => Str, default => 'Blowfish';

has 'crypto_key' => is => 'rw', isa => Str, default => __FILE__;

has 'expiration_time' => is => 'rw' isa => Int, default => 3600;

has 'message' =>
   is      => 'rw',
   isa     => Str,
   default => 'Form submission failed. Please try again.';

has 'token_prefix' =>
   is      => 'lazy',
   isa     => Str,
   builder => sub {
      my $self = shift;
      my $form = $self->form or return NUL;
      my $ctx  = $form->ctx or return NUL;
      my $id   = $ctx->session->{id};

      return $id ? "${id}|" : NUL;
   };

has '+default_method' => default => sub { \&_get_token };

has '+required' => default => TRUE;

sub validate {
   my ($self, $value) = @_;

   $self->add_error($self->message) unless $self->_verify_token($value);

   return;
}

sub _get_token {
   my $self  = shift;
   my $value = $self->token_prefix . (time + $self->expiration_time);
   my $token = encode_base64($self->cipher->encrypt($value));

   $token =~ s{[\s\r\n]+}{}gmx;
   return $token;
}

sub _verify_token {
   my ($self, $token) = @_;

   return unless $token;

   my $value;

   try {
      $value = $self->cipher->decrypt(decode_base64($token));

      if (my $prefix = $self->token_prefix) {
         return unless $value =~ s{\A\Q$prefix\E}{}mx;
      }
   }
   catch {};

   return unless defined $value;
   return unless $value =~ m{ \A \d+ \z }mx;
   return if time > $value;
   return TRUE;
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
