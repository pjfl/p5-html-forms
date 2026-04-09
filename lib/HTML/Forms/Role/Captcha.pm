package HTML::Forms::Role::Captcha;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( Int Str );
use Type::Utils            qw( class_type );
use Moo::Role;

requires qw(context json_parser redis_client);

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Role::Captcha - Captcha form methods

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Role::Captcha';

=head1 Description

Captcha form methods

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item captcha_image_url

=cut

has 'captcha_image_url' => is => 'rw', isa => class_type('URI'), lazy => TRUE;

=item captcha_lifetime

=cut

has 'captcha_lifetime' => is => 'ro', isa => Int, default => 3_600;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item get_captcha

=cut

sub get_captcha {
   my $self  = shift;
   my $key   = 'html_forms_captcha-' . $self->context->session->{id};
   my $value = $self->redis_client->get($key) or return;

   return $self->json_parser->decode($value);
}

=item set_captcha

=cut

sub set_captcha {
   my ($self, $captcha) = @_;

   my $key   = 'html_forms_captcha-' . $self->context->session->{id};
   my $value = $self->json_parser->encode($captcha);
   my $ttl   = $self->captcha_lifetime;

   return $self->redis_client->set_with_ttl($key, $value, $ttl);
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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
