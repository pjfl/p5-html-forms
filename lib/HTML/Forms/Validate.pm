package HTML::Forms::Validate;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE FALSE NUL );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Int Str Undef );
use HTML::Forms::Util      qw( get_meta );
use Ref::Util              qw( is_arrayref is_coderef is_hashref
                               is_regexpref is_scalarref );
use Scalar::Util           qw( blessed refaddr );
use Try::Tiny;
use Unexpected::Functions  qw( throw );
use Moo::Role;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Validate - Validation methods

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Validate';

=head1 Description

Validation methods

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item actions

=cut

has 'actions'  =>
   is          => 'rw',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_action    => 'push',
      clear_actions => 'clear',
      has_actions   => 'count',
      num_actions   => 'count',
   };

=item range_end

=cut

has 'range_end'   => is => 'rw', isa => Int|Undef;

=item range_start

=cut

has 'range_start' => is => 'rw', isa => Int|Undef;

=item required

=cut

has 'required' => is => 'rw', isa => Bool, default => FALSE;

=item required_when

=item has_required_when

Predicate

=cut

has 'required_when' =>
   is               => 'rw',
   isa              => HashRef,
   predicate        => 'has_required_when';

=item required_message

=cut

has 'required_message' => is => 'rw', isa => ArrayRef|Str;

=item unique

=item has_unique

Predicate

=cut

has 'unique' => is => 'rw', isa => Bool, predicate => 'has_unique';

=item unique_message

=cut

has 'unique_message' => is => 'rw', isa => Str;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item match_when

=cut

sub match_when {
   my ($self, $when) = @_;

   my $matched = 0;

   for my $key (keys %{ $when }) {
      my $check_against = $when->{ $key };
      my $from_form = ($key =~ m{ \A \+ }mx); $key =~ s{ \A \+ }{}mx;
      my $field = $from_form
                ? $self->form->field( $key ) : $self->parent->subfield( $key );

      unless ($field) {
         warn "Field '${key}' not found processing 'when' for '"
            . $self->full_name . "'";
         next;
      }

      my $field_fif = defined $field->fif ? $field->fif : NUL;

      if (is_coderef $check_against) {
         $matched++ if $check_against->( $field_fif, $self );
      }
      elsif (is_arrayref $check_against) {
         for my $value (@{ $check_against }) {
            $matched++ if $value eq $field_fif;
         }
      }
      elsif ($check_against eq $field_fif) { $matched++ }
      else { $matched = 0; last }
   }

   return $matched;
}

=item test_ranges

=cut

sub test_ranges {
   my $field = shift;

   return TRUE if $field->can('options') || $field->has_errors;

   my $value = $field->value;

   return TRUE unless defined $value;

   my $high = $field->range_end;
   my $low  = $field->range_start;

   if (defined $low && defined $high) {
      return $value >= $low && $value <= $high ? TRUE : $field->add_error(
         $field->get_message('range_incorrect'), $low, $high
      );
   }

   if (defined $low) {
      return $value >= $low ? TRUE : $field->add_error(
         $field->get_message('range_too_low'), $low
      );
   }

   if (defined $high) {
      return $value <= $high ? TRUE : $field->add_error(
         $field->get_message('range_too_high'), $high
      );
   }

   return TRUE;
}

=item validate

Returns true

=cut

sub validate {
   return TRUE;
}

=item validate_field

=cut

sub validate_field {
   my $self = shift;

   return unless $self->has_result;

   $self->clear_errors; # This is only here for testing convenience

   # If the 'fields_for_input_without_param' flag is set, and the field doesn't
   # have input, copy the value to the input.
   if (!$self->has_input && $self->form
       && $self->form->use_fields_for_input_without_param) {
      $self->result->_set_input( $self->value );
   }

   # Handle required and required_when processing, and transfer input to value
   my $continue_validation = TRUE;

   if (($self->required ||
        ($self->has_required_when && $self->match_when( $self->required_when )))
       && (!$self->has_input || !$self->input_defined)) {
      $self->missing(TRUE);
      $self->add_error($self->get_message('required'), ucfirst $self->loc_label);

      if ($self->has_input) {
         if ($self->not_nullable) { $self->_set_value( $self->input ) }
         else { $self->_set_value( undef ) }
      }

      $continue_validation = FALSE;
   }
   elsif ($self->DOES( 'HTML::Forms::Field::Repeatable' )) {}
   elsif (!$self->has_input) { $continue_validation = FALSE }
   elsif (!$self->input_defined) {
      if ($self->not_nullable) {
         $self->_set_value( $self->input );
         # Handles the case where a compound field value needs to have empty
         # subfields
         $continue_validation = FALSE unless $self->has_flag( 'is_compound' );
      }
      elsif ($self->no_value_if_empty || $self->has_flag( 'is_contains' )) {
         $continue_validation = FALSE;
      }
      else {
         $self->_set_value( undef );
         $continue_validation = FALSE;
      }
   }

   return unless $continue_validation || $self->validate_when_empty;

   # Do building of node
   if ($self->DOES( 'HTML::Forms::Fields' )) { $self->_fields_validate }
   else {
      my $input = $self->input;

      $input = $self->inflate( $input ) if $self->has_inflate_method;
      $self->_set_value( $input );
   }

   $self->_inner_validate_field;
   $self->_apply_actions;
   $self->validate( $self->value );
   $self->test_ranges;

   # Form field validation method
   $self->_validate( $self ) if $self->has_value && defined $self->value;
   # Validation done, if everything validated, do deflate_value for
   # final $form->value
   if ($self->has_deflate_value_method && !$self->has_errors) {
      $self->_set_value( $self->deflate_value( $self->value ) );
   }

   return !$self->has_errors;
}

