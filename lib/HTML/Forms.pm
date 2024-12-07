package HTML::Forms;

use 5.010001;
use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 67 $ =~ /\d+/gmx );

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE NUL );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef
                               HFsArrayRefStr HFsField HFsResult
                               LoadableClass Object Str Undef );
use Data::Clone            qw( clone );
use HTML::Forms::Util      qw( has_some_value );
use Ref::Util              qw( is_arrayref is_blessed_ref
                               is_coderef is_hashref );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( inflate_placeholders throw );
use HTML::Forms::Params;
use HTML::Forms::Result;
use Moo::Role ();
use Moo;
use MooX::HandlesVia;

extends 'HTML::Forms::Base';

=pod

=encoding utf-8

=head1 Name

HTML::Forms - HTML forms using Moo

=head1 Synopsis

   my $form = HTML::Forms->new_with_traits(
      name => 'test_tt', traits => [ 'HTML::Forms::Role::Defaults' ],
   );

   $form->render;

=head1 Description

Generates markup for and processes input from HTML forms. This is a L<Moo>
based copy of L<HTML::FormHandler>

=head2 JavaScript

Files F<wcom-*.js> are included in the F<share/js> directory of the source
tree. These will be installed to the F<File::ShareDir> distribution level
shared data files. Nothing further is done with these files. They should be
concatenated in sort order by filename and the result placed under the
webservers document root. Link to this from the web applications pages. Doing
this is outside the scope of this distribution

When content is loaded the JS method C<WCom.Form.Renderer.scan(content)> must
be called to inflate the otherwise empty HTML C<div> element if the front end
rendering class is being used. The function
C<WCom.Util.Event.onReady(callback)> is available to install the scan when the
page loads

=head2 Styling

A file F<hforms-minimal.less> is included in the F<share/less> directory
of the source tree.  This will be installed to L<File::ShareDir> distribution
level shared data files. Nothing further is done with this file. It would need
compiling using the Node.js LESS compiler to produce a CSS file which should be
placed under the web servers document root and then linked to in the header of
the web applications pages. This is outside the scope of this distribution

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item Mutable booleans defaulting false

=over 3

=item did_init_obj - True when the result has been initialised

=item do_form_wrapper - If true wraps the form in a containing element

=item do_label_colon - If true a colon is appended to the label

=item do_label_colon_right - If true place the label colon on the right

=item do_label_right - If true place the label on the right if the field

=item processed - True when the form has been processed

=item render_js_after - If true render the JS after the form

=item use_init_obj_when_no_accessor_in_item - Self describing

=item verbose - When true emits diagnostics on stderr

=back

=cut

has [ 'did_init_obj',
      'do_form_wrapper',
      'do_label_colon',
      'do_label_colon_right',
      'do_label_right',
      'processed',
      'render_js_after',
      'use_init_obj_when_no_accessor_in_item',
      'verbose' ] => is  => 'rw', isa => Bool, default => FALSE;

=pod

=item Immutable booleans defaulting false

=over 3

=item html_prefix - If true the form name is prepended to field names

=item is_html5 - If true apply HTML5 attributes to fields

=item messages_before_start - If true display messages before the form start

=item no_preload - If the true the result is not initialised on build

=item no_widgets - If true widget roles are not applied to the form

=item quote_bind_value - If true quote the bind values in messages

=back

=cut

has [ 'html_prefix',
      'is_html5',
      'messages_before_start',
      'no_preload',
      'no_widgets',
      'quote_bind_value' ] => is => 'ro', isa => Bool, default => FALSE;

=item action

URL for the action attribute on the form. A mutable string with no default

=cut

has 'action' => is  => 'rw', isa => Str;

=item active

A mutable array reference of active field names with an empty default

Handles; C<add_active>, C<clear_active>, and C<has_active> via the array trait

=cut

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

=item context

An optional mutable weak reference to the context object

=item clear_context

Clearer

=item has_context

Predicate

=cut

has 'context' =>
   is        => 'rw',
   clearer   => 'clear_context',
   predicate => 'has_context',
   weak_ref  => TRUE;

