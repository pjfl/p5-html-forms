package HTML::Forms::Field;

use HTML::Forms::Constants qw( DOT EXCEPTION_CLASS TRUE FALSE META NUL );
use HTML::Forms::Types     qw( Bool CodeRef HashRef HFs HFsArrayRefStr
                               HFsFieldResult Int Str Undef );
use Data::Clone            qw( data_clone );
use HTML::Forms::Util      qw( convert_full_name has_some_value
                               merge ucc_widget );
use Ref::Util              qw( is_arrayref is_coderef is_hashref );
use Scalar::Util           qw( blessed weaken );
use Unexpected::Functions  qw( inflate_placeholders throw );
use HTML::Forms::Field::Result;
use Data::Dumper;
use Sub::Name;
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;
use Sub::HandlesVia;

$Data::Dumper::Indent   = TRUE;
$Data::Dumper::Sortkeys = sub { [ sort keys %{$_[0]} ] };
$Data::Dumper::Terse    = TRUE;

our $class_messages = {
   'error_occurred'  => 'error occurred',
   'field_invalid'   => 'field is invalid',
   'no_match'        => '[_1] does not match',
   'not_allowed'     => '[_1] not allowed',
   'range_incorrect' => 'Value must be between [_1] and [_2]',
   'range_too_high'  => 'Value must be less than or equal to [_1]',
   'range_too_low'   => 'Value must be greater than or equal to [_1]',
   'required'        => '[_1] field is required',
   'unique'          => 'Duplicate value for [_1]',
   'wrong_value'     => 'Wrong value',
};

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field - Base class for the field objects

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';
   with    'HTML::Forms::Role::Defaults';

   has '+title'        => default => 'Registration Request';
   has '+info_message' => default => 'Answer the registration questions';
   has '+item_class'   => default => 'User';
   has '+no_update'    => default => TRUE;

   has_field 'name' => label => 'User Name', required => TRUE;

   has_field 'email' => type => 'Email', required => TRUE;

   has_field 'submit' => type => 'Button';

=head1 Description

Base class for the field objects

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item Mutable booleans defaulting false

=over 3

=item C<disabled> - If true the field is disabled

=item C<hide_info> - If true do not display the field C<info>

=item C<is_contains> - Set to true if this is a container for other fields

=item C<label_top> - When true the label is rendered in and above the  field

=item C<no_value_if_empty> - If true do not validate when no input defined on a nullable field

=item C<not_nullable> - If true then the field cannot be null

=item C<noupdate> - If true do not try to update the result with this field value

=item C<password> - If true C<fif> will return null

=item C<readonly> - If true the field is read only

=item C<validate_inline> - If true set JS handler to validate field

=item C<validate_when_empty> - If true validate the field even if it has no value

=item C<writeonly> - If true prevents setting of field value from result object

=back

=cut

has [ 'disabled',
      'hide_info',
      'is_contains',
      'label_top',
      'no_value_if_empty',
      'not_nullable',
      'noupdate',
      'password',
      'readonly',
      'validate_inline',
      'validate_when_empty',
      'writeonly' ] => is => 'rw', isa => Bool, default => FALSE;

=item accessor

A mutable lazy string which defaults to the last dot separated component of
the C<name> attribute

=cut

has 'accessor' =>
   is      => 'rw',
   isa     => Str,
   lazy    => TRUE,
   default => sub {
      my $accessor = shift->name;

      $accessor =~ s{ \A (.*) \. }{}gmx if $accessor =~ m{ \. }mx;

      return $accessor;
   };

=item has__active

Predicate. The private C<_active> attribute is cleared whenever the form is
cleared. Ephemeral activation

=item clear_active

Clearer

=cut

has '_active' =>
   is         => 'rw',
   isa        => Bool,
   clearer    => 'clear_active',
   predicate  => 'has__active';

=item active_column

An immutable string which defaults to C<active>. Provides support for
L<HTML::Forms::Model::DBIC>

=cut

has 'active_column' => is => 'ro', isa => Str, default => 'active';

=item default

A lazy mutable untyped attribute. The default value for the field

=cut

has 'default' => is => 'rw', lazy => TRUE;

=item default_method

An immutable lazy code reference without default. When called it should return
the default value for the field

Handles; C<_default> as C<execute> via the code trait

=item has_default_method

Predicate

=cut

has 'default_method' =>
   is          => 'lazy',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => { _default => 'execute', },
   predicate   => 'has_default_method',
   writer      => '_set_default_method';

=item default_over_obj

A mutable boolean which defaults to false. If true initialise the field using
the default value from the field declaration instead of the value from the
C<item> object

=cut

has 'default_over_obj' => is => 'rw', isa => Bool, default => FALSE;

=item deflation

A mutable code reference without default. If set it is used by C<fif> to
deflate the fields result value for output. See also C<deflate_method> and
C<deflate_value>

=item has_deflation

Predicate

