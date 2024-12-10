package HTML::Forms::Role::Captcha;

use HTML::Forms::Constants qw( META );
use HTML::Forms::Types     qw( Str );
use Moo::Role;
use HTML::Forms::Moo;

requires 'context';

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

has 'captcha_image_url' =>
   is      => 'lazy',
   isa     => Str,
   default => '/captcha/image';

has_field 'captcha' => type => 'Captcha', label => 'Verification';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item get_captcha

=cut

sub get_captcha {
   my $self = shift;

   return unless $self->context;

   return $self->context->session->{captcha};
}

=item set_captcha

=cut

sub set_captcha {
   my ($self, $captcha) = @_;

   return unless $self->context;

   return $self->context->session( captcha => $captcha );
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