=item default_locale

If C<context> is provided and has a C<config> object use it's C<locale>
attribute, otherwise default to C<en>. An immutable lazy string used as
the default language in building the C<language_handle>

=cut

has 'default_locale' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;

      if ($self->has_context and my $context = $self->context) {
         return $context->config->locale
            if $context->can('config') && $context->config->can('locale');
      }

      return 'en';
   };

=item defaults

A mutable hash reference of default values keyed by field name. These are
applied to the field when the form is setup overriding the default value in
the field definition

Handles; C<clear_defaults> and C<has_defaults> via the hash trait

=cut

has 'defaults' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      clear_defaults => 'clear',
      has_defaults   => 'count',
   };

=item dependency

A mutable array reference of array references. Each inner reference should
contain two or more field names. If the first named field has a value then
the subsequent fields are required

=cut

has 'dependency' => is => 'rw', isa => ArrayRef[ArrayRef];

=item enctype

A mutable string without default. Sets the encoding type on the form element

=cut

has 'enctype' => is  => 'rw', isa => Str;

=item error_message

A mutable string without default. This string (if set) is rendered either
before or near the start of the form if the form result C<has_errors> or
C<has_form_errors>

=item clear_error_messsage

Clearer

=item has_error_message

Predicate

=cut

has 'error_message' =>
   is        => 'rw',
   isa       => Str,
   clearer   => 'clear_error_message',
   predicate => 'has_error_message';

=item field_traits

A lazy immutable array reference with an empty default. This list of
C<HTML::Forms::Widget::Field::Trait> roles are applied to all fields on the
form

Handles; C<add_field_trait> and C<has_field_traits> via the array trait

=cut

has 'field_traits' =>
   is          => 'lazy',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_field_trait  => 'push',
      has_field_traits => 'count',
   };

=item for_js

A mutable hash reference with an empty default. Provides support for the
C<Repeatable> field type. Keyed by the repeatable field name contains a
data structure used by the JS event handlers to add/remove repeatable fields
to/from the form. Populated automatically by the C<Repeatable> field type

Handles; C<clear_for_js>, C<has_for_js>, and C<set_for_js> via the hash trait

=cut

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

=item form_element_attr

A mutable hash reference with an empty default. Attributes and values applied
to the form element

Handles; C<delete_form_element_attr>, C<exists_form_element_attr>,
C<get_form_element_attr>, C<has_form_element_attr>, and
C<set_form_element_attr> via the hash trait

=item form_element_class

A mutable array reference of strings with an empty default. List of classes
to apply to the form element

Handles C<has_form_element_class> via the array trait

=item form_wrapper_attr

A mutable hash reference with an empty default. Attributes and values applied
to the form wrapper

Handles; C<delete_form_wrapper_attr>, C<exists_form_wrapper_attr>,
C<get_form_wrapper_attr>, C<has_form_wrapper_attr>, and
C<set_form_wrapper_attr> via the hash trait

=item form_wrapper_class

A mutable array reference of strings with an empty default. List of classes
to apply to the form wrapper

Handles C<has_form_wrapper_class> via the array trait

=cut

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

=item form_tags

An immutable hash reference with an empty default. The optional tags are
applied to the form HTML. Keys used;

=over 3

=item C<after> - Markup rendered at the very end of the form

=item C<after_start> - Markup rendered after the form has been started

=item C<before> - Markup rendered at the start before the form

=item C<before_end> - Markup rendered before the end of the form

=item C<error_class> - Error message class. Defaults to C<alert alert-severe>

=item C<info_class> - Info message class. Defaults to C<alert alert-info>

=item C<legend> - Content for the form's legend

=item C<messages_wrapper_class> - Defaults to C<form-messages>

=item C<no_form_messages> - If true no form messages will be rendered

=item C<success_class> - Defaults to C<alert alert-success>

=item C<wrapper_tag> - Tag to wrap the form in. Defaults to C<fieldset>

=back

The keys that contain markup are only implemented by the
L<Template Tookit|HTML::Forms::Render::WithTT> renderer