=cut

has 'deflation' => is => 'rw', isa => CodeRef, predicate => 'has_deflation';

=item do_label

A mutable boolean which defaults to true. If false the field label will not
be rendered

=cut

has 'do_label' => is => 'rw', isa => Bool, default => TRUE;

=item do_wrapper

A mutable boolean which defaults to true. If false the field will not be
rendered wrapped in a containing element

=cut

has 'do_wrapper' => is => 'rw', isa => Bool, default => TRUE;

=item element_wrapper_class

A mutable array reference of string with an empty default. Classes applied to
the field wrapper element

Handles; C<has_element_wrapper_class> via the array trait

=cut

has 'element_wrapper_class' =>
   is          => 'rw',
   isa         => HFsArrayRefStr,
   coerce      => TRUE,
   builder     => 'build_element_wrapper_class',
   handles_via => 'Array',
   handles     => {
      _add_element_wrapper_class => 'push',
      has_element_wrapper_class  => 'count',
   };

=item fif_from_value

An immutable boolean defaulting false. If true when C<fif> is called and the
result doesn't have a value use the result input instead

=cut

has 'fif_from_value' => is => 'ro', isa => Bool, default => FALSE;

=item form

A mutable weak reference to the form object

=item has_form

Predicate

=cut

has 'form'   =>
   is        => 'rw',
   isa       => HFs,
   predicate => 'has_form',
   weak_ref  => TRUE;

=item html_name

A lazy mutable string which defaults to the form prefix concatenated with
C<full_name>

=cut

has 'html_name' =>
   is      => 'rw',
   isa     => Str,
   builder => sub {
      my $self   = shift;
      my $form   = $self->form;
      my $prefix = $form && $form->html_prefix ? $form->name . DOT : NUL;

      return $prefix . $self->full_name;
   },
   lazy    => TRUE;

=item html5_type_attr

A mutable string which default to C<text>. When rendering an HTML5 form this
is the default element type to use

=cut

has 'html5_type_attr' => is => 'rw', isa => Str, default => 'text';

=item id

A lazy mutable string which defaults to the C<html_name> attribute value. The
C<id> set on the rendered input element

=cut

has 'id'   =>
   is      => 'rw',
   isa     => Str,
   builder => sub { shift->html_name },
   lazy    => TRUE;

=item inactive

A mutable boolean without default. If true this field is marked as
inactive. Inactive fields do not render in

=item clear_inactive

Clearer

=cut

has 'inactive' => is => 'rw', isa => Bool, clearer => 'clear_inactive';

=item info

A mutable string without default. This text to display near the start of the
form. Usually an instruction to fill in the form

=cut

has 'info' => is => 'rw', isa => Str;

=item init_value

A mutable untyped attribute without default. The fields initial value

=item has_init_value

Predicate

=item clear_init_value

Clearer

=cut

has 'init_value' =>
   is        => 'rw',
   clearer   => 'clear_init_value',
   predicate => 'has_init_value';

=item input_param

A mutable string without default. If set use this as the attribute to use
in the C<input> hash when initialising the result instead of the field C<name>

=cut

has 'input_param' => is => 'rw', isa => Str;

=item input_without_param

A mutable untyped attribute. Used to set the result input when initialising
the result from input

=item has_input_without_param

Predicate

=cut

has 'input_without_param' => is => 'rw', predicate => 'has_input_without_param';

=item js_package

An immutable string which defaults to C<WCom.Form.Util>. Object containing
JS utility methods

=cut

has 'js_package' => is => 'ro', isa => Str, default => 'WCom.Form.Util';

=item label

A lazy mutable string or an undefined value. The optional label for the field

=cut

has 'label' =>
   is       => 'rw',
   isa      => Str|Undef,
   builder  => sub {
      my $self  = shift;
      my $name  = $self->name;
      my $label;

      $label = $self->form->lookup_label($name) if $self->has_form;
      $label = ucfirst $name unless $label;
      $label =~ s{ _ }{ }gmx;
      return $label;
   },
   lazy     => TRUE;

=item localise_method

A lazy immutable code reference which is used to localise text messages. Will
use the C<localise> method on the form object if we have a form otherwise it
will just inflate the placeholders

Handles; C<_localise> as C<execute> via the code trait

=cut

has 'localise_method' =>
   is          => 'lazy',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => { _localise => 'execute' },
   builder     => sub {
      my $self     = shift;
      my $defaults = [ '[?]', '[]', TRUE ]; # Undef, null, no quote bind value

      return sub { inflate_placeholders $defaults, @_ } unless $self->has_form;

      my $form = $self->form; weaken $form;

      return sub { $form->localise( @_ ) };
   };

=item messages

A mutable hash reference of strings with an empty default. Additional messages
which might be used by the field

Handles; C<set_message> via the hash trait

=cut

