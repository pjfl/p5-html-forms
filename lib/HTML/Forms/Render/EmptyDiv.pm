package HTML::Forms::Render::EmptyDiv;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef HFs Int Str );
use HTML::Forms::Util      qw( json_bool );
use Ref::Util              qw( is_arrayref );
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

=item container_tag

Immutable string which defaults to C<div>. The HTML element to return when
rendering

=cut

has 'container_tag' => is => 'ro', isa => Str, default => 'div';

=item current_page

A mutable integer that defaults to zero. The page that is displayed when a
multi-page form is rendered

=cut

has 'current_page' => is => 'rw', isa => Int, default => 0;

=item form

A required weak reference to the L<HTML::Forms> object

=cut

has 'form' => is => 'ro', isa => HFs, required => TRUE, weak_ref => TRUE;

=item form_class

An immutable string which defaults to C<html-forms>. Class applied to the
serialised form element. This is searched for by the browser JS

=cut

has 'form_class' => is => 'ro', isa => Str, default => 'html-forms';

has '_has_page_breaks' => is => 'rw', isa => Bool, default => FALSE;

=item C<html>

An immutable instance of L<HTML::Tiny>

=cut

has 'html' =>
   is      => 'ro',
   isa     => class_type('HTML::Tiny'),
   default => sub { HTML::Tiny->new };

=item num_pages

An immutable integer that defaults to one. The number of tabs/pages to spread
the fields across. Set either this or C<page_size> not both

=cut

has 'num_pages' => is => 'ro', isa => Int, default => 1;

=item page_names

An immutable array reference of strings with an empty default. Used to name
the tabs/pages in a multi-page form

=cut

has 'page_names' => is => 'ro', isa => ArrayRef[Str], default => sub { [] };

=item page_size

An immutable integer that defaults to zero. If non zero the number of fields
to display per page. This makes the form display across a set of tabs/pages

Alternatively set C<< tags => { page_break => TRUE } >> on the field
declaration to create a page break on that field

=cut

has 'page_size' =>
   is       => 'lazy',
   isa      => Int,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return $self->_page_size if ($self->num_pages < 2);

      my $field_count = @{$self->form->sorted_fields};

      return int $field_count / $self->num_pages;
   };

has '_page_size' =>
   is       => 'ro',
   isa      => Int,
   init_arg => 'page_size',
   default  => 0;

# Private attributes
has '_json_parser' =>
   is      => 'ro',
   isa     => class_type(JSON::MaybeXS::JSON),
   default => sub {
      return JSON::MaybeXS->new( convert_blessed => TRUE, utf8 => FALSE );
   };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item render

Returns an HTML string containing the empty C<container_tag> which has class
and data attributes set. The class is used to trigger JS in the browser, the
data is used to configure that JS

=cut

sub render {
   my $self = shift;
   my $tag  = $self->container_tag;
   my $data = {
      'class'            => $self->form_class,
      'data-form-config' => $self->_serialise_form
   };

   return $self->html->$tag($data);
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

   my $page_break = $field->get_tag('page_break') // FALSE;

   $self->_has_page_breaks(TRUE) if $page_break;

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
      label       => $field->localise_label,
      labelAttr   => $label_attr,
      labelRight  => json_bool $field->get_tag('label_right') // FALSE,
      labelTag    => $field->get_tag('label_tag') || 'label',
      name        => $field->name,
      pageBreak   => json_bool $page_break,
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
   $attr->{href}         = $field->href          if $field->can('href');
   $attr->{html}         = $field->html          if $field->can('html');
   $attr->{icons}        = $field->icons         if $field->can('icons');
   $attr->{multiple}     = $field->multiple      if $field->can('multiple');
   $attr->{options}      = $field->options       if $field->can('options');
   $attr->{rows}         = $field->rows          if $field->can('rows');
   $attr->{size}         = $field->size          if $field->can('size');
   $attr->{src}          = $field->src           if $field->can('src');
   $attr->{toggle}       = $field->toggle_config_encoded
      if $field->can('has_toggle') && $field->has_toggle;

   return $attr;
}

sub _serialise_form {
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
      ? is_arrayref $form->info_message
      ? [ map { $form->localise($_) } @{$form->info_message} ]
      : $form->localise($form->info_message) : NUL;

   my $success_message = $form->has_success_message
      && $form->result->validated
      ? $form->localise($form->success_message) : NUL;
   my $tags = {
      map {
         (my $key = $_) =~ s{ _(\w{1}) }{\u$1}gmx;
         $key => delete $form->form_tags->{$_}
      } keys %{$form->form_tags}
   };

   return $self->_json_parser->encode({
      attributes      => $form_attr,
      currentPage     => $self->current_page,
      doFormWrapper   => json_bool $form->do_form_wrapper,
      errorMsg        => $error_message,
      fields          => $self->_serialise_fields,
      hasPageBreaks   => json_bool $self->_has_page_breaks,
      infoMessage     => $info_message,
      msgsBeforeStart => json_bool $form->messages_before_start,
      name            => $form->name,
      pageNames       => $self->page_names,
      pageSize        => $self->page_size,
      successMsg      => $success_message,
      tags            => $tags,
      wrapperAttr     => $wrapper_attr,
   });
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