Handles; C<has_tag>, C<set_tag>, and C<tag_exists> via the hash trait

See L<HTML::Forms/get_tag>

=cut

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

=item http_method

An immutable string with a default of C<post>. The method attribute on the
form element

=cut

has 'http_method' => is  => 'ro', isa => Str, default => 'post';

=item inactive

A mutable array reference of inactive field names with an empty default

Handles; C<add_inactive>, C<clear_inactive>, and C<has_inactive> via the array
trait

=cut

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

=item index

An immutable hash reference of field objects with an empty default. Provides an
index by field name to the field objects in the
L<fields|HTML::Forms::Fields/fields> array

Handles; C<add_to_index>, C<field_from_index>, and C<field_in_index> via the
hash trait

=cut

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

=item info_message

A mutable string with no default. The information message to display at the
start of the form

=item clear_info_message

Clearer

=item has_info_message

Predicate

=cut

has 'info_message' =>
   is        => 'rw',
   isa       => Str,
   clearer   => 'clear_info_message',
   predicate => 'has_info_message';

=item init_object

A lazy untyped mutable attribute with no default. If C<item> is not set and
this attribute is, it will be used to initialise the C<result> object

=item clear_init_object

Clearer

=cut

has 'init_object' => is => 'rw', clearer => 'clear_init_object', lazy => TRUE;

=item language_handle

A lazy object built by C<build_language_handle>. An instance of
C<language_handle_class> it is used to translate text into different
languages via the calls to C<maketext>

=cut

has 'language_handle' =>
   is      => 'lazy',
   isa     => Object,
   builder => 'build_language_handle';

=item language_handle_class

A lazy loadable class which defaults to L<HTML::Forms::I18N>. The name of the
class which implements language translation. Expected to be a subclass of
L<Locale::Maketext>

=cut

has 'language_handle_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'HTML::Forms::I18N';

=item locales

A lazy immutable array reference of strings. Defaults to the C<locales> on
the C<request> object if available, empty otherwise

=item has_locales

Predicate

=cut

has 'locales' =>
   is         => 'lazy',
   isa        => ArrayRef[Str],
   coerce     => sub {
      my $v = shift; return is_arrayref $v ? $v : [ split m{ \s }mx, $v ];
   },
   default    => sub {
      my $self = shift;

      if ($self->has_context and my $req = $self->context->request) {
         return $req->locales if $req->can('locales');
      }

      return [];
   },
   predicate  => 'has_locales';

=item messages

A mutable hash reference of string with an empty default. If set these messages
will be used in preference to class messages by the C<get_message> method on
the field object

Handles; C<set_message> via the hash trait

=cut

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

=item name

A mutable string with a random default. The name of the form element

=cut

has 'name' =>
   is      => 'rw',
   isa     => Str,
   default => sub { 'form' . int( rand 1000 ) };

=item no_update

A mutable bool without default. If set to true the call
in C<process> to update the model will be skipped

=item clear_no_update

Clearer

=cut

has 'no_update' => is => 'rw', isa => Bool, clearer => 'clear_no_update';

=item params

A mutable hash reference with an empty default. Should be set to the keys
and values of the form when it is posted back. Parameters are munged by the
trigger. See L<HTML::Forms::Params>

Handles; C<clear_params>, C<get_param>, C<has_params>, and C<set_param> via
the hash trait

=cut

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
   lazy        => TRUE,
   trigger     => sub { shift->_munge_params( @_ ) };

=item params_args

An immutable array reference with an empty default. Arguments passed to the
L<HTML::Forms::Params> constructor

=cut

has 'params_args' => is => 'ro', isa => ArrayRef, default => sub { [] };

=item posted

A mutable boolean without default. Should be set to true if the form was posted

=item clear_posted

Clearer

=item has_posted

Predicate

=cut

has 'posted' =>
   is        => 'rw',
   isa       => Bool,
   clearer   => 'clear_posted',
   predicate => 'has_posted';