has 'messages' =>
   is          => 'rw',
   isa         => HashRef[Str],
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      _get_field_message => 'get',
      _has_field_message => 'exists',
      set_message        => 'set',
   };

=item name

A mutable required string. The name of the field

=cut

has 'name'   => is => 'rw', isa => Str, required => TRUE;

=item order

A mutable integer defaulting to zero. Set to non zero fields are sorted by
this number. If left zero their order in form class is used

=cut

has 'order'  => is => 'rw', isa => Int,  default => 0;

=item parent

A mutable untyped weak reference to the parent field or form. No default

=item has_parent

Predicate

=cut

has 'parent' => is => 'rw', predicate => 'has_parent', weak_ref => TRUE;

has '_pin_result' =>
   is     => 'ro',
   isa    => HFsFieldResult,
   reader => '_get_pin_result',
   writer => '_set_pin_result';

=item result

An immutable weak reference to the result object

Handles; C<errors>, C<add_warning>, C<all_errors>, C<all_warnings>,
C<clear_errors>, C<has_errors>, C<has_warnings>, C<missing>, C<num_errors>,
C<num_warnings>, C<validated>, and C<warnings>

=item has_result

Predicate

=item clear_result

Clearer

=cut

has 'result' =>
   is        => 'ro',
   isa       => HFsFieldResult,
   clearer   => 'clear_result',
   handles   => [
      qw( _clear_input _clear_value errors _push_errors _set_input
          _set_value add_warning all_errors all_warnings clear_errors has_errors
          has_warnings missing num_errors num_warnings validated warnings )
   ],
   predicate => 'has_result',
   weak_ref  => TRUE,
   writer    => '_set_result';

=item set_default

An immutable string without default. Used by the C<build_default_method> method.
If not set the above method uses the string C<< default_C<full_name> >>. If the
form has that as a method installs that as the C<default_method> on this field
object

=cut

has 'set_default' => is => 'ro', isa => Str, writer => '_set_default';

=item set_validate

An immutable string without default. Used by the C<build_validate_method>
method.  If not set the above method uses the string C<< validate_C<full_name>
>>. If the form has that as a method installs that as the C<validate_method> on
this field object

=cut

has 'set_validate' => is => 'ro', isa => Str;

=item style

A mutable string without default. If set this is applied as the C<style>
attribute of the field

=cut

has 'style' => is => 'rw', isa => Str;

=item C<tabindex>

A mutable integer without default. If set this is applied as the C<tabindex>
attribute of the input field

=cut

has 'tabindex' => is => 'rw', isa => Int;

=item tags

A mutable hash reference with an empty default. Tag keys include;
C<after_element>, C<after_wrapper>, C<before_element>, C<before_wrapper>,
C<checkbox_element_wrapper>, C<controls_div>, C<error_class>, C<label_after>,
C<label_before>, C<label_right>, C<label_tag>, C<no_errors>, C<no_wrapper_id>,
C<reveal>, C<warning_class>, and C<wrapper_tag>. These are included in the
HTML when the field is rendered

Handles; C<delete_tag>, C<has_tag>, C<set_tag>, and C<tag_exists> via the hash
trait

=cut

has 'tags'       =>
    is           => 'rw',
    isa          => HashRef,
    builder      => sub { {} },
    handles_via  => 'Hash',
    handles      => {
      delete_tag => 'delete',
      _get_tag   => 'get',
      has_tag    => 'exists',
      set_tag    => 'set',
      tag_exists => 'exists',
    };

=item temp

A mutable untyped attribute without default. Not used anywhere by anything

=cut

has 'temp' => is => 'rw';

=item title

A mutable string without default. This title attribute of the fields rendered
HTML

=cut

has 'title' => is => 'rw', isa => Str;

=item trim

A mutable hash reference of code references. By default has one entry
C<transform> which is function that removes leading and trailing space from
the field value

=cut

has 'trim' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub {
      return {
         transform => sub {
            my $value = shift;

            return unless defined $value;

            my @values = is_arrayref($value) ? @{$value} : ($value);

            for (grep { defined && !ref($_) } @values) {
               s{ \A \s+ }{}mx; s{ \s+ \z }{}mx;
            }

            return is_arrayref($value) ? \@values : $values[0];
         }
      };
   };

=item type

A mutable string which defaults to the fields classname. Set to select the
field subclass

=cut

has 'type' => is => 'rw', isa => Str, default => sub { ref shift };

=item type_attr

A mutable string which defaults to C<text>. The HTML input element type
attribute

=cut

has 'type_attr' => is => 'rw', isa => Str, default => 'text';

=item validate_method

A lazy code reference constructed by C<build_validate_method>. The method
used to validate the field

Handles; C<_validate> as C<execute> via the code trait

=cut

has 'validate_method' =>
   is          => 'lazy',
   isa         => CodeRef,
   builder     => 'build_validate_method',
   handles_via => 'Code',
   handles     => { _validate => 'execute', };

=item widget

