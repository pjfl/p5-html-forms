package HTML::Forms::Field;

use namespace::autoclean -except => '_html_forms_meta';

use Data::Dumper;
use HTML::Entities         qw( encode_entities );
use HTML::Forms::Constants qw( DOT EXCEPTION_CLASS TRUE FALSE NUL );
use HTML::Forms::Field::Result;
use HTML::Forms::Types     qw( Bool CodeRef HashRef HFs HFsArrayRefStr
                               HFsFieldResult Int Str Undef );
use HTML::Forms::Util      qw( convert_full_name has_some_value
                               merge ucc_widget );
use Ref::Util              qw( is_arrayref is_coderef is_hashref );
use Scalar::Util           qw( blessed weaken );
use Sub::Name;
use Try::Tiny;
use Unexpected::Functions  qw( inflate_placeholders throw );
use Moo;
use MooX::HandlesVia;
# TODO: Do we really need this?
use HTML::Forms::Moo;

has [ 'disabled',
      'is_contains',
      'no_value_if_empty',
      'not_nullable',
      'noupdate',
      'password',
      'readonly',
      'validate_when_empty',
      'writeonly' ] => is => 'rw', isa => Bool, default => FALSE;

has 'accessor' =>
   is          => 'rw',
   isa         => Str,
   builder     => sub {
      my $accessor = shift->name;

      $accessor =~ m{ \. }mx and $accessor =~ s{ \A (.*) \. }{}gmx;

      return $accessor;
   },
   lazy        => TRUE;

# 'active' is cleared whenever the form is cleared. Ephemeral activation.
has '_active' =>
   is         => 'rw',
   isa        => Bool,
   clearer    => 'clear_active',
   predicate  => 'has__active';

has 'default' => is => 'rw', lazy => TRUE;

has 'default_method' =>
   is          => 'ro',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => { _default => 'execute', },
   predicate   => 'has_default_method',
   writer      => '_set_default_method';

has 'default_over_obj' => is => 'rw', builder => sub { };

has 'deflation' => is => 'rw', isa => CodeRef, predicate => 'has_deflation';

has 'do_label' => is => 'rw', isa => Bool, default => TRUE;

has 'do_wrapper' => is => 'rw', isa => Bool, default => TRUE;

has 'field_group' => is => 'ro', isa => Str, default => NUL;

has 'fif_from_value' => is => 'ro', isa => Str;

has 'form'   =>
   is        => 'rw',
   isa       => HFs,
   predicate => 'has_form',
   weak_ref  => TRUE;

has 'html_name' =>
   is      => 'rw',
   isa     => Str,
   builder => sub {
      my $self   = shift;
      my $form   = $self->form;
      my $prefix = $form && $form->html_prefix ? $form->name . DOT : NUL;

      return $prefix . $self->full_name;
   },
   lazy    => 1;

has 'html5_type_attr' => is => 'ro', isa => Str, default => 'text';

has 'id'   =>
   is      => 'rw',
   isa     => Str,
   builder => sub { shift->html_name },
   lazy    => TRUE;

has 'inactive' => is => 'rw', isa => Bool, clearer => 'clear_inactive';

has 'init_value' =>
   is        => 'rw',
   clearer   => 'clear_init_value',
   predicate => 'has_init_value';

has 'input_without_param' => is => 'rw', predicate => 'has_input_without_param';

has 'label' =>
   is       => 'rw',
   isa      => Str|Undef,
   builder  => sub {
      my $label = ucfirst shift->name; $label =~ s{ _ }{ }gmx; return $label;
   },
   lazy     => TRUE;

has 'localise_method' =>
   is          => 'lazy',
   isa         => CodeRef,
   builder     => sub {
      my $self     = shift;
      my $defaults = [ '[?]', '[]', TRUE ]; # Undef, null, no quote bind value

      return sub { inflate_placeholders $defaults, @_ } unless $self->has_form;

      my $form = $self->form; weaken $form;

      return sub { $form->localise( @_ ) } if $form;
   },
   handles_via => 'Code',
   handles     => { _localise => 'execute' };

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

has 'name'   => is => 'rw', isa => Str, required => TRUE;

has 'order'  => is => 'rw', isa => Int,  default => 0;

has 'parent' => is => 'rw', predicate => 'has_parent', weak_ref => TRUE;

has '_pin_result' =>
   is     => 'ro',
   isa    => HFsFieldResult,
   reader => '_get_pin_result',
   writer => '_set_pin_result';

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