has '_renderer' =>
   is      => 'lazy',
   isa     => Object,
   handles => ['render'],
   default => sub {
      my $self = shift;
      my $args = { %{$self->renderer_args}, form => $self };

      return $self->renderer_class->new($args);
   };

=item renderer_args

An immutable hash reference passed to the constructor of the C<renderer> object
empty by default

=cut

has 'renderer_args' => is => 'ro', isa => HashRef, default => sub { {} };

=item renderer_class

A lazy loadable class which defaults to L<HTML::Forms::Render::WithTT>. The
class name of the C<renderer> object. Set to L<HTML::Forms::Render::EmptyDiv>
form rendering will by done by JS in the browser

=cut

has 'renderer_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   default => sub { 'HTML::Forms::Render::WithTT' };

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

=item result

An lazy immutable L<HTML::Forms::Result> object constructed by the
C<build_result> method

Handles; C<add_result>, C<all_form_errors>, C<clear_form_errors>,
C<form_errors>, C<has_form_errors>, C<has_input>, C<has_value>, C<input>,
C<is_valid>, C<num_form_errors>, C<push_form_errors>, C<ran_validation>,
C<results>, C<validated>, and C<value>

=item clear_result

Clearer

=item has_result

Predicate

=cut

has 'result' =>
   is        => 'lazy',
   isa       => HFsResult,
   builder   => 'build_result',
   clearer   => 'clear_result',
   handles   => [
      qw( _clear_input _clear_value _set_input _set_value add_result
          all_form_errors clear_form_errors form_errors has_form_errors
          has_input has_value input is_valid num_form_errors push_form_errors
          ran_validation results validated value )
   ],
   predicate => 'has_result',
   writer    => '_set_result';

=item style

A mutable string with no default. If set this is applied as the C<style>
attribute of the form

=cut

has 'style' => is  => 'rw', isa => Str;

=item success_message

A mutable string with no default. If set this is displayed near the start of
the form

=item clear_success_message

Clearer

=item has_success_message

Predicate

=cut

has 'success_message' =>
   is        => 'rw',
   isa       => Str,
   clearer   => 'clear_success_message',
   predicate => 'has_success_message';

=item title

An immutable string with no default. If set and L<HTML::Forms::Role::Defaults>
is applied to the form class this string will be used as the form legend

=cut

has 'title' => is => 'ro', isa => Str;

=item update_field_list

A mutable hash reference with an empty default. If set the keys are field
names an the values are hash references of field attribute names and values.
This will be applied to the fields in the form when C<setup_form> is called

Handles; C<clear_update_field_list>, C<has_update_field_list>, and
C<set_update_field_list> via the hash trait

=cut

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

=item use_defaults_over_obj

A mutable boolean without default. If true will use the defaults on the field
definition in preference to the C<item> object

=item clear_use_defaults_over_obj

Clearer

=cut

has 'use_defaults_over_obj' =>
   is      => 'rw',
   isa     => Bool,
   clearer => 'clear_use_defaults_over_obj';

=item use_fields_for_input_without_param

A mutable boolean without default. Changes how the field object instantiates
the result object

=cut

has 'use_fields_for_input_without_param' => is => 'rw', isa => Bool;

=item use_init_obj_over_item

A mutable boolean which defaults false. If true the C<init_object> is used in
preference to the C<item> when initialising the C<result> object

=item clear_use_init_obj_over_item

Clearer

=cut

has 'use_init_obj_over_item' =>
   is      => 'rw',
   isa     => Bool,
   clearer => 'clear_use_init_obj_over_item',
   default => FALSE;

=item widget_form

An immutable string which defaults to C<Simple>. If set to C<Complex> then
the L<HTML::Forms::Role::Widget::Form::Complex> role will be applied to the
form and result objects

=cut

has 'widget_form' =>
   is      => 'ro',
   isa     => Str,
   default => 'Simple',
   writer  => 'set_widget_form';

=item widget_name_space

An immutable array reference of string with an empty default. Additional name
spaces to be search when looking for widget roles

Handles; C<add_widget_name_space> via the array trait

=cut

