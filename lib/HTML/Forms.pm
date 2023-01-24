package HTML::Forms;

use 5.010001;
use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 2 $ =~ /\d+/gmx );

use Data::Clone            qw( clone );
use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE NUL );
use HTML::Forms::Result;
use HTML::Forms::Types     qw( ArrayRef Bool HashRef
                               HFsArrayRefStr HFsField HFsResult
                               LoadableClass Object Str Undef );
use HTML::Forms::Util      qw( has_some_value );
use Ref::Util              qw( is_arrayref is_blessed_ref
                               is_coderef is_hashref );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Unexpected::Functions  qw( inflate_placeholders throw );
use Moo::Role ();
use Moo;
use MooX::HandlesVia;

extends 'HTML::Forms::Base';

=pod

=encoding utf-8

=head1 Name

HTML::Forms - Generates markup for and processes input from HTML forms

=head1 Synopsis

   {
      package HTML::Forms::Renderer;

      use Moo::Role;

      with 'HTML::Forms::Render::WithTT';

      sub _build_tt_include_path { [ 'share/templates' ] }
   }

   my $form = HTML::Forms->new_with_traits(
      name => 'test_tt', traits => [ 'HTML::Forms::Renderer' ],
   );

   $form->render;

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=cut

has [ 'did_init_obj',
      'do_form_wrapper',
      'processed',
      'use_init_obj_when_no_accessor_in_item',
      'verbose' ] => is  => 'rw', isa => Bool, default => FALSE;

has [ 'html_prefix',
      'is_html5',
      'no_preload',
      'no_widgets',
      'quote_bind_value' ] => is => 'ro', isa => Bool, default => FALSE;

=item action

URL for the action attribute on the form

=cut

has 'action' => is  => 'rw', isa => Str;

has 'active'   =>
   is          => 'rw',
   isa         => ArrayRef[Str],
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_active   => 'push',
      clear_active => 'clear',
      has_active   => 'count',
   };

has 'ctx' => is => 'rw', clearer => 'clear_ctx', weak_ref => TRUE;

has 'default_locale' => is => 'ro', isa => Str, default => 'en';

has 'defaults' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      clear_defaults => 'clear',
      has_defaults   => 'count',
   };

has 'dependency' => is => 'rw', isa => ArrayRef;

has 'enctype' => is  => 'rw', isa => Str;

has 'field_traits' =>
   is          => 'lazy',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      has_field_traits => 'count',
   };

has 'for_js'   =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      clear_for_js => 'clear',
      has_for_js   => 'count',
      set_for_js   => 'set',
   };

for my $attr ('form_element', 'form_wrapper') {
   has "${attr}_attr" =>
      is          => 'rw',
      isa         => HashRef,
      builder     => sub { {} },
      handles_via => 'Hash',
      handles     => {
         "delete_${attr}_attr" => 'delete',
         "exists_${attr}_attr" => 'exists',
         "get_${attr}_attr"    => 'get',
         "has_${attr}_attr"    => 'count',
         "set_${attr}_attr"    => 'set',
      };
   has "${attr}_class" =>
      is          => 'rw',
      isa         => HFsArrayRefStr,
      builder     => sub { [] },
      coerce      => TRUE,
      handles_via => 'Array',
      handles     => {
         "_add_${attr}_class" => 'push',
         "has_${attr}_class"  => 'count',
      };
}

has 'form_tags' =>
   is           => 'ro',
   isa          => HashRef,
   builder      => sub { {} },
   handles_via  => 'Hash',
   handles      => {
      _get_tag   => 'get',
      has_tag    => 'exists',
      set_tag    => 'set',
      tag_exists => 'exists',
   };

has 'http_method' => is  => 'ro', isa => Str, default => 'post';

has 'inactive' =>
   is          => 'rw',
   isa         => ArrayRef[Str],
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_inactive   => 'push',
      clear_inactive => 'clear',
      has_inactive   => 'count',
   };

has 'index'    =>
   is          => 'ro',
   isa         => HashRef[HFsField],
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      add_to_index     => 'set',
      field_from_index => 'get',
      field_in_index   => 'exists',
   };