has 'set_default' => is => 'ro', isa => Str, writer => '_set_default';

has 'set_validate' => is => 'ro', isa => Str;

has 'style' => is => 'rw', isa => Str;

has 'tabindex' => is => 'rw', isa => Int;

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

has 'temp' => is => 'rw';

has 'title' => is => 'rw', isa => Str;

has 'trim' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub { {
      transform => sub {
         my $value  = shift; defined $value or return;
         my @values = is_arrayref( $value ) ? @{ $value } : ($value);

         for (grep { defined && !ref( $_ ) } @values) {
            s{ \A \s+ }{}mx; s{ \s+ \z }{}mx;
         }

         return is_arrayref( $value ) ? \@values : $values[ 0 ];
      },
   } };

has 'type' => is => 'rw', isa => Str, default => sub { ref shift };

has 'type_attr' => is => 'rw', isa => Str, default => 'text';

has 'validate_method' =>
   is          => 'lazy',
   isa         => CodeRef,
   builder     => 'build_validate_method',
   handles_via => 'Code',
   handles     => { _validate => 'execute', };

has 'widget' => is => 'rw', isa => Str;

has 'widget_wrapper' => is => 'rw', isa => Str;

has 'widget_name_space' =>
   is          => 'ro',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   coerce      => TRUE,
   handles_via => 'Array',
   handles     => { add_widget_name_space => 'push', };

has 'wrapper_tags' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => { has_wrapper_tags => 'count', };

{  # Create inflation/deflation methods
   for my $attr (qw(deflate deflate_value inflate inflate_default)) {
      has "${attr}_method" =>
         is          => 'ro',
         isa         => CodeRef,
         handles_via => 'Code',
         handles     => { $attr => 'execute' },
         predicate   => "has_${attr}_method",
         writer      => "_set_${attr}_method";
   }
}

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
         shift->$_add_meth( is_arrayref $_[ 0 ] ? @{ $_[ 0 ] } : @_ );
      }
   }
}

with 'HTML::Forms::Validate';
with 'HTML::Forms::Widget::ApplyRole';

sub BUILD {
   my ($self, $params) = @_;

#  $self->merge_tags( $self->wrapper_tags ) if $self->has_wrapper_tags;
   $self->build_default_method;
   $self->validate_method;
   $self->add_widget_name_space( @{ $self->form->widget_name_space } )
      if $self->form;
   $self->add_action( $self->trim ) if $self->trim;
   $self->_build_apply_list;
   $self->add_action( @{ $params->{apply} } ) if $params->{apply};

   return;
}

$Data::Dumper::Indent   = TRUE;
$Data::Dumper::Sortkeys = sub { [ sort keys %{ $_[ 0 ] } ] };
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

# Public methods
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

sub add_standard_element_classes {
   my ($self, $result, $class) = @_;

   push @{$class}, 'error'    if $result && $result->has_errors;
   push @{$class}, 'warning'  if $result && $result->has_warnings;
   push @{$class}, 'disabled' if $self->disabled;
   return;
}

sub add_standard_label_classes {
   my ($self, $result, $class) = @_;

   return;
}

sub add_standard_wrapper_classes {
   my ($self, $result, $class) = @_;

   push @{$class}, 'error'
      if $result->has_error_results || $result->has_errors;

   push @{$class}, 'warning' if $result->has_warnings;

   return;
}

sub attributes {
   return shift->element_attributes(@_);
}

# This is not a "true" builder, because sometimes 'default_method' is not set
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

sub build_result {
   my $self   = shift;
   my @parent = $self->parent && $self->parent->result
              ? ( 'parent' => $self->parent->result ) : ();
   my $result = HTML::Forms::Field::Result->new(
      field_def => $self, name => $self->name, @parent
   );

   # TODO: To prevent garbage collection of result and create circular ref
   $self->_set_pin_result( $result );
   $self->_set_result( $result );
}

sub build_validate_method {
   my $self = shift;
   my $form = $self->form; weaken $form;
   my $set_validate = $self->set_validate;

   $set_validate ||= 'validate_' . convert_full_name( $self->full_name );

   return $form && $form->can( $set_validate )
        ? sub { $form->$set_validate } : sub { };
}

sub clear_data  {
   my $self = shift;

   $self->clear_result;
   $self->clear_active;

   return;
}