has 'widget_name_space' =>
   is          => 'ro',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   coerce      => TRUE,
   handles_via => 'Array',
   handles     => { add_widget_name_space => 'push', };

=item widget_wrapper

An immutable string which defaults to C<Simple>. Adds a C<render> method to
the field object

=cut

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

Defines the following methods;

=over 3

=item BUILDARGS

Additionally allows for construction from either an C<item> object instance or
an C<item_id>

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

=item BUILD

Applies widget roles, builds the fields, sets the active field list, and
initialises the result object. Will also dump the field definitions if
C<verbose> is true

The methods C<before_build_fields>, and C<after_build_fields> are called either
side of the above and are dummy methods in this class. Made for overriding in a
form role

=cut

sub BUILD {
   my $self = shift;

   $self->before_build_fields;
   $self->apply_widget_role($self, $self->widget_form, 'Form')
      unless $self->no_widgets || $self->widget_form eq 'Simple';
   $self->build_fields;
   $self->build_active if $self->has_active
      || $self->has_inactive || $self->has_flag('is_wizard');
   $self->after_build_fields;

   return if defined $self->item_id && !$self->item;

   $self->_init_result(TRUE) unless $self->no_preload;
   $self->dump_fields if $self->verbose;
   return;
}

=item add_form_element_class

   $class = $self->add_form_element_class( @args );

Takes either an array reference of a list. Pushes onto the C<form_element>
class list

=cut

sub add_form_element_class {
   my ($self, @args) = @_;

   return $self->_add_form_element_class(
      is_arrayref $args[0] ? @{ $args[0] } : @args
   );
}

=item add_form_error

   $self->add_form_error( @message );

Pushes the supplied message (after localising) onto form errors. Uses the
C<form is invalid> message if one is not supplied

=cut

sub add_form_error {
   my ($self, @message) = @_;

   @message = ('form is invalid') unless defined $message[0];

   $self->push_form_errors($self->language_handle->maketext(@message));
   return;
}

=item add_form_wrapper_class

   $class = $self->add_form_wrapper_class( @args );

Takes either an array reference of a list. Pushes onto the C<form_wrapper>
class list

=cut

sub add_form_wrapper_class {
   my ($self, @args) = @_;

   return $self->_add_form_wrapper_class(
      is_arrayref $args[0] ? @{ $args[0] } : @args
   );
}

=item after_build_fields

Dummy method called by C<BUILD>. Expected to be decorated in the form classes

=cut

sub after_build_fields {}

=item after_update_model

Called after the the call to C<update_model>. Return without doing anything
unless we C<has_repeatable_fields> and we also has an C<item>. This an attempt
to reload the repeatable relationships after the database is updated, so that
we get the primary keys of the repeatable elements. Otherwise, if a form is
re-presented, repeatable elements without primary keys may be created
again. There is no reliable way to connect up existing repeatable elements with
their db-created primary keys.

=cut