has 'info_message' =>
   is        => 'rw',
   clearer   => 'clear_info_message',
   predicate => 'has_info_message';

has 'init_object' => is => 'rw', clearer => 'clear_init_object';

has 'language_handle' =>
   is      => 'lazy',
   isa     => Object,
   builder => 'build_language_handle';

has 'language_handle_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'HTML::Forms::I18N';

has 'locales' =>
   is         => 'lazy',
   isa        => ArrayRef[Str],
   coerce     => sub { my $v = shift; return is_arrayref $v ? $v : [ $v ] },
   predicate  => 'has_locales';

has 'messages' =>
   is          => 'rw',
   isa         => HashRef[Str],
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      _get_form_message => 'get',
      _has_form_message => 'exists',
      set_message       => 'set',
   };

has 'name' =>
   is      => 'rw',
   isa     => Str,
   default => sub { 'form' . int( rand 1000 ) };

has 'no_update' => is => 'rw', isa => Bool, clearer => 'clear_no_update';

has 'params'   =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      clear_params => 'clear',
      get_param    => 'get',
      has_params   => 'count',
      set_param    => 'set',
   },
   trigger     => sub { shift->_munge_params( @_ ) };

has 'params_args' => is => 'ro', isa => ArrayRef, default => sub { [] };

has 'params_class' =>
   is      => 'ro',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'HTML::Forms::Params';

has 'posted' =>
   is        => 'rw',
   isa       => Bool,
   clearer   => 'clear_posted',
   predicate => 'has_posted';

has '_repeatable_fields' =>
   is          => 'rw',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_repeatable_field  => 'push',
      has_repeatable_fields => 'count',
      all_repeatable_fields => 'elements',
   };

has '_required' =>
   is          => 'rw',
   isa         => ArrayRef[HFsField],
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_required   => 'push',
      clear_required => 'clear',
   };

has 'result' =>
   is        => 'ro',
   isa       => HFsResult,
   builder   => 'build_result',
   clearer   => 'clear_result',
   handles   => [
      qw( _clear_input _clear_value _set_input _set_value add_result
          all_form_errors clear_form_errors form_errors has_form_errors
          has_input has_value input is_valid num_form_errors push_form_errors
          ran_validation results validated value )
   ],
   lazy      => TRUE,
   predicate => 'has_result',
   writer    => '_set_result';

has 'style' => is  => 'rw', isa => Str;

has 'update_field_list' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      clear_update_field_list => 'clear',
      has_update_field_list   => 'count',
      set_update_field_list   => 'set',
   };

has 'use_defaults_over_obj' =>
   is      => 'rw',
   isa     => Bool,
   clearer => 'clear_use_defaults_over_obj';

has 'use_fields_for_input_without_param' => is => 'rw', isa => Bool;

has 'use_init_obj_over_item' =>
   is      => 'rw',
   isa     => Bool,
   clearer => 'clear_use_init_obj_over_item';

has 'widget_form' =>
   is      => 'ro',
   isa     => Str,
   default => 'Simple',
   writer  => 'set_widget_form';

has 'widget_name_space' =>
   is          => 'ro',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   coerce      => TRUE,
   handles_via => 'Array',
   handles     => { add_widget_name_space => 'push', };

has 'widget_wrapper'=>
   is      => 'ro',
   isa     => Str,
   default => 'Simple',
   writer  => 'set_widget_wrapper';

with 'HTML::Forms::Model';
with 'HTML::Forms::Fields';
with 'HTML::Forms::InitResult';
with 'HTML::Forms::Widget::ApplyRole';
with 'HTML::Forms::Blocks';

=back

=head1 Subroutines/Methods

=cut

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $arg = $args[0];

   if (scalar @args == 1 && !is_hashref $arg) {
      return blessed( $arg ) ? { item => $arg } : { item_id => $arg };
   }

   return $orig->($self, @args);
};

sub BUILD {
   my $self = shift;

   $self->before_build;
   $self->apply_widget_role($self, $self->widget_form, 'Form')
      unless $self->no_widgets || $self->widget_form eq 'Simple';
   $self->build_fields;
   $self->build_active if $self->has_active
      || $self->has_inactive || $self->has_flag('is_wizard');
   $self->after_build;

   return if defined $self->item_id && !$self->item;

   $self->_init_result(TRUE) unless $self->no_preload;
   $self->dump_fields if $self->verbose;
   return;
}