sub dump {
   my $self = shift;

   warn 'HFs: ',         $self->name, "\n";
   warn 'HFs: type: ',   $self->type, "\n";
   warn 'HFs: required: ', ($self->required ? 'true' : 'false'), "\n";
   warn 'HFs: label: ',  $self->label,  "\n";
   warn 'HFs: widget: ', $self->widget || NUL, "\n";

   my $v   = $self->value;      warn 'HFs: value: ',      _emit( $v   ) if $v;
   my $iv  = $self->init_value; warn 'HFs: init_value: ', _emit( $iv  ) if $iv;
   my $i   = $self->input;      warn 'HFs: input: ',      _emit( $i   ) if $i;
   my $fif = $self->fif;        warn 'HFs: fif: ',        _emit( $fif ) if $fif;

   warn 'HFs: options: ' . Dumper( $self->options ) if $self->can( 'options' );

   return;
}

sub _emit {
   my $v = shift;

   return "${v}\n" if blessed $v and $v->isa( 'DateTime' );

   return Dumper( $v );
}

sub element_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr = {};

   if ($self->form && $self->form->has_flag( 'is_html5' )) {
      $attr->{required} = 'required'    if $self->required;
      $attr->{min} = $self->range_start if defined $self->range_start;
      $attr->{max} = $self->range_end   if defined $self->range_end;
   }

   for my $dep_attr ('disabled', 'readonly') {
      $attr->{ $dep_attr } = $dep_attr if $self->$dep_attr;
   }

   for my $dep_attr ('style', 'tabindex', 'title') {
      $attr->{ $dep_attr } = $self->$dep_attr if defined $self->$dep_attr;
   }

   $attr = { %{ $attr }, %{ $self->element_attr } };

   my $class = [ @{ $self->element_class } ];

   $self->add_standard_element_classes( $result, $class );

   $attr->{class} = $class if scalar @{ $class };

   return $attr unless $self->form;

   my $mod_attr
      = $self->form->html_attributes( $self, 'element', $attr, $result );

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

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
                ? $self->_apply_deflation( $lresult->value )
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

sub full_name {
   my $self = shift;
   my $name = $self->name;

   # Field should always have a parent unless it's a standalone field test
   my $parent_name = $self->parent->full_name if $self->parent;

   return defined $parent_name && length $parent_name
        ? "${parent_name}.${name}" : $name;
}

sub get_class_messages  {
   my $self = shift;
   my $messages = { %{ $class_messages } };

   $messages->{required} = $self->required_message if $self->required_message;
   $messages->{unique} = $self->unique_message if $self->unique_message;

   return $messages;
}

sub get_default_value {
   my $self = shift;

   return $self->_default if $self->has_default_method;
   return $self->default  if defined $self->default;
   return;
}

sub get_message {
   my ($self, $msg) = @_;

   # First look in messages set on individual field
   return $self->_get_field_message( $msg )
       if $self->_has_field_message( $msg );
   # then look at form messages
   return $self->form->_get_form_message( $msg )
       if $self->has_form && $self->form->_has_form_message( $msg );
   # then look for messages up through inherited field classes
   return $self->get_class_messages->{ $msg };
}

sub get_tag {
   my ($self, $name) = @_;

   return NUL unless $self->tag_exists( $name );

   my $tag = $self->_get_tag( $name );

   return $self->$tag if is_coderef $tag;
   return $tag unless $tag =~ m{ \A % }mx;

   (my $block_name = $tag) =~ s{ \A % }{}mx;

   return $self->form->block( $block_name )->render
      if $self->form && $self->form->block_exists( $block_name );

   return NUL;
}

sub has_flag {
   my ($self, $flag_name) = @_;

   return $self->can( $flag_name ) ? $self->$flag_name : undef;
}

sub has_input {
   my $self = shift;

   return $self->has_result ? $self->result->has_input : undef;
}

sub has_value {
   my $self = shift;

   return $self->has_result ? $self->result->has_value : undef;
}

sub html_element {
   return 'input';
}

sub input {
   my ($self, @args) = @_;

   # Allow testing fields individually by creating result if no form
   return unless $self->has_result || !$self->form;

   return @args ? $self->result->_set_input( @args ) : $self->result->input;
}

sub input_defined {
   my $self = shift;

   return $self->has_input ? has_some_value( $self->input ) : undef;
}

sub input_type {
   my $self = shift;

   return $self->form && $self->form->has_flag( 'is_html5' )
        ? $self->html5_type_attr : $self->type_attr;
}

sub is_active {
   my $self = shift;

   return !$self->is_inactive;
}

sub is_form { FALSE }