A mutable string without default. Set by the subclass it selects how the
field is rendered

=cut

has 'widget' => is => 'rw', isa => Str;

=item widget_wrapper

A mutable string without default. Returned by the C<uwrapper> method

=cut

has 'widget_wrapper' => is => 'rw', isa => Str;

=item widget_name_space

An immutable array reference of string with an empty default. The forms
C<widget_name_space> is added by the C<BUILD> method if set. This is searched
for C<Field::Traits>, C<Form>, and C<Wrapper> widgets by
L<HTML::Forms::Widget::ApplyRole>

Handles; C<add_widget_name_space> via the array trait

=cut

has 'widget_name_space' =>
   is          => 'ro',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   coerce      => TRUE,
   handles_via => 'Array',
   handles     => { add_widget_name_space => 'push', };

=item wrapper_tags

A mutable hash reference with an empty default. These tags are applied to the
HTML of the field wrapper

Handles; C<has_wrapper_tags> via the hash trait

=cut

has 'wrapper_tags' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => { has_wrapper_tags => 'count', };

=item deflate_method

An immutable code reference.

=item has_deflate_method

Predicate

=item deflate_value_method

An immutable code reference.

=item has_deflate_value_method

Predicate

=item inflate_method

An immutable code reference.

=item has_inflate_method

Predicate

=item inflate_default_method

An immutable code reference.

=item has_inflate_default_method

Predicate

=cut

{  # Create inflation/deflation methods
   for my $attr (qw(deflate deflate_value inflate inflate_default)) {
      has "${attr}_method" =>
         is          => 'ro',
         isa         => CodeRef,
         handles_via => 'Code',
         handles     => { $attr => 'execute_method' },
         predicate   => "has_${attr}_method",
         writer      => "_set_${attr}_method";
   }
}

=item element_attr

A mutable hash reference with an empty default.

=item element_class

A mutable array reference of string with an empty default.

=item add_element_class

A method that pushes onto the C<element_class>

=item label_attr

A mutable hash reference with an empty default.

=item label_class

A mutable array reference of string with an empty default.

=item add_label_class

A method that pushes onto the C<label_class>

=item wrapper_attr

A mutable hash reference with an empty default.

=item wrapper_class

A mutable array reference of string with an empty default.

=item add_wrapper_class

A method that pushes onto the C<wrapper_class>

=cut

{  # Create the attributes and methods for; element_attr, element_class,
   # label_attr, label_class, wrapper_attr, wrapper_class
   no strict 'refs';

   for my $attr ('element', 'label', 'wrapper') {
      # trigger to move 'class' set via _attr to the class slot
      my $add_meth = "add_${attr}_class";
      my $trigger_sub = sub {
         my ($self, $value) = @_;

         if (my $class = delete $self->{ "${attr}_attr" }->{class}) {
            $self->$add_meth( $class );
         }
      };

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
         },
         lazy        => TRUE,
         trigger     => $trigger_sub;
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

      # create wrapper for add_to_ to accept arrayref
      my $add_to_class = __PACKAGE__ . "::add_${attr}_class";
      my $_add_meth    = __PACKAGE__ . "::_add_${attr}_class";

      *$add_to_class = subname $add_to_class, sub {
         shift->$_add_meth( is_arrayref $_[0] ? @{ $_[0] } : @_ );
      };
   }
}

with 'HTML::Forms::Validate';
with 'HTML::Forms::Widget::ApplyRole';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

   $self->BUILD($params);

Merges the C<wrapper_tags>. Calls C<build_default_method> and build the
validate method. Adds the form C<widget_name_space>. Adds the C<trim> action if
set. Builds the C<apply_list> and adds the actions from C<< $params->{apply} >>

=cut

sub BUILD {
   my ($self, $params) = @_;

   $self->merge_tags($self->wrapper_tags) if $self->has_wrapper_tags;

   $self->build_default_method;
   $self->validate_method;

   $self->add_widget_name_space(@{$self->form->widget_name_space})
      if $self->form && $self->form->widget_name_space;

   $self->add_action($self->trim) if $self->trim;

   $self->_build_apply_list;

   $self->add_action(@{$params->{apply}}) if $params->{apply};

   return;
}

=item add_element_wrapper_class

   $class = $self->add_element_wrapper_class($class);

Pushes the supplied list or array reference of classes onto the element
wrapper class list

=cut

sub add_element_wrapper_class {
   my $self = shift;

   return $self->_add_element_wrapper_class(is_arrayref $_[0] ? @{$_[0]} : @_);
}

=item add_error

   $localised_error = $self->add_error(@message);

Localises the message, pushes it onto the list of error and returns it

=cut

sub add_error {
   my ($self, @message) = @_;

   @message = ($class_messages->{field_invalid}) unless defined $message[0];
   @message = @{$message[0]} if is_arrayref $message[0];

   my $out;

   try   { $out = $self->_localise(@message) }
   catch {
      throw 'Localizing error message for [_1] failed. Check brackets. [_2]',
         [$self->label, $_];
   };

   return $self->push_errors($out);
}