sub after_update_model {
   my $self = shift;

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

=item attributes

A proxy for C<form_element_attributes>

=cut

sub attributes {
   return shift->form_element_attributes;
}

=item before_build_fields

Dummy method called at the start of the C<BUILD> method. Expected to be
decorated in the form classes

=cut

sub before_build_fields {}

=item build_active

Called at build time it clears the inactive status of any C<active> fields and
sets the inactive status on any C<inactive> fields

=cut

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

=item build_errors

Moves the errors to the C<result> object

=cut

sub build_errors {
   my $self = shift;

   for my $error_result (@{$self->result->error_results}) {
      $self->result->_push_errors($error_result->all_errors);
   }

   return;
}

=item build_language_handle

Constructor for the C<language_handle> attribute. Will use C<locales> if
available otherwise uses the environment variable C<LANGUAGE_HANDLE>.
Always appends C<default_locale> to the list supplied to the
C<language_handle_class>'s C<get_handle> constructor method

=cut

sub build_language_handle {
   my $self    = shift;
   my @locales = $self->has_locales            ? @{ $self->locales }
               : defined $ENV{LANGUAGE_HANDLE} ? ($ENV{LANGUAGE_HANDLE})
               : ();

   push @locales, $self->default_locale;

   return $self->language_handle_class->get_handle(@locales);
}

=item build_result

Builds the C<result> object an instance of L<HTML::Forms::Result>

=cut

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

=item clear

Calls all the clearers defined on the form object. Sets C<processed> and
C<did_init_obj> to false

=cut

sub clear {
   my $self = shift;

   $self->clear_data;
   $self->clear_params;
   $self->clear_posted;
   $self->clear_item;
   $self->clear_init_object;
   $self->clear_context;
   $self->processed(FALSE);
   $self->did_init_obj(FALSE);
   $self->clear_result;
   $self->clear_use_defaults_over_obj;
   $self->clear_use_init_obj_over_item;
   $self->clear_no_update;
   $self->clear_error_message;
   $self->clear_info_message;
   $self->clear_for_js;
   return;
}

=item fif

   $hash = $self->fif( @args );

Fill in form. Returns a hash reference whose keys are the field names and
whose values are take from the result

=cut

sub fif { shift->fields_fif(@_) }

=item form

Returns the self referential object

=cut

sub form { shift }

=item form_element_attributes

Returns a hash reference of keys and values which are applied to the form
element

Also calls C<html_attributes> with a 'type' of 'form_element' returning it's
returned hash reference if set. Allows for an overridden C<html_attributes>
to "fix things up" if required

=cut

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

=item form_wrapper_attributes

Returns a hash reference of keys and values which are applied to the form
wrapper element

Also calls C<html_attributes> with a 'type' of 'form_wrapper' returning it's
returned hash reference if set. Allows for an overridden C<html_attributes>
to "fix things up" if required

=cut

sub form_wrapper_attributes {
   my $self  = shift;
   my $attr  = { %{ $self->form_wrapper_attr } };
   my $class = [ @{ $self->form_wrapper_class } ];

   $attr->{class} = $class if scalar @{ $class };

   my $mod_attr = $self->html_attributes($self, 'form_wrapper', $attr);

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

=item full_accessor

Dummy method returns the null string

=cut

sub full_accessor { NUL }

=item full_name

Dummy method returns the null string

=cut

sub full_name { NUL }

=item get_default_value

Dummy method returns nothing

=cut

sub get_default_value { }

=item get_tag

   $tag_string = $self->get_tag( $name );

Returns the C<forms_tags> entry for the given name if it exists, otherwise
returns null. Code references a called as a method and their values are
returned. If the tag begins with a C<%> and the following word is a named
C<block> call the blocks render method and return that. Return null otherwise

=cut

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

=item has_flag

   $bool = $self->has_flag( $flag_name );

If the form object has a method C<flag_name> call it and return it's value.
Return undef otherwise

=cut

sub has_flag {
   my ($self, $flag_name) = @_;

   return $self->can($flag_name) ? $self->$flag_name : undef;
}

=item html_attributes

   $attrs = $self->html_attributes( $object, $type, $attrs, $result );

Dummy method that returns the supplied C<attrs>. Called by
C<form_element_attributes>. The C<type> argument is one of; 'element',
'element_wrapper', 'form_element', 'form_wrapper', 'label', or 'wrapper'.

Applied roles can modify this method to alter the attributes of the
above list of form elements

=cut

sub html_attributes {
   my ($self, $obj, $type, $attrs, $result) = @_;

   return $attrs;
}

=item init_value

   $self->init_value( $field, $value );

Sets both the initial and current field values to the one supplied

=cut

sub init_value {
   my ($self, $field, $value) = @_;

   $field->init_value($value);
   $field->_set_value($value);

   return;
}

=item localise

   $message = $self->localise( $message, @args );

Calls C<maketext> on the C<language_handle> to localise the supplied message.
If localisation fails will substitute the placeholder variables and return
that string

=cut

sub localise {
   my ($self, $message, @args) = @_;

   my $text = $self->language_handle->maketext($message, @args);

   return $text if $text;

   # Display values for undef and null bind values which are quoted by default
   my $defaults = [ '[?]', '[]', !$self->quote_bind_value ];

   return inflate_placeholders $defaults, $message, @args;
}

=item new_with_traits

   $form = $self->new_with_traits( %args );

Either a class or object method. Returns a new instance of this class with
the list of supplied C<traits> in the C<args> hash applied. This rest of the
C<args> hash is supplied to the constructor of the new object

=cut

sub new_with_traits {
   my ($class, %args) = @_;

   my $traits = delete $args{traits} || [];

   $class = blessed $class if is_blessed_ref $class;

   $class = Moo::Role->create_class_with_roles($class, @{ $traits })
      if scalar @{ $traits };

   return $class->new(%args);
}

=item process

   $validated = $self->process( @args );

Calls L<HTML::Forms/clear> if L<HTML::Forms/processed> is true. Calls
L<HTML::Forms/setup_form> with the supplied C<@args>. If the form was
L<HTML::Forms/posted> calls L<HTML::Forms/validate_form>. If
L<HTML::Forms/validated> is true and L<HTML::Forms/no_update> is false call
both L<HTML::Forms/update_model> and then L<HTML::Forms/after_update_model>.
Set L<HTML::Forms/processed> to true and return L<HTML::Forms/validated>

Consider this fragment from a controller/model method that processes a form
C<GET> or C<POST>. It stashes the form object (for rendering in the HTML
template) and if posted successfully stashes a redirect to the login page with
a message that should be displayed to the user

   my $form = $self->new_form('Register', { context => $context });

   if ($form->process( posted => $context->posted )) {
      my $job     = $context->stash->{job};
      my $login   = $context->uri_for_action('page/login');
      my $message = 'Registration request [_1] dispatched';

      $context->stash(redirect $login, [$message, $job->label]);
      return;
   }

   $context->stash(form => $form);

=cut

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

=item set_active

Set active fields to C<active> and inactive fields to C<inactive>

=cut

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

=item setup_form

   $self->setup_form( @args );

Called from L<HTML::Forms/process>. The C<@args> is either a hash reference or
a list of keys and values. The hash reference is used to instantiate the
C<params> hash reference, the list is used to set attributes on the form
object. L<HTML::Forms::Model/build_item> is called if we have an C<item_id>
and no C<item>. The C<result> object is cleared, fields have their activation
state set, L<HTML::Forms/update_fields> is called, C<posted> is set to true if
we has C<params> and C<posted> wasn't supplied to the constructor. The
C<result> is initialised. If C<posted> the result is cleared again and then
initialised from the C<params> provided

=cut

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

=item update_field

   $self->update_field( $field_name, $updates );

Updates the named field's attributes using the keys and values provided in the
C<updates> hash reference

=cut

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

=item update_fields

Called from L<HTML::Forms/process>. If we C<has_update_field_list> call
C<update_field> for each element in the list. If we C<has_defaults> call
C<update_field> supplying those defaults

=cut

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

=item validate

Dummy method which always returns true. Decorate this method from the form
class, it is called from L<HTML::Forms/validate_form>

=cut

sub validate { TRUE }

=item validate_form

Called from L<HTML::Forms/process> if the form was posted. Sets required
dependencies, validates individual fields, calls the above C<validate> method,
calls L<HTML::Forms::Model/validate_model>, sets field values, builds any
errors, clears the dependencies, clears C<posted>, sets C<ran_validation> to
true and returns the C<validated> attribute

=cut

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

=item values

Returns L<HTML::Forms::Result/value>

=cut

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

   my $_fix_params = HTML::Forms::Params->new(@{ $self->params_args || [] });
   my $new_params  = $_fix_params->expand_hash($params);

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

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

Setting L<HTML::Forms/verbose> to true will output diagnostic information to
C<stderr>

=head1 Dependencies

=over 3

=item L<Data::Clone>

=item L<Moo>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Forms.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

Gerda Shank E<lt>gshank@cpan.orgE<gt> - Author of L<HTML::FormHandler> of
which this is a L<Moo> based copy

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

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
