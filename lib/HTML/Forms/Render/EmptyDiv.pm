package HTML::Forms::Render::EmptyDiv;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use HTML::Forms::Types     qw( HashRef HFs Int Str );
use HTML::Forms::Util      qw( json_bool );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( throw );
use JSON::MaybeXS;
use HTML::Tiny;
use Try::Tiny;
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Render::EmptyDiv - Serialiser for front end rendering

=head1 Synopsis

   use HTML::Forms::Render::EmptyDiv;

=head1 Description

Generates an empty C<div> with a data attribute containing a rich description
of the required form. Intention is for the HTML form to be rendered by JS
running in the browser

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item container

A lazy string containing the C<container_tag> which is returned by the
C<render> method

=cut

has 'container' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;
      my $tag  = $self->container_tag;

      return $self->_html->$tag($self->data);
   };

=item container_tag

Immutable string which defaults to C<div>. The HTML element to return when
rendering

=cut

has 'container_tag' => is => 'ro', isa => Str, default => 'div';

=item data

A hash reference of keys and values applied to the attributes of the
C<container>

=cut

has 'data' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;
      my $form = $self->form;
      my $form_attr = $form->attributes;

      $form_attr->{className} = join SPC, @{delete $form_attr->{class}};

      my $wrapper_attr = $form->form_wrapper_attributes;

      $wrapper_attr->{className} = join SPC, @{delete $wrapper_attr->{class}};

      my $error_message = $form->has_error_message
         && ($form->result->has_errors || $form->result->has_form_errors)
         ? $form->localise($form->error_message) : NUL;
      my $info_message = $form->has_info_message
         ? $form->localise($form->info_message || NUL) : NUL;
      my $success_message = $form->has_success_message
         && $form->result->validated
         ? $form->localise($form->success_message) : NUL;
      my $tags = {
         map {
            (my $key = $_) =~ s{ _(\w{1}) }{\u$1}gmx;
            $key => delete $form->form_tags->{$_}
         } keys %{$form->form_tags}
      };

      my $config = {
            attributes      => $form_attr,
            doFormWrapper   => json_bool $form->do_form_wrapper,
            errorMsg        => $error_message,
            fields          => $self->_serialise_fields,
            infoMessage     => $info_message,
            msgsBeforeStart => json_bool $form->messages_before_start,
            name            => $form->name,
            pageSize        => $self->page_size,
            successMsg      => $success_message,
            tags            => $tags,
            wrapperAttr     => $wrapper_attr,
      };

      return {
         'class'            => 'html-forms',
         'data-form-config' => $self->_json->encode($config),
      };
   };

=item form

A required weak reference to the L<HTML::Forms> object

=cut

has 'form' => is => 'ro', isa => HFs, required => TRUE, weak_ref => TRUE;

=item page_size

=cut

has 'page_size' => is => 'ro', isa => Int, default => 0;

# Private attributes
has '_html' =>
   is      => 'ro',
   isa     => class_type('HTML::Tiny'),
   default => sub { HTML::Tiny->new };

has '_json' =>
   is      => 'ro',
   isa     => class_type(JSON::MaybeXS::JSON),
   default => sub {
      return JSON::MaybeXS->new( convert_blessed => TRUE, utf8 => FALSE );
   };

=back

=head1 Subroutines/Methods

=over 3

=item render

Returns an HTML string containing the empty C<div>

=cut

sub render {
   my $self = shift;

   return $self->container;
}

# Private methods
sub _serialise_fields {
   my $self   = shift;
   my $fields = [];

   for my $field (@{$self->form->sorted_fields}) {
      push @{$fields}, $self->_serialise_field($field);
   }

   return $fields;
}

sub _serialise_field {
   my ($self, $field) = @_;

   my $form = $self->form;
   my $field_attr = $field->attributes;
   my $disabled = delete $field_attr->{disabled};

   $field_attr->{className} = join SPC, @{delete $field_attr->{class} // []};

   my $depends = join SPC, @{delete $field_attr->{'data-field-depends'} // []};
   my $ds_spec = delete $field_attr->{'data-ds-specification'} // NUL;
   my $label_attr = $field->label_attributes // {};

   $label_attr->{className} = join SPC, @{delete $label_attr->{class}};
   $label_attr->{htmlFor}   = $field->id;

   my $wrapper_attr = $field->wrapper_attributes // {};

   $wrapper_attr->{className} = join SPC, @{delete $wrapper_attr->{class}};

   my $handlers = delete $field_attr->{javascript};
   my $result   = $field->result;
   my $attr     = {
      attributes  => $field_attr,
      depends     => $depends,
      disabled    => $disabled,
      doLabel     => json_bool $field->do_label,
      dsSpec      => $ds_spec,
      handlers    => $handlers,
      hideInfo    => json_bool $field->hide_info,
      htmlElement => $field->html_element,
      htmlName    => $field->html_name,
      id          => $field->id,
      info        => $field->info,
      inputType   => $field->input_type,
      label       => $field->loc_label,
      labelAttr   => $label_attr,
      labelRight  => json_bool $field->get_tag('label_right') // FALSE,
      labelTag    => $field->get_tag('label_tag') || 'label',
      name        => $field->name,
      result      => {
         allErrors   => [ map { $form->localise($_) } $result->all_errors ],
         allWarnings => [ map { $form->localise($_) } $result->all_warnings ]
      },
      reveal      => json_bool $field->get_tag('reveal'),
      value       => $field->value,
      widget      => $field->widget || 'Text',
      wrapperAttr => $wrapper_attr,
   };

   $attr->{checkboxValue} = $field->checkbox_value
      if $field->can('checkbox_value');
   $attr->{clickHandler} = $field->click_handler
      if $field->can('click_handler');
   $attr->{cols}         = $field->cols          if $field->can('cols');
   $attr->{displayAs}    = $field->display_as    if $field->can('display_as');
   $attr->{emptySelect}  = $field->empty_select  if $field->can('empty_select');
   $attr->{fif}          = $field->fif           if $field->can('fif');
   $attr->{html}         = $field->html          if $field->can('html');
   $attr->{multiple}     = $field->multiple      if $field->can('multiple');
   $attr->{options}      = $field->options       if $field->can('options');
   $attr->{rows}         = $field->rows          if $field->can('rows');
   $attr->{size}         = $field->size          if $field->can('size');
   $attr->{src}          = $field->src           if $field->can('src');
   $attr->{toggle}       = $field->toggle_config_encoded
      if $field->can('has_toggle') && $field->has_toggle;

   return $attr;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Tiny>

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
