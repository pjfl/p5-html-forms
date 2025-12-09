package HTML::Forms::Role::Defaults;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE TT_THEME );
use HTML::Forms::Types     qw( ArrayRef Str );
use HTML::Forms::Util      qw( get_meta );
use Unexpected::Functions  qw( throw );
use Moo::Role;

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

=item default_action_path

=cut

has 'default_action_path' =>
   is      => 'ro',
   isa     => Str,
   default => 'api/form_validate_field';

=item default_charset

=cut

has 'default_charset' => is => 'ro', isa => Str, default => 'utf-8';

=item default_field_traits

=cut

has 'default_field_traits' =>
   is      => 'ro',
   isa     => ArrayRef,
   default => sub { [ qw( Grouped Label Toggle ) ] };

=item default_form_class

=cut

has 'default_form_class' => is => 'ro', isa => Str, default => TT_THEME;

=item default_form_legend

=cut

has 'default_form_legend' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self  = shift;

      return $self->title if $self->title;

      my $label = ucfirst $self->name;

      $label =~ s{ _ }{ }gmx;
      return $label;
   };

=item default_form_wrapper_class

=cut

has 'default_form_wrapper_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'form-wrapper';

=item default_request_token

=cut

has 'default_request_token' => is => 'ro', isa => Str, default => '_verify';

=item default_validate_method

=cut

has 'default_validate_method' =>
   is      => 'ro',
   isa     => Str,
   default => 'WCom.Form.Util.validateField';

=item default_wrapper_tag

=cut

has 'default_wrapper_tag' => is => 'ro', isa => Str, default => 'fieldset';

=item do_form_wrapper

=cut

has '+do_form_wrapper' => is => 'rw', default => TRUE;

=item enctype

=cut

has '+enctype' => is => 'rw', default => 'multipart/form-data';

=item error_message

=cut

has '+error_message' =>
   is      => 'rw',
   default => 'Please fix the errors below';

=item is_html5

=cut

has '+is_html5' => is => 'rw', default => TRUE;

=item messages_before_start

=cut

has '+messages_before_start' => is => 'rw', default => FALSE;

=item success_message

=cut

has '+success_message' =>
   is      => 'rw',
   default => 'The form was successfully submitted';

=item log

=item has_log

Predicate

=cut

has 'log' => is => 'ro', predicate => 'has_log';

=back

=head1 Subroutines/Methods

Defines the following methods

=over 3

=item before_build_fields

=cut

around 'before_build_fields' => sub {
   my ($orig, $self) = @_;

   $orig->($self);
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
};

=item html_attributes

=cut

around 'html_attributes' => sub {
   my ($orig, $self, $obj, $type, $attrs, $result) = @_;

   $attrs = $orig->($self, $obj, $type, $attrs, $result);

   if ($type eq 'element') {
      $self->_add_field_validation($obj, $attrs) if $obj->validate_inline;
      $obj->tags->{label_tag} = 'span' if $obj->label_top;
   }

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

sub _add_field_validation {
   my ($self, $field, $attrs) = @_;

   my $name    = $field->name;
   my $uri     = $self->context->uri_for_action($self->default_action_path);
   my $vmethod = $self->default_validate_method;
   my $call    = "${vmethod}('${uri}', '${name}')";

   if (my $js = $attrs->{javascript}) {
      if (exists $js->{onblur}) {
         my $existing = $js->{onblur};

         $attrs->{javascript}->{onblur} = "${existing}; ${call}";
      }
      else { $attrs->{javascript}->{onblur} = $call }
   }
   else { $attrs->{javascript} = { onblur => $call } }

   return;
}

use namespace::autoclean;

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
