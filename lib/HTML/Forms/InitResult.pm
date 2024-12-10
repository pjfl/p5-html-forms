package HTML::Forms::InitResult;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Field::Result;
use Ref::Util              qw( is_arrayref is_plain_hashref );
use Scalar::Util           qw( blessed );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::InitResult - Initialise result

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::InitResult';

=head1 Description

Initialise result

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item find_sub_item

   $item = $self->find_sub_item( $item, $field_name_arry );

This is used for reloading repeatable fields from the database if they've
changed and for finding field values in the C<init_object> when we have an item
and the C<use_init_obj_when_no_accessor_in_item> flag is set

=cut

sub find_sub_item {
   my ($self, $item, $field_name_array) = @_;

   my $this_fname = shift @{ $field_name_array };
   my $field = $self->field( $this_fname );
   my $new_item = $self->_get_value( $field, $item );

   $new_item = $field->find_sub_item( $new_item, $field_name_array )
      if scalar @{ $field_name_array };

   return $new_item;
}

sub _get_value {
   my ($self, $field, $item) = @_;

   my $accessor = $field->accessor;
   my @values;

   if ($field->default_over_obj) {
      @values = $field->get_default_value;
   }
   elsif ($field->form && $field->form->use_defaults_over_obj
      && (@values = $field->get_default_value)) {
   }
   elsif (blessed($item) && $item->can($accessor)) {
      # This must be an array, so that DBIx::Class relations are arrays not
      # resultsets
      @values = $item->$accessor;
      # For non-DBIC blessed object where access returns arrayref
      if (scalar @values == 1 && $field->has_flag('multiple')
          && is_arrayref $values[0]) {
         @values = @{$values[0]};
      }
   }
   elsif (exists $item->{$accessor}) {
      my $v = $item->{$accessor};

      if ($field->has_flag('multiple') && is_arrayref $v) { @values = @{$v}}
      else { @values = $v }
   }
   elsif (@values = $field->get_default_value) {
   }
   else { return }

   @values = $field->inflate_default(@values)
      if $field->has_inflate_default_method;

   my $value;

   if ($field->has_flag('multiple')) {
      $value = scalar @values == 1 && ! defined $values[0] ? [] : \@values;
   }
   else { $value = @values > 1 ? \@values : shift @values }

   return $value;
}

# _init is for building fields when there is no initial object and no params
sub _result_from_fields {
   my ($self, $self_result) = @_;

   # Defaults for compounds, etc.
   if (my @values = $self->get_default_value) {
      my $value = @values > 1 ? \@values : shift @values;

      return $self->_result_from_object( $self_result, $value )
         if blessed $value || is_plain_hashref $value;

      if (defined $value) {
         $self->init_value( $value );
         $self_result->_set_value( $value );
      }
   }

   my $my_value;

   for my $field ($self->sorted_fields) {
      next if $field->inactive && !$field->_active;

      my $result = HTML::Forms::Field::Result->new(
         name => $field->name, parent => $self_result
      );

      $result = $field->_result_from_fields( $result );
      $my_value->{ $field->name } = $result->value if $result->has_value;
      $self_result->add_result( $result ) if $result;
   }

   # Setting value here to handle disabled compound fields, where we want to
   # preserve the 'value' because the fields aren't submitted...except for the
   # form. Not sure it's the best idea to skip for form, but it maintains
   # previous behavior
#   $self_result->_set_value( $my_value ) if scalar keys %{ $my_value };
   $self->_set_result( $self_result );
   $self_result->_set_field_def( $self ) if $self->DOES( 'HTML::Forms::Field' );

   return $self_result;
}

# Building fields from input (params) formerly done in validate_field
sub _result_from_input {
   my ($self, $self_result, $input, $exists) = @_;

   # Transfer the input values to the input attributes of the subfields
   return unless defined( $input ) || $exists || $self->has_fields;

   $self_result->_set_input( $input );

   if (is_plain_hashref $input) {
      for my $field ($self->sorted_fields) {
         next if $field->inactive && !$field->_active;

         my $field_name = $field->name;
         my $result = HTML::Forms::Field::Result->new(
            name => $field_name, parent => $self_result
         );

         $result = $field->_result_from_input(
            $result,
            $input->{ $field->input_param || $field_name },
            exists $input->{ $field->input_param || $field_name }
         );

         $self_result->add_result( $result ) if $result;
      }
   }

   $self->_set_result( $self_result );
   $self_result->_set_field_def( $self ) if $self->DOES( 'HTML::Forms::Field' );

   return $self_result;
}

# Building fields from model object or init_obj hash formerly _init_from_object
sub _result_from_object {
   my ($self, $self_result, $item) = @_;

   return unless $item || $self->has_fields; # Empty fields for compounds

   my $init_obj = $self->form->init_object;
   my $my_value;

   for my $field ($self->sorted_fields) {
      next if $field->inactive && !$field->_active;

      my $result = HTML::Forms::Field::Result->new(
         name => $field->name, parent => $self_result
      );

      if ((is_plain_hashref $item && !exists $item->{ $field->accessor } )
          || (blessed $item && !$item->can( $field->accessor ))) {
         my $found = FALSE;

         if ($field->form->use_init_obj_when_no_accessor_in_item) {
            # If we're using an item, look for accessor not found in item
            # in the init_object
            my @names = split m{ \. }mx, $field->full_name;
            my $init_obj_value = $self->find_sub_item( $init_obj, \@names );

            if (defined $init_obj_value) {
               $found = TRUE;
               $result = $field->_result_from_object(
                  $result, $init_obj_value
               );
            }
         }

         $result = $field->_result_from_fields( $result ) unless $found;
      }
      else {
         my $value;

         $value = $self->_get_value( $field, $item ) unless $field->writeonly;
         $result = $field->_result_from_object( $result, $value );
      }

      $self_result->add_result( $result ) if $result;
      $my_value->{ $field->name } = $field->value;
   }

   $self_result->_set_value( $my_value );
   $self->_set_result( $self_result );
   $self_result->_set_field_def( $self ) if $self->DOES( 'HTML::Forms::Field' );

   return $self_result;
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