# Public methods
sub add_form_element_class {
   my ($self, @args) = @_;

   return $self->_add_form_element_class(
      is_arrayref $args[0] ? @{ $args[0] } : @args
   );
}

sub add_form_error {
   my ($self, @message) = @_;

   @message = ('form is invalid') unless defined $message[0];

   $self->push_form_errors($self->language_handle->maketext(@message));
   return;
}

sub add_form_wrapper_class {
   my ($self, @args) = @_;

   return $self->_add_form_wrapper_class(
      is_arrayref $args[0] ? @{ $args[0] } : @args
   );
}

sub after_build {}

sub after_update_model {
   my $self = shift;
   # This an attempt to reload the repeatable
   # relationships after the database is updated, so that we get the
   # primary keys of the repeatable elements. Otherwise, if a form
   # is re-presented, repeatable elements without primary keys may
   # be created again. There is no reliable way to connect up
   # existing repeatable elements with their db-created primary keys.
   return unless $self->has_repeatable_fields && $self->item;

   for my $field ($self->all_repeatable_fields) {
      next unless $field->is_active;
      # Check to see if there are any repeatable subfields with
      # null primary keys, so we can skip reloading for the case
      # where all repeatables have primary keys.
      my $needs_reload = 0;

      for my $sub_field ($field->fields) {
         if ($sub_field->has_flag('is_compound')
             && $sub_field->has_primary_key) {
            for my $pk_field (@{ $sub_field->primary_key }) {
               $needs_reload++ unless $pk_field->fif;
            }

            last if $needs_reload;
         }
      }

      next unless $needs_reload;

      my @names = split m{ \. }mx, $field->full_name;
      my $rep_item = $self->find_sub_item($self->item, \@names);
      # $rep_item is a single row or an array of rows or undef
      # If we found a database item for the repeatable, replace
      # the existing result with a result derived from the item.
      if (ref $rep_item) {
         my $parent = $field->parent;
         my $result = $field->result;

         $field->init_state;

         my $new_result = $field->_result_from_object($result, $rep_item);
         # find index of existing result
         my $index = $parent->result->find_result_index(sub { $_ == $result });
         # replace existing result with new result
         $parent->result->set_result_at_index($index, $new_result);
      }
   }

   return;
}

sub attributes {
   return shift->form_element_attributes(@_);
}

sub before_build {}

sub build_active {
   my $self = shift;

   if ($self->has_active) {
      for my $fname (@{ $self->active }) {
         my $field = $self->field($fname);

         if ($field) { $field->clear_inactive }
         else { warn "Field ${fname} not found to set active\n" }
      }

      $self->clear_active;
   }

   if ($self->has_inactive) {
      for my $fname (@{ $self->inactive }) {
         my $field = $self->field($fname);

         if ($field) { $field->inactive(TRUE) }
         else { warn "Field ${fname} not found to set inactive\n" }
      }

      $self->clear_inactive;
   }

   return;
}

sub build_errors {
   my $self = shift;

   for my $error_result (@{$self->result->error_results}) {
      $self->result->_push_errors($error_result->all_errors);
   }

   return;
}

sub build_language_handle {
   my $self    = shift;
   my @locales = $self->has_locales            ? @{ $self->locales }
               : defined $ENV{LANGUAGE_HANDLE} ? ($ENV{LANGUAGE_HANDLE})
               : ($self->default_locale);

   return $self->language_handle_class->get_handle(@locales);
}

sub build_result {
   my $self  = shift;
   my $class = 'HTML::Forms::Result';

   if ($self->widget_form) {
      my $role = $self->get_widget_role($self->widget_form, 'Form');

      throw 'Form widget role [_1] not found', [$self->widget_form]
         unless $role;

      $class = Moo::Role->create_class_with_roles($class, $role);
   }

   return $class->new(form => $self, name => $self->name);
}

