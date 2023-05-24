package HTML::Forms::Role::Defaults;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE TT_THEME );
use HTML::Forms::Types     qw( ArrayRef Str );
use HTML::Forms::Util      qw( get_meta );
use Unexpected::Functions  qw( throw );
use Moo::Role;

with 'HTML::Forms::Render::WithTT';

has '+enctype' => is => 'rw', default => 'multipart/form-data';

has '+error_message' =>
   is      => 'rw',
   default => 'Please fix the errors below';

has '+messages_before_start' => is => 'ro', default => TRUE;

has '+success_message' =>
   is      => 'rw',
   default => 'The form was successfully submitted';

has 'default_charset' => is => 'ro', isa => Str, default => 'utf-8';

has 'default_field_traits' =>
   is      => 'ro',
   isa     => ArrayRef,
   builder => sub { [ qw( Label Toggle ) ] };

has 'default_form_class' => is => 'ro', isa => Str, default => TT_THEME;

has 'default_form_legend' =>
   is      => 'lazy',
   isa     => Str,
   builder => sub {
      my $self  = shift;

      return $self->title if $self->title;

      my $label = ucfirst $self->name;

      $label =~ s{ _ }{ }gmx;
      return $label;
   };

has 'default_form_wrapper_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'form-wrapper';

has 'default_request_token' => is => 'ro', isa => Str, default => '_verify';

has 'default_wrapper_tag' => is => 'ro', isa => Str, default => 'div';

around 'html_attributes' => sub {
   my ($orig, $self, $obj, $type, $attrs, $result) = @_;

   $attrs = $orig->($self, $obj, $type, $attrs, $result);

   if ($type eq 'label') {
      my $class = 'option-label';
      if ($obj->parent->isa('HTML::Forms')) {
         $class = 'field-label';
         $attrs->{title} //= 'Required'
            if $obj->required && $obj->parent->is_html5;
      }
      push @{$attrs->{class}}, $class;
   }

   if ($type eq 'wrapper') {
      pop @{$attrs->{class}} if $obj->get_tag('label_right')
         && $obj->parent->isa('HTML::Forms::Field::Duration')
         && $attrs->{class}->[-1] eq 'label-right';
   }

   return $attrs;
};

sub before_build {
   my $self = shift;

   $self->set_tag( legend => $self->default_form_legend );
   $self->set_tag( wrapper_tag => $self->default_wrapper_tag );
   $self->set_form_element_attr( 'accept-charset' => $self->default_charset );
   $self->add_form_element_class( $self->default_form_class );
   $self->add_form_wrapper_class( $self->default_form_wrapper_class );

   for my $trait_name (@{ $self->default_field_traits }) {
      $self->add_field_trait($self->get_field_trait($trait_name));
   }

   if (my $name = $self->default_request_token) {
      my $meta = get_meta($self);

      $meta->add_to_field_list({ name => $name, type => 'RequestToken' });
   }

   return;
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Role::Defaults - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Role::Defaults;
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
