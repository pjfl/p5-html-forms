package HTML::Forms::Field::Repeatable;

use HTML::Forms::Constants qw( DOT FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Bool HashRef HFsField Int Str );
use HTML::Forms::Util      qw( merge );
use JSON::MaybeXS          qw( encode_json );
use Ref::Util              qw( is_arrayref );
use Scalar::Util           qw( weaken );
use HTML::Forms::Field::Repeatable::Instance;
use HTML::Forms::Field::PrimaryKey;
use HTML::Forms::Field::Result;
use Moo;
use MooX::HandlesVia;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Compound';

has '+widget' => default => 'Repeatable';

has 'auto_id' => is => 'rw', isa => Bool, default => FALSE;

has 'contains' =>
   is          => 'rw',
   isa         => HFsField,
   predicate   => 'has_contains';

has 'index' => is => 'rw', isa => Int, default => 0;

has 'init_contains' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      has_init_contains => 'count',
   };

has 'instance_wrapper_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'input-repeatable';

has 'is_repeatable'  => is => 'ro', isa => Bool, default => TRUE;

has '_js_package'    => is => 'ro', isa => Str, default => 'HForms.Repeatable';

has 'num_extra'      => is => 'rw', isa => Int, default => 0;

has 'num_when_empty' => is => 'rw', isa => Int, default => 1;

has 'setup_for_js'   => is => 'rw', isa => Bool, default => TRUE;

after 'after_build' => sub {
   my $self = shift; weaken $self;
   my $form = $self->form;

   if ($form && $form->can('load_js_package')) {
      $form->load_js_package($self->_js_package);
      $form->load_js_package(sub { $self->render_repeatable_js });
   }

   return;
};

# Public methods
sub add_extra {
   my ($self, $count) = @_;

   $count = 1 unless defined $count;

   my $index = $self->index;

   while ($count) { $self->_add_extra( $index++ ); $count-- }

   return $self->index( $index );
}

sub clone_element {
   my ($self, $index) = @_;

   my $field = $self->contains->clone_field( errors => [], error_fields => [] );

   $field->name( $index );
   $field->parent( $self );

   $self->clone_fields( $field, [ $field->all_fields ] ) if $field->has_fields;

   return $field;
}

sub clone_fields {
   my ($self, $parent, $fields) = @_;

   $parent->fields( [] );

   for my $field (@{ $fields }) {
      my $new_field = $field->clone_field( errors => [], error_fields => [] );

      $self->clone_fields( $new_field, [ $new_field->all_fields ] )
         if $new_field->does('HTML::Forms::Fields') && $new_field->has_fields;

      $new_field->parent( $parent );
      $parent->add_field( $new_field );
   }

   return;
}

sub create_element {
   my $self = shift;
   my $instance_attr = {
      is_contains => TRUE,
      name        => 'contains',
      parent      => $self,
      type        => 'Repeatable::Instance',
   };

   # Primary_key array is used for reloading after database update
   $instance_attr->{primary_key} = $self->primary_key
      if $self->has_primary_key;

   $instance_attr = merge( $self->init_contains, $instance_attr )
      if $self->has_init_contains;

   my $instance;

   if ($self->form) {
      $instance_attr->{form} = $self->form;
      $instance = $self->form->_make_adhoc_field(
         'HTML::Forms::Field::Repeatable::Instance', $instance_attr
      );
   }
   else {
      $instance = HTML::Forms::Field::Repeatable::Instance->new(
         %{ $instance_attr }
      );
   }

   # Copy the fields from this field into the instance
   $instance->add_field( $self->all_fields );

   for my $field ($instance->all_fields) { $field->parent( $instance ) }

   # Set required flag
   $instance->required( $self->required );

   return $instance unless $self->auto_id;

   # auto_id has no way to change widgets...deprecate this?
   unless (grep { $_->can( 'is_primary_key' ) && $_->is_primary_key }
           $instance->all_fields) {
      my $field_attr = { name => 'id', parent => $instance };
      my $field;

      if ($self->form) { # This will pull in the widget role
         $field_attr->{form} = $self->form;
         $field = $self->form->_make_adhoc_field(
            'HTML::Forms::Field::PrimaryKey', $field_attr
         );
      }
      else { # The following won't have a widget role applied
         $field = HTML::Forms::Field::PrimaryKey->new( %{ $field_attr } );
      }

      $instance->add_field( $field );
   }

   return $instance;
}

sub init_state {
   my $self = shift;

   # must clear out instances built last time
   unless ($self->has_contains) {
      if ($self->num_fields == 1 and $self->field( 'contains' )) {
         $self->field( 'contains' )->is_contains( TRUE );
         $self->contains( $self->field( 'contains' ) );
      }
      else { $self->contains( $self->create_element ) }
   }

   $self->clear_fields;
   return;
}