=item add_standard_element_classes

   $self->add_standard_element_classes($result, $class);

Conditionally pushes one or more of the following onto the C<class> array
reference; C<error>, C<warning>, and C<disabled>. These classes are applied to
the element HTML

=cut

sub add_standard_element_classes {
   my ($self, $result, $class) = @_;

   push @{$class}, 'error'    if $result && $result->has_errors;
   push @{$class}, 'warning'  if $result && $result->has_warnings;
   push @{$class}, 'disabled' if $self->disabled;
   return;
}

=item add_standard_element_wrapper_classes

   $self->add_standard_element_wrapper_classes($result, $class);

Does nothing, can be overridden in a subclass. These classes are applied to
the element wrapper HTML

=cut

sub add_standard_element_wrapper_classes {
   my ($self, $result, $class) = @_;

   return;
}

=item add_standard_label_classes

   $self->add_standard_label_classes($result, $class);

Does nothing, can be overridden in a subclass. These classes are applied to
the label HTML

=cut

sub add_standard_label_classes {
   my ($self, $result, $class) = @_;

   return;
}

=item add_standard_wrapper_classes

   $self->add_standard_wrapper_classes($result, $class);

Conditionally pushes one or more of the following onto the C<class> array
reference; C<input-field>, C<input-error>, C<input-warning>, and
C<label-right>. These classes are applied to the wrapper HTML

=cut