sub is_inactive {
   my $self = shift;

   return (($self->inactive && !$self->_active)
       || (!$self->inactive && $self->has__active && !$self->_active));
}

sub label_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr  = { %{ $self->label_attr  } };
   my $class = [ @{ $self->label_class } ];

   $self->add_standard_label_classes( $result, $class );

   $attr->{class} = $class if scalar @{ $class };

   return $attr unless $self->form;

   my $mod_attr
      = $self->form->html_attributes( $self, 'label', $attr, $result );

   return is_hashref $mod_attr ? $mod_attr : $attr;
}

sub loc_label {
   my $self = shift;

   return $self->_localise( $self->label );
}

sub merge_tags {
   my ($self, $new) = @_;

   my $old = $self->tags;

   return $self->tags( merge $new, $old );
}

sub push_errors {
   my ($self, @errors) = @_;

   $self->_push_errors( @errors );

   $self->parent->propagate_error( $self->result ) if $self->parent;

   return;
}

sub reset_result {
   my $self = shift;

   $self->clear_result;
   $self->build_result;
   return;
}

sub uwrapper {
   my $self = shift;

   return ucc_widget( $self->widget_wrapper || NUL ) || 'simple';
}

sub uwidget {
   my $self = shift;

   return ucc_widget( $self->widget || NUL ) || 'simple';
}

sub value {
   my ($self, @args) = @_;

   # Allow testing fields individually by creating result if no form
   return unless $self->has_result || !$self->form;

   my $result = $self->result or return;

   return @args ? $result->_set_value( @args ) : $result->value;
}

sub value_changed {
   my $self = shift; my @cmp;

   for ('init_value', 'value') {
      my $val = $self->$_ // NUL;

      push @cmp, join '|', sort
         map { blessed $_ && $_->isa( 'DateTime' ) ? $_->iso8601 : "${_}" }
         is_arrayref $val ? @{ $val } : $val;
   }

   return $cmp[ 0 ] ne $cmp[ 1 ];
}

sub wrapper_attributes {
   my ($self, $result) = @_; $result //= $self->result;

   my $attr  = { %{ $self->wrapper_attr  } };
   my $class = [ @{ $self->wrapper_class } ];

   $self->add_standard_wrapper_classes( $result, $class );

   $attr->{class} = $class if scalar @{ $class };

   $attr->{id} = $self->id if $self->has_flag( 'is_compound' )
      && !exists $attr->{id} && !$self->get_tag( 'no_wrapper_id' );

   return $attr unless $self->form;

   my $mod_attr
      = $self->form->html_attributes( $self, 'wrapper', $attr, $result );

   return $mod_attr && is_hashref $mod_attr ? $mod_attr : $attr;
}

sub wrapper_tag {
   my $self = shift; return $self->get_tag( 'wrapper_tag' ) || 'div';
}

# Private methods
sub _apply_deflation {
   my ($self, $value) = @_;

   if ($self->has_deflation) { $value = $self->deflation->( $value ) }
   elsif ($self->has_deflate_method) { $value = $self->deflate( $value ) }

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
      $result->_set_value( $self->init_value );
   }
   elsif (my @values = $self->get_default_value) {
      @values = $self->inflate_default( @values )
         if $self->has_inflate_default_method;

      my $value = @values > 1 ? \@values : shift @values;

      if (defined $value) {
         $self->init_value( $value );
         $result->_set_value( $value );
      }
   }

   $self->_set_result( $result );
   $result->_set_field_def( $self );
   return $result;
}

sub _result_from_input {
   my ($self, $result, $input, $exists) = @_;

   if ($exists) { $result->_set_input( $input ) }
   elsif ($self->disabled) {
      # This maybe should come from _result_from_object, but there's
      # not a reliable way to get there from here. Field can handle...
      return $self->_result_from_fields( $result );
   }
   elsif ($self->form and $self->form->use_fields_for_input_without_param) {
      return $self->_result_from_fields( $result );
   }
   elsif ($self->has_input_without_param) {
      $result->_set_input( $self->input_without_param );
   }

   $self->_set_result( $result );
   $result->_set_field_def( $self );
   return $result;
}

sub _result_from_object {
   my ($self, $result, $value) = @_;

   $self->_set_result( $result );

   if ($self->form) { $self->form->init_value( $self, $value ) }
   else {
      $self->init_value( $value );
      $result->_set_value( $value );
   }

   $result->_set_value( undef ) if $self->writeonly;
   $result->_set_field_def( $self );
   return $result;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field;
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