sub render_repeatable_js {
   my $self = shift;
   my $form = $self->form or return;

   return NUL unless $form->has_for_js;

   my (%html, %index, %level);

   for my $name (keys %{$form->for_js}) {
      my $field = $form->for_js->{$name};

      $html{$name}  = $field->{html};
      $index{$name} = $field->{index};
      $level{$name} = $field->{level};
   }

   my $html_str  = encode_json( \%html );
   my $index_str = encode_json( \%index );
   my $level_str = encode_json( \%level );
   my $js        = $self->_js_package . DOT . 'initialise(%s, %s, %s)';

   return sprintf "${js}", $html_str, $index_str, $level_str;
}

# Private methods
sub _add_extra {
   my ($self, $index) = @_;

   my $field = $self->clone_element( $index );
   my $result =
      HTML::Forms::Field::Result->new( name => $index, parent => $self->result);

   $result = $field->_result_from_fields( $result );
   $self->result->add_result( $result ) if $result;
   $self->add_field( $field );
   return $field;
}

sub _fields_validate {
   my $self = shift;
   my @value_array;

   # Loop through array of fields and validate
   for my $field ($self->all_fields) {
      next if $field->is_inactive;

      # Validate each field and "inflate" input -> value.
      $field->validate_field;    # This calls the field's 'validate' routine
      push @value_array, $field->value if $field->has_value;
   }

   return $self->_set_value( \@value_array );
}

sub _result_from_fields { # Create an empty field
   my ($self, $result) = @_;

   # Check for defaults
   if (my @values = $self->get_default_value) {
      return $self->_result_from_object( $result, \@values );
   }

   $self->init_state;
   $self->_set_result( $result );

   my $count = $self->num_when_empty;
   my $index = 0;

   $self->fields( [] );

   while ($count > 0) {
      my $field = $self->clone_element( $index );
      my $result = HTML::Forms::Field::Result->new(
         name => $index, parent => $self->result
      );

      $result = $field->_result_from_fields( $result );
      $self->result->add_result( $result ) if $result;
      $self->add_field( $field );
      $index++;
      $count--;
   }

   $self->index( $index );
   $self->_setup_for_js if $self->setup_for_js;
   $self->result->_set_field_def( $self );
   return $result;
}

# params exist and validation will be performed (later)
sub _result_from_input {
   my ($self, $result, $input) = @_;

   $self->init_state;
   $result->_set_input( $input );
   $self->_set_result( $result );
   # If Repeatable has array input, need to build instances
   $self->fields( [] );

   my $index = 0;

   if (is_arrayref $input) {
      # Build appropriate instance array
      for my $element (@{ $input }) {
         next unless defined $element; # skip empty slots

         my $field  = $self->clone_element( $index );
         my $result = HTML::Forms::Field::Result->new(
            name => $index, parent => $self->result
         );

         $result = $field->_result_from_input( $result, $element, 1 );
         $self->result->add_result( $result );
         $self->add_field( $field );
         $index++;
      }
   }

   $self->index( $index );
   $self->_setup_for_js if $self->setup_for_js;
   $self->result->_set_field_def( $self );
   return $self->result;
}

# This is called when there is an init_object or a db item with values
sub _result_from_object {
   my ($self, $result, $values) = @_;

   return $self->_result_from_fields( $result )
      if $self->num_when_empty > 0 && !$values;

   $self->item( $values );
   $self->init_state;
   $self->_set_result( $result );
   $self->fields( [] );

   $values = [ $values ] if $values && !is_arrayref $values;

   # Create field instances and fill with values
   my $index = 0;
   my @new_values;

   for my $element (@{ $values }) {
      next unless $element;

      my $field = $self->clone_element( $index );
      my $result = HTML::Forms::Field::Result->new(
         name => $index, parent => $self->result
      );

      $element = $field->inflate_default( $element )
         if $field->has_inflate_default_method;

      $result = $field->_result_from_object( $result, $element );
      push @new_values, $result->value;
      $self->add_field( $field );
      $self->result->add_result( $field->result );
      $index++;
   }

   if (my $num_extra = $self->num_extra) {
      while ($num_extra) { $self->_add_extra( $index++ ); $num_extra--}
   }

   $self->index( $index );
   $self->_setup_for_js if $self->setup_for_js;
   $values = \@new_values if scalar @new_values;
   $self->_set_value( $values );
   $self->result->_set_field_def( $self );
   return $self->result;
}

sub _setup_for_js {
   my $self = shift;

   return unless $self->form;

   my $full_name   = $self->full_name;
   my $index_level =()= $full_name =~ /{index\d+}/g; $index_level++;
   my $field_name  = "{index-$index_level}";
   my $field       = $self->_add_extra( $field_name );
   my $rendered    = $field->render;

   # Remove extra result & field, now that it's rendered
   $self->result->_pop_result;
   $self->_pop_field;
   # Set the information in the form
   # $self->index is the index of the next instance
   $self->form->set_for_js( $self->full_name, {
      html => $rendered, index => $self->index, level => $index_level
   } );

   return;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Repeatable - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::Repeatable;
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

Copyright (c) 2018 Peter Flanigan. All rights reserved

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