sub add_standard_wrapper_classes {
   my ($self, $result, $class) = @_;


   unshift @{$class}, 'input-field'
      unless ($class->[0] // NUL) =~ m{ compound }mx;
   push @{$class}, 'input-error'
      if $result->has_error_results || $result->has_errors;
   push @{$class}, 'input-warning' if $result->has_warnings;
   push @{$class}, 'label-right' if $self->get_tag('label_right');
   return;
}

=item attributes

Proxy for C<element_attributes>

=cut

sub attributes {
   return shift->element_attributes(@_);
}

=item build_default_method

Builds the method that is used to provide the field default value. This is not
a "true" builder, because sometimes C<default_method> is not set

=cut

sub build_default_method {
   my $self = shift;
   my $form = $self->form;
   my $set_default = $self->set_default;

   $set_default ||= 'default_' . convert_full_name($self->full_name);

   if ($form && $form->can($set_default)) {
      weaken $self;

      $self->_set_default_method(sub {
         return $self->form->$set_default($self, $self->form->item);
      });
   }

   return;
}

=item build_element_wrapper_class

Returns an empty array reference. Can be overloaded in subclasses

=cut

sub build_element_wrapper_class { [] }

=item build_result

Builds the result object

=cut

sub build_result {
   my $self   = shift;
   my @parent = $self->parent && $self->parent->result
              ? ( 'parent' => $self->parent->result ) : ();
   my $result = HTML::Forms::Field::Result->new(
      field_def => $self, name => $self->name, @parent
   );

   # TODO: To prevent garbage collection of result and create circular ref
   $self->_set_pin_result($result);
   $self->_set_result($result);
}

=item build_validate_method

Returns a code reference which is called as a method to validate this field

=cut

sub build_validate_method {
   my $self = shift;
   my $form = $self->form; weaken $form;
   my $set_validate = $self->set_validate;

   $set_validate ||= 'validate_' . convert_full_name($self->full_name);

   return $form && $form->can($set_validate)
        ? sub { $form->$set_validate } : sub { };
}

=item clear_data

Calls C<clear_result> and C<clear_active>

=cut

sub clear_data  {
   my $self = shift;

   $self->clear_result;
   $self->clear_active;

   return;
}

=item clone_field

   $field_object_ref = $self->clone_field(%params);

Returns a clone of this field with it's attributes mutated by the supplied
parameters

=cut

sub clone_field {
   my ($self, %params) = @_;

   my $class = blessed $self;

   return $class->new({ %{ data_clone($self) }, %params });
}

=item dump

Outputs to C<stderr> a dump of this objects attributes

=cut

sub dump {
   my $self = shift;

   warn 'HFs: Field name: ',   $self->name, "\n";
   warn 'HFs: type: ',   $self->type, "\n";
   warn 'HFs: required: ', ($self->required ? 'true' : 'false'), "\n";
   warn 'HFs: label: ',  $self->label,  "\n";
   warn 'HFs: widget: ', $self->widget || NUL, "\n";

   my $v   = $self->value;      warn 'HFs: value: ',      _emit($v  ) if $v;
   my $iv  = $self->init_value; warn 'HFs: init_value: ', _emit($iv ) if $iv;
   my $i   = $self->input;      warn 'HFs: input: ',      _emit($i  ) if $i;
   my $fif = $self->fif;        warn 'HFs: fif: ',        _emit($fif) if $fif;

   warn 'HFs: options: ' . Dumper($self->options) if $self->can('options');

   return;
}

sub _emit {
   my $v = shift;

   return "${v}\n" if blessed $v and $v->isa('DateTime');

   return Dumper($v);
}

=item element_attributes

   $attribute_hash = $self->element_attributes($result);

Returns a hash reference of attributes that are applied the the fields element
HTML. Calls C<html_attributes> on the form object if set, passing
C<element>

=cut

sub element_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr = {};

   if ($self->form && $self->form->has_flag('is_html5')) {
      $attr->{required} = 'required'    if $self->required;
      $attr->{min} = $self->range_start if defined $self->range_start;
      $attr->{max} = $self->range_end   if defined $self->range_end;
   }

   for my $dep_attr ('disabled', 'readonly') {
      $attr->{$dep_attr} = $dep_attr if $self->$dep_attr;
   }

   for my $dep_attr ('style', 'tabindex', 'title') {
      $attr->{$dep_attr} = $self->$dep_attr if defined $self->$dep_attr;
   }

   $attr->{size} = $self->size if $self->can('size') && $self->size;

   $attr = { %{$attr}, %{$self->element_attr} };

   my $class = [ @{$self->element_class} ];

   $self->add_standard_element_classes($result, $class);

   $attr->{class} = $class if scalar @{$class};

   return $attr unless $self->form;

   my $mod_attr
      = $self->form->html_attributes($self, 'element', $attr, $result);

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

=item element_wrapper_attributes

   $attribute_hash = $self->element_wrapper_attributes($result);

Returns a hash reference of attributes that are applied the the fields element
wrapper HTML. Calls C<html_attributes> on the form object if set, passing
C<element_wrapper>

=cut

sub element_wrapper_attributes {
   my ($self, $result) = @_;

   $result ||= $self->result;

   my $attr  = {};
   my $class = [ @{$self->element_wrapper_class} ];

   $self->add_standard_element_wrapper_classes($result, $class);

   $attr->{class} = $class if scalar @{$class};

   return $attr unless $self->form;

   my $mod_attr =
      $self->form->html_attributes($self, 'element_wrapper', $attr, $result );

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

=item C<fif>

   $value = $self->fif($result);

Fill in form. Returns the result value after having applied any deflation

=cut

sub fif {
   my ($self, $result) = @_;

   return if $self->inactive && !$self->_active;
   return NUL if $self->password;
   return unless $result || $self->has_result;

   my $lresult = $result || $self->result;

   if (($self->has_result && $self->has_input && !$self->fif_from_value) ||
       ($self->fif_from_value && !defined $lresult->value)) {
      return defined $lresult->input ? $lresult->input : NUL;
   }

   if ($lresult->has_value) {
      my $value = $self->_can_deflate
                ? $self->_apply_deflation($lresult->value)
                : $lresult->value;

      return defined $value ? $value : NUL;
   }
   elsif (defined $self->value) {
      # This is because checkboxes and submit buttons have their own 'value'
      # needs to be fixed in some better way
      return $self->value;
   }

   return NUL;
}

=item for_field

If the tag C<label_tag> is C<label> return the C<< for="<id>" >> string used
in the field label

=cut

sub for_field {
   my $self      = shift;
   my $label_tag = $self->get_tag('label_tag') || 'label';

   return NUL if $label_tag ne 'label';

   return ' for="' . $self->id . '"';
}

=item full_accessor

Returns C<< <parent accessor>.<accessor> >> if the field has a
parent. Otherwise returns just C<accessor>

=cut

sub full_accessor {
   my $self   = shift;
   my $parent = $self->parent;

   if ($self->is_contains) {
      return NUL unless $parent;
      return $parent->full_accessor;
   }

   my $accessor = $self->accessor;
   my $parent_accessor; $parent_accessor = $parent->full_accessor if $parent;

   return defined $parent_accessor && length $parent_accessor
        ? "${parent_accessor}.${accessor}" : $accessor;
}

=item full_name

Returns C<< <parent name>.<name> >> if the field has a parent. Otherwise
returns just C<name>

=cut

sub full_name {
   my $self = shift;
   my $name = $self->name;

   # Field should always have a parent unless it's a standalone field test
   my $parent_name; $parent_name = $self->parent->full_name if $self->parent;

   return defined $parent_name && length $parent_name
        ? "${parent_name}.${name}" : $name;
}

=item get_class_messages

Returns a hash reference of messages including C<required_message> and
C<unique_message> if set

=cut

sub get_class_messages  {
   my $self = shift;
   my $messages = { %{$class_messages} };

   $messages->{required} = $self->required_message if $self->required_message;
   $messages->{unique} = $self->unique_message if $self->unique_message;

   return $messages;
}

=item get_default_value

Returns the result of calling C<default_method> if set, returns C<default>
if defined, otherwise returns undefined

=cut

sub get_default_value {
   my $self = shift;

   return $self->_default if $self->has_default_method;
   return $self->default  if defined $self->default;
   return;
}

=item get_message

   $message_text = $self->get_message($message_name);

Returns the named message text if exists

=cut

sub get_message {
   my ($self, $msg) = @_;

   # First look in messages set on individual field
   return $self->_get_field_message($msg)
       if $self->_has_field_message($msg);
   # then look at form messages
   return $self->form->_get_form_message($msg)
       if $self->has_form && $self->form->_has_form_message($msg);
   # then look for messages up through inherited field classes
   return $self->get_class_messages->{$msg};
}

=item get_tag

   $tag = $self->get_tag($tag_name);

Returns the named tag if it exists

=cut

sub get_tag {
   my ($self, $name) = @_;

   return NUL unless $self->tag_exists($name);

   my $tag = $self->_get_tag($name);

   return $self->$tag if is_coderef $tag;
   return $tag unless $tag =~ m{ \A % }mx;

   (my $block_name = $tag) =~ s{ \A % }{}mx;

   return $self->form->block( $block_name )->render
      if $self->form && $self->form->block_exists($block_name);

   return NUL;
}

=item has_flag

   $bool = $self->has_flag($flag_name);

Returns true if the field object has the C<flag_name> as an attribute and it
is true

=cut

sub has_flag {
   my ($self, $flag_name) = @_;

   return $self->can($flag_name) ? $self->$flag_name : undef;
}

=item has_input

Returns true if we C<has_result> and that result C<has_input>

=cut

sub has_input {
   my $self = shift;

   return $self->has_result ? $self->result->has_input : undef;
}

=item has_value

Returns true if we C<has_result> and that result C<has_value>

=cut

sub has_value {
   my $self = shift;

   return $self->has_result ? $self->result->has_value : undef;
}

=item html_element

Returns the string C<input>. The default HTML element to render

=cut

sub html_element {
   return 'input';
}

=item input

   $input = $self->input(@args);

Accessor/mutator for the C<input> attribute on the result object

=cut

sub input {
   my ($self, @args) = @_;

   # Allow testing fields individually by creating result if no form
   return unless $self->has_result || !$self->form;

   return @args ? $self->result->_set_input(@args) : $self->result->input;
}

=item input_defined

Returns true if the field C<has_input> and that input C<has_some_value>

=cut

sub input_defined {
   my $self = shift;

   return $self->has_input ? has_some_value($self->input) : undef;
}

=item input_type

If the form's C<is_html5> flag is set return the C<html5_type_attr> otherwise
return the C<type_attr>

=cut

sub input_type {
   my $self = shift;

   return $self->form && $self->form->has_flag('is_html5')
        ? $self->html5_type_attr : $self->type_attr;
}

=item is_active

Returns true if the field is active. Inactive fields do not render in

=cut

sub is_active {
   my $self = shift;

   return !$self->is_inactive;
}

=item is_checkbox

Returns true if C<widget> is a checkbox

=cut

sub is_checkbox {
   my $self = shift;

   return lc $self->widget eq 'checkbox' ? TRUE : FALSE;
}

=item is_form

Returns false because this is a field not a form

=cut

sub is_form { FALSE }

=item is_inactive

Return true if the field is inactive. Inactive fields do not render in

=cut

sub is_inactive {
   my $self = shift;

   return (($self->inactive && !$self->_active)
       || (!$self->inactive && $self->has__active && !$self->_active));
}

=item label_attributes

   $attribute_hash = $self->label_attributes($result);

Returns a hash reference of attributes that are applied the the field label's
HTML. Calls C<html_attributes> on the form object if set, passing C<label>

=cut

sub label_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr  = { %{$self->label_attr } };
   my $class = [ @{$self->label_class} ];

   $self->add_standard_label_classes($result, $class);

   $attr->{class} = $class if scalar @{$class};

   return $attr unless $self->form;

   my $mod_attr
      = $self->form->html_attributes($self, 'label', $attr, $result);

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

=item localise_label

Returns the localised C<label> attribute

=cut

sub localise_label {
   my $self  = shift;
   my $label = $self->label;

   $label =~ s{ \A \s+ }{}mx;
   $label =~ s{ \s+ \z }{}mx;

   return $label ? $self->_localise($label) : NUL;
}

=item merge_tags

   $tags = $self->merge_tags($new_tags);

Merges the new tags in with the existing ones and returns the merged collection

=cut

sub merge_tags {
   my ($self, $new) = @_;

   my $old = $self->tags;

   return $self->tags(merge $new, $old);
}

=item push_errors

   $self->push_errors(@new_errors);

Pushes the new errors onto the list of errors and propagates the error to
the parent if set

=cut

sub push_errors {
   my ($self, @errors) = @_;

   $self->_push_errors(@errors);

   $self->parent->propagate_error($self->result) if $self->parent;

   return;
}

=item reset_result

Clears the result and builds a new one

=cut

sub reset_result {
   my $self = shift;

   $self->clear_result;
   $self->build_result;
   return;
}

=item C<uwrapper>

Returns the C<widget_wrapper> attribute or C<simple> if not set. Converts to
snake case and upcases the first character

=cut

sub uwrapper {
   my $self = shift;

   return ucc_widget($self->widget_wrapper || NUL) || 'simple';
}

=item C<uwidget>

Returns the C<widget> attribute or C<simple> if not set. Converts to snake
case and upcases the first character

=cut

sub uwidget {
   my $self = shift;

   return ucc_widget($self->widget || NUL) || 'simple';
}

=item value

   $value = $self->value($new_value);

Accessor/mutator for the results C<value> attribute

=cut

sub value {
   my ($self, @args) = @_;

   # Allow testing fields individually by creating result if no form
   return unless $self->has_result || !$self->form;

   my $result = $self->result or return;

   return @args ? $result->_set_value(@args) : $result->value;
}

=item value_changed

Return true if the C<init_value> and C<value> are different. Works if they are
lists as well as scalars

=cut

sub value_changed {
   my $self = shift;
   my @cmp;

   for ('init_value', 'value') {
      my $val = $self->$_ // NUL;

      push @cmp, join '|', sort
         map { blessed $_ && $_->isa('DateTime') ? $_->iso8601 : "${_}" }
         is_arrayref $val ? @{$val} : $val;
   }

   return $cmp[0] ne $cmp[1];
}

=item wrapper_attributes

   $attribute_hash = $self->wrapper_attributes($result);

Returns a hash reference of attributes that are applied the the field's wrapper
HTML. Calls C<html_attributes> on the form object if set, passing C<wrapper>

=cut

sub wrapper_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr  = { %{$self->wrapper_attr } };
   my $class = [ @{$self->wrapper_class} ];

   $self->add_standard_wrapper_classes($result, $class);

   $attr->{class} = $class if scalar @{$class};

   $attr->{id} = 'field_' . $self->id
      if !exists $attr->{id} && !$self->get_tag('no_wrapper_id');

   return $attr unless $self->form;

   my $mod_attr
      = $self->form->html_attributes($self, 'wrapper', $attr, $result);

   return $mod_attr && is_hashref $mod_attr ? $mod_attr : $attr;
}

=item wrapper_tag

Returns either the tag C<wrapper_tag>, or if the C<is_repeatable> flag is set
it returns C<fieldset>, or if neither are set it returns C<div>

=cut

sub wrapper_tag {
   my $self = shift;
   my $tag  = $self->get_tag('wrapper_tag');

   $tag ||= $self->has_flag('is_repeatable') ? 'fieldset' : 'div';

   return $tag;
}

# Private methods
sub _apply_deflation {
   my ($self, $value) = @_;

   if ($self->has_deflation) { $value = $self->deflation->($value) }
   elsif ($self->has_deflate_method) { $value = $self->deflate($value) }

   return $value;
}

sub _can_deflate {
   my $self = shift;

   return $self->has_deflation || $self->has_deflate_method;
}

# This is the recursive routine that is used
# to initialize field results if there is no initial object and no params
sub _result_from_fields {
   my ($self, $result) = @_;

   if ($self->disabled && $self->has_init_value) {
      $result->_set_value($self->init_value);
   }
   elsif (my @values = $self->get_default_value) {
      @values = $self->inflate_default(@values)
         if $self->has_inflate_default_method;

      my $value = @values > 1 ? \@values : shift @values;

      if (defined $value) {
         $self->init_value($value);
         $result->_set_value($value);
      }
   }

   $self->_set_result($result);
   $result->_set_field_def($self);
   return $result;
}

sub _result_from_input {
   my ($self, $result, $input, $exists) = @_;

   if ($exists) { $result->_set_input($input) }
   elsif ($self->disabled) {
      # This maybe should come from _result_from_object, but there's
      # not a reliable way to get there from here. Field can handle...
      return $self->_result_from_fields($result);
   }
   elsif ($self->form and $self->form->use_fields_for_input_without_param) {
      return $self->_result_from_fields($result);
   }
   elsif ($self->has_input_without_param) {
      $result->_set_input($self->input_without_param);
   }

   $self->_set_result($result);
   $result->_set_field_def($self);
   return $result;
}

sub _result_from_object {
   my ($self, $result, $value) = @_;

   $self->_set_result($result);

   if ($self->form) { $self->form->init_value($self, $value) }
   else {
      $self->init_value($value);
      $result->_set_value($value);
   }

   $result->_set_value(undef) if $self->writeonly;
   $result->_set_field_def($self);
   return $result;
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Validate>

=item L<HTML::Forms::Widget::ApplyRole>

=item L<HTML::Forms::Field::Result>

=item L<HTML::Forms::Moo>

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