# Private methods
sub _apply_actions {
   my $self = shift;
   my $error_message;

   my $is_type = sub {
      my $class = blessed shift;

      return $class ? $class->isa( 'Type::Tiny' ) : undef;
   };

   my @actions = map { is_arrayref $_ ? @{$_} : $_ } @{ $self->actions || [] };

   for my $action (@actions) {
      $error_message = undef;
      # The first time through value == input
      my $value = $self->value;
      my $new_value = $value;
      # Constraints
      $action = { type => $action } if !ref $action || $is_type->($action);

      if (my $when = $action->{when}) {
         next unless $self->match_when($when);
      }

      if (exists $action->{type}) {
         my $tobj;

         if ($is_type->($action->{type})) { $tobj = $action->{type} }
         else {
            my $type = $action->{type};

            throw "Cannot find type constraint [_1]", [$type];
         }

         if ($tobj->has_coercion && $tobj->validate($value)) {
            try {
               $new_value = $tobj->coerce( $value );
               $self->_set_value( $new_value );
            }
            catch {
               if ($tobj->has_message) {
                  $error_message = $tobj->message->($value);
               }
               else { $error_message = $_ }
            };
         }

         $error_message //= $tobj->validate($new_value);
      }
      elsif (is_coderef $action->{check}) {
         if (!$action->{check}->($value, $self)) {
            $error_message = $self->get_message('wrong_value');
         }
      }
      elsif (is_regexpref $action->{check}) {
         if ($value !~ $action->{check}) {
            $error_message = [ $self->get_message('no_match'), $value ];
         }
      }
      elsif (is_arrayref $action->{check}) {
         if (!grep { $value eq $_ } @{ $action->{check} }) {
            $error_message = [ $self->get_message('not_allowed'), $value ];
         }
      }
      elsif (is_coderef $action->{transform}) {
         try {
            no warnings 'all';
            $new_value = $action->{transform}->($value, $self);
            $self->_set_value($new_value);
         }
         catch {
            $error_message = $_ || $self->get_message('error_occurred');
         };
      }

      if (defined $error_message) {
         my @message = is_arrayref $error_message
                     ? @{$error_message} : ($error_message);

         if (defined $action->{message}) {
            my $act_msg = $action->{message};

            if (is_coderef $act_msg) {
               $act_msg = $act_msg->($value, $self, $error_message);
            }

            if (is_arrayref $act_msg) { @message = @{ $act_msg } }
            elsif (is_scalarref \$act_msg) { @message = ($act_msg) }
         }

         $self->add_error(@message);
      }
   }

   return;
}

sub _build_apply_list {
   my $self = shift;

   return unless get_meta($self);

   my $addr = refaddr $self;
   my $seen = $self->{_seen} //= {};

   return if $seen->{$addr};

   $seen->{$addr} = TRUE;

   my @apply_list;

   for my $class (reverse get_meta($self)->linearised_isa) {
      my $meta = get_meta($class);

      next unless $meta;

      if ($meta->can('calculate_all_roles')) {
         for my $role ($meta->calculate_all_roles) {
            if ($role->can('apply_list') && $role->has_apply_list) {
               for my $apply_def (@{ $role->apply_list }) {
                  push @apply_list, [ @{$apply_def} ]; # copy arrayref
               }
            }
         }
      }

      if ($meta->can('apply_list') && $meta->has_apply_list) {
         for my $apply_def (@{ $meta->apply_list }) {
            push @apply_list, [ @{$apply_def} ]; # copy arrayref
         }
      }
   }

   $self->add_action(@apply_list);
   return;
}

sub _inner_validate_field { }

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