sub clear {
   my $self = shift;

   $self->clear_data;
   $self->clear_params;
   $self->clear_posted;
   $self->clear_item;
   $self->clear_init_object;
   $self->clear_ctx;
   $self->processed(FALSE);
   $self->did_init_obj(FALSE);
   $self->clear_result;
   $self->clear_use_defaults_over_obj;
   $self->clear_use_init_obj_over_item;
   $self->clear_no_update;
   $self->clear_info_message;
   $self->clear_for_js;
   return;
}

sub fif { shift->fields_fif(@_) }

sub form { shift }

sub form_element_attributes {
   my $self = shift;
   my $attr = {};

   $attr->{action } = $self->action if $self->action;
   $attr->{enctype} = $self->enctype if $self->enctype;
   $attr->{id     } = $self->name;
   $attr->{method } = $self->http_method if $self->http_method;
   $attr->{style  } = $self->style if $self->style;

   $attr = { %{ $attr }, %{ $self->form_element_attr } };

   my $class = [ @{ $self->form_element_class } ];

   $attr->{class} = $class if scalar @{ $class };

   my $mod_attr = $self->html_attributes($self, 'form_element', $attr);

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

sub form_wrapper_attributes {
   my $self  = shift;
   my $attr  = { %{ $self->form_wrapper_attr } };
   my $class = [ @{ $self->form_wrapper_class } ];

   $attr->{class} = $class if scalar @{ $class };

   my $mod_attr = $self->html_attributes($self, 'form_wrapper', $attr);

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

sub full_accessor { NUL }

sub full_name { NUL }

sub get_default_value { }

sub get_tag {
   my ($self, $name) = @_;

   return NUL unless $self->tag_exists($name);

   my $tag = $self->_get_tag($name);

   return $self->$tag if is_coderef $tag;
   return $tag unless $tag =~ m{ \A % }mx;

   (my $block_name = $tag) =~ s{ \A % }{}mx;

   return $self->form->block($block_name)->render
      if $self->form && $self->form->block_exists($block_name);

   return NUL;
}

sub has_flag {
   my ($self, $flag_name) = @_;

   return $self->can($flag_name) ? $self->$flag_name : undef;
}

sub html_attributes {
   my ($self, $obj, $type, $attrs, $result) = @_;

   return $attrs;
}

sub init_value {
   my ($self, $field, $value) = @_;

   $field->init_value($value);
   $field->_set_value($value);

   return;
}

sub localise {
   my ($self, @message) = @_;

   my $in = shift @message;
   my $out;

   try   { $out = $self->language_handle->maketext($in) }
   catch { $out = $in };

   # Display values for undef and null bind values which are quoted by default
   my $defaults = [ '[?]', '[]', !$self->quote_bind_value ];

   return inflate_placeholders $defaults, $out, @message;
}

sub new_with_traits {
   my ($class, %args) = @_;

   $class = blessed $class if is_blessed_ref $class;

   my $traits = delete $args{traits} // [];

   $class = Moo::Role->create_class_with_roles($class, @{ $traits })
      if scalar @{ $traits };

   return $class->new(%args);
}

sub process {
   my ($self, @args) = @_;

   warn "HFs: process ", $self->name, "\n" if $self->verbose;
   $self->clear if $self->processed;
   $self->setup_form(@args);
   $self->validate_form if $self->posted;

   if ($self->validated && !$self->no_update) {
      $self->update_model;
      $self->after_update_model;
   }

   $self->dump_fields if $self->verbose;
   $self->processed(TRUE);

   return $self->validated;
}

sub set_active {
   my $self = shift;

   if ($self->has_active) {
      for my $fname (@{ $self->active }) {
         my $field = $self->field($fname);

         if ($field) { $field->_active(TRUE) }
         else { warn "Field ${fname} not found to set active" }
      }

      $self->clear_active;
   }

   if ($self->has_inactive) {
      for my $fname (@{ $self->inactive }) {
         my $field = $self->field($fname);

         if ($field) { $field->_active(FALSE) }
         else { warn "Field ${fname} not found to set inactive" }
      }

      $self->clear_inactive;
   }

   return;
}

sub setup_form {
   my ($self, @args) = @_;

   if (@args == 1) { $self->params( $args[0] ) }
   elsif (@args > 1) {
      my $hashref = { @args };

      while (my ($key, $value) = each %{ $hashref }) {
         throw 'Invalid attribute [_1] passed to setup_form', [ $key ]
            unless $self->can($key);
         $self->$key($value);
      }
   }

   $self->item($self->build_item) if $self->item_id && !$self->item;
   $self->clear_result;
   $self->set_active;
   $self->update_fields;
   # Initialization of Repeatable fields and Select options will be done in
   # _result_from_object when there's an initial object in _result_from_input
   # when there are params and by _result_from_fields for empty forms
   $self->posted(TRUE) if $self->has_params && !$self->has_posted;
   $self->_init_result unless $self->did_init_obj;

   # If params exist and if posted flag is either not set or set to true
   my $params = clone($self->params);

   if ($self->posted) {
      $self->clear_result;
      $self->_result_from_input($self->result, $params, TRUE);
   }

   return;
}

sub update_field {
   my ($self, $field_name, $updates) = @_;

   my $field = $self->field($field_name) or
      throw 'Field [_1] is not found and cannot be updated by update_field',
         [ $field_name ];

   while (my ($attr_name, $attr_value) = each %{ $updates }) {
      throw 'Invalid attribute [_1] passed to update_field', [ $attr_name ]
         unless $field->can($attr_name);

      if ($attr_name eq 'tags') { $field->set_tag(%{ $attr_value }) }
      else { $field->$attr_name($attr_value) }
   }

   return;
}

sub update_fields {
   my $self = shift;

   if ($self->has_update_field_list) {
      my $updates = $self->update_field_list;

      for my $field_name (keys %{ $updates }) {
         $self->update_field($field_name, $updates->{$field_name});
      }

      $self->clear_update_field_list;
   }

   if ($self->has_defaults) {
      my $defaults = $self->defaults;

      for my $field_name (keys %{ $defaults }) {
         $self->update_field($field_name, {
            default => $defaults->{ $field_name },
         });
      }

      $self->clear_defaults;
   }

   return;
}

sub validate { TRUE }

sub validate_form {
   my $self = shift;

   $self->_set_dependency;    # set required dependencies
   $self->_fields_validate;
   $self->validate;           # empty method for users
   $self->validate_model;     # model specific validation
   $self->fields_set_value;
   $self->build_errors;       # move errors to result
   $self->_clear_dependency;
   $self->clear_posted;
   $self->ran_validation(TRUE);

   $self->dump_validated if $self->verbose;

   return $self->validated;
}

sub values {
   return shift->value;
}

# Private methods
sub _clear_dependency {
   my $self = shift;

   $_->required(FALSE) for @{$self->_required};

   $self->clear_required;
   return;
}

sub _init_result {
   my ($self, $construction) = @_;

   if (my $init_object = $self->use_init_obj_over_item
       ? ($self->init_object || $self->item)
       : ($self->item || $self->init_object)) {
      $self->_result_from_object($self->result, $init_object);
   }
   elsif ($construction || !$self->posted) {
      # No initial object. empty form must be initialized
      $self->_result_from_fields($self->result);
   }

   return;
}

sub _munge_params {
   my ($self, $params, $attr) = @_;

   my $_fix_params = $self->params_class->new(@{ $self->params_args || [] });
   my $new_params = $_fix_params->expand_hash($params);

   $new_params = $new_params->{$self->name} if $self->html_prefix;

   $self->{params} = $new_params // {}; # TODO: Ick
   return;
}

sub _set_dependency {
   my $self    = shift;
   my $depends = $self->dependency || return;
   my $params  = $self->params;

   for my $group (@{$depends}) {
      next if @{$group} < 2;

      for my $name (@{$group}) {
         my $value = $params->{$name};

         next unless has_some_value($value);
         next if $self->field($name)->type eq 'Boolean' && $value == 0;

         for (@{$group}) {
            my $field = $self->field($_);

            next unless $field && !$field->required;

            $self->add_required($field);
            $field->required(TRUE);
         }

         last;
      }
   }

   return;
}

1;

__END__

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Moo>

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

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
