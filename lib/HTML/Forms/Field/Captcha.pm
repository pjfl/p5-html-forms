package HTML::Forms::Field::Captcha;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef Int LoadableClass Object Str );
use JSON::MaybeXS          qw( decode_json );
use List::Util             qw( first );
use Moo;

extends 'HTML::Forms::Field';

has 'address_key' => is => 'rw', isa => Str, default => NUL;

has 'capture' =>
   is      => 'lazy',
   isa     => Object,
   builder => sub {
      my $self = shift;

      return $self->captcha_class->new;
   };

has 'captcha_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'Captcha::reCAPTCHA';

has 'captcha_type' => is => 'rw', isa => Str, default => 'local';

has 'domains' => is => 'rw', isa => ArrayRef, builder => sub { [] };

has 'gd_font' => is => 'rw', isa => Str, default => 'Large';

has 'height' => is => 'rw', isa => Int, default => 20;

has 'image' => is => 'rw';

has 'image_attr' =>
   is      => 'lazy',
   isa     => HashRef,
   builder => sub {
      my $self = shift;
      my $form = $self->form;
      my $attr = { height => $self->height, width => $self->width };

      return { attributes => $attr, src => $form->captcha_image_url };
   };

has 'image_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'GD::SecurityImage';

has 'lines' => is => 'rw', isa => Int, default => 2;

has 'response_key' =>
   is      => 'rw',
   isa     => Str,
   default => 'g-recaptcha-response';

has 'scramble'   => is => 'rw', isa => Int, default => 0;

has 'secret_key' => is => 'rw', isa => Str, default => NUL;

has 'site_key'   => is => 'rw', isa => Str, default => NUL;

has 'theme'      => is => 'rw', isa => Str, default => NUL;

has 'width'      => is => 'rw', isa => Int, default => 80;


has '+noupdate'      => default => TRUE;

has '+widget'        => default => 'Captcha';

has '+wrapper_class' => default => 'captcha';

our $class_messages = {
   'captcha_verify_failed' => 'Verification incorrect. Try again.',
};

# Public methods
sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages } };
}

sub get_default_value {
   my $self = shift;

   return unless $self->captcha_type eq 'local';

   my $captcha = $self->form->get_captcha;

   if ($captcha) {
      if ($captcha->{validated}) {
         $self->required(FALSE);
         $self->widget('NoRender');
      }
      else {
         $self->required(TRUE);
         $self->widget('Captcha');
         $self->image($captcha->{image});
      }
   }
   else {
      $self->required(TRUE);
      $self->widget('Captcha');
      $self->_generate_captcha;
   }

   return;
}

sub fif { }

sub validate {
   my $self = shift;

   if ($self->captcha_type eq 'local') {
      my $captcha = $self->form->get_captcha;

      if ($captcha and $captcha->{rnd} eq $self->value) {
         $captcha->{validated} = TRUE;
         $self->form->set_captcha($captcha);
      }
      else {
         $self->_add_verify_error;
         $self->_generate_captcha;
      }
   }
   else {
      my $params = {
         address  => $self->input->{$self->address_key},
         response => $self->input->{$self->response_key},
      };

      $self->_add_verify_error unless $self->_captcha_check($params);
   }

   return !$self->has_errors;
}

# Private methods
sub _add_verify_error {
   my $self = shift;

   $self->add_error($self->get_message('captcha_verify_failed'));
   return;
}

sub _build_html {
   my $self    = shift;
   my $options = {};

   $options->{theme} = $self->theme if $self->theme;

   return $self->capture->get_html_v2($self->site_key, $options);
}

sub _captcha_check {
   my ($self, $params) = @_;

   return FALSE unless $params->{response} && $self->secret_key;

   my $request = {
      secret   => $self->secret_key,
      response => $params->{response},
   };

   $request->{remoteip} = $params->{address} if $params->{address};

   my $response = $self->captcha->_post_request($request);
   my $content  = decode_json $response->content;
   my $success  = $response->is_success && $content->{success} ? TRUE : FALSE;

   $success = FALSE
      unless $success && $self->domains->[0]
      && first { $_ eq $content->{hostname} } @{$self->domains};

   return $success;
}

sub _generate_captcha {
   my $self = shift;

   # Fails to require GD::SecurityImage unless import is called
   $self->image_class->import;

   my ($image, $type, $rnd) = $self->image_class->new(
      gd_font  => $self->gd_font,
      height   => $self->height,
      lines    => $self->lines,
      scramble => $self->scramble,
      width    => $self->width,
   )->random->create->out;
   my $captcha = {
      image     => $image,
      type      => $type,
      rnd       => $rnd,
      validated => FALSE,
   };

   $self->image($image);
   $self->form->set_captcha($captcha);
   return;
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Captcha - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::Captcha;
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
