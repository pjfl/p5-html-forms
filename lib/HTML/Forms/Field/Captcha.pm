package HTML::Forms::Field::Captcha;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef Int LoadableClass Object Str );
use JSON::MaybeXS          qw( decode_json );
use List::Util             qw( first );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field';

our $class_messages = {
   'captcha_verify_failed' => 'Verification incorrect. Try again.',
};

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Captcha - Is the user a robot?

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Captcha';

=head1 Description

Generates and processes C<captcha> fields

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item address_key

=cut

has 'address_key' => is => 'rw', isa => Str, default => NUL;

=item capture

=cut

has 'capture' =>
   is      => 'lazy',
   isa     => Object,
   builder => sub {
      my $self = shift;

      return $self->captcha_class->new;
   };

=item captcha_class

=cut

has 'captcha_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'Captcha::reCAPTCHA';

=item captcha_type

=cut

has 'captcha_type' => is => 'rw', isa => Str, default => 'local';

=item domains

=cut

has 'domains' => is => 'rw', isa => ArrayRef, builder => sub { [] };

=item gd_font

=cut

has 'gd_font' => is => 'rw', isa => Str, default => 'Large';

=item height

=cut

has 'height' => is => 'rw', isa => Int, default => 20;

=item image

=cut

has 'image' => is => 'rw';

=item image_attr

=cut

has 'image_attr' =>
   is      => 'lazy',
   isa     => HashRef,
   builder => sub {
      my $self = shift;
      my $form = $self->form;
      my $attr = { height => $self->height, width => $self->width };

      return { attributes => $attr, src => $form->captcha_image_url };
   };

=item image_class

=cut

has 'image_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'GD::SecurityImage';

=item lines

=cut

has 'lines' => is => 'rw', isa => Int, default => 2;

=item response_key

=cut

has 'response_key' =>
   is      => 'rw',
   isa     => Str,
   default => 'g-recaptcha-response';

=item size

=cut

has 'size' => is => 'ro', isa => Int, default => 8;

=item scramble

=cut

has 'scramble' => is => 'rw', isa => Int, default => 0;

=item secret_key

=cut

has 'secret_key' => is => 'rw', isa => Str, default => NUL;

=item site_key

=cut

has 'site_key' => is => 'rw', isa => Str, default => NUL;

=item theme

=cut

has 'theme' => is => 'rw', isa => Str, default => NUL;

=item width

=cut

has 'width' => is => 'rw', isa => Int, default => 80;

=item C<noupdate>

=cut

has '+noupdate' => default => TRUE;

=item widget

=cut

has '+widget' => default => 'Captcha';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-captcha';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<fif>

=cut

sub fif { }

=item get_class_messages

=cut

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages } };
}

=item get_default_value

=cut

sub get_default_value {
   my $self = shift;

   return unless $self->captcha_type eq 'local';

   my $captcha; $captcha = $self->form->get_captcha if $self->form;

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

=item get_html

=cut

sub get_html {
   my $self    = shift;
   my $options = {};

   $options->{theme} = $self->theme if $self->theme;

   return $self->capture->get_html_v2($self->site_key, $options);
}

=item validate

=cut

sub validate {
   my $self = shift;

   if ($self->captcha_type eq 'local') {
      my $captcha; $captcha = $self->form->get_captcha if $self->form;

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
   $self->form->set_captcha($captcha) if $self->form;
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

=item L<HTML::Forms::Field>

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
